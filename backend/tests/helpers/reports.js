// Shared helpers to create users and reports through the real API (test database).
const request = require('supertest');
const app = require('../../src/app');
const { query } = require('../../src/db/pool');
const files = require('./files');

async function registerUser(email) {
  const res = await request(app)
    .post('/api/auth/register')
    .send({
      full_name: 'Luis Prueba',
      doc_type: 'CC',
      doc_number: 'TEST0009',
      email,
      password: 'clave-segura-9',
      accept_terms: true,
    })
    .expect(201);
  return { token: res.body.token, id: res.body.user.id };
}

async function authorityId(code) {
  const { rows } = await query('SELECT id FROM authorities WHERE code = $1', [code]);
  return rows[0].id;
}

/** Valid report fields as the app sends them (multipart text fields). */
function validFields(overrides = {}) {
  return {
    vehicle_type: 'bus',
    plate: 'abc-123',
    smoke_color: 'negro',
    description: 'Humo negro al arrancar',
    lat: '4.579',
    lng: '-74.217',
    address: 'Carrera 3A, Ubaté, Soacha ciudad',
    occurred_at: new Date(Date.now() - 10 * 60 * 1000).toISOString(),
    requester_name: 'Luis Prueba',
    requester_doc_type: 'CC',
    requester_doc_number: 'TEST0009',
    requester_email: 'luis@example.com',
    requester_phone: '',
    ...overrides,
  };
}

/** POST /api/reports with fields and attachments [{buffer, name}]. */
function postReport(token, fields, attachments = [{ buffer: files.jpeg(), name: 'placa.jpg' }]) {
  const req = request(app).post('/api/reports').set('Authorization', `Bearer ${token}`);
  for (const [key, value] of Object.entries(fields)) {
    if (value !== undefined) req.field(key, value);
  }
  for (const { buffer, name } of attachments) req.attach('files', buffer, name);
  return req;
}

module.exports = { registerUser, authorityId, validFields, postReport };
