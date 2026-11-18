const fs = require('fs');
const request = require('supertest');
const app = require('../src/app');
const mailer = require('../src/modules/mail/mailer');
const { describeDb, resetUsers, closeDb } = require('./helpers/db');
const { registerUser, authorityId, validFields, postReport } = require('./helpers/reports');

// US-14 / US-22 · PATCH /api/reports/:id/status — «Marcar como enviado» (RB-06).

const uploadDir = process.env.UPLOAD_DIR;

describeDb('PATCH /api/reports/:id/status (test database)', () => {
  let ana;
  let otro;
  let sdm;
  let sda;

  beforeAll(async () => {
    await resetUsers();
    fs.rmSync(uploadDir, { recursive: true, force: true });
    ana = await registerUser('ana@example.com');
    otro = await registerUser('otro@example.com');
    sdm = String(await authorityId('SDM'));
    sda = String(await authorityId('SDA'));
  });
  beforeEach(() => {
    jest.spyOn(mailer, 'sendMail').mockResolvedValue({ messageId: 'simulado' });
    jest.spyOn(console, 'log').mockImplementation(() => {});
  });
  afterEach(() => jest.restoreAllMocks());
  afterAll(async () => {
    await resetUsers();
    fs.rmSync(uploadDir, { recursive: true, force: true });
    await closeDb();
  });

  async function newReport(authority = sdm) {
    const res = await postReport(ana.token, validFields({ authority_id: authority }));
    return res.body.report;
  }
  const mark = (user, id, body = { status: 'enviado' }) =>
    request(app).patch(`/api/reports/${id}/status`).set('Authorization', `Bearer ${user.token}`).send(body);
  const detail = (id) => request(app).get(`/api/reports/${id}`).set('Authorization', `Bearer ${ana.token}`);

  it('200: after the portal (SDM, no email) the report is «enviado» by hand', async () => {
    const report = await newReport();
    const res = await mark(ana, report.id);

    expect(res.status).toBe(200);
    expect(res.body.report).toMatchObject({ status: 'enviado', sent_via: 'manual', send_mode: null });
    expect(res.body.report.sent_at).not.toBeNull();
    expect((await detail(report.id)).body.report).toMatchObject({ status: 'enviado', sent_via: 'manual' });
  });

  it('409: it cannot be marked twice', async () => {
    const report = await newReport();
    await mark(ana, report.id).expect(200);
    const again = await mark(ana, report.id);
    expect(again.status).toBe(409);
    expect(again.body.error.code).toBe('ALREADY_SENT');
  });

  it('409: a report already sent by email cannot be marked by hand', async () => {
    const report = await newReport(sda);
    await request(app)
      .post(`/api/reports/${report.id}/send`)
      .set('Authorization', `Bearer ${ana.token}`)
      .send({ confirm: true })
      .expect(200);
    expect((await mark(ana, report.id)).status).toBe(409);
    expect((await detail(report.id)).body.report.sent_via).toBe('email');
  });

  it('after marking it by hand, it cannot be sent by email (409)', async () => {
    const report = await newReport(sda);
    await mark(ana, report.id).expect(200);
    const send = await request(app)
      .post(`/api/reports/${report.id}/send`)
      .set('Authorization', `Bearer ${ana.token}`)
      .send({ confirm: true });
    expect(send.status).toBe(409);
    expect(mailer.sendMail).not.toHaveBeenCalled();
  });

  it('400: only «enviado» is accepted', async () => {
    const report = await newReport();
    for (const body of [{}, { status: 'generado' }, { status: 'borrado' }]) {
      expect((await mark(ana, report.id, body)).status).toBe(400);
    }
    expect((await detail(report.id)).body.report.status).toBe('generado');
  });

  it('404: another user cannot mark someone else’s report', async () => {
    const report = await newReport();
    expect((await mark(otro, report.id)).status).toBe(404);
    expect((await detail(report.id)).body.report.status).toBe('generado');
  });

  it('401 without a token', async () => {
    const report = await newReport();
    expect((await request(app).patch(`/api/reports/${report.id}/status`).send({ status: 'enviado' })).status).toBe(401);
  });
});
