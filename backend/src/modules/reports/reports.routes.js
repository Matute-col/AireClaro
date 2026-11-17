const express = require('express');
const { z } = require('zod');
const requireAuth = require('../../middleware/auth');
const validate = require('../../middleware/validate');
const { receiveEvidence, checkEvidence } = require('../../middleware/upload');
const AppError = require('../../utils/AppError');
const { removeFiles } = require('../../utils/storage');
const { createReportSchema } = require('./reports.schema');
const reportsService = require('./reports.service');

const router = express.Router();

router.use(requireAuth);

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** A malformed id cannot exist: answer 404 like any report that is not yours. */
function requireUuidParams(...names) {
  return (req, res, next) => {
    const bad = names.some((name) => !UUID_REGEX.test(req.params[name] || ''));
    next(bad ? new AppError(404, 'NOT_FOUND', reportsService.NOT_FOUND_MESSAGE) : undefined);
  };
}

const listQuery = z.object({
  page: z.coerce.number().int().min(1, { error: 'La página debe ser 1 o mayor.' }).default(1),
  limit: z.coerce
    .number()
    .int()
    .min(1, { error: 'El límite debe estar entre 1 y 50.' })
    .max(50, { error: 'El límite debe estar entre 1 y 50.' })
    .default(20),
  status: z.enum(['generado', 'enviado'], { error: 'Estado no válido.' }).optional(),
});

// GET /api/reports?page=1&limit=20&status=generado → {items, page, total}
router.get('/', async (req, res) => {
  const parsed = listQuery.safeParse(req.query);
  if (!parsed.success) {
    throw new AppError(
      400,
      'VALIDATION_ERROR',
      'Revisa los datos ingresados.',
      parsed.error.issues.map((issue) => ({ field: issue.path.join('.'), message: issue.message })),
    );
  }
  res.json(await reportsService.list(req.user.id, parsed.data));
});

// GET /api/reports/:id/media/:mediaId → the file, only for the owner.
router.get('/:id/media/:mediaId', requireUuidParams('id', 'mediaId'), async (req, res, next) => {
  const file = await reportsService.getMediaFile(req.user.id, req.params.id, req.params.mediaId);
  res.set('Content-Type', file.mimeType);
  res.set('Cache-Control', 'private, max-age=3600');
  res.sendFile(file.absolutePath, (err) => {
    if (!err) return;
    if (err.code === 'ENOENT') {
      next(new AppError(404, 'NOT_FOUND', 'El archivo de evidencia ya no está disponible.'));
    } else if (!res.headersSent) {
      next(err);
    }
  });
});

// POST /api/reports (multipart/form-data): report fields + files[] (1 to 3).
// Order: receive files → validate fields → check files by content → save.
router.post(
  '/',
  receiveEvidence,
  validate(createReportSchema),
  checkEvidence,
  async (req, res) => {
    const report = await reportsService.create(req.user.id, req.body, req.files);
    res.status(201).json({ report });
  },
);

// If any step above fails, the temporary uploads of this request are deleted
// before the normal error handler answers.
// eslint-disable-next-line no-unused-vars
router.use(async (err, req, res, next) => {
  await removeFiles((req.files || []).map((file) => file.path));
  next(err);
});

module.exports = router;
