const express = require('express');
const { z } = require('zod');
const requireAuth = require('../../middleware/auth');
const AppError = require('../../utils/AppError');
const geoService = require('./geo.service');

const router = express.Router();

const reverseQuery = z.object({
  lat: z.coerce
    .number({ error: 'La latitud debe ser un número.' })
    .min(-90, { error: 'La latitud debe estar entre -90 y 90.' })
    .max(90, { error: 'La latitud debe estar entre -90 y 90.' }),
  lng: z.coerce
    .number({ error: 'La longitud debe ser un número.' })
    .min(-180, { error: 'La longitud debe estar entre -180 y 180.' })
    .max(180, { error: 'La longitud debe estar entre -180 y 180.' }),
});

router.use(requireAuth);

// GET /api/geo/reverse?lat=4.579&lng=-74.217
router.get('/reverse', async (req, res) => {
  const parsed = reverseQuery.safeParse(req.query);
  if (!parsed.success) {
    throw new AppError(
      400,
      'VALIDATION_ERROR',
      'Revisa los datos ingresados.',
      parsed.error.issues.map((issue) => ({ field: issue.path.join('.'), message: issue.message })),
    );
  }
  res.json(await geoService.reverse(parsed.data.lat, parsed.data.lng));
});

module.exports = router;
