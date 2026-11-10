import { sign, verify } from "hono/jwt";
import { env } from "../config/env";
import { collection } from "../db/mongo";
import { Collections } from "../db/collections";
import type { RefreshToken } from "../types/models";

export type Kind = "admin" | "user";

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

const sha256 = (s: string) => new Bun.CryptoHasher("sha256").update(s).digest("hex");

export async function issueTokens(kind: Kind, subjectId: string): Promise<TokenPair> {
  const now = Math.floor(Date.now() / 1000);
  const accessToken = await sign(
    { sub: subjectId, kind, iat: now, exp: now + env.ACCESS_TOKEN_TTL_SECONDS },
    env.JWT_SECRET,
    "HS256",
  );
  const refreshToken = Buffer.from(crypto.getRandomValues(new Uint8Array(32))).toString("base64url");
  await collection<RefreshToken>(Collections.refreshTokens).insertOne({
    _id: sha256(refreshToken),
    kind,
    subjectId,
    expiresAt: new Date(Date.now() + env.REFRESH_TOKEN_TTL_DAYS * 86_400_000),
  });
  return { accessToken, refreshToken, expiresIn: env.ACCESS_TOKEN_TTL_SECONDS };
}

export async function verifyAccessToken(token: string): Promise<{ sub: string; kind: Kind }> {
  const payload = await verify(token, env.JWT_SECRET, "HS256");
  return { sub: String(payload.sub), kind: payload.kind as Kind };
}

/** Single-use: consumes the refresh token and returns its owner. */
export async function consumeRefreshToken(token: string): Promise<RefreshToken | null> {
  const doc = await collection<RefreshToken>(Collections.refreshTokens).findOneAndDelete({
    _id: sha256(token),
  });
  if (!doc || doc.expiresAt < new Date()) return null;
  return doc;
}

export async function revokeRefreshToken(token: string): Promise<void> {
  await collection<RefreshToken>(Collections.refreshTokens).deleteOne({ _id: sha256(token) });
}

export async function revokeAllFor(subjectId: string): Promise<void> {
  await collection<RefreshToken>(Collections.refreshTokens).deleteMany({ subjectId });
}
