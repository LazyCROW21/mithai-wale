// Builds the admin web UI for Cloudflare Pages → admin-ui/dist
//   bun scripts/build-admin.ts [--allow-http]
//   API_URL=https://... bun scripts/build-admin.ts   (override deploy.config.json)
import { existsSync } from "node:fs";
import { join } from "node:path";
import { ADMIN, SECURITY_HEADERS, apiBaseUrl, done, headersFile, run, step } from "./_lib";

export const ADMIN_OUT = join(ADMIN, "dist");

export async function buildAdmin(): Promise<string> {
  const apiUrl = apiBaseUrl();
  step(`Build admin UI (API: ${apiUrl})`);
  if (!existsSync(join(ADMIN, "node_modules"))) {
    await run("npm", ["ci", "--no-audit", "--no-fund"], { cwd: ADMIN });
  }
  // Process env beats admin-ui/.env, so the local API URL there is not used.
  await run("npm", ["run", "build"], { cwd: ADMIN, env: { VITE_API_URL: apiUrl } });

  // Strict CSP: the admin UI only loads its own assets and talks to the API.
  const csp = [
    "default-src 'self'",
    `connect-src 'self' ${new URL(apiUrl).origin}`,
    "img-src 'self' data:",
    "style-src 'self' 'unsafe-inline'",
    "script-src 'self'",
    "object-src 'none'",
    "base-uri 'self'",
    "form-action 'self'",
    "frame-ancestors 'none'",
  ].join("; ");

  // Cloudflare Pages serves index.html for unknown paths (SPA fallback) since
  // there is no 404.html, so client-side routes work without _redirects.
  await Bun.write(
    join(ADMIN_OUT, "_headers"),
    headersFile({
      "/*": {
        ...SECURITY_HEADERS,
        "Content-Security-Policy": csp,
        "Referrer-Policy": "no-referrer",
        "X-Robots-Tag": "noindex, nofollow",
      },
      "/": { "Cache-Control": "no-cache" },
      "/index.html": { "Cache-Control": "no-cache" },
      "/assets/*": { "Cache-Control": "public, max-age=31536000, immutable" },
    }),
  );
  done("Admin build ready: admin-ui/dist");
  return ADMIN_OUT;
}

if (import.meta.main) await buildAdmin();
