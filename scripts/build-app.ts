// Builds the Flutter web app for Cloudflare Pages → client/build/web
//   bun scripts/build-app.ts [--allow-http]
//   API_URL=https://... bun scripts/build-app.ts   (override deploy.config.json)
import { join } from "node:path";
import { CLIENT, SECURITY_HEADERS, apiBaseUrl, done, headersFile, run, step } from "./_lib";

export const APP_OUT = join(CLIENT, "build", "web");

// Files that decide which build the browser runs must never be cached.
const NO_CACHE = { "Cache-Control": "no-cache" };

export async function buildApp(): Promise<string> {
  const apiUrl = apiBaseUrl();
  step(`Build Flutter web app (API: ${apiUrl})`);
  await run("flutter", ["build", "web", "--release", `--dart-define=API_URL=${apiUrl}`], { cwd: CLIENT });

  // The app uses hash routing (/#/orders), so no SPA rewrite rules are needed.
  await Bun.write(
    join(APP_OUT, "_headers"),
    headersFile({
      "/*": {
        ...SECURITY_HEADERS,
        "Permissions-Policy": "camera=(self), microphone=(), geolocation=()",
      },
      "/": NO_CACHE,
      "/index.html": NO_CACHE,
      "/flutter_bootstrap.js": NO_CACHE,
      "/flutter_service_worker.js": NO_CACHE,
      "/version.json": NO_CACHE,
      "/manifest.json": NO_CACHE,
    }),
  );
  done(`Flutter web build ready: client/build/web`);
  return APP_OUT;
}

if (import.meta.main) await buildApp();
