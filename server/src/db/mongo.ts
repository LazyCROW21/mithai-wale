import { MongoClient, type Db, type Collection, type Document } from "mongodb";
import { env } from "../config/env";

let client: MongoClient | null = null;
let db: Db | null = null;

export async function connectMongo(): Promise<Db> {
  if (db) return db;
  client = new MongoClient(env.MONGO_URI, { serverSelectionTimeoutMS: 5000 });
  await client.connect();
  db = client.db(env.MONGO_DB_NAME);
  await db.command({ ping: 1 });
  return db;
}

export function getDb(): Db {
  if (!db) throw new Error("MongoDB not connected. Call connectMongo() first.");
  return db;
}

export function collection<T extends Document = Document>(name: string): Collection<T> {
  return getDb().collection<T>(name);
}

export async function pingMongo(): Promise<boolean> {
  try {
    await getDb().command({ ping: 1 });
    return true;
  } catch {
    return false;
  }
}

export async function disconnectMongo(): Promise<void> {
  await client?.close();
  client = null;
  db = null;
}
