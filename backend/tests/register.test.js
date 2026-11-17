const request = require('supertest');
const app = require('../src/app');
const { registerSchema } = require('../src/modules/auth/auth.schema');
const { describeDb, resetUsers, closeDb } = require('./helpers/db');

function validBody(overrides = {}) {
  return {
    full_name: 'Ana Prueba',
    doc_type: 'CC',
    doc_number: 'TEST0001',
    email: 'ana@example.com',
    phone: '0000000',
    password: 'clave-segura-1',
    accept_terms: true,
    ...overrides,
  };
}

// --- Validation only (no database) ---
describe('register schema', () => {
  it('trims full_name, doc_number and email, and lowercases the email', () => {
    const data = registerSchema.parse(
      validBody({ full_name: '  Ana Prueba  ', doc_number: ' TEST0001 ', email: '  Ana@Example.COM ' }),
    );
    expect(data.full_name).toBe('Ana Prueba');
    expect(data.doc_number).toBe('TEST0001');
    expect(data.email).toBe('ana@example.com');
  });

  it('rejects a name that is only spaces (trim before validating)', () => {
    const result = registerSchema.safeParse(validBody({ full_name: '    ' }));
    expect(result.success).toBe(false);
  });

  it('accepts a missing or empty phone and stores null', () => {
    expect(registerSchema.parse(validBody({ phone: undefined })).phone).toBeNull();
    expect(registerSchema.parse(validBody({ phone: '  ' })).phone).toBeNull();
  });

  it('rejects passwords longer than 72 bytes', () => {
    const result = registerSchema.safeParse(validBody({ password: 'ñ'.repeat(40) }));
    expect(result.success).toBe(false);
  });
});

describe('POST /api/auth/register validation (no database)', () => {
  it('returns 400 with Spanish field errors', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send(validBody({ email: 'no-es-correo', password: '123', doc_type: 'XX' }));

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    const fields = res.body.error.details.map((d) => d.field);
    expect(fields).toEqual(expect.arrayContaining(['email', 'password', 'doc_type']));
    expect(res.body.error.details.find((d) => d.field === 'password').message).toMatch(/al menos 8/);
  });

  it('requires accepting the data policy (RF-11)', async () => {
    const res = await request(app).post('/api/auth/register').send(validBody({ accept_terms: false }));
    expect(res.status).toBe(400);
    expect(res.body.error.details[0].field).toBe('accept_terms');
  });

  it('returns 400 when the body is missing', async () => {
    const res = await request(app).post('/api/auth/register');
    expect(res.status).toBe(400);
  });
});

// --- With the test database (Neon "test" branch) ---
describeDb('POST /api/auth/register (database)', () => {
  beforeAll(resetUsers);
  afterAll(async () => {
    await resetUsers();
    await closeDb();
  });

  it('creates the account, saves consent_at and opens the session (CP-01)', async () => {
    const before = Date.now();
    const res = await request(app).post('/api/auth/register').send(validBody({ email: ' Ana@Example.com ' }));

    expect(res.status).toBe(201);
    expect(typeof res.body.token).toBe('string');
    expect(res.body.user.email).toBe('ana@example.com');
    expect(res.body.user.password_hash).toBeUndefined();
    expect(new Date(res.body.user.consent_at).getTime()).toBeGreaterThanOrEqual(before - 60_000);
  });

  it('rejects a duplicate email, ignoring case (CP-02)', async () => {
    const res = await request(app).post('/api/auth/register').send(validBody({ email: 'ANA@example.com' }));

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('EMAIL_TAKEN');
    expect(res.body.error.message).toBe('Este correo ya está registrado.');
  });

  it('stores the password as a bcrypt hash', async () => {
    const { query } = require('../src/db/pool');
    const { rows } = await query('SELECT password_hash FROM users WHERE email = $1', ['ana@example.com']);
    expect(rows[0].password_hash).toMatch(/^\$2[aby]\$10\$/);
  });
});
