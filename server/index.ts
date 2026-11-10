import { app } from "./src/app";
import { env } from "./src/config/env";
import { connectMongo, disconnectMongo } from "./src/db/mongo";
import { ensureIndexes } from "./src/db/indexes";

await connectMongo();
await ensureIndexes();
console.log(`MongoDB connected (${env.MONGO_DB_NAME})`);

const server = Bun.serve({ port: env.PORT, fetch: app.fetch });
console.log(`Server listening on ${server.url}`);

const shutdown = async () => {
  await server.stop();
  await disconnectMongo();
  process.exit(0);
};
process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
