const fs = require('fs');
const request = require('supertest');
const app = require('../src/app');
const env = require('../src/config/env');
const mailer = require('../src/modules/mail/mailer');
const { query } = require('../src/db/pool');
const files = require('./helpers/files');
const { pdfText } = require('./helpers/pdfText');
const { describeDb, resetUsers, closeDb } = require('./helpers/db');
const { registerUser, authorityId, validFields, postReport } = require('./helpers/reports');

// US-21 · POST /api/reports/:id/send. The SMTP transport is ALWAYS a fake here:
// no real email leaves jest (and the test SMTP host is a reserved «.invalid» name).

const uploadDir = process.env.UPLOAD_DIR;

describeDb('POST /api/reports/:id/send (US-21, test database, fake SMTP)', () => {
  let luis;
  let otro;
  let sda;
  let sdm;
  let sent;

  beforeAll(async () => {
    await resetUsers();
    fs.rmSync(uploadDir, { recursive: true, force: true });
    luis = await registerUser('luis@example.com');
    otro = await registerUser('otro@example.com');
    sda = String(await authorityId('SDA'));
    sdm = String(await authorityId('SDM'));
  });
  beforeEach(() => {
    sent = [];
    jest.spyOn(mailer, 'sendMail').mockImplementation(async (message) => {
      sent.push(message);
      return { messageId: 'simulado' };
    });
    jest.spyOn(console, 'log').mockImplementation(() => {});
    jest.spyOn(console, 'error').mockImplementation(() => {});
  });
  afterEach(() => {
    jest.restoreAllMocks();
    env.MAIL_MODE = 'test';
  });
  afterAll(async () => {
    await resetUsers();
    fs.rmSync(uploadDir, { recursive: true, force: true });
    await closeDb();
  });

  async function newReport(authority = sda, attachments, frames) {
    const res = await postReport(luis.token, validFields({ authority_id: authority }), attachments, frames);
    expect(res.status).toBe(201);
    return res.body.report;
  }
  const send = (user, id, body = { confirm: true }) =>
    request(app).post(`/api/reports/${id}/send`).set('Authorization', `Bearer ${user.token}`).send(body);
  const statusOf = async (id) =>
    (await query('SELECT status, sent_via, send_mode, sent_at FROM reports WHERE id = $1', [id])).rows[0];

  it('200 (CP-23): test mode → test inbox, [PRUEBA], copy and reply-to the citizen, PDF and evidence', async () => {
    const report = await newReport(sda, [
      { buffer: files.realPng(), name: 'placa.png' },
      { buffer: files.mp4(), name: 'humo.mp4' },
    ]);
    const res = await send(luis, report.id);

    expect(res.status).toBe(200);
    expect(res.body.delivery).toMatchObject({ mode: 'test', evidence_attached: true });
    expect(sent).toHaveLength(1);
    const mail = sent[0];
    expect(mail.to).toBe('buzon-prueba@example.com');
    expect(mail.from).toBe('AireClaro <no-responder@example.com>');
    expect(mail.cc).toBe('luis@example.com');
    expect(mail.replyTo).toBe('luis@example.com');
    expect(mail.subject).toMatch(/^\[PRUEBA\] Petición ciudadana – .* – vehículo de placa ABC123 – Reporte [0-9A-F]{8}$/);
    expect(mail.text).toContain('Ley 1755 de 2015, art. 21');
    expect(mail.text).toContain('no constituyen una medición técnica');

    // PDF first, then the evidence (photo, then video).
    expect(mail.attachments.map((a) => a.contentType)).toEqual(['application/pdf', 'image/png', 'video/mp4']);
    const pdf = pdfText(mail.attachments[0].content);
    expect(pdf).toContain('Fotografía 1 (PNG, 1 KB) – Archivo adjunto al correo.');
    expect(pdf).toContain('Video 1 (MP4, 1 KB) – Archivo adjunto al correo.');

    expect(await statusOf(report.id)).toMatchObject({ status: 'enviado', sent_via: 'email', send_mode: 'test' });
    expect((await statusOf(report.id)).sent_at).not.toBeNull();
  });

  it('evidence over 15 MB: only the PDF, which says «Disponible a solicitud del peticionario»', async () => {
    const report = await newReport();
    await query(`UPDATE report_media SET size_bytes = 16 * 1024 * 1024 WHERE report_id = $1`, [report.id]);
    const res = await send(luis, report.id);

    expect(res.status).toBe(200);
    expect(res.body.delivery.evidence_attached).toBe(false);
    expect(sent[0].attachments).toHaveLength(1);
    expect(pdfText(sent[0].attachments[0].content)).toContain('– Disponible a solicitud del peticionario.');
    expect(sent[0].text).toContain('disponible a solicitud del peticionario');
  });

  it('video frames travel inside the PDF, never as separate attachments (US-23)', async () => {
    const frames = [0, 10, 20, 30].map((extra) => files.realJpeg(extra));
    const report = await newReport(sda, [{ buffer: files.mp4(), name: 'humo.mp4' }], { 0: frames });
    await send(luis, report.id).expect(200);

    expect(sent[0].attachments.map((a) => a.contentType)).toEqual(['application/pdf', 'video/mp4']);
    expect(pdfText(sent[0].attachments[0].content)).toContain('Fotogramas del video 1 (4)');
  });

  it('409 (CP-25): a report can be sent only once', async () => {
    const report = await newReport();
    await send(luis, report.id).expect(200);
    const again = await send(luis, report.id);

    expect(again.status).toBe(409);
    expect(again.body.error.code).toBe('ALREADY_SENT');
    expect(sent).toHaveLength(1);
  });

  it('409: a double tap sends one email (the second one is refused while sending)', async () => {
    const report = await newReport();
    const [a, b] = await Promise.all([send(luis, report.id), send(luis, report.id)]);

    expect([a.status, b.status].sort()).toEqual([200, 409]);
    expect(sent).toHaveLength(1);
  });

  it('422 (CP-24): authority without a verified email (SDM) → nothing is sent', async () => {
    const report = await newReport(sdm);
    const res = await send(luis, report.id);

    expect(res.status).toBe(422);
    expect(res.body.error.code).toBe('AUTHORITY_WITHOUT_EMAIL');
    expect(sent).toHaveLength(0);
    expect((await statusOf(report.id)).status).toBe('generado');
  });

  it('422 (CP-28): live mode with an unverified authority never sends', async () => {
    const report = await newReport(sdm);
    env.MAIL_MODE = 'live';
    const res = await send(luis, report.id);

    expect(res.status).toBe(422);
    expect(sent).toHaveLength(0);
  });

  it('live mode (fake SMTP): goes to the verified authority email, without [PRUEBA]', async () => {
    const report = await newReport();
    env.MAIL_MODE = 'live';
    const res = await send(luis, report.id);

    expect(res.status).toBe(200);
    expect(sent[0].to).toBe('atencionalciudadano@ambientebogota.gov.co');
    expect(sent[0].subject).not.toContain('[PRUEBA]');
    expect((await statusOf(report.id)).send_mode).toBe('live');
  });

  it('502 (CP-26): SMTP failure → message, status unchanged, and it can be retried', async () => {
    const report = await newReport();
    mailer.sendMail.mockRejectedValueOnce(Object.assign(new Error('auth failed for luis@example.com'), { code: 'EAUTH' }));

    const res = await send(luis, report.id);
    expect(res.status).toBe(502);
    expect(res.body.error.code).toBe('MAIL_SEND_FAILED');
    expect((await statusOf(report.id)).status).toBe('generado');

    // Only the error code is logged, never addresses.
    const logged = console.error.mock.calls.flat().join(' ');
    expect(logged).toContain('EAUTH');
    expect(logged).not.toContain('@');

    await send(luis, report.id).expect(200);
  });

  it('503: MAIL_MODE=off → nothing is sent', async () => {
    const report = await newReport();
    env.MAIL_MODE = 'off';
    const res = await send(luis, report.id);

    expect(res.status).toBe(503);
    expect(res.body.error.code).toBe('MAIL_DISABLED');
    expect(sent).toHaveLength(0);
  });

  it('503: SMTP not configured on the server', async () => {
    const report = await newReport();
    const host = env.SMTP_HOST;
    env.SMTP_HOST = '';
    try {
      const res = await send(luis, report.id);
      expect(res.status).toBe(503);
      expect(res.body.error.code).toBe('MAIL_NOT_CONFIGURED');
    } finally {
      env.SMTP_HOST = host;
    }
    expect((await statusOf(report.id)).status).toBe('generado');
  });

  it('400: the sending must be confirmed explicitly ({confirm: true})', async () => {
    const report = await newReport();
    for (const body of [{}, { confirm: false }, { confirm: 'true' }]) {
      const res = await send(luis, report.id, body);
      expect(res.status).toBe(400);
    }
    expect(sent).toHaveLength(0);
  });

  it('404 (CP-29): another user cannot send someone else’s report', async () => {
    const report = await newReport();
    const res = await send(otro, report.id);

    expect(res.status).toBe(404);
    expect(sent).toHaveLength(0);
    expect((await statusOf(report.id)).status).toBe('generado');
  });

  it('401 without a token', async () => {
    const report = await newReport();
    expect((await request(app).post(`/api/reports/${report.id}/send`).send({ confirm: true })).status).toBe(401);
  });
});
