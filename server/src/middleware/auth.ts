import type { Context, MiddlewareHandler } from "hono";
import { collection } from "../db/mongo";
import { Collections } from "../db/collections";
import { verifyAccessToken } from "../auth/tokens";
import { can, type Permission } from "../auth/permissions";
import { forbidden, unauthorized } from "../lib/errors";
import type { Admin, AppEnv, Principal, Role, Shop, Tenant, User } from "../types/models";

/** Verifies the bearer token, then loads the subject fresh so revocations/role changes apply immediately. */
export const authenticate: MiddlewareHandler<AppEnv> = async (c, next) => {
  const header = c.req.header("Authorization");
  if (!header?.startsWith("Bearer ")) throw unauthorized("Missing bearer token");

  let claims;
  try {
    claims = await verifyAccessToken(header.slice(7));
  } catch {
    throw unauthorized("Invalid or expired token");
  }

  let principal: Principal;
  if (claims.kind === "admin") {
    const admin = await collection<Admin>(Collections.admins).findOne({ _id: claims.sub });
    if (!admin) throw unauthorized();
    principal = { kind: "admin", id: admin._id };
  } else {
    const user = await collection<User>(Collections.users).findOne({ _id: claims.sub });
    if (!user || !user.active) throw unauthorized();
    const tenant = await collection<Tenant>(Collections.tenants).findOne({ _id: user.tenantId });
    if (!tenant?.active) throw unauthorized("Tenant is disabled");
    principal = {
      kind: "user",
      id: user._id,
      tenantId: user.tenantId,
      role: user.role,
      shopIds: user.shopIds,
      allShops: user.role === "owner",
    };
  }
  c.set("principal", principal);
  await next();
};

export const requireAdmin: MiddlewareHandler<AppEnv> = async (c, next) => {
  if (c.get("principal").kind !== "admin") throw forbidden("Admin only");
  await next();
};

/** Requires a tenant user with one of the given roles. */
export const requireRole =
  (...roles: Role[]): MiddlewareHandler<AppEnv> =>
  async (c, next) => {
    const p = c.get("principal");
    if (p.kind !== "user" || !roles.includes(p.role)) throw forbidden("Insufficient role");
    await next();
  };

/** Requires the caller's role to hold a feature permission (see auth/permissions.ts). */
export const requirePermission =
  (permission: Permission): MiddlewareHandler<AppEnv> =>
  async (c, next) => {
    const p = c.get("principal");
    if (p.kind !== "user" || !can(p.role, permission)) throw forbidden("Insufficient permissions");
    await next();
  };

/**
 * Shops a request is allowed to touch. Owners see every shop (optionally narrowed
 * by ?shopId=). Everyone else is permanently limited to their assigned shops;
 * asking for a shop outside that set is rejected.
 * Returns null for "no shop restriction" (owner, no filter).
 */
export function scopedShopIds(c: Context<AppEnv>): string[] | null {
  const p = userOf(c);
  const requested = c.req.query("shopId");
  if (p.allShops) return requested ? [requested] : null;
  if (requested && !p.shopIds.includes(requested)) throw forbidden("No access to this shop");
  return requested ? [requested] : p.shopIds;
}

/** Requires a tenant user (any role). */
export const requireUser: MiddlewareHandler<AppEnv> = async (c, next) => {
  if (c.get("principal").kind !== "user") throw forbidden("Tenant user only");
  await next();
};

/** Ensures :shopId exists in the user's tenant and the user may access it. */
export const requireShopAccess: MiddlewareHandler<AppEnv> = async (c, next) => {
  const p = c.get("principal");
  if (p.kind !== "user") throw forbidden("Tenant user only");
  const shopId = c.req.param("shopId");
  if (!shopId) throw forbidden();
  if (!p.allShops && !p.shopIds.includes(shopId)) throw forbidden("No access to this shop");
  const shop = await collection<Shop>(Collections.shops).findOne({ _id: shopId, tenantId: p.tenantId });
  if (!shop) throw forbidden("No access to this shop");
  await next();
};

/** Returns the tenant principal; throws if the caller isn't a tenant user. */
export function userOf(c: Context<AppEnv>) {
  const p = c.get("principal");
  if (p.kind !== "user") throw forbidden("Tenant user only");
  return p;
}
