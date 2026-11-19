import { z } from "zod";

/**
 * Document schemas for synced collections. Field names match the Flutter
 * models' toMap(). Server-owned fields (_id, tenantId, shopId, updatedAt,
 * deletedAt) are never accepted from the client.
 */

const isoDate = z.coerce.date();

export const categoryDoc = z.object({
  name: z.string().min(1),
  emoji: z.string().nullish(),
  sortOrder: z.number().int().optional(),
  createdAt: isoDate.optional(),
});

export const menuItemDoc = z.object({
  title: z.string().min(1),
  description: z.string().nullish(),
  categoryId: z.string().nullish(),
  price: z.number().min(0),
  unit: z.string().min(1),
  isAvailable: z.boolean().default(true),
  createdAt: isoDate.optional(),
});

export const orderItem = z.object({
  name: z.string().min(1),
  quantity: z.number().min(0),
  unit: z.string().min(1),
  unitPrice: z.number().min(0),
  deliveryDate: isoDate,
  /** Status of this line's delivery day (all lines on a day share it). */
  status: z.string().min(1).default("Placed"),
});

export const orderDoc = z.object({
  customerName: z.string().default(""),
  customerPhone: z.string().default(""),
  items: z.array(orderItem).default([]),
  orderDate: isoDate,
  totalBill: z.number().min(0),
  /** Overall status, derived on the client from the per-day item statuses. */
  status: z.string().min(1),
  discountType: z.enum(["percentage", "flat"]).nullish(),
  discountAmount: z.number().min(0).default(0),
  token: z.string().max(20).nullish(),
  tokenDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).nullish(),
  createdAt: isoDate.optional(),
});

export const paymentDoc = z.object({
  orderId: z.string().min(1),
  amount: z.number().min(0),
  type: z.enum(["credit", "debit"]),
  paymentMode: z.string().min(1),
  note: z.string().default(""),
  customerName: z.string().default(""),
  referenceNumber: z.string().nullish(),
  createdAt: isoDate.optional(),
});

export const inventoryDoc = z.object({
  name: z.string().min(1),
  unit: z.string().min(1),
  quantity: z.number().min(0).default(0),
  lowStockThreshold: z.number().min(0).default(0),
  createdAt: isoDate.optional(),
});
