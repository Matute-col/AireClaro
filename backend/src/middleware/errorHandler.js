const AppError = require('../utils/AppError');

// 404 for any route that was not matched.
function notFound(req, res, next) {
  next(new AppError(404, 'NOT_FOUND', 'Recurso no encontrado'));
}

// Single place that turns errors into { error: { code, message, details } }.
// Never logs request bodies (they may contain passwords or personal data).
// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, next) {
  if (err instanceof AppError) {
    return res.status(err.status).json({
      error: { code: err.code, message: err.message, details: err.details },
    });
  }

  // Errors raised by express.json() (malformed JSON or body too large).
  if (err.type === 'entity.parse.failed') {
    return res
      .status(400)
      .json({ error: { code: 'INVALID_JSON', message: 'El cuerpo de la petición no es JSON válido' } });
  }
  if (err.type === 'entity.too.large') {
    return res
      .status(413)
      .json({ error: { code: 'PAYLOAD_TOO_LARGE', message: 'La petición es demasiado grande' } });
  }

  console.error(`[error] ${req.method} ${req.path}: ${err.message}`);
  return res
    .status(500)
    .json({ error: { code: 'INTERNAL_ERROR', message: 'Ocurrió un error inesperado. Intenta de nuevo.' } });
}

module.exports = { notFound, errorHandler };
