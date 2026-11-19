import type { Context } from "hono";
import type { z } from "zod";
import { HttpError } from "./errors";

export async function parseBody<S extends z.ZodType>(c: Context, schema: S): Promise<z.infer<S>> {
  let raw: unknown;
  try {
    raw = await c.req.json();
  } catch {
    throw new HttpError(400, "Request body must be valid JSON");
  }
  return schema.parse(raw);
}
