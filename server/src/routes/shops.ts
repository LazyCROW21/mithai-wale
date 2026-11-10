import { Hono } from "hono";
import { z } from "zod";
import { Collections } from "../db/collections";
import { TenantRepo } from "../db/tenant-repo";
import { notFound } from "../lib/errors";
import { parseBody } from "../lib/validate";
import { requireRole, requireShopAccess, userOf } from "../middleware/auth";
import type { AppEnv, Shop } from "../types/models";
import { shopScopedRouter } from "./shop-scoped";

const createSchema = z.object({
  name: z.string().min(1),
  address: z.string().optional(),
  phone: z.string().optional(),
  active: z.boolean().default(true),
});
const updateSchema = createSchema.partial();

const shopsOf = (tenantId: string) => new TenantRepo<Shop>(Collections.shops, tenantId);

/** Mounted under /shops behind authenticate + requireUser. */
export const shopsRouter = new Hono<AppEnv>()
  .get("/", async (c) => {
    const p = userOf(c);
    const filter = p.allShops ? {} : { _id: { $in: p.shopIds } };
    return c.json(await shopsOf(p.tenantId).list(filter, { sort: { name: 1 } }));
  })
  .post("/", requireRole("owner"), async (c) => {
    const body = await parseBody(c, createSchema);
    return c.json(await shopsOf(userOf(c).tenantId).create(body), 201);
  })
  .get("/:shopId", requireShopAccess, async (c) => {
    const shop = await shopsOf(userOf(c).tenantId).get(c.req.param("shopId"));
    if (!shop) throw notFound("Shop");
    return c.json(shop);
  })
  .patch("/:shopId", requireRole("owner"), async (c) => {
    const body = await parseBody(c, updateSchema);
    const shop = await shopsOf(userOf(c).tenantId).update(c.req.param("shopId"), body);
    if (!shop) throw notFound("Shop");
    return c.json(shop);
  })
  // Everything under /shops/:shopId/* requires access to that shop.
  .use("/:shopId/*", requireShopAccess)
  .route("/:shopId", shopScopedRouter);
