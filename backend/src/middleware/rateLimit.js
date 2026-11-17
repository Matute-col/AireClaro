const rateLimit = require('express-rate-limit');
const env = require('../config/env');

const FIFTEEN_MINUTES = 15 * 60 * 1000;

function createLimiter(limit) {
  return rateLimit({
    windowMs: FIFTEEN_MINUTES,
    limit,
    standardHeaders: 'draft-8',
    legacyHeaders: false,
    handler: (req, res) => {
      res.status(429).json({
        error: {
          code: 'TOO_MANY_REQUESTS',
          message: 'Demasiadas peticiones. Espera unos minutos e intenta de nuevo.',
        },
      });
    },
  });
}

// Under jest the limits are raised so the test suite itself is not blocked;
// tests/rateLimit.test.js checks the limiter behavior with a small limit.
const isTest = env.NODE_ENV === 'test';

// Global: 300 requests per 15 min per IP (each evidence thumbnail is one request).
// Auth: 10 per 15 min.
const globalLimiter = createLimiter(isTest ? 1000 : 300);
const authLimiter = createLimiter(isTest ? 1000 : 10);

module.exports = { createLimiter, globalLimiter, authLimiter };
