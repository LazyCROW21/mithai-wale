import { z } from "zod";
import { Collections } from "../db/collections";
import type { Category, MenuItem } from "../types/models";
import { crudRouter } from "./crud";

const categoryCreate = z.object({
  name: z.string().min(1),
  sortOrder: z.number().int().default(0),
});

export const categoriesRouter = crudRouter<Category>({
  collection: Collections.categories,
  label: "Category",
  createSchema: categoryCreate,
  updateSchema: categoryCreate.partial(),
  writeRoles: ["owner"],
  sort: { sortOrder: 1 },
});

const menuItemCreate = z.object({
  categoryId: z.string().min(1),
  name: z.string().min(1),
  description: z.string().optional(),
  basePrice: z.number().min(0),
  active: z.boolean().default(true),
});

export const menuItemsRouter = crudRouter<MenuItem>({
  collection: Collections.menuItems,
  label: "Menu item",
  createSchema: menuItemCreate,
  updateSchema: menuItemCreate.partial(),
  writeRoles: ["owner"],
  sort: { name: 1 },
});
