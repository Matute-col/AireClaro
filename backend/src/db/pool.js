const { Pool } = require('pg');
const env = require('../config/env');

let pool;

// An idle client lost its connection. Like errorHandler.js, only the error code is
// logged by default; the full message (it may include connection details) only
// when LOG_ERROR_DETAILS=true is set on purpose.
function logIdleClientError(err) {
  const code = err.code || err.name || 'UNKNOWN';
  const detail = env.LOG_ERROR_DETAILS ? ` - ${err.message}` : '';
  console.error(`[db] error en conexión inactiva: ${code}${detail}`);
}

// Lazily creates the connection pool, so the app (and tests like /health)
// can start without a database.
function getPool() {
  if (!env.DATABASE_URL) {
    throw new Error('DATABASE_URL no está configurada en backend/.env');
  }
  if (!pool) {
    pool = new Pool({
      connectionString: env.DATABASE_URL,
      ssl: env.DATABASE_SSL ? { rejectUnauthorized: true } : false,
      max: 5,
    });
    pool.on('error', logIdleClientError);
  }
  return pool;
}

function query(text, params) {
  return getPool().query(text, params);
}

module.exports = { getPool, query, logIdleClientError };
