const rateLimit = require('express-rate-limit');

const FIFTEEN_MINUTES = 15 * 60 * 1000;

function limiter(limit) {
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

// Global: 100 requests per 15 min per IP. Auth: 10 per 15 min (used from US-01).
const globalLimiter = limiter(100);
const authLimiter = limiter(10);

module.exports = { globalLimiter, authLimiter };
