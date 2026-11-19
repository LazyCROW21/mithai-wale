import { MongoClient, type Db, type Collection, type Document } from "mongodb";
import { env } from "../config/env";

let client: MongoClient | null = null;
let db: Db | null = null;
let connecting: Promise<Db> | null = null;

/**
 * Idempotent and safe under concurrency: on serverless, many requests can hit a
 * cold instance at once, and they must share one client/pool.
 */
export function connectMongo(): Promise<Db> {
  if (db) return Promise.resolve(db);
  connecting ??= (async () => {
    // Small pool: every warm serverless instance holds its own connections.
    const c = new MongoClient(env.MONGO_URI, { serverSelectionTimeoutMS: 5000, maxPoolSize: 10 });
    await c.connect();
    const d = c.db(env.MONGO_DB_NAME);
    await d.command({ ping: 1 });
    client = c;
    db = d;
    return d;
  })().catch((err) => {
    connecting = null; // allow a retry on the next request
    throw err;
  });
  return connecting;
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
  connecting = null;
}
