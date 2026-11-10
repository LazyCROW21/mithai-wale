import { Hono } from "hono";
import { z } from "zod";
import { Collections } from "../db/collections";
import { TenantRepo } from "../db/tenant-repo";
import { revokeAllFor } from "../auth/tokens";
import { HttpError, forbidden, isDuplicateKey, notFound } from "../lib/errors";
import { hashPassword, publicUser } from "../lib/password";
import { parseBody } from "../lib/validate";
import { userOf } from "../middleware/auth";
import type { AppEnv, Shop, User } from "../types/models";

const staffRole = z.enum(["manager", "employee"]);

const createSchema = z.object({
  username: z.string().min(3),
  password: z.string().min(8),
  name: z.string().min(1),
  role: staffRole,
  // Store owners and employees must be tied to at least one shop.
  shopIds: z.array(z.string()).min(1, "Assign at least one shop"),
});
const updateSchema = z
  .object({
    name: z.string().min(1),
    role: staffRole,
    shopIds: z.array(z.string()).min(1, "Assign at least one shop"),
    active: z.boolean(),
    password: z.string().min(8),
  })
  .partial();

const usersOf = (tenantId: string) => new TenantRepo<User>(Collections.users, tenantId);

async function assertShopsInTenant(tenantId: string, shopIds: string[]) {
  if (shopIds.length === 0) return;
  const found = await new TenantRepo<Shop>(Collections.shops, tenantId).count({ _id: { $in: shopIds } });
  if (found !== new Set(shopIds).size) throw new HttpError(422, "One or more shopIds are invalid");
}

/** Mounted under /users behind authenticate + requireRole("owner"). */
export const usersRouter = new Hono<AppEnv>()
  .get("/", async (c) => {
    const list = await usersOf(userOf(c).tenantId).list();
    return c.json(list.map(publicUser));
  })
  .get("/:id", async (c) => {
    const user = await usersOf(userOf(c).tenantId).get(c.req.param("id"));
    if (!user) throw notFound("User");
    return c.json(publicUser(user));
  })
  .post("/", async (c) => {
    const { tenantId } = userOf(c);
    const body = await parseBody(c, createSchema);
    await assertShopsInTenant(tenantId, body.shopIds);
    const { password, ...rest } = body;
    try {
      const user = await usersOf(tenantId).create({
        ...rest,
        passwordHash: await hashPassword(password),
        active: true,
      });
      return c.json(publicUser(user), 201);
    } catch (e) {
      if (isDuplicateKey(e)) throw new HttpError(409, "Username already in use");
      throw e;
    }
  })
  .patch("/:id", async (c) => {
    const { tenantId } = userOf(c);
    const repo = usersOf(tenantId);
    const target = await repo.get(c.req.param("id"));
    if (!target) throw notFound("User");
    if (target.role === "owner") throw forbidden("Owner accounts are managed by the platform admin");

    const { password, ...patch } = await parseBody(c, updateSchema);
    if (patch.shopIds) await assertShopsInTenant(tenantId, patch.shopIds);
    const set: Partial<User> = { ...patch };
    if (password) set.passwordHash = await hashPassword(password);

    const updated = await repo.update(target._id, set);
    if (password || patch.active === false) await revokeAllFor(target._id);
    return c.json(publicUser(updated!));
  })
  .delete("/:id", async (c) => {
    const repo = usersOf(userOf(c).tenantId);
    const target = await repo.get(c.req.param("id"));
    if (!target) throw notFound("User");
    if (target.role === "owner") throw forbidden("Owner accounts cannot be deleted here");
    await repo.remove(target._id);
    await revokeAllFor(target._id);
    return c.body(null, 204);
  });
