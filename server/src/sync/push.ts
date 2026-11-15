import { z } from "zod";
import type { Document } from "mongodb";
import { collection } from "../db/mongo";
import { Collections } from "../db/collections";
import { isDuplicateKey } from "../lib/errors";
import type { Principal, Shop } from "../types/models";
import { specByName, type SyncSpec } from "./registry";

export const MAX_PUSH_OPS = 100;
const OP_RESULT_TTL_DAYS = 30;

type UserPrincipal = Extract<Principal, { kind: "user" }>;

/** Synced documents use string ids (UUIDs from devices). */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type SyncRecord = { _id: string; [key: string]: any };

// ── Wire DTOs ────────────────────────────────────────────────────────────────

export const pushRequest = z.object({
  deviceId: z.string().min(1).max(100),
  // Each op is validated individually so one bad op doesn't fail the batch.
  ops: z.array(z.record(z.string(), z.unknown())).max(MAX_PUSH_OPS),
});

const id = z.string().min(1).max(100);
const base = { opId: id, collection: z.string(), id };
const opSchema = z.discriminatedUnion("op", [
  z.object({ ...base, op: z.literal("create"), shopId: z.string().optional(), doc: z.record(z.string(), z.unknown()) }),
  z.object({ ...base, op: z.literal("update"), baseUpdatedAt: z.coerce.date().optional(), patch: z.record(z.string(), z.unknown()) }),
  z.object({ ...base, op: z.literal("delete"), baseUpdatedAt: z.coerce.date().optional() }),
  z.object({ ...base, op: z.literal("adjust"), delta: z.number() }),
]);
type SyncOp = z.infer<typeof opSchema>;

export type OpStatus = "applied" | "merged" | "duplicate" | "conflict" | "rejected";

export interface OpResult {
  opId: string;
  status: OpStatus;
  id?: string;
  updatedAt?: Date;
  doc?: Document;
  error?: { code: string; message: string };
}

const reject = (opId: string, id: string | undefined, code: string, message: string): OpResult => ({
  opId,
  id,
  status: "rejected",
  error: { code, message },
});

/** Removes server-internal fields before returning a document to a device. */
export function toWire(doc: Document): Document {
  const { tenantId, ...rest } = doc;
  return rest;
}

// ── Processing ───────────────────────────────────────────────────────────────

export async function processPush(
  p: UserPrincipal,
  deviceId: string,
  rawOps: Record<string, unknown>[],
): Promise<OpResult[]> {
  const results: OpResult[] = [];
  // Sequential on purpose: ops on the same document must apply in order.
  for (const raw of rawOps) {
    results.push(await processOne(p, deviceId, raw));
  }
  return results;
}

async function processOne(p: UserPrincipal, deviceId: string, raw: Record<string, unknown>): Promise<OpResult> {
  const opId = typeof raw.opId === "string" ? raw.opId : "";
  const parsed = opSchema.safeParse(raw);
  if (!parsed.success) {
    return reject(opId, typeof raw.id === "string" ? raw.id : undefined, "INVALID_OP", z.prettifyError(parsed.error));
  }
  const op = parsed.data;

  // Idempotency: a retried op returns its original outcome.
  const opsCol = collection<{ _id: string; result: OpResult; expiresAt: Date }>(Collections.syncOps);
  const opKey = `${p.tenantId}:${op.opId}`;
  const seen = await opsCol.findOne({ _id: opKey });
  if (seen) return { ...seen.result, status: seen.result.status === "rejected" ? "rejected" : "duplicate" };

  const result = await apply(p, deviceId, op);
  if (result.status !== "rejected" || result.error?.code !== "INTERNAL") {
    await opsCol
      .insertOne({ _id: opKey, result, expiresAt: new Date(Date.now() + OP_RESULT_TTL_DAYS * 86_400_000) })
      .catch((e) => {
        if (!isDuplicateKey(e)) throw e;
      });
  }
  return result;
}

async function apply(p: UserPrincipal, deviceId: string, op: SyncOp): Promise<OpResult> {
  const spec = specByName.get(op.collection);
  if (!spec) return reject(op.opId, op.id, "UNKNOWN_COLLECTION", `'${op.collection}' is not synced`);
  if (!spec.ops.includes(op.op)) {
    return reject(op.opId, op.id, "OP_NOT_ALLOWED", `'${op.op}' is not allowed on ${spec.collection}`);
  }
  const roles = op.op === "delete" ? (spec.deleteRoles ?? spec.writeRoles) : spec.writeRoles;
  if (!roles.includes(p.role)) return reject(op.opId, op.id, "FORBIDDEN", "Your role cannot do this");

  try {
    switch (op.op) {
      case "create":
        return await applyCreate(p, deviceId, spec, op);
      case "update":
        return await applyUpdate(p, deviceId, spec, op);
      case "delete":
        return await applyDelete(p, deviceId, spec, op);
      case "adjust":
        return await applyAdjust(p, deviceId, spec, op);
    }
  } catch (e) {
    console.error("sync op failed", op.opId, e);
    return reject(op.opId, op.id, "INTERNAL", "Server error while applying this change");
  }
}

/** Filter that limits a shop-scoped collection to the user's shops. */
function accessFilter(p: UserPrincipal, spec: SyncSpec): Document {
  const f: Document = { tenantId: p.tenantId };
  if (spec.scope === "shop" && !p.allShops) f.shopId = { $in: p.shopIds };
  return f;
}

