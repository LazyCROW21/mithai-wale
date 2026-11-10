import type { Filter, FindOptions, OptionalUnlessRequiredId, UpdateFilter } from "mongodb";
import { collection } from "./mongo";
import type { TenantDoc } from "../types/models";

/**
 * Repository bound to one tenant (and optionally extra scope fields like shopId).
 * Every read/write is automatically constrained by the scope, so handlers cannot
 * accidentally touch another tenant's data.
 */
export class TenantRepo<T extends TenantDoc> {
  constructor(
    private readonly name: string,
    private readonly tenantId: string,
    private readonly extraScope: Record<string, unknown> = {},
  ) {}

  private get col() {
    return collection<T>(this.name);
  }

  private scope(filter: object = {}): Filter<T> {
    return { ...filter, ...this.extraScope, tenantId: this.tenantId } as Filter<T>;
  }

  list(filter: object = {}, options?: FindOptions): Promise<T[]> {
    return this.col.find(this.scope(filter), options).toArray() as Promise<T[]>;
  }

  async get(id: string): Promise<T | null> {
    return (await this.col.findOne(this.scope({ _id: id }))) as T | null;
  }

  findOne(filter: object): Promise<T | null> {
    return this.col.findOne(this.scope(filter)) as Promise<T | null>;
  }

  async create(data: Omit<T, "_id" | "tenantId" | "createdAt">): Promise<T> {
    const doc = {
      ...data,
      ...this.extraScope,
      _id: crypto.randomUUID(),
      tenantId: this.tenantId,
      createdAt: new Date(),
    } as unknown as T;
    await this.col.insertOne(doc as OptionalUnlessRequiredId<T>);
    return doc;
  }

  async update(id: string, patch: object): Promise<T | null> {
    const { _id, tenantId, createdAt, ...safe } = patch as Record<string, unknown>;
    return (await this.col.findOneAndUpdate(
      this.scope({ _id: id }),
      { $set: safe } as UpdateFilter<T>,
      { returnDocument: "after" },
    )) as T | null;
  }

  /** Scoped raw update for custom operations (e.g. $inc, upsert). */
  updateOne(filter: object, update: UpdateFilter<T>, upsert = false) {
    return this.col.updateOne(this.scope(filter), update, { upsert });
  }

  async remove(id: string): Promise<boolean> {
    const res = await this.col.deleteOne(this.scope({ _id: id }));
    return res.deletedCount === 1;
  }

  count(filter: object = {}): Promise<number> {
    return this.col.countDocuments(this.scope(filter));
  }
}
