import { z } from "zod";
import type { Document } from "mongodb";
import { can } from "../auth/permissions";
import { collection } from "../db/mongo";
import { Collections } from "../db/collections";
import type { Principal } from "../types/models";
import { syncSpecs } from "./registry";
import { toWire, type SyncRecord } from "./push";

type UserPrincipal = Extract<Principal, { kind: "user" }>;

export const DEFAULT_PULL_LIMIT = 500;
export const MAX_PULL_LIMIT = 1000;
/**
 * Only changes older than this are served. A write that started earlier but
 * committed later than a faster one would otherwise land behind a device's
 * cursor and never be pulled.
 */
export const SETTLE_MS = 3000;

export const pullQuery = z.object({
  since: z.coerce.date().optional(),
  afterId: z.string().default(""),
  limit: z.coerce.number().int().min(1).max(MAX_PULL_LIMIT).default(DEFAULT_PULL_LIMIT),
  /** Scope fingerprint from the device's previous pull; a mismatch forces a full resync. */
  scope: z.string().optional(),
});
export type PullQuery = z.infer<typeof pullQuery>;

interface Source {
  name: string;
  filter: Document;
}

/** Fingerprint of what this user may see. Changes when role or shop assignment changes. */
export function scopeOf(p: UserPrincipal): string {
  const key = `${p.role}|${p.allShops ? "*" : [...p.shopIds].sort().join(",")}`;
  return new Bun.CryptoHasher("sha256").update(key).digest("hex").slice(0, 16);
}

function sourcesFor(p: UserPrincipal): Source[] {
  const shopFilter = p.allShops ? {} : { shopId: { $in: p.shopIds } };
  const sources: Source[] = [
    // Shops are pull-only: names/active flags for the device.
    { name: Collections.shops, filter: p.allShops ? {} : { _id: { $in: p.shopIds } } },
  ];
  for (const spec of syncSpecs) {
    if (spec.readPermission && !can(p.role, spec.readPermission)) continue;
    sources.push({ name: spec.collection, filter: spec.scope === "shop" ? shopFilter : {} });
  }
  return sources;
}

export async function processPull(p: UserPrincipal, q: PullQuery) {
  const serverTime = new Date();
  const scope = scopeOf(p);

  if (q.since && q.scope && q.scope !== scope) {
    return { serverTime, scope, resync: true, changes: {}, next: null, hasMore: false };
  }

  const upper = new Date(serverTime.getTime() - SETTLE_MS);
  const cursor: Document = q.since
    ? { $or: [{ updatedAt: { $gt: q.since } }, { updatedAt: q.since, _id: { $gt: q.afterId } }] }
    : {};

  // Fetch limit+1 from each collection, then merge by (updatedAt, _id) so one
  // cursor stays valid across collections.
  const perSource = await Promise.all(
    sourcesFor(p).map(async (s) => {
      const docs = await collection<SyncRecord>(s.name)
        .find(<Document>{
          ...s.filter,
          tenantId: p.tenantId,
          updatedAt: { $lte: upper },
          ...cursor,
          // A full download doesn't need tombstones.
          ...(q.since ? {} : { deletedAt: null }),
        })
        .sort({ updatedAt: 1, _id: 1 })
        .limit(q.limit + 1)
        .toArray();
      return docs.map((d) => ({ source: s.name, doc: d }));
    }),
  );

  const merged = perSource
    .flat()
    .sort((a, b) => a.doc.updatedAt - b.doc.updatedAt || (a.doc._id < b.doc._id ? -1 : a.doc._id > b.doc._id ? 1 : 0));
  const page = merged.slice(0, q.limit);
  const hasMore = merged.length > q.limit;

  const changes: Record<string, Document[]> = {};
  for (const { source, doc } of page) (changes[source] ??= []).push(toWire(doc));

  const last = page.at(-1)?.doc;
  // Nothing new up to `upper`: the device can safely move its cursor there.
  const next = last
    ? { since: last.updatedAt as Date, afterId: last._id as string }
    : { since: upper, afterId: "" };

  return { serverTime, scope, resync: false, changes, next, hasMore };
}
