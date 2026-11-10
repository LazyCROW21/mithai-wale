import { Hono } from "hono";
import type { AppEnv } from "../types/models";
import { authenticate, requireAdmin, requireRole, requireUser } from "../middleware/auth";
import { adminAuthRouter, authRouter } from "./auth";
import { adminTenantsRouter } from "./admin-tenants";
import { categoriesRouter, menuItemsRouter } from "./catalog";
import { healthRouter } from "./health";
import { inventoryListRouter, ordersListRouter, paymentsListRouter } from "./scoped-lists";
import { shopsRouter } from "./shops";
import { usersRouter } from "./users";

export const apiRouter = new Hono<AppEnv>()
  .route("/health", healthRouter)
  // public
  .route("/auth", authRouter)
  .route("/admin/auth", adminAuthRouter)
  // platform admin
  .use("/admin/tenants/*", authenticate, requireAdmin)
  .use("/admin/tenants", authenticate, requireAdmin)
  .route("/admin/tenants", adminTenantsRouter)
  // tenant users
  .use("/users/*", authenticate, requireRole("owner"))
  .use("/users", authenticate, requireRole("owner"))
  .route("/users", usersRouter)
  .use("/categories/*", authenticate, requireUser)
  .use("/categories", authenticate, requireUser)
  .route("/categories", categoriesRouter)
  .use("/menu-items/*", authenticate, requireUser)
  .use("/menu-items", authenticate, requireUser)
  .route("/menu-items", menuItemsRouter)
  .use("/shops/*", authenticate, requireUser)
  .use("/shops", authenticate, requireUser)
  .route("/shops", shopsRouter)
  // role-aware flat lists (owner: all shops; others: permanently their own shop)
  .use("/inventory/*", authenticate, requireUser)
  .use("/inventory", authenticate, requireUser)
  .route("/inventory", inventoryListRouter)
  .use("/orders/*", authenticate, requireUser)
  .use("/orders", authenticate, requireUser)
  .route("/orders", ordersListRouter)
  .use("/payments/*", authenticate, requireUser)
  .use("/payments", authenticate, requireUser)
  .route("/payments", paymentsListRouter);
