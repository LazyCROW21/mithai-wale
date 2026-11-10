import type { ErrorHandler, NotFoundHandler } from "hono";
import { ZodError } from "zod";
import { HttpError } from "../lib/errors";

export const onError: ErrorHandler = (err, c) => {
  if (err instanceof HttpError) {
    return c.json({ error: { message: err.message, details: err.details } }, err.status);
  }
  if (err instanceof ZodError) {
    return c.json({ error: { message: "Validation failed", details: err.flatten() } }, 422);
  }
  console.error(err);
  return c.json({ error: { message: "Internal server error" } }, 500);
};

export const onNotFound: NotFoundHandler = (c) =>
  c.json({ error: { message: `Route ${c.req.method} ${c.req.path} not found` } }, 404);
