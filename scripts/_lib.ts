// Shared helpers for the build/deploy scripts. Run scripts with Bun from anywhere:
//   bun scripts/deploy-api.ts
import { existsSync } from "node:fs";
import { join, relative, resolve } from "node:path";

export const ROOT = resolve(import.meta.dir, "..");
export const SERVER = join(ROOT, "server");
export const CLIENT = join(ROOT, "client");
export const ADMIN = join(ROOT, "admin-ui");

interface DeployConfig {
  api: { url: string };
  app: { cloudflareProject: string; url: string };
  admin: { cloudflareProject: string; url: string };
}

export const config: DeployConfig = await Bun.file(join(ROOT, "deploy.config.json")).json();

/** CLI flags, e.g. `--preview`, `--skip-build`. */
export const flags = new Set(Bun.argv.slice(2));

const INSTALL_HINTS: Record<string, string> = {
  vercel: "Install it with `npm i -g vercel`, then `vercel login`.",
  wrangler: "Install it with `npm i -g wrangler`, then `wrangler login`.",
  flutter: "Install Flutter and add its bin folder to PATH.",
  npm: "Install Node.js (includes npm).",
};

export function fail(message: string): never {
  console.error(`\n✖ ${message}`);
  process.exit(1);
}

export function step(title: string) {
  console.log(`\n━━ ${title}`);
}

export function done(message: string) {
  console.log(`\n✔ ${message}`);
}

/** Absolute path of a CLI on PATH (resolves .cmd/.bat on Windows). */
export function tool(name: string): string {
  if (name === "bun") return process.execPath;
  const path = Bun.which(name);
  if (!path) fail(`"${name}" was not found on PATH. ${INSTALL_HINTS[name] ?? ""}`);
  return path;
}

interface RunOptions {
  cwd: string;
  env?: Record<string, string>;
  /** Capture stdout (still echoed) and return it. */
  capture?: boolean;
}

/** Runs a command, streaming output; exits the script if it fails. */
export async function run(cmd: string, args: string[], opts: RunOptions): Promise<string> {
  console.log(`$ ${cmd} ${args.join(" ")}   [${relative(ROOT, opts.cwd) || "."}]`);
  const proc = Bun.spawn([tool(cmd), ...args], {
    cwd: opts.cwd,
    env: { ...process.env, ...opts.env },
    stdin: "inherit",
    stdout: opts.capture ? "pipe" : "inherit",
    stderr: "inherit",
  });
  let out = "";
  if (opts.capture && proc.stdout) {
    const decoder = new TextDecoder();
    for await (const chunk of proc.stdout) {
      const text = decoder.decode(chunk);
      out += text;
      process.stdout.write(text);
    }
  }
  const code = await proc.exited;
  if (code !== 0) fail(`\`${cmd} ${args[0] ?? ""}\` exited with code ${code}`);
  return out;
}

/** Base URL the frontends call, e.g. https://api.example.com/api/v1 */
export function apiBaseUrl(): string {
  const url = (process.env.API_URL ?? config.api.url).replace(/\/+$/, "");
  if (!/^https:\/\//.test(url) && !flags.has("--allow-http")) {
    fail(`API URL must be https (got "${url}"). Pass --allow-http for a local test build.`);
  }
  return url.endsWith("/api/v1") ? url : `${url}/api/v1`;
}

/** Cloudflare Pages branch: production unless --preview. */
export function pagesBranch(): string {
  return flags.has("--preview") ? "preview" : "main";
}

export function requireDir(path: string, hint: string) {
  if (!existsSync(path)) fail(`${relative(ROOT, path)} not found. ${hint}`);
}

/** Minimal KEY=VALUE .env parser (comments and blank lines ignored). */
export async function readEnvFile(path: string): Promise<Record<string, string>> {
  const out: Record<string, string> = {};
  for (const line of (await Bun.file(path).text()).split(/\r?\n/)) {
    const m = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$/);
    if (!m) continue;
    out[m[1]!] = m[2]!.replace(/^(['"])(.*)\1$/, "$2");
  }
  return out;
}

/** Serialises a Cloudflare Pages `_headers` file. */
export function headersFile(rules: Record<string, Record<string, string>>): string {
  return (
    Object.entries(rules)
      .map(([path, headers]) =>
        [path, ...Object.entries(headers).map(([k, v]) => `  ${k}: ${v}`)].join("\n"),
      )
      .join("\n") + "\n"
  );
}

export const SECURITY_HEADERS = {
  "X-Content-Type-Options": "nosniff",
  "X-Frame-Options": "DENY",
  "Referrer-Policy": "strict-origin-when-cross-origin",
};
