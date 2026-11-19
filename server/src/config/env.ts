import { z } from "zod";

const schema = z.object({
  PORT: z.coerce.number().int().default(3000),
  NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
  MONGO_URI: z.string().min(1),
  MONGO_DB_NAME: z.string().min(1).default("mithai_wale"),
  JWT_SECRET: z.string().min(32, "JWT_SECRET must be at least 32 characters"),
  ACCESS_TOKEN_TTL_SECONDS: z.coerce.number().int().positive().default(900),
  REFRESH_TOKEN_TTL_DAYS: z.coerce.number().int().positive().default(30),
  CORS_ORIGINS: z.string().default("http://localhost:5173"),
  // Platform super admin: static credentials, short-lived non-refreshable tokens.
  SUPERADMIN_USERNAME: z.string().min(3).optional(),
  SUPERADMIN_PASSWORD: z.string().min(12, "SUPERADMIN_PASSWORD must be at least 12 characters").optional(),
  ADMIN_TOKEN_TTL_SECONDS: z.coerce.number().int().positive().default(300),
});

const parsed = schema.safeParse(process.env);
if (!parsed.success) {
  const fields = z.flattenError(parsed.error).fieldErrors;
  console.error("Invalid environment variables:", fields);
  // Throw rather than process.exit so serverless platforms surface the error.
  throw new Error(`Invalid environment variables: ${Object.keys(fields).join(", ")}`);
}

export const env = {
  ...parsed.data,
  corsOrigins: parsed.data.CORS_ORIGINS.split(",").map((s) => s.trim()),
};
