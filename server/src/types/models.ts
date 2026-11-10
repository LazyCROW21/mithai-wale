export type Role = "owner" | "manager" | "employee";

interface Base {
  _id: string;
  createdAt: Date;
}

/** Every tenant-owned document carries tenantId. */
export interface TenantDoc extends Base {
  tenantId: string;
}

export interface Admin extends Base {
  username: string;
  passwordHash: string;
}

export interface Tenant extends Base {
  name: string;
  slug: string;
  active: boolean;
}

export interface User extends TenantDoc {
  username: string;
  passwordHash: string;
  name: string;
  role: Role;
  /** Shops the user can access. Ignored for owners (they access all shops). */
  shopIds: string[];
  active: boolean;
}

export interface RefreshToken {
  /** sha256 of the token */
  _id: string;
  kind: "admin" | "user";
  subjectId: string;
  expiresAt: Date;
}

export interface Shop extends TenantDoc {
  name: string;
  address?: string;
  phone?: string;
  active: boolean;
}

export interface Category extends TenantDoc {
  name: string;
  sortOrder: number;
}

export interface MenuItem extends TenantDoc {
  categoryId: string;
  name: string;
  description?: string;
  basePrice: number;
  active: boolean;
}

/** Per-shop override of a franchise catalog item. */
export interface ShopMenuItem extends TenantDoc {
  shopId: string;
  menuItemId: string;
  enabled: boolean;
  price?: number;
}

export interface InventoryItem extends TenantDoc {
  shopId: string;
  name: string;
  unit: string;
  quantity: number;
  lowStockThreshold: number;
}

/** Principal attached to a request after authentication. */
export type Principal =
  | { kind: "admin"; id: string }
  | { kind: "user"; id: string; tenantId: string; role: Role; shopIds: string[]; allShops: boolean };

export type AppEnv = { Variables: { principal: Principal } };
