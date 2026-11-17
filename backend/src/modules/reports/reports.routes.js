const express = require('express');
const requireAuth = require('../../middleware/auth');
const validate = require('../../middleware/validate');
const { receiveEvidence, checkEvidence } = require('../../middleware/upload');
const { removeFiles } = require('../../utils/storage');
const { createReportSchema } = require('./reports.schema');
const reportsService = require('./reports.service');

const router = express.Router();

router.use(requireAuth);

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
