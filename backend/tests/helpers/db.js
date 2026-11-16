// Helpers for tests that need the test database (Neon "test" branch).
const hasTestDb = process.env.TEST_DB_VERIFIED === 'true';

if (!hasTestDb) {
  console.warn(
    '[tests] TEST_DATABASE_URL no está configurada: se omiten las pruebas que usan la base de datos.',
  );
}

// describe() when the test database is available, describe.skip() otherwise.
const describeDb = hasTestDb ? describe : describe.skip;

function assertTestDb() {
  if (process.env.NODE_ENV !== 'test' || !hasTestDb) {
    throw new Error('Limpieza bloqueada: solo se permite sobre la base de pruebas.');
  }
}

// Removes all users (and, by cascade, their reports and media). Test database only.
async function resetUsers() {
  assertTestDb();
  const { query } = require('../../src/db/pool');
  await query('TRUNCATE users CASCADE');
}

async function closeDb() {
  if (!hasTestDb) return;
  const { getPool } = require('../../src/db/pool');
  await getPool().end();
}

module.exports = { hasTestDb, describeDb, resetUsers, closeDb };
