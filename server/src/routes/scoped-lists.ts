import { Hono } from "hono";
import { Collections } from "../db/collections";
import { TenantRepo } from "../db/tenant-repo";
import { notImplemented } from "../lib/errors";
import { requirePermission, scopedShopIds, userOf } from "../middleware/auth";
import type { AppEnv, InventoryItem } from "../types/models";

/**
 * Role-aware "flat" list routes.
 *
 * Franchise admins (owner) see data across all shops and can narrow with ?shopId=.
 * Store owners / employees are permanently filtered to their own shop(s) by the
 * server, so the client never has to (and cannot) widen the scope.
 */
export const inventoryListRouter = new Hono<AppEnv>()
  .use(requirePermission("inventory"))
  .get("/", async (c) => {
    const ids = scopedShopIds(c);
    const items = await new TenantRepo<InventoryItem>(Collections.inventoryItems, userOf(c).tenantId).list(
      ids ? { shopId: { $in: ids } } : {},
      { sort: { name: 1 } },
    );
    return c.json(items);
  });

// Business layer for orders/payments isn't implemented yet; the routes and guards are.
export const ordersListRouter = new Hono<AppEnv>()
  .use(requirePermission("orders"))
  .all("*", () => {
    throw notImplemented("Orders");
  });

export const paymentsListRouter = new Hono<AppEnv>()
  .use(requirePermission("ledger"))
  .all("*", () => {
    throw notImplemented("Payments");
  });
