const jwt = require('jsonwebtoken');
const request = require('supertest');
const app = require('../src/app');
const { updateProfileSchema } = require('../src/modules/users/users.schema');
const { describeDb, resetUsers, closeDb } = require('./helpers/db');

const SOME_ID = '00000000-0000-4000-8000-000000000000';

// --- Token checks (CP-20), no database: requireAuth rejects before any query ---
describe('GET /api/me token checks (CP-20)', () => {
  it('401 without a token', async () => {
    const res = await request(app).get('/api/me');
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('UNAUTHORIZED');
  });

  it('401 with an expired token and a "session expired" message', async () => {
    const expired = jwt.sign(
      { sub: SOME_ID, exp: Math.floor(Date.now() / 1000) - 60 },
      process.env.JWT_SECRET,
      { algorithm: 'HS256' },
    );
    const res = await request(app).get('/api/me').set('Authorization', `Bearer ${expired}`);
    expect(res.status).toBe(401);
    expect(res.body.error.message).toMatch(/expiró/);
  });

  it('401 with a token signed with another secret', async () => {
    const forged = jwt.sign({}, 'otro-secreto-que-no-es-el-del-servidor-1234', {
      subject: SOME_ID,
      algorithm: 'HS256',
    });
    const res = await request(app).get('/api/me').set('Authorization', `Bearer ${forged}`);
    expect(res.status).toBe(401);
    expect(res.body.error.message).toMatch(/no es válida/);
  });

  it('401 with an unsigned token (alg "none")', async () => {
    const unsigned = jwt.sign({}, null, { subject: SOME_ID, algorithm: 'none' });
    const res = await request(app).get('/api/me').set('Authorization', `Bearer ${unsigned}`);
    expect(res.status).toBe(401);
  });

  it('401 with a malformed header', async () => {
    const res = await request(app).get('/api/me').set('Authorization', 'Token abc');
    expect(res.status).toBe(401);
  });
});

describe('update profile schema', () => {
  it('drops the email field (email cannot be edited)', () => {
    const data = updateProfileSchema.parse({
      full_name: ' Ana ',
      doc_type: 'CC',
      doc_number: ' 123456 ',
      email: 'otro@example.com',
    });
    expect(data).not.toHaveProperty('email');
    expect(data.full_name).toBe('Ana');
    expect(data.doc_number).toBe('123456');
  });
});

// --- With the test database ---
describeDb('GET and PUT /api/me (database)', () => {
  let token;

  beforeAll(async () => {
    await resetUsers();
    const res = await request(app)
      .post('/api/auth/register')
      .send({
        full_name: 'Marta Prueba',
        doc_type: 'CC',
        doc_number: '52123456',
        email: 'marta@example.com',
        phone: '3109876543',
        password: 'clave-segura-3',
        accept_terms: true,
      })
      .expect(201);
    token = res.body.token;
  });
  afterAll(async () => {
    await resetUsers();
    await closeDb();
  });

  const auth = () => ({ Authorization: `Bearer ${token}` });

  it('GET returns the profile without password_hash', async () => {
    const res = await request(app).get('/api/me').set(auth());
    expect(res.status).toBe(200);
    expect(res.body.user).toMatchObject({
      full_name: 'Marta Prueba',
      doc_type: 'CC',
      doc_number: '52123456',
      email: 'marta@example.com',
      phone: '3109876543',
    });
    expect(res.body.user.password_hash).toBeUndefined();
  });

  it('PUT updates name, document and phone, trims them, and ignores email', async () => {
    const res = await request(app).put('/api/me').set(auth()).send({
      full_name: '  Marta Lucía Prueba  ',
      doc_type: 'PAS',
      doc_number: ' ab998877 ',
      phone: '',
      email: 'hackeado@example.com',
    });

    expect(res.status).toBe(200);
    expect(res.body.user).toMatchObject({
      full_name: 'Marta Lucía Prueba',
      doc_type: 'PAS',
      doc_number: 'AB998877',
      phone: null,
      email: 'marta@example.com',
    });

    const again = await request(app).get('/api/me').set(auth());
    expect(again.body.user.email).toBe('marta@example.com');
  });

  it('PUT applies the same rules as registration (400 in Spanish)', async () => {
    const res = await request(app)
      .put('/api/me')
      .set(auth())
      .send({ full_name: ' ', doc_type: 'XX', doc_number: '12', phone: 'abc' });

    expect(res.status).toBe(400);
    const fields = res.body.error.details.map((d) => d.field);
    expect(fields).toEqual(expect.arrayContaining(['full_name', 'doc_type', 'doc_number', 'phone']));
  });

  it('401 when the token belongs to a user that no longer exists', async () => {
    const ghost = jwt.sign({}, process.env.JWT_SECRET, { subject: SOME_ID, algorithm: 'HS256' });
    const res = await request(app).get('/api/me').set('Authorization', `Bearer ${ghost}`);
    expect(res.status).toBe(401);
  });
});
