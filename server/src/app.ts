import { Hono } from "hono";
import { cors } from "hono/cors";
import { logger } from "hono/logger";
import { env } from "./config/env";
import { connectMongo } from "./db/mongo";
import { apiRouter } from "./routes";
import { onError, onNotFound } from "./middleware/error";
import type { AppEnv } from "./types/models";

export const app = new Hono<AppEnv>()
  .use(logger())
  .use(
    cors({
      origin: (origin) => {
        if (!origin) return origin;
        if (env.corsOrigins.includes("*") || env.corsOrigins.includes(origin)) return origin;
        // Flutter web dev servers pick a random localhost port.
        if (env.NODE_ENV !== "production" && /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)) {
          return origin;
        }
        return null;
      },
      allowHeaders: ["Content-Type", "Authorization"],
      allowMethods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
      maxAge: 600,
    }),
  )
  // Lazy connect: a no-op once connected; on serverless the first request of a
  // cold instance opens the (shared, reused) client.
  .use("/api/*", async (_c, next) => {
    await connectMongo();
    await next();
  })
  .route("/api/v1", apiRouter);

app.onError(onError);
app.notFound(onNotFound);
