const express = require('express');
const { z } = require('zod');
const requireAuth = require('../../middleware/auth');
const validate = require('../../middleware/validate');
const { receiveEvidence, checkEvidence, uploadedPaths } = require('../../middleware/upload');
const AppError = require('../../utils/AppError');
const { removeFiles } = require('../../utils/storage');
const { createReportSchema } = require('./reports.schema');
const env = require('../../config/env');
const reportsService = require('./reports.service');
const pqrsdService = require('../pqrsd/pqrsd.service');
const sendService = require('../mail/send.service');

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

// GET /api/reports/:id → {report, media, authority}, only for the owner.
router.get('/:id', requireUuidParams('id'), async (req, res) => {
  res.json(await reportsService.getById(req.user.id, req.params.id));
});

// GET /api/reports/:id/pqrsd → {authority, plate, status, text, mail_mode} (preview).
router.get('/:id/pqrsd', requireUuidParams('id'), async (req, res) => {
  const preview = await pqrsdService.getText(req.user.id, req.params.id);
  res.json({ ...preview, mail_mode: env.MAIL_MODE });
});

// GET /api/reports/:id/pqrsd.pdf → the request as PDF (generated on the fly, not stored).
router.get('/:id/pqrsd.pdf', requireUuidParams('id'), async (req, res) => {
  const { buffer, fileName } = await pqrsdService.getPdf(req.user.id, req.params.id);
  res.set('Content-Type', 'application/pdf');
  res.set('Content-Disposition', `inline; filename="${fileName}"`);
  res.set('Cache-Control', 'private, no-store');
  res.send(buffer);
});

// POST /api/reports/:id/send {confirm: true} → email to the authority (US-21, RF-17).
const sendBody = z.object({
  confirm: z.literal(true, { error: 'Confirma el envío de la solicitud.' }),
});
router.post('/:id/send', requireUuidParams('id'), validate(sendBody), async (req, res) => {
  res.json(await sendService.sendReport(req.user.id, req.params.id));
});

// PATCH /api/reports/:id/status {status: 'enviado'} → «Marcar como enviado» (US-14, US-22).
const statusBody = z.object({
  status: z.literal('enviado', { error: 'Solo se puede marcar la solicitud como «enviado».' }),
});
// DELETE /api/reports/:id → 204. Only the owner (404 otherwise), with its files (US-18).
router.delete('/:id', requireUuidParams('id'), async (req, res) => {
  if (sendService.isSending(req.params.id)) {
    throw new AppError(409, 'SEND_IN_PROGRESS', 'El envío de esta solicitud por correo está en curso.');
  }
  await reportsService.deleteReport(req.user.id, req.params.id);
  res.status(204).end();
});

router.patch('/:id/status', requireUuidParams('id'), validate(statusBody), async (req, res) => {
  if (sendService.isSending(req.params.id)) {
    throw new AppError(409, 'SEND_IN_PROGRESS', 'El envío de esta solicitud por correo está en curso.');
  }
  res.json({ report: await reportsService.markAsSent(req.user.id, req.params.id) });
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

// POST /api/reports (multipart/form-data): report fields + files[] (1 to 3)
// + frames_v<N> (up to 4 JPEG frames of the video at position N, US-23).
// Order: receive files → validate fields → check files by content → save.
router.post(
  '/',
  receiveEvidence,
  validate(createReportSchema),
  checkEvidence,
  async (req, res) => {
    const report = await reportsService.create(req.user.id, req.body, req.files, req.frames);
    res.status(201).json({ report });
  },
);

// If any step above fails, the temporary uploads of this request are deleted
// before the normal error handler answers.
// eslint-disable-next-line no-unused-vars
router.use(async (err, req, res, next) => {
  await removeFiles(uploadedPaths(req));
  next(err);
});

module.exports = router;
