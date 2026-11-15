/** Central registry of collection names. */
export const Collections = {
  admins: "admins",
  tenants: "tenants",
  users: "users",
  refreshTokens: "refresh_tokens",
  devices: "devices",
  counters: "counters",
  syncOps: "sync_ops",
  shops: "shops",
  categories: "categories",
  menuItems: "menu_items",
  shopMenuItems: "shop_menu_items",
  inventoryItems: "inventory_items",
  orders: "orders",
  payments: "payments",
} as const;

/**
 * Collections that sync to devices. Deletes on these are soft (tombstones with
 * `deletedAt`) so the deletion itself can be pulled by other devices.
 */
export const SoftDeleteCollections: ReadonlySet<string> = new Set([
  Collections.categories,
  Collections.menuItems,
  Collections.shopMenuItems,
  Collections.inventoryItems,
  Collections.orders,
  Collections.payments,
]);
