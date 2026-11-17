const { query } = require('../../db/pool');

// Authority emails are never sent to the app: only whether one is verified (can_email).

async function list() {
  const { rows } = await query(
    `SELECT id, code, name, portal_url, (email IS NOT NULL AND email_verified) AS can_email
       FROM authorities
      ORDER BY id`,
  );
  return rows;
}

async function getIdByCode(code) {
  if (!code) return null;
  const { rows } = await query('SELECT id FROM authorities WHERE code = $1', [code]);
  return rows[0]?.id ?? null;
}

async function getById(id) {
  const { rows } = await query('SELECT id, code, name FROM authorities WHERE id = $1', [id]);
  return rows[0] ?? null;
}

module.exports = { list, getIdByCode, getById };
