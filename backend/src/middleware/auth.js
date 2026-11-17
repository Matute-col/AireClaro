const AppError = require('../utils/AppError');
const { verifyToken } = require('../utils/jwt');

// Requires "Authorization: Bearer <token>". Sets req.user = { id }.
// Expired, badly signed or malformed tokens -> 401 so the app returns to login (CP-20).
function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');

  if (scheme !== 'Bearer' || !token) {
    return next(new AppError(401, 'UNAUTHORIZED', 'Debes iniciar sesión para continuar.'));
  }

  try {
    const payload = verifyToken(token);
    req.user = { id: payload.sub };
    return next();
  } catch (err) {
    const message =
      err.name === 'TokenExpiredError'
        ? 'Tu sesión expiró. Inicia sesión de nuevo.'
        : 'Tu sesión no es válida. Inicia sesión de nuevo.';
    return next(new AppError(401, 'UNAUTHORIZED', message));
  }
}

module.exports = requireAuth;
