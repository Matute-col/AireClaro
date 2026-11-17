const { z } = require('zod');

// Report fields (docs/05 · Validaciones). Built step by step:
// US-06 vehicle data; location and requester fields are added with US-07/US-08.

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

module.exports = { VEHICLE_TYPES, SMOKE_COLORS, normalizePlate, vehicleFields };
