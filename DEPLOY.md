# Deployment

| Part | Host | Source | Script |
|---|---|---|---|
| API | Vercel (Hono on Bun runtime, region `bom1`) | `server/` | `bun run deploy:api` |
| Flutter web app | Cloudflare Pages `mithai-wale-app` | `client/` | `bun run deploy:app` |
| Admin UI | Cloudflare Pages `mithai-wale-admin` | `admin-ui/` | `bun run deploy:admin` |

Public URLs and project names live in [deploy.config.json](deploy.config.json). Secrets never go there.

## One-time setup

1. **CLIs**: `npm i -g vercel wrangler`, then `vercel login` and `wrangler login`.
2. **MongoDB Atlas**: create a cluster (ideally `ap-south-1` / Mumbai), a database user scoped to the app database, and allow `0.0.0.0/0` in Network Access (Vercel has no fixed IPs).
3. **Vercel API project**: in `server/` run `vercel link` (create a new project). Set env vars in the project (Production):

   | Var | Value |
   |---|---|
   | `MONGO_URI` | Atlas connection string |
   | `MONGO_DB_NAME` | `mithai_wale` |
   | `JWT_SECRET` | 48+ random chars |
   | `SUPERADMIN_USERNAME` | admin login name |
   | `SUPERADMIN_PASSWORD` | 12+ chars, long passphrase |
   | `ADMIN_TOKEN_TTL_SECONDS` | `300` (optional, default) |
   | `CORS_ORIGINS` | `https://mithai-wale-app.pages.dev,https://mithai-wale-admin.pages.dev` |

   e.g. `vercel env add SUPERADMIN_PASSWORD production`. Then put the API's production URL in `deploy.config.json` → `api.url`.
4. **Cloudflare Pages projects** (once each):
   ```
   wrangler pages project create mithai-wale-app --production-branch=main
   wrangler pages project create mithai-wale-admin --production-branch=main
   ```
   Put their URLs in `deploy.config.json` and in `CORS_ORIGINS`.
5. **Indexes**: create `server/.env.production.local` (gitignored, never uploaded) with the production `MONGO_URI`, `MONGO_DB_NAME`, `JWT_SECRET`, then run `bun run deploy:api -- --indexes` once (and again whenever `server/src/db/indexes.ts` changes).

## Everyday use

```
bun run deploy:api                 # type check → vercel deploy --prod → health check
bun run deploy:api -- --indexes    # …also ensure Mongo indexes first
bun run deploy:app                 # flutter build web → wrangler pages deploy
bun run deploy:admin               # vite build → wrangler pages deploy
bun run build:app                  # build only (client/build/web)
bun run build:admin                # build only (admin-ui/dist)
```

Flags: `--preview` (preview deploy instead of production), `--skip-build` (deploy the existing build), `--skip-checks` (API: skip type check), `--allow-http` (build against a non-https API for local testing). `API_URL=https://… bun run build:app` overrides the API URL for one build.

Deploy the API first when a change spans server and clients.

## Admin access

The admin UI is protected by the static super admin credentials (`SUPERADMIN_USERNAME` / `SUPERADMIN_PASSWORD`). A login grants a 5-minute access token with no refresh token; the UI shows a countdown and returns to the sign-in screen on expiry. Failed logins are limited to 5 per IP per 15 minutes. To rotate the password, change the env var on Vercel and redeploy.
