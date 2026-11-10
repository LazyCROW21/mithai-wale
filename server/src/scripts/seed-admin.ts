import { env } from "../config/env";
import { Collections } from "../db/collections";
import { ensureIndexes } from "../db/indexes";
import { collection, connectMongo, disconnectMongo } from "../db/mongo";
import { hashPassword } from "../lib/password";
import type { Admin } from "../types/models";

const { ADMIN_USERNAME, ADMIN_PASSWORD } = env;
if (!ADMIN_USERNAME || !ADMIN_PASSWORD) {
  console.error("Set ADMIN_USERNAME and ADMIN_PASSWORD in .env");
  process.exit(1);
}

await connectMongo();
await ensureIndexes();
const admins = collection<Admin>(Collections.admins);
const passwordHash = await hashPassword(ADMIN_PASSWORD);
const res = await admins.updateOne(
  { username: ADMIN_USERNAME },
  { $set: { passwordHash }, $setOnInsert: { _id: crypto.randomUUID(), createdAt: new Date() } },
  { upsert: true },
);
console.log(res.upsertedCount ? `Created admin "${ADMIN_USERNAME}"` : `Updated password for admin "${ADMIN_USERNAME}"`);
await disconnectMongo();
