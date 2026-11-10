import type { Role } from "../types/models";

/**
 * Feature areas of the app. This is the single source of truth: the server
 * guards routes with it and returns it to the client, which uses it to decide
 * which screens/navigation to show.
 *
 * Role naming in the product:
 *   owner    = franchise admin (whole franchise, all shops, staff)
 *   manager  = store owner     (own shop(s) only; no staff management)
 *   employee = cashier         (own shop(s); billing/orders only)
 */
export type Permission =
  | "home"
  | "shop" // place orders / billing counter
  | "menu"
  | "orders"
  | "ledger" // bill collection
  | "inventory"
  | "shops" // manage shops
  | "staff" // manage staff credentials
  | "profile"
  | "settings";

export const rolePermissions: Record<Role, readonly Permission[]> = {
  owner: ["home", "shop", "menu", "orders", "ledger", "inventory", "shops", "staff", "profile", "settings"],
  manager: ["home", "shop", "menu", "orders", "ledger", "inventory", "profile", "settings"],
  employee: ["home", "shop", "orders", "ledger", "profile", "settings"],
};

export const can = (role: Role, permission: Permission) => rolePermissions[role].includes(permission);
