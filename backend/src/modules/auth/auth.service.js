const bcrypt = require('bcryptjs');
const { query } = require('../../db/pool');
const AppError = require('../../utils/AppError');
const { signToken } = require('../../utils/jwt');
const { PUBLIC_COLUMNS } = require('../users/users.service');

const BCRYPT_COST = 10;

// US-01. Creates the account, stores the consent date and opens the session.
async function register(data) {
  const passwordHash = await bcrypt.hash(data.password, BCRYPT_COST);
  try {
    const { rows } = await query(
      `INSERT INTO users (full_name, doc_type, doc_number, email, phone, password_hash, consent_at)
       VALUES ($1, $2, $3, $4, $5, $6, now())
       RETURNING ${PUBLIC_COLUMNS}`,
      [data.full_name, data.doc_type, data.doc_number, data.email, data.phone, passwordHash],
    );
    const user = rows[0];
    return { token: signToken(user.id), user };
  } catch (err) {
    // 23505 = unique violation (users.email).
    if (err.code === '23505') {
      throw new AppError(409, 'EMAIL_TAKEN', 'Este correo ya está registrado.', [
        { field: 'email', message: 'Este correo ya está registrado.' },
      ]);
    }
    throw err;
  }
}

module.exports = { register };
