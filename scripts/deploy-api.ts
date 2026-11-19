// Checks and deploys the API (server/) to Vercel. Vercel builds it remotely
// (Hono on the Bun runtime), so the local "build" step is a type check.
//   bun scripts/deploy-api.ts [--preview] [--indexes] [--skip-checks]
//
//   --indexes   also ensure MongoDB indexes on the production database. Reads
//               MONGO_URI / MONGO_DB_NAME / JWT_SECRET from server/.env.production.local
//               (gitignored) — never from server/.env, which points at local Mongo.
import { existsSync } from "node:fs";
import { join } from "node:path";
import { SERVER, config, done, fail, flags, readEnvFile, run, step, tool } from "./_lib";

tool("vercel");
const prod = !flags.has("--preview");

if (!existsSync(join(SERVER, ".vercel", "project.json"))) {
  fail("server/ is not linked to a Vercel project. Run `vercel link` inside server/ first.");
}

if (!flags.has("--skip-checks")) {
  step("Type check server");
  await run("bun", ["run", "typecheck"], { cwd: SERVER });
}

if (flags.has("--indexes")) {
  step("Ensure MongoDB indexes (production database)");
  const envPath = join(SERVER, ".env.production.local");
  if (!existsSync(envPath)) {
    fail("server/.env.production.local not found. Put the production MONGO_URI, MONGO_DB_NAME and JWT_SECRET there.");
  }
  const prodEnv = await readEnvFile(envPath);
  if (!prodEnv.MONGO_URI) fail("MONGO_URI missing in server/.env.production.local");
  await run("bun", ["run", "db:indexes"], { cwd: SERVER, env: prodEnv });
}

step(`Deploy API → Vercel (${prod ? "production" : "preview"})`);
const out = await run("vercel", ["deploy", ...(prod ? ["--prod"] : [])], { cwd: SERVER, capture: true });
const deploymentUrl = out.trim().split(/\s+/).find((s) => s.startsWith("https://"));

if (prod) {
  // Preview deployments sit behind Vercel's deployment protection, so only check prod.
  step(`Health check ${config.api.url}/api/v1/health`);
  let ok = false;
  for (let i = 0; i < 5 && !ok; i++) {
    try {
      const res = await fetch(`${config.api.url}/api/v1/health`);
      console.log(`  ${res.status} ${await res.text()}`);
      ok = res.ok;
    } catch (err) {
      console.log(`  ${(err as Error).message}`);
    }
    if (!ok) await Bun.sleep(3000);
  }
  if (!ok) fail("Health check failed. Check `vercel logs` and the project's env vars.");
}

done(`API deployed${deploymentUrl ? `: ${deploymentUrl}` : ""}`);
