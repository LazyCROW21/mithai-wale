import { Hono } from "hono";
import { z } from "zod";
import { collection } from "../db/mongo";
import { Collections } from "../db/collections";
import { hashPassword, publicUser, verifyPassword } from "../lib/password";
import { unauthorized } from "../lib/errors";
import { parseBody } from "../lib/validate";
import { consumeRefreshToken, issueTokens, revokeRefreshToken } from "../auth/tokens";
import { authenticate } from "../middleware/auth";
import { rolePermissions } from "../auth/permissions";
import type { Admin, AppEnv, Shop, Tenant, User } from "../types/models";

/** What the client needs to render the right navigation and scope its lists. */
async function buildSession(user: User, tenant: Tenant) {
  const shops = await collection<Shop>(Collections.shops)
    .find(
      user.role === "owner"
        ? { tenantId: tenant._id }
        : { tenantId: tenant._id, _id: { $in: user.shopIds } },
    )
    .sort({ name: 1 })
    .toArray();
  return {
    user: publicUser(user),
    tenant: { id: tenant._id, name: tenant.name, slug: tenant.slug },
    permissions: rolePermissions[user.role],
    // For store owners/employees this is their (fixed) shop list; owners get every shop.
    shops: shops.map((s) => ({ id: s._id, name: s.name, active: s.active })),
  };
}

const loginSchema = z.object({
  tenant: z.string().min(1), // tenant slug
  username: z.string().min(1),
  password: z.string().min(1),
});
const adminLoginSchema = loginSchema.omit({ tenant: true });
const refreshSchema = z.object({ refreshToken: z.string().min(1) });

// Used to equalise timing when the account doesn't exist.
const dummyHash = await hashPassword("dummy-password");

async function checkPassword(plain: string, hash: string | undefined) {
  const ok = await verifyPassword(plain, hash ?? dummyHash);
  return ok && hash !== undefined;
}

export const authRouter = new Hono<AppEnv>()
  .post("/login", async (c) => {
    const { tenant: slug, username, password } = await parseBody(c, loginSchema);
    const tenant = await collection<Tenant>(Collections.tenants).findOne({ slug: slug.toLowerCase() });
    const user = tenant
      ? await collection<User>(Collections.users).findOne({ tenantId: tenant._id, username })
      : null;
    const ok = await checkPassword(password, user?.passwordHash);
    if (!tenant?.active || !user?.active || !ok) throw unauthorized("Invalid credentials");
    return c.json({ ...(await issueTokens("user", user._id)), ...(await buildSession(user, tenant)) });
  })
  .post("/refresh", async (c) => {
    const { refreshToken } = await parseBody(c, refreshSchema);
    const stored = await consumeRefreshToken(refreshToken);
    if (!stored) throw unauthorized("Invalid refresh token");
    return c.json(await issueTokens(stored.kind, stored.subjectId));
  })
  .post("/logout", async (c) => {
    const { refreshToken } = await parseBody(c, refreshSchema);
    await revokeRefreshToken(refreshToken);
    return c.body(null, 204);
  })
  .get("/me", authenticate, async (c) => {
    const p = c.get("principal");
    if (p.kind === "admin") {
      const admin = await collection<Admin>(Collections.admins).findOne({ _id: p.id });
      return c.json({ kind: "admin", user: admin && publicUser(admin) });
    }
    const user = await collection<User>(Collections.users).findOne({ _id: p.id });
    const tenant = user && (await collection<Tenant>(Collections.tenants).findOne({ _id: user.tenantId }));
    if (!user || !tenant) throw unauthorized();
    return c.json({ kind: "user", ...(await buildSession(user, tenant)) });
  });

export const adminAuthRouter = new Hono<AppEnv>().post("/login", async (c) => {
  const { username, password } = await parseBody(c, adminLoginSchema);
  const admin = await collection<Admin>(Collections.admins).findOne({ username });
  const ok = await checkPassword(password, admin?.passwordHash);
  if (!admin || !ok) throw unauthorized("Invalid credentials");
  return c.json({ ...(await issueTokens("admin", admin._id)), user: publicUser(admin) });
});
