const express = require('express');
const { z } = require('zod');
const requireAuth = require('../../middleware/auth');
const AppError = require('../../utils/AppError');
const { query } = require('../../db/pool');
const { VEHICLE_TYPES } = require('../reports/reports.schema');

// US-15 · GET /api/map/reports — reports of ALL users on the map (RF-10).
// Privacy (RB-07): only id, coordinates, vehicle type and date. Never the plate, photos,
// address, requester or owner. Requires a session like the rest of the API.

const router = express.Router();
router.use(requireAuth);

const MAX_PINS = 500;
const DATE = /^\d{4}-\d{2}-\d{2}$/;

const mapQuery = z
  .object({
    // One or more types separated by commas: «bus,camion».
    vehicle_type: z
      .string()
      .optional()
      .transform((value) => (value ? value.split(',').map((t) => t.trim()) : []))
      .refine((types) => types.every((t) => VEHICLE_TYPES.includes(t)), {
        error: 'Tipo de vehículo no válido.',
      }),
    from: z.string().regex(DATE, { error: 'La fecha inicial debe tener el formato AAAA-MM-DD.' }).optional(),
    to: z.string().regex(DATE, { error: 'La fecha final debe tener el formato AAAA-MM-DD.' }).optional(),
  })
  .refine((q) => !q.from || !q.to || q.from <= q.to, {
    error: 'La fecha inicial no puede ser posterior a la final.',
    path: ['from'],
  });

/** Start of a Colombian day (UTC-5, no daylight saving) as a Date. */
function startOfBogotaDay(day) {
  return new Date(`${day}T00:00:00-05:00`);
}

// GET /api/map/reports?vehicle_type=bus,camion&from=2026-11-01&to=2026-11-18
router.get('/reports', async (req, res) => {
  const parsed = mapQuery.safeParse(req.query);
  if (!parsed.success) {
    throw new AppError(
      400,
      'VALIDATION_ERROR',
      'Revisa los filtros del mapa.',
      parsed.error.issues.map((issue) => ({ field: issue.path.join('.'), message: issue.message })),
    );
  }
  const { vehicle_type: types, from, to } = parsed.data;

  const filters = [];
  const params = [];
  if (types.length > 0) {
    params.push(types);
    filters.push(`vehicle_type = ANY($${params.length})`);
  }
  if (from) {
    params.push(startOfBogotaDay(from));
    filters.push(`occurred_at >= $${params.length}`);
  }
  if (to) {
    // Until the end of that day: before the start of the next one.
    const next = startOfBogotaDay(to);
    next.setUTCDate(next.getUTCDate() + 1);
    params.push(next);
    filters.push(`occurred_at < $${params.length}`);
  }
  params.push(MAX_PINS);

  const { rows } = await query(
    `SELECT id, lat, lng, vehicle_type, occurred_at
       FROM reports
      ${filters.length ? `WHERE ${filters.join(' AND ')}` : ''}
      ORDER BY occurred_at DESC
      LIMIT $${params.length}`,
    params,
  );
  res.json(rows);
});

module.exports = router;
