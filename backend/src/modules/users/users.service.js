const { query } = require('../../db/pool');
const AppError = require('../../utils/AppError');

// Columns returned to the client. Never includes password_hash.
const PUBLIC_COLUMNS =
  'id, full_name, doc_type, doc_number, email, phone, consent_at, created_at, updated_at';

// The token is valid but the user no longer exists.
function sessionInvalid() {
  return new AppError(401, 'UNAUTHORIZED', 'Tu sesión no es válida. Inicia sesión de nuevo.');
}

async function getById(id) {
  const { rows } = await query(`SELECT ${PUBLIC_COLUMNS} FROM users WHERE id = $1`, [id]);
  if (!rows[0]) throw sessionInvalid();
  return rows[0];
}

async function updateProfile(id, data) {
  const { rows } = await query(
    `UPDATE users
        SET full_name = $2, doc_type = $3, doc_number = $4, phone = $5, updated_at = now()
      WHERE id = $1
      RETURNING ${PUBLIC_COLUMNS}`,
    [id, data.full_name, data.doc_type, data.doc_number, data.phone],
  );
  if (!rows[0]) throw sessionInvalid();
  return rows[0];
}

module.exports = { PUBLIC_COLUMNS, getById, updateProfile };
