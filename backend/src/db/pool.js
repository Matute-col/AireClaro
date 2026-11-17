const { Pool } = require('pg');
const env = require('../config/env');

let pool;

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
    pool.on('error', (err) => console.error(`[db] error en conexión inactiva: ${err.message}`));
  }
  return pool;
}

function query(text, params) {
  return getPool().query(text, params);
}

module.exports = { getPool, query };
