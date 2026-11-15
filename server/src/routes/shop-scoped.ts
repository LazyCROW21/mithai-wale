import { Hono } from "hono";
import { z } from "zod";
import { Collections } from "../db/collections";
import { TenantRepo } from "../db/tenant-repo";
import { notFound } from "../lib/errors";
import { parseBody } from "../lib/validate";
import { requireRole, userOf } from "../middleware/auth";
import type { AppEnv, InventoryItem, MenuItem, ShopMenuItem } from "../types/models";
import { crudRouter } from "./crud";
import { inventoryDoc } from "../sync/schemas";

const shopScope = (c: { req: { param: (k: string) => string | undefined } }) => ({
  shopId: c.req.param("shopId"),
});

const inventoryCreate = inventoryDoc;

const inventory = crudRouter<InventoryItem>({
  collection: Collections.inventoryItems,
  label: "Inventory item",
  createSchema: inventoryCreate,
  updateSchema: inventoryCreate.partial(),
  writeRoles: ["owner", "manager"],
  readRoles: ["owner", "manager"],
  scope: shopScope,
  sort: { name: 1 },
}).post("/:id/adjust", requireRole("owner", "manager"), async (c) => {
  const { delta } = await parseBody(c, z.object({ delta: z.number() }));
  const repo = new TenantRepo<InventoryItem>(Collections.inventoryItems, userOf(c).tenantId, shopScope(c));
  const id = c.req.param("id");
  // Reject adjustments that would take stock below zero.
  const res = await repo.updateOne(
    { _id: id, ...(delta < 0 ? { quantity: { $gte: -delta } } : {}) },
    { $inc: { quantity: delta } },
  );
  if (res.matchedCount === 0) {
    if (!(await repo.get(id))) throw notFound("Inventory item");
    return c.json({ error: { message: "Insufficient stock" } }, 409);
  }
  return c.json(await repo.get(id));
});

/** Franchise catalog merged with this shop's overrides. */
const menu = new Hono<AppEnv>()
  .get("/", async (c) => {
    const { tenantId } = userOf(c);
    const items = await new TenantRepo<MenuItem>(Collections.menuItems, tenantId).list({ isAvailable: true });
    const overrides = await new TenantRepo<ShopMenuItem>(Collections.shopMenuItems, tenantId, shopScope(c)).list();
    const byItem = new Map(overrides.map((o) => [o.menuItemId, o]));
    return c.json(
      items.map((item) => {
        const o = byItem.get(item._id);
        return { ...item, enabled: o?.enabled ?? true, price: o?.price ?? item.price };
      }),
    );
  })
  .put(
    "/:menuItemId",
    requireRole("owner", "manager"),
    async (c) => {
      const { tenantId } = userOf(c);
      const menuItemId = c.req.param("menuItemId");
      const body = await parseBody(c, z.object({ enabled: z.boolean(), price: z.number().min(0).optional() }));
      if (!(await new TenantRepo<MenuItem>(Collections.menuItems, tenantId).get(menuItemId))) {
        throw notFound("Menu item");
      }
      const repo = new TenantRepo<ShopMenuItem>(Collections.shopMenuItems, tenantId, shopScope(c));
      const set = { enabled: body.enabled, ...(body.price !== undefined ? { price: body.price } : {}) };
      await repo.updateOne(
        { menuItemId },
        {
          $set: set,
          ...(body.price === undefined ? { $unset: { price: "" } } : {}),
          $setOnInsert: { _id: crypto.randomUUID(), createdAt: new Date(), deletedAt: null },
        },
        true,
      );
      return c.json(await repo.findOne({ menuItemId }));
    },
  );

/** Everything mounted here is already behind authenticate + requireShopAccess. */
export const shopScopedRouter = new Hono<AppEnv>()
  .route("/menu", menu)
  .route("/inventory", inventory);
// Orders and payments are written through /sync/push; read them via
// /orders?shopId= and /payments?shopId=.
