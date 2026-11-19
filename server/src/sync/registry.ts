import type { z } from "zod";
import type { Permission } from "../auth/permissions";
import { Collections } from "../db/collections";
import type { Role } from "../types/models";
import { categoryDoc, inventoryDoc, menuItemDoc, orderDoc, paymentDoc } from "./schemas";

export type SyncOpType = "create" | "update" | "delete" | "adjust";

export interface SyncSpec {
  /** Mongo collection name; also the key used on the wire. */
  collection: string;
  /** tenant = franchise-wide (catalog); shop = belongs to one shop. */
  scope: "tenant" | "shop";
  doc: z.ZodObject;
  ops: readonly SyncOpType[];
  /** Roles allowed to create/update/adjust. */
  writeRoles: readonly Role[];
  /** Roles allowed to delete (defaults to writeRoles). */
  deleteRoles?: readonly Role[];
  /** Permission needed to pull this collection (default: any tenant user). */
  readPermission?: Permission;
}

// NOTE: catalog write access for store owners is temporary; the menu-screen
// role behaviour (franchise catalog vs per-shop overrides) is deferred.
export const syncSpecs: readonly SyncSpec[] = [
  {
    collection: Collections.categories,
    scope: "tenant",
    doc: categoryDoc,
    ops: ["create", "update", "delete"],
    writeRoles: ["owner", "manager"],
  },
  {
    collection: Collections.menuItems,
    scope: "tenant",
    doc: menuItemDoc,
    ops: ["create", "update", "delete"],
    writeRoles: ["owner", "manager"],
  },
  {
    collection: Collections.orders,
    scope: "shop",
    doc: orderDoc,
    ops: ["create", "update", "delete"],
    writeRoles: ["owner", "manager", "employee"],
    deleteRoles: ["owner", "manager"],
    readPermission: "orders",
  },
  {
    // Ledger entries are append-only: corrections are new entries.
    collection: Collections.payments,
    scope: "shop",
    doc: paymentDoc,
    ops: ["create", "delete"],
    writeRoles: ["owner", "manager", "employee"],
    deleteRoles: ["owner", "manager"],
    readPermission: "ledger",
  },
  {
    // Stock changes travel as deltas ("adjust") so devices never overwrite each other.
    collection: Collections.inventoryItems,
    scope: "shop",
    doc: inventoryDoc,
    ops: ["create", "update", "delete", "adjust"],
    writeRoles: ["owner", "manager"],
    readPermission: "inventory",
  },
];

export const specByName = new Map(syncSpecs.map((s) => [s.collection, s]));
