import { Hono } from "hono";
import { z } from "zod";
import { Collections } from "../db/collections";
import { collection } from "../db/mongo";
import { TenantRepo } from "../db/tenant-repo";
import { notFound } from "../lib/errors";
import { parseBody } from "../lib/validate";
import { requireRole, requireShopAccess, userOf } from "../middleware/auth";
import type { AppEnv, PrintProfile, PrintProfileDoc, Shop } from "../types/models";
import { shopScopedRouter } from "./shop-scoped";

const createSchema = z.object({
  name: z.string().min(1),
  address: z.string().optional(),
  phone: z.string().optional(),
  active: z.boolean().default(true),
});
const updateSchema = createSchema.partial();

// ── Print profiles (page setup + letterhead) ────────────────────────────────
// Stored in their own collection so the images never ride along with shop
// lists, sessions or sync pulls.

const mm = z.number().min(0).max(2000);
/** Base64 image; ~700k chars ≈ 500 KB. */
const image = z.string().max(700_000).nullish();
const printProfileSchema = z.object({
  pageSize: z.enum(["a4", "a5", "letter", "custom"]),
  pageWidthMm: mm.min(40),
  pageHeightMm: mm.min(40),
  marginTopMm: mm,
  marginBottomMm: mm,
  marginLeftMm: mm,
  marginRightMm: mm,
  headerImage: image,
  footerImage: image,
});

const printProfiles = () => collection<PrintProfileDoc>(Collections.printProfiles);
const profileId = (tenantId: string, shopId: string | null) =>
  shopId ? `${tenantId}:shop:${shopId}` : `${tenantId}:franchise`;

const publicProfile = (d: PrintProfileDoc): PrintProfile => {
  const { _id, tenantId, shopId, updatedAt, ...profile } = d;
  return profile;
};

async function saveProfile(tenantId: string, shopId: string | null, body: PrintProfile) {
  const _id = profileId(tenantId, shopId);
  const doc: PrintProfileDoc = {
    ...body,
    headerImage: body.headerImage ?? null,
    footerImage: body.footerImage ?? null,
    _id,
    tenantId,
    shopId,
    updatedAt: new Date(),
  };
  await printProfiles().replaceOne({ _id }, doc, { upsert: true });
  return publicProfile(doc);
}

const shopsOf = (tenantId: string) => new TenantRepo<Shop>(Collections.shops, tenantId);

/** Mounted under /shops behind authenticate + requireUser. */
export const shopsRouter = new Hono<AppEnv>()
  .get("/", async (c) => {
    const p = userOf(c);
    const filter = p.allShops ? {} : { _id: { $in: p.shopIds } };
    return c.json(await shopsOf(p.tenantId).list(filter, { sort: { name: 1 } }));
  })
  // Franchise default plus the override of every shop the caller can access.
  // (Static paths must stay above "/:shopId".)
  .get("/print-profiles", async (c) => {
    const p = userOf(c);
    const docs = await printProfiles()
      .find({
        tenantId: p.tenantId,
        ...(p.allShops ? {} : { $or: [{ shopId: null }, { shopId: { $in: p.shopIds } }] }),
      })
      .toArray();
    const franchise = docs.find((d) => d.shopId === null);
    return c.json({
      franchise: franchise ? publicProfile(franchise) : null,
      shops: Object.fromEntries(
        docs.filter((d) => d.shopId !== null).map((d) => [d.shopId, publicProfile(d)]),
      ),
    });
  })
  .put("/print-profile", requireRole("owner"), async (c) => {
    const body = await parseBody(c, printProfileSchema);
    return c.json(await saveProfile(userOf(c).tenantId, null, body));
  })
  .delete("/print-profile", requireRole("owner"), async (c) => {
    await printProfiles().deleteOne({ _id: profileId(userOf(c).tenantId, null) });
    return c.body(null, 204);
  })
  // A shop's own setup: the franchise owner, or the manager of that shop.
  .put("/:shopId/print-profile", requireRole("owner", "manager"), requireShopAccess, async (c) => {
    const body = await parseBody(c, printProfileSchema);
    return c.json(await saveProfile(userOf(c).tenantId, c.req.param("shopId"), body));
  })
  // Removing it makes the shop fall back to the franchise default.
  .delete("/:shopId/print-profile", requireRole("owner", "manager"), requireShopAccess, async (c) => {
    await printProfiles().deleteOne({ _id: profileId(userOf(c).tenantId, c.req.param("shopId")) });
    return c.body(null, 204);
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
