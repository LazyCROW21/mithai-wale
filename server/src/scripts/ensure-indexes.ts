// Creates/updates MongoDB indexes. Run once per deploy against the target database
// (serverless instances don't build indexes on cold start).
import { env } from "../config/env";
import { ensureIndexes } from "../db/indexes";
import { connectMongo, disconnectMongo } from "../db/mongo";

await connectMongo();
await ensureIndexes();
console.log(`Indexes ensured on database "${env.MONGO_DB_NAME}"`);
await disconnectMongo();
