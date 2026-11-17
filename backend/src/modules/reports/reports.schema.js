const { z } = require('zod');
const { profileFields } = require('../users/users.schema');

// Report fields (docs/05 · Validaciones). Built step by step:
// US-06 vehicle data, US-08 requester data; the full create schema arrives with US-09.

const VEHICLE_TYPES = ['bus', 'microbus', 'camion', 'tractomula', 'otro'];
const SMOKE_COLORS = ['negro', 'gris', 'blanco'];
const PLATE_REGEX = /^([A-Z]{3}\d{3}|[A-Z]{3}\d{2}[A-Z])$/;

/** Uppercase, without spaces or dashes: «abc-12d» → «ABC12D». */
function normalizePlate(value) {
  return typeof value === 'string' ? value.toUpperCase().replace(/[\s-]/g, '') : value;
}

const vehicleFields = {
  vehicle_type: z.enum(VEHICLE_TYPES, {
    error: 'Elige un tipo de vehículo válido.',
  }),

  plate: z.preprocess(
    normalizePlate,
    z
      .string({ error: 'La placa es obligatoria.' })
      .regex(PLATE_REGEX, { error: 'La placa debe tener el formato ABC123 o ABC12D.' }),
  ),

  smoke_color: z.enum(SMOKE_COLORS, {
    error: 'Elige el color del humo (negro, gris o blanco).',
  }),

  // Optional, up to 500 characters; empty text is stored as null.
  description: z.preprocess(
    (value) => (typeof value === 'string' && value.trim() === '' ? null : value),
    z
      .string({ error: 'La descripción debe ser un texto.' })
      .trim()
      .max(500, { error: 'La descripción puede tener máximo 500 caracteres.' })
      .nullish()
      .transform((value) => value ?? null),
  ),
};

// US-08 · Requester (peticionario): the same rules as the user profile, so the
// data prefilled from the profile is always valid. There is no anonymous option.
const requesterFields = {
  requester_name: profileFields.full_name,
  requester_doc_type: profileFields.doc_type,
  requester_doc_number: profileFields.doc_number,
  requester_email: z
    .string({ error: 'El correo es obligatorio.' })
    .trim()
    .toLowerCase()
    .pipe(z.email({ error: 'Escribe un correo electrónico válido.' })),
  requester_phone: profileFields.phone,
};

// US-09 · Location, time and authority. Multipart fields arrive as text.
const emptyToUndefined = (value) => (value === '' || value === null ? undefined : value);

function coordinate(name, limit) {
  const message = `La ${name} debe estar entre -${limit} y ${limit}.`;
  return z.preprocess(
    emptyToUndefined,
    z.coerce
      .number({ error: `La ${name} es obligatoria.` })
      .min(-limit, { error: message })
      .max(limit, { error: message }),
  );
}

// Small tolerance for phone clocks that run a bit fast.
const CLOCK_TOLERANCE_MS = 5 * 60 * 1000;

const locationFields = {
  lat: coordinate('latitud', 90),
  lng: coordinate('longitud', 180),

  address: z.preprocess(
    (value) => (typeof value === 'string' && value.trim() === '' ? null : value),
    z
      .string()
      .trim()
      .max(300, { error: 'La dirección puede tener máximo 300 caracteres.' })
      .nullish()
      .transform((value) => value ?? null),
  ),

  occurred_at: z.preprocess(
    emptyToUndefined,
    z.coerce
      .date({ error: 'La fecha y hora del reporte no son válidas.' })
      .refine((date) => date.getTime() <= Date.now() + CLOCK_TOLERANCE_MS, {
        error: 'La fecha y hora del reporte no pueden estar en el futuro.',
      }),
  ),

  // Optional: without it the server applies the authority rule (docs/05).
  authority_id: z.preprocess(
    emptyToUndefined,
    z.coerce
      .number({ error: 'Elige una autoridad válida.' })
      .int({ error: 'Elige una autoridad válida.' })
      .positive({ error: 'Elige una autoridad válida.' })
      .optional(),
  ),
};

// POST /reports. Unknown fields (e.g. user_id, status) are dropped: the owner
// comes only from the token and every new report starts as «generado».
const createReportSchema = z.object({
  ...vehicleFields,
  ...locationFields,
  ...requesterFields,
});

module.exports = {
  VEHICLE_TYPES,
  SMOKE_COLORS,
  normalizePlate,
  vehicleFields,
  requesterFields,
  locationFields,
  createReportSchema,
};
