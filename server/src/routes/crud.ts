import { Hono, type MiddlewareHandler } from "hono";
import type { z } from "zod";
import { TenantRepo } from "../db/tenant-repo";
import { notFound } from "../lib/errors";
import { parseBody } from "../lib/validate";
import { requireRole, userOf } from "../middleware/auth";
import type { AppEnv, Role, TenantDoc } from "../types/models";

interface CrudOptions {
  collection: string;
  label: string;
  createSchema: z.ZodType;
  updateSchema: z.ZodType;
  /** Roles allowed to create/update/delete. */
  writeRoles: Role[];
  /** Roles allowed to read. Defaults to every tenant user. */
  readRoles?: Role[];
  /** Extra scope fields derived from the request (e.g. shopId from the path). */
  scope?: (c: { req: { param: (k: string) => string | undefined } }) => Record<string, unknown>;
  /** Mongo sort for list. */
  sort?: Record<string, 1 | -1>;
}

/** Tenant-scoped CRUD router. Assumes `authenticate` (and shop access, if scoped) ran upstream. */
export function crudRouter<T extends TenantDoc>(opts: CrudOptions) {
  const repoOf = (c: Parameters<typeof userOf>[0]) =>
    new TenantRepo<T>(opts.collection, userOf(c).tenantId, opts.scope?.(c) ?? {});
  const write = requireRole(...opts.writeRoles);
  const read: MiddlewareHandler<AppEnv> = opts.readRoles
    ? requireRole(...opts.readRoles)
    : (_c, next) => next();

  return new Hono<AppEnv>()
    .get("/", read, async (c) => c.json(await repoOf(c).list({}, { sort: opts.sort })))
    .get("/:id", read, async (c) => {
      const doc = await repoOf(c).get(c.req.param("id"));
      if (!doc) throw notFound(opts.label);
      return c.json(doc);
    })
    .post("/", write, async (c) => {
      const body = (await parseBody(c, opts.createSchema)) as Omit<T, "_id" | "tenantId" | "createdAt">;
      return c.json(await repoOf(c).create(body), 201);
    })
    .patch("/:id", write, async (c) => {
      const body = await parseBody(c, opts.updateSchema);
      const doc = await repoOf(c).update(c.req.param("id"), body as object);
      if (!doc) throw notFound(opts.label);
      return c.json(doc);
    })
    .delete("/:id", write, async (c) => {
      if (!(await repoOf(c).remove(c.req.param("id")))) throw notFound(opts.label);
      return c.body(null, 204);
    });
}
