import { collection } from "./mongo";
import { Collections as C, SoftDeleteCollections } from "./collections";

export async function ensureIndexes(): Promise<void> {
  // Sync cursor index on every pulled collection: (tenant, updatedAt, _id).
  const pulled = [...SoftDeleteCollections, C.shops];
  await Promise.all([
    collection(C.loginAttempts).createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 }),
    collection(C.tenants).createIndex({ slug: 1 }, { unique: true }),
    collection(C.users).createIndex({ tenantId: 1, username: 1 }, { unique: true }),
    collection(C.refreshTokens).createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 }),
    collection(C.refreshTokens).createIndex({ subjectId: 1 }),
    collection(C.syncOps).createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 }),
    collection(C.devices).createIndex({ tenantId: 1, code: 1 }, { unique: true }),
    ...pulled.map((name) => collection(name).createIndex({ tenantId: 1, updatedAt: 1, _id: 1 })),
    collection(C.shops).createIndex({ tenantId: 1, active: 1 }),
    collection(C.categories).createIndex({ tenantId: 1, sortOrder: 1 }),
    collection(C.menuItems).createIndex({ tenantId: 1, categoryId: 1 }),
    collection(C.shopMenuItems).createIndex(
      { tenantId: 1, shopId: 1, menuItemId: 1 },
      { unique: true },
    ),
    collection(C.inventoryItems).createIndex({ tenantId: 1, shopId: 1, name: 1 }),
    collection(C.orders).createIndex({ tenantId: 1, shopId: 1, orderDate: -1 }),
    collection(C.payments).createIndex({ tenantId: 1, shopId: 1, createdAt: -1 }),
  ]);
}
