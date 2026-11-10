import { Hono } from "hono";
import { z } from "zod";
import { collection } from "../db/mongo";
import { Collections } from "../db/collections";
import { revokeAllFor } from "../auth/tokens";
import { HttpError, isDuplicateKey, notFound } from "../lib/errors";
import { hashPassword, publicUser } from "../lib/password";
import { parseBody } from "../lib/validate";
import type { AppEnv, Tenant, User } from "../types/models";

const slug = z
  .string()
  .min(2)
  .max(40)
  .regex(/^[a-z0-9]+(-[a-z0-9]+)*$/, "lowercase letters, digits and dashes only");

const createSchema = z.object({
  name: z.string().min(1),
  slug,
  owner: z.object({
    name: z.string().min(1),
    username: z.string().min(3),
    password: z.string().min(8),
  }),
});
const updateSchema = z.object({ name: z.string().min(1), active: z.boolean() }).partial();

const tenants = () => collection<Tenant>(Collections.tenants);
const users = () => collection<User>(Collections.users);

/** Mounted under /admin/tenants behind authenticate + requireAdmin. */
export const adminTenantsRouter = new Hono<AppEnv>()
  .get("/", async (c) => c.json(await tenants().find().sort({ createdAt: -1 }).toArray()))
  .get("/:id", async (c) => {
    const tenant = await tenants().findOne({ _id: c.req.param("id") });
    if (!tenant) throw notFound("Tenant");
    const owners = await users().find({ tenantId: tenant._id, role: "owner" }).toArray();
    return c.json({ ...tenant, owners: owners.map(publicUser) });
  })
  .post("/", async (c) => {
    const body = await parseBody(c, createSchema);
    const tenant: Tenant = {
      _id: crypto.randomUUID(),
      name: body.name,
      slug: body.slug,
      active: true,
      createdAt: new Date(),
    };
    try {
      await tenants().insertOne(tenant);
    } catch (e) {
      if (isDuplicateKey(e)) throw new HttpError(409, "Tenant slug already in use");
      throw e;
    }
    const owner: User = {
      _id: crypto.randomUUID(),
      tenantId: tenant._id,
      username: body.owner.username,
      passwordHash: await hashPassword(body.owner.password),
      name: body.owner.name,
      role: "owner",
      shopIds: [],
      active: true,
      createdAt: new Date(),
    };
    try {
      await users().insertOne(owner);
    } catch (e) {
      await tenants().deleteOne({ _id: tenant._id }); // keep creation atomic enough
      throw e;
    }
    return c.json({ ...tenant, owner: publicUser(owner) }, 201);
  })
  .patch("/:id", async (c) => {
    const patch = await parseBody(c, updateSchema);
    const tenant = await tenants().findOneAndUpdate(
      { _id: c.req.param("id") },
      { $set: patch },
      { returnDocument: "after" },
    );
    if (!tenant) throw notFound("Tenant");
    if (patch.active === false) {
      const all = await users().find({ tenantId: tenant._id }, { projection: { _id: 1 } }).toArray();
      await Promise.all(all.map((u) => revokeAllFor(u._id)));
    }
    return c.json(tenant);
  })
  /** Reset an owner's password (e.g. forgotten credentials). */
  .post("/:id/owners/:userId/reset-password", async (c) => {
    const { password } = await parseBody(c, z.object({ password: z.string().min(8) }));
    const res = await users().updateOne(
      { _id: c.req.param("userId"), tenantId: c.req.param("id"), role: "owner" },
      { $set: { passwordHash: await hashPassword(password) } },
    );
    if (res.matchedCount === 0) throw notFound("Owner");
    await revokeAllFor(c.req.param("userId"));
    return c.body(null, 204);
  });
