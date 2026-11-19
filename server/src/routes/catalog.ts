import { Collections } from "../db/collections";
import { categoryDoc, menuItemDoc } from "../sync/schemas";
import type { Category, MenuItem } from "../types/models";
import { crudRouter } from "./crud";

export const categoriesRouter = crudRouter<Category>({
  collection: Collections.categories,
  label: "Category",
  createSchema: categoryDoc,
  updateSchema: categoryDoc.partial(),
  writeRoles: ["owner"],
  sort: { sortOrder: 1, name: 1 },
});

export const menuItemsRouter = crudRouter<MenuItem>({
  collection: Collections.menuItems,
  label: "Menu item",
  createSchema: menuItemDoc,
  updateSchema: menuItemDoc.partial(),
  writeRoles: ["owner"],
  sort: { title: 1 },
});
