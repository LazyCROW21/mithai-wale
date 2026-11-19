import { Hono } from "hono";
import { pingMongo } from "../db/mongo";

export const healthRouter = new Hono().get("/", async (c) => {
  const mongo = await pingMongo();
  return c.json({ status: mongo ? "ok" : "degraded", mongo }, mongo ? 200 : 503);
});
