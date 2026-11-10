import { Hono } from "hono";
import { cors } from "hono/cors";
import { logger } from "hono/logger";
import { env } from "./config/env";
import { apiRouter } from "./routes";
import { onError, onNotFound } from "./middleware/error";
import type { AppEnv } from "./types/models";

export const app = new Hono<AppEnv>()
  .use(logger())
  .use(cors({ origin: env.corsOrigins }))
  .route("/api/v1", apiRouter);

app.onError(onError);
app.notFound(onNotFound);
