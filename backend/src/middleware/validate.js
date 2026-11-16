const AppError = require('../utils/AppError');

// Validates req.body with a zod schema. On success, req.body is replaced with the
// parsed (trimmed / normalized) data; unknown fields are dropped.
function validate(schema) {
  return (req, res, next) => {
    const result = schema.safeParse(req.body ?? {});
    if (!result.success) {
      const details = result.error.issues.map((issue) => ({
        field: issue.path.join('.'),
        message: issue.message,
      }));
      return next(new AppError(400, 'VALIDATION_ERROR', 'Revisa los datos ingresados.', details));
    }
    req.body = result.data;
    return next();
  };
}

module.exports = validate;
