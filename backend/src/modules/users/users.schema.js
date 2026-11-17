const { z } = require('zod');

// Profile fields shared by registration (US-01) and profile update (US-03),
// so both follow exactly the same rules. Text is trimmed before validating.
const profileFields = {
  full_name: z
    .string({ error: 'El nombre completo es obligatorio.' })
    .trim()
    .min(2, { error: 'El nombre debe tener al menos 2 caracteres.' })
    .max(100, { error: 'El nombre puede tener máximo 100 caracteres.' }),

  doc_type: z.enum(['CC', 'CE', 'PAS'], {
    error: 'Elige un tipo de documento válido (CC, CE o PAS).',
  }),

  doc_number: z
    .string({ error: 'El número de documento es obligatorio.' })
    .trim()
    .toUpperCase()
    .regex(/^[A-Z0-9]{4,20}$/, {
      error: 'El número de documento debe tener entre 4 y 20 letras o números, sin espacios ni puntos.',
    }),

  // Optional. Spaces and dashes are removed; an empty value is stored as null.
  phone: z.preprocess(
    (value) => {
      if (typeof value !== 'string') return value;
      const clean = value.replace(/[\s-]/g, '');
      return clean === '' ? null : clean;
    },
    z
      .string({ error: 'El teléfono debe ser un texto.' })
      .regex(/^\+?[0-9]{7,15}$/, { error: 'El teléfono debe tener entre 7 y 15 dígitos.' })
      .nullish()
      .transform((value) => value ?? null),
  ),
};

// PUT /me: same rules as registration. Unknown fields (e.g. email) are dropped:
// the email cannot be changed (RF-13).
const updateProfileSchema = z.object(profileFields);

module.exports = { profileFields, updateProfileSchema };
