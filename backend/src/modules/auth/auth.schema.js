const { z } = require('zod');
const { profileFields } = require('../users/users.schema');

const email = z
  .string({ error: 'El correo es obligatorio.' })
  .trim()
  .toLowerCase()
  .pipe(z.email({ error: 'Escribe un correo electrónico válido.' }));

const registerSchema = z.object({
  ...profileFields,
  email,
  password: z
    .string({ error: 'La contraseña es obligatoria.' })
    .min(8, { error: 'La contraseña debe tener al menos 8 caracteres.' })
    // bcrypt only uses the first 72 bytes; longer passwords are rejected, not cut.
    .refine((value) => Buffer.byteLength(value, 'utf8') <= 72, {
      error: 'La contraseña es demasiado larga (máximo 72 caracteres).',
    }),
  accept_terms: z.literal(true, {
    error: 'Debes aceptar la política de tratamiento de datos para crear la cuenta.',
  }),
});

// Login only checks that both fields are present; wrong credentials get a generic message.
const loginSchema = z.object({
  email: z.string({ error: 'El correo es obligatorio.' }).trim().toLowerCase().min(1, {
    error: 'El correo es obligatorio.',
  }),
  password: z.string({ error: 'La contraseña es obligatoria.' }).min(1, {
    error: 'La contraseña es obligatoria.',
  }),
});

module.exports = { registerSchema, loginSchema };
