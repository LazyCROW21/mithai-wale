export type Role = "owner" | "manager" | "employee";

interface Base {
  _id: string;
  createdAt: Date;
}

/**
 * Every tenant-owned document carries tenantId.
 * `updatedAt` is always set by the server on every write and is the sync cursor.
 * `deletedAt` marks a tombstone for synced collections (soft delete).
 */
export interface TenantDoc extends Base {
  tenantId: string;
  updatedAt: Date;
  deletedAt?: Date | null;
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

/** Page setup and letterhead used when printing bills and other documents. */
export interface PrintProfile {
  pageSize: "a4" | "a5" | "letter" | "custom";
  pageWidthMm: number;
  pageHeightMm: number;
  /** Printing area: content never prints outside these margins. */
  marginTopMm: number;
  marginBottomMm: number;
  marginLeftMm: number;
  marginRightMm: number;
  /** Base64 image drawn in the top margin when the letterhead is included. */
  headerImage?: string | null;
  /** Base64 image drawn in the bottom margin when the letterhead is included. */
  footerImage?: string | null;
}

/** Stored print profile: the franchise default (`shopId: null`) or one shop's override. */
export interface PrintProfileDoc extends PrintProfile {
  _id: string; // `${tenantId}:franchise` or `${tenantId}:shop:${shopId}`
  tenantId: string;
  shopId: string | null;
  updatedAt: Date;
}

/** A device registered to a tenant. `code` prefixes daily order tokens (A-12). */
export interface Device {
  _id: string; // `${tenantId}:${deviceId}`
  tenantId: string;
  deviceId: string;
  code: string;
  name?: string;
  lastUserId: string;
  createdAt: Date;
  lastSeenAt: Date;
}

// ── Synced business data (field names match the Flutter models) ─────────────

export interface Category extends TenantDoc {
  name: string;
  emoji?: string | null;
  sortOrder?: number;
}

export interface MenuItem extends TenantDoc {
  title: string;
  description?: string | null;
  categoryId?: string | null;
  price: number;
  unit: string;
  isAvailable: boolean;
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

export interface OrderItem {
  name: string;
  quantity: number;
  unit: string;
  unitPrice: number;
  deliveryDate: Date;
}

export interface Order extends TenantDoc {
  shopId: string;
  customerName: string;
  customerPhone: string;
  items: OrderItem[];
  orderDate: Date;
  totalBill: number;
  status: string;
  discountType?: "percentage" | "flat" | null;
  discountAmount: number;
  /** Daily token shown to customers, e.g. "A-12" (device code + daily counter). */
  token?: string | null;
  /** Local date the token belongs to (YYYY-MM-DD); tokens reset daily. */
  tokenDate?: string | null;
}

export interface Payment extends TenantDoc {
  shopId: string;
  orderId: string;
  amount: number;
  type: "credit" | "debit";
  paymentMode: string;
  note: string;
  customerName: string;
  referenceNumber?: string | null;
}

/** Principal attached to a request after authentication. */
export type Principal =
  | { kind: "admin"; id: string }
  | { kind: "user"; id: string; tenantId: string; role: Role; shopIds: string[]; allShops: boolean };

export type AppEnv = { Variables: { principal: Principal } };
