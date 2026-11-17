const express = require('express');
const requireAuth = require('../../middleware/auth');
const authoritiesService = require('./authorities.service');

const router = express.Router();

router.use(requireAuth);

// GET /api/authorities → [{id, code, name, portal_url, can_email}]
router.get('/', async (req, res) => {
  res.json(await authoritiesService.list());
});

module.exports = router;
