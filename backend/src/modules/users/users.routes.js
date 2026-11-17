const express = require('express');
const requireAuth = require('../../middleware/auth');
const validate = require('../../middleware/validate');
const { updateProfileSchema } = require('./users.schema');
const controller = require('./users.controller');

const router = express.Router();

router.use(requireAuth);

router.get('/', controller.getMe);
router.put('/', validate(updateProfileSchema), controller.updateMe);

module.exports = router;
