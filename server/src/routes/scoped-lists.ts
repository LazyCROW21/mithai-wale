import { Hono } from "hono";
import { Collections } from "../db/collections";
import { TenantRepo } from "../db/tenant-repo";
import type { Permission } from "../auth/permissions";
import { requirePermission, scopedShopIds, userOf } from "../middleware/auth";
import type { AppEnv, TenantDoc } from "../types/models";

/**
 * Role-aware read-only list routes.
 *
 * Franchise admins (owner) see data across all shops and can narrow with ?shopId=.
 * Store owners / employees are permanently filtered to their own shop(s) by the
 * server, so the client never has to (and cannot) widen the scope.
 * Writes for these collections go through /sync/push.
 */
function scopedList(name: string, permission: Permission, sort: Record<string, 1 | -1>) {
  return new Hono<AppEnv>().use(requirePermission(permission)).get("/", async (c) => {
    const ids = scopedShopIds(c);
    const docs = await new TenantRepo<TenantDoc>(name, userOf(c).tenantId).list(
      ids ? { shopId: { $in: ids } } : {},
      { sort },
    );
    return c.json(docs);
  });
}

export const inventoryListRouter = scopedList(Collections.inventoryItems, "inventory", { name: 1 });
export const ordersListRouter = scopedList(Collections.orders, "orders", { orderDate: -1 });
export const paymentsListRouter = scopedList(Collections.payments, "ledger", { createdAt: -1 });
