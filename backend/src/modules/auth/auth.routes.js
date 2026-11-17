const express = require('express');
const validate = require('../../middleware/validate');
const { authLimiter } = require('../../middleware/rateLimit');
const { registerSchema, loginSchema } = require('./auth.schema');
const controller = require('./auth.controller');

const router = express.Router();

// Stricter limit for /auth: 10 requests per 15 minutes per IP.
router.use(authLimiter);

router.post('/register', validate(registerSchema), controller.register);
router.post('/login', validate(loginSchema), controller.login);

module.exports = router;
