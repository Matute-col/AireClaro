// Reads and validates environment variables once, at startup.
// Error messages only name the variables, never their values (they may be secrets).
require('dotenv').config({ quiet: true });
const { z } = require('zod');

const schema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(3000),
  DATABASE_URL: z.string().default(''),
  DATABASE_SSL: z
    .enum(['true', 'false'])
    .default('true')
    .transform((v) => v === 'true'),
  JWT_SECRET: z.string().min(32, 'debe tener al menos 32 caracteres'),
  JWT_EXPIRES_IN: z.string().default('7d'),
  UPLOAD_DIR: z.string().default('./uploads'),
  MAX_PHOTO_MB: z.coerce.number().positive().default(8),
  MAX_VIDEO_MB: z.coerce.number().positive().default(25),
  NOMINATIM_BASE_URL: z.string().default('https://nominatim.openstreetmap.org'),
  NOMINATIM_USER_AGENT: z.string().default('AireClaro-UNAD/1.0'),
  CORS_ORIGIN: z.string().default('*'),
  MAIL_MODE: z.enum(['test', 'live', 'off']).default('test'),
});

const parsed = schema.safeParse(process.env);

if (!parsed.success) {
  const problems = parsed.error.issues
    .map((issue) => `- ${issue.path.join('.')}: ${issue.message}`)
    .join('\n');
  throw new Error(`Configuración inválida en backend/.env:\n${problems}`);
}

module.exports = parsed.data;
