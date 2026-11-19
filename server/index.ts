// Vercel entry point (Hono on the Bun runtime): Vercel serves the default export.
// For local development run `bun run dev` (src/local.ts), which starts Bun.serve.
import { app } from "./src/app";

export default app;