async function resolveShopId(p: UserPrincipal, requested: string | undefined): Promise<string | null> {
  if (!p.allShops) {
    if (requested) return p.shopIds.includes(requested) ? requested : null;
    return p.shopIds[0] ?? null; // store-scoped users write to their own shop
  }
  if (!requested) return null;
  const shop = await collection<Shop>(Collections.shops).findOne({ _id: requested, tenantId: p.tenantId });
  return shop ? requested : null;
}

async function applyCreate(
  p: UserPrincipal,
  deviceId: string,
  spec: SyncSpec,
  op: Extract<SyncOp, { op: "create" }>,
): Promise<OpResult> {
  const doc = spec.doc.safeParse(op.doc);
  if (!doc.success) return reject(op.opId, op.id, "VALIDATION", z.prettifyError(doc.error));

  const col = collection<SyncRecord>(spec.collection);
  let shopId: string | null = null;
  if (spec.scope === "shop") {
    shopId = await resolveShopId(p, op.shopId);
    if (!shopId) return reject(op.opId, op.id, "SHOP_NOT_ALLOWED", "Missing or inaccessible shopId");
  }

  const now = new Date();
  const { createdAt, ...fields } = doc.data as Record<string, unknown> & { createdAt?: Date };
  const record: SyncRecord = {
    ...fields,
    _id: op.id,
    tenantId: p.tenantId,
    ...(shopId ? { shopId } : {}),
    createdAt: createdAt ?? now,
    updatedAt: now,
    deletedAt: null,
    updatedBy: { userId: p.id, deviceId },
  };
  try {
    await col.insertOne(record);
  } catch (e) {
    if (!isDuplicateKey(e)) throw e;
    // Same id already exists: a retried create whose result was lost.
    const existing = await col.findOne({ _id: op.id, ...accessFilter(p, spec) });
    if (!existing) return reject(op.opId, op.id, "ID_TAKEN", "This id belongs to another record");
    return { opId: op.opId, status: "duplicate", id: op.id, updatedAt: existing.updatedAt, doc: toWire(existing) };
  }
  return { opId: op.opId, status: "applied", id: op.id, updatedAt: now };
}

async function applyUpdate(
  p: UserPrincipal,
  deviceId: string,
  spec: SyncSpec,
  op: Extract<SyncOp, { op: "update" }>,
): Promise<OpResult> {
  const patch = spec.doc.partial().strict().safeParse(op.patch);
  if (!patch.success) return reject(op.opId, op.id, "VALIDATION", z.prettifyError(patch.error));
  const { createdAt: _ignored, ...fields } = patch.data as Record<string, unknown>;

  const col = collection<SyncRecord>(spec.collection);
  const filter = { _id: op.id, ...accessFilter(p, spec) };
  const current = await col.findOne(filter);
  if (!current) return reject(op.opId, op.id, "NOT_FOUND", "Record not found");
  if (current.deletedAt) {
    // Deletes win: tell the device the record is gone.
    return { opId: op.opId, status: "conflict", id: op.id, updatedAt: current.updatedAt, doc: toWire(current),
      error: { code: "DELETED", message: "Record was deleted on another device" } };
  }

  const now = new Date();
  const updated = await col.findOneAndUpdate(
    filter,
    { $set: { ...fields, updatedAt: now, updatedBy: { userId: p.id, deviceId } } },
    { returnDocument: "after" },
  );
  if (!updated) return reject(op.opId, op.id, "NOT_FOUND", "Record not found");

  // Field-level last-writer-wins: if someone else changed the record since the
  // device last saw it, the patch is still applied and the merged doc returned.
  const stale = op.baseUpdatedAt && current.updatedAt > op.baseUpdatedAt;
  return stale
    ? { opId: op.opId, status: "merged", id: op.id, updatedAt: now, doc: toWire(updated) }
    : { opId: op.opId, status: "applied", id: op.id, updatedAt: now };
}

async function applyDelete(
  p: UserPrincipal,
  deviceId: string,
  spec: SyncSpec,
  op: Extract<SyncOp, { op: "delete" }>,
): Promise<OpResult> {
  const col = collection<SyncRecord>(spec.collection);
  const filter = { _id: op.id, ...accessFilter(p, spec) };
  const current = await col.findOne(filter);
  if (!current) return reject(op.opId, op.id, "NOT_FOUND", "Record not found");
  if (current.deletedAt) return { opId: op.opId, status: "applied", id: op.id, updatedAt: current.updatedAt };

  const now = new Date();
  await col.updateOne(filter, { $set: { deletedAt: now, updatedAt: now, updatedBy: { userId: p.id, deviceId } } });
  return { opId: op.opId, status: "applied", id: op.id, updatedAt: now };
}

async function applyAdjust(
  p: UserPrincipal,
  deviceId: string,
  spec: SyncSpec,
  op: Extract<SyncOp, { op: "adjust" }>,
): Promise<OpResult> {
  const col = collection<SyncRecord>(spec.collection);
  const filter = { _id: op.id, deletedAt: null, ...accessFilter(p, spec) };
  const now = new Date();
  const updated = await col.findOneAndUpdate(
    { ...filter, ...(op.delta < 0 ? { quantity: { $gte: -op.delta } } : {}) },
    { $inc: { quantity: op.delta }, $set: { updatedAt: now, updatedBy: { userId: p.id, deviceId } } },
    { returnDocument: "after" },
  );
  if (updated) return { opId: op.opId, status: "applied", id: op.id, updatedAt: now, doc: toWire(updated) };

  const current = await col.findOne(filter);
  if (!current) return reject(op.opId, op.id, "NOT_FOUND", "Record not found");
  return {
    opId: op.opId,
    status: "rejected",
    id: op.id,
    doc: toWire(current),
    error: { code: "INSUFFICIENT_STOCK", message: "Stock would go below zero" },
  };
}
