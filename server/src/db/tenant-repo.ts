import type { Filter, FindOptions, OptionalUnlessRequiredId, UpdateFilter } from "mongodb";
import { collection } from "./mongo";
import { SoftDeleteCollections } from "./collections";
import type { TenantDoc } from "../types/models";

type NewDoc<T> = Omit<T, "_id" | "tenantId" | "createdAt" | "updatedAt" | "deletedAt"> & {
  _id?: string;
  /** Device-supplied creation time; defaults to now. */
  createdAt?: Date;
};

/**
 * Repository bound to one tenant (and optionally extra scope fields like shopId).
 *
 * - Every read/write is constrained by the scope, so handlers cannot touch
 *   another tenant's data.
 * - `updatedAt` is stamped by the server on every write (it's the sync cursor).
 * - For synced collections, deletes are soft (tombstones) and reads hide them.
 */
export class TenantRepo<T extends TenantDoc> {
  private readonly soft: boolean;

  constructor(
    private readonly name: string,
    private readonly tenantId: string,
    private readonly extraScope: Record<string, unknown> = {},
  ) {
    this.soft = SoftDeleteCollections.has(name);
  }

  private get col() {
    return collection<T>(this.name);
  }

  private scope(filter: object = {}, includeDeleted = false): Filter<T> {
    return {
      ...filter,
      ...this.extraScope,
      tenantId: this.tenantId,
      ...(this.soft && !includeDeleted ? { deletedAt: null } : {}),
    } as Filter<T>;
  }

  list(filter: object = {}, options?: FindOptions): Promise<T[]> {
    return this.col.find(this.scope(filter), options).toArray() as Promise<T[]>;
  }

  async get(id: string, includeDeleted = false): Promise<T | null> {
    return (await this.col.findOne(this.scope({ _id: id }, includeDeleted))) as T | null;
  }

  findOne(filter: object): Promise<T | null> {
    return this.col.findOne(this.scope(filter)) as Promise<T | null>;
  }

  async create(data: NewDoc<T>): Promise<T> {
    const now = new Date();
    const doc = {
      ...data,
      ...this.extraScope,
      _id: data._id ?? crypto.randomUUID(),
      tenantId: this.tenantId,
      createdAt: data.createdAt ?? now,
      updatedAt: now,
      ...(this.soft ? { deletedAt: null } : {}),
    } as unknown as T;
    await this.col.insertOne(doc as OptionalUnlessRequiredId<T>);
    return doc;
  }

  async update(id: string, patch: object): Promise<T | null> {
    const { _id, tenantId, createdAt, updatedAt, deletedAt, ...safe } = patch as Record<string, unknown>;
    return (await this.col.findOneAndUpdate(
      this.scope({ _id: id }),
      { $set: { ...safe, updatedAt: new Date() } } as UpdateFilter<T>,
      { returnDocument: "after" },
    )) as T | null;
  }

  /** Scoped raw update for custom operations (e.g. $inc). Stamps updatedAt. */
  updateOne(filter: object, update: UpdateFilter<T>, upsert = false) {
    const u = update as Record<string, Record<string, unknown> | undefined>;
    const withStamp = { ...u, $set: { ...(u.$set ?? {}), updatedAt: new Date() } } as UpdateFilter<T>;
    return this.col.updateOne(this.scope(filter), withStamp, { upsert });
  }

  /** Soft delete (tombstone) for synced collections, hard delete otherwise. */
  async remove(id: string): Promise<boolean> {
    if (this.soft) {
      const now = new Date();
      const res = await this.col.updateOne(this.scope({ _id: id }), {
        $set: { deletedAt: now, updatedAt: now },
      } as UpdateFilter<T>);
      return res.matchedCount === 1;
    }
    const res = await this.col.deleteOne(this.scope({ _id: id }));
    return res.deletedCount === 1;
  }

  count(filter: object = {}): Promise<number> {
    return this.col.countDocuments(this.scope(filter));
  }
}
