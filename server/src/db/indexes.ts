import { collection } from "./mongo";
import { Collections as C } from "./collections";

export async function ensureIndexes(): Promise<void> {
  await Promise.all([
    collection(C.admins).createIndex({ username: 1 }, { unique: true }),
    collection(C.tenants).createIndex({ slug: 1 }, { unique: true }),
    collection(C.users).createIndex({ tenantId: 1, username: 1 }, { unique: true }),
    collection(C.refreshTokens).createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 }),
    collection(C.refreshTokens).createIndex({ subjectId: 1 }),
    collection(C.shops).createIndex({ tenantId: 1, active: 1 }),
    collection(C.categories).createIndex({ tenantId: 1, sortOrder: 1 }),
    collection(C.menuItems).createIndex({ tenantId: 1, categoryId: 1 }),
    collection(C.shopMenuItems).createIndex(
      { tenantId: 1, shopId: 1, menuItemId: 1 },
      { unique: true },
    ),
    collection(C.inventoryItems).createIndex({ tenantId: 1, shopId: 1, name: 1 }),
    collection(C.orders).createIndex({ tenantId: 1, shopId: 1, createdAt: -1 }),
    collection(C.payments).createIndex({ tenantId: 1, shopId: 1, createdAt: -1 }),
  ]);
}
