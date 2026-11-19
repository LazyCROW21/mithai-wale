// Builds and deploys the admin web UI to Cloudflare Pages.
//   bun scripts/deploy-admin.ts [--preview] [--skip-build]
import { ADMIN_OUT, buildAdmin } from "./build-admin";
import { ROOT, config, done, flags, pagesBranch, requireDir, run, step, tool } from "./_lib";

tool("wrangler"); // fail fast, before the build

const dir = flags.has("--skip-build") ? ADMIN_OUT : await buildAdmin();
requireDir(dir, "Run `bun scripts/build-admin.ts` first.");

const branch = pagesBranch();
step(`Deploy admin → Cloudflare Pages "${config.admin.cloudflareProject}" (${branch})`);
await run(
  "wrangler",
  ["pages", "deploy", dir, `--project-name=${config.admin.cloudflareProject}`, `--branch=${branch}`, "--commit-dirty=true"],
  { cwd: ROOT },
);
done(branch === "main" ? `Admin live at ${config.admin.url}` : "Preview deployed (URL above)");
