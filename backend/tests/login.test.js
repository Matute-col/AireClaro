const request = require('supertest');
const app = require('../src/app');
const { describeDb, resetUsers, closeDb } = require('./helpers/db');

describe('POST /api/auth/login validation (no database)', () => {
  it('returns 400 when fields are missing', async () => {
    const res = await request(app).post('/api/auth/login').send({});
    expect(res.status).toBe(400);
    const fields = res.body.error.details.map((d) => d.field);
    expect(fields).toEqual(expect.arrayContaining(['email', 'password']));
  });
});

describeDb('POST /api/auth/login (database)', () => {
  const account = {
    full_name: 'Luis Prueba',
    doc_type: 'CE',
    doc_number: 'TEST0001',
    email: 'luis@example.com',
    password: 'clave-segura-2',
    accept_terms: true,
  };

  beforeAll(async () => {
    await resetUsers();
    await request(app).post('/api/auth/register').send(account).expect(201);
  });
  afterAll(async () => {
    await resetUsers();
    await closeDb();
  });

  it('logs in with valid credentials (email trimmed, any case)', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: '  LUIS@example.com ', password: account.password });

    expect(res.status).toBe(200);
    expect(typeof res.body.token).toBe('string');
    expect(res.body.user.email).toBe(account.email);
    expect(res.body.user.password_hash).toBeUndefined();
  });

  it('wrong password and unknown email give the same generic error', async () => {
    const wrongPassword = await request(app)
      .post('/api/auth/login')
      .send({ email: account.email, password: 'otra-clave-9' });
    const unknownEmail = await request(app)
      .post('/api/auth/login')
      .send({ email: 'nadie@example.com', password: account.password });

    expect(wrongPassword.status).toBe(401);
    expect(unknownEmail.status).toBe(401);
    expect(wrongPassword.body).toEqual(unknownEmail.body);
    expect(wrongPassword.body.error.message).toBe('Correo o contraseña incorrectos.');
  });
});
