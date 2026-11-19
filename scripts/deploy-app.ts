// Builds and deploys the Flutter web app to Cloudflare Pages.
//   bun scripts/deploy-app.ts [--preview] [--skip-build]
import { APP_OUT, buildApp } from "./build-app";
import { ROOT, config, done, flags, pagesBranch, requireDir, run, step, tool } from "./_lib";

tool("wrangler"); // fail fast, before a long build

const dir = flags.has("--skip-build") ? APP_OUT : await buildApp();
requireDir(dir, "Run `bun scripts/build-app.ts` first.");

const branch = pagesBranch();
step(`Deploy app → Cloudflare Pages "${config.app.cloudflareProject}" (${branch})`);
await run(
  "wrangler",
  ["pages", "deploy", dir, `--project-name=${config.app.cloudflareProject}`, `--branch=${branch}`, "--commit-dirty=true"],
  { cwd: ROOT },
);
done(branch === "main" ? `App live at ${config.app.url}` : "Preview deployed (URL above)");
