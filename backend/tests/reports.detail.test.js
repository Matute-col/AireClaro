const fs = require('fs');
const request = require('supertest');
const app = require('../src/app');
const files = require('./helpers/files');
const { describeDb, resetUsers, closeDb } = require('./helpers/db');
const { registerUser, authorityId, validFields, postReport } = require('./helpers/reports');

const uploadDir = process.env.UPLOAD_DIR;
const NO_ID = '00000000-0000-4000-8000-000000000000';

describeDb('GET /api/reports/:id (US-11, test database)', () => {
  let ana;
  let otro;
  let report;

  beforeAll(async () => {
    await resetUsers();
    fs.rmSync(uploadDir, { recursive: true, force: true });
    ana = await registerUser('ana@example.com');
    otro = await registerUser('otro@example.com');
    const res = await postReport(
      ana.token,
      validFields({ authority_id: String(await authorityId('SDA')) }),
      [
        { buffer: files.jpeg(), name: 'placa.jpg' },
        { buffer: files.mp4(), name: 'humo.mp4' },
      ],
    );
    report = res.body.report;
  });
  afterAll(async () => {
    await resetUsers();
    fs.rmSync(uploadDir, { recursive: true, force: true });
    await closeDb();
  });

  const get = (user, url) => request(app).get(url).set('Authorization', `Bearer ${user.token}`);

  it('the owner gets the report, its media and the authority', async () => {
    const res = await get(ana, `/api/reports/${report.id}`);

    expect(res.status).toBe(200);
    expect(res.body.report).toMatchObject({
      id: report.id,
      plate: 'ABC123',
      vehicle_type: 'bus',
      smoke_color: 'negro',
      description: 'Humo negro al arrancar',
      status: 'generado',
      sent_at: null,
      requester_name: 'Luis Prueba',
      requester_email: 'luis@example.com',
    });
    expect(res.body.media.map((m) => m.kind).sort()).toEqual(['photo', 'video']);
    expect(res.body.authority).toEqual({
      id: await authorityId('SDA'),
      code: 'SDA',
      name: 'Secretaría Distrital de Ambiente de Bogotá',
      portal_url: 'https://www.bogota.gov.co/sdqs',
      can_email: true,
    });
  });

  it('never exposes the authority email or the stored file paths', async () => {
    const body = JSON.stringify((await get(ana, `/api/reports/${report.id}`)).body);
    expect(body).not.toContain('@ambientebogota.gov.co');
    expect(body).not.toContain('file_path');
    expect(body).not.toContain('reports/');
  });

  it('PROPERTY (RB-01): another user gets 404, the same answer as a report that does not exist', async () => {
    const someoneElse = await get(otro, `/api/reports/${report.id}`);
    const missing = await get(ana, `/api/reports/${NO_ID}`);

    expect(someoneElse.status).toBe(404);
    expect(missing.status).toBe(404);
    expect(someoneElse.body).toEqual(missing.body);
    expect(someoneElse.body.error.message).toBe('No encontramos este reporte.');
  });

  it('another user cannot read the evidence either', async () => {
    const res = await get(otro, `/api/reports/${report.id}/media/${report.media[0].id}`);
    expect(res.status).toBe(404);
  });

  it('a malformed id gets 404', async () => {
    expect((await get(ana, '/api/reports/no-es-un-id')).status).toBe(404);
  });

  it('requires a token', async () => {
    expect((await request(app).get(`/api/reports/${report.id}`)).status).toBe(401);
  });
});
