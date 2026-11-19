import { createHash, timingSafeEqual } from "node:crypto";
import type { Context } from "hono";
import { sign } from "hono/jwt";
import { env } from "../config/env";
import { collection } from "../db/mongo";
import { Collections } from "../db/collections";
import { tooManyRequests } from "../lib/errors";
import type { LoginAttempt } from "../types/models";

/**
 * Platform super admin. Credentials are static (SUPERADMIN_USERNAME / SUPERADMIN_PASSWORD
 * env vars); a successful login grants a short-lived access token with no refresh
 * token, so the admin signs in again when it expires.
 */
export const SUPERADMIN_SUBJECT = "superadmin";

export const superadminConfigured = () => Boolean(env.SUPERADMIN_USERNAME && env.SUPERADMIN_PASSWORD);

const digest = (s: string) => createHash("sha256").update(s).digest();

/** Constant-time compare of both fields (no short-circuit, no length leak). */
export function checkSuperadmin(username: string, password: string): boolean {
  if (!superadminConfigured()) return false;
  const userOk = timingSafeEqual(digest(username), digest(env.SUPERADMIN_USERNAME!));
  const passOk = timingSafeEqual(digest(password), digest(env.SUPERADMIN_PASSWORD!));
  return userOk && passOk;
}

export async function issueSuperadminToken() {
  const now = Math.floor(Date.now() / 1000);
  const expiresIn = env.ADMIN_TOKEN_TTL_SECONDS;
  const accessToken = await sign(
    { sub: SUPERADMIN_SUBJECT, kind: "admin", iat: now, exp: now + expiresIn },
    env.JWT_SECRET,
    "HS256",
  );
  return { accessToken, expiresIn };
}

// ── Brute-force protection ────────────────────────────────────────────────────
// Stored in Mongo (not memory) because serverless instances don't share memory.

const MAX_FAILURES = 5;
const WINDOW_MS = 15 * 60_000;

/** Client IP. On Vercel `x-forwarded-for` is set by the platform, not the client. */
export function clientIp(c: Context): string {
  return (
    c.req.header("x-forwarded-for")?.split(",")[0]?.trim() ||
    c.req.header("x-real-ip") ||
    "unknown"
  );
}

const attempts = () => collection<LoginAttempt>(Collections.loginAttempts);

export async function assertNotLocked(key: string): Promise<void> {
  const doc = await attempts().findOne({ _id: key });
  if (doc && doc.count >= MAX_FAILURES && doc.expiresAt > new Date()) {
    throw tooManyRequests("Too many failed attempts. Try again later.");
  }
}

export async function recordFailure(key: string): Promise<void> {
  await attempts().updateOne(
    { _id: key },
    { $inc: { count: 1 }, $setOnInsert: { expiresAt: new Date(Date.now() + WINDOW_MS) } },
    { upsert: true },
  );
}

export async function clearFailures(key: string): Promise<void> {
  await attempts().deleteOne({ _id: key });
}
