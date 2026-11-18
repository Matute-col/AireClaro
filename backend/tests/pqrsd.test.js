const fs = require('fs');
const request = require('supertest');
const app = require('../src/app');
const files = require('./helpers/files');
const { describeDb, resetUsers, closeDb } = require('./helpers/db');
const { registerUser, authorityId, validFields, postReport } = require('./helpers/reports');
const { pdfText } = require('./helpers/pdfText');

const uploadDir = process.env.UPLOAD_DIR;

/** Supertest returns binary bodies as Buffer with this parser. */
function binary(res, callback) {
  const chunks = [];
  res.on('data', (chunk) => chunks.push(chunk));
  res.on('end', () => callback(null, Buffer.concat(chunks)));
}

describeDb('GET /api/reports/:id/pqrsd and .pdf (US-12, test database)', () => {
  let jose;
  let otro;
  let report;
  let videoOnly;

  beforeAll(async () => {
    await resetUsers();
    fs.rmSync(uploadDir, { recursive: true, force: true });
    jose = await registerUser('jose@example.com');
    otro = await registerUser('otro@example.com');
    const sda = String(await authorityId('SDA'));

    // Spanish characters everywhere: tildes, ñ, ü, ¿?, ¡!, «» and º.
    const res = await postReport(
      jose.token,
      validFields({
        authority_id: sda,
        address: 'Calle 13, Barrio Güemes, Bogotá ciudad',
        description: '¿Humo? ¡Sí! Muy denso en la vía a Soacha; año 2026, nº 1',
        requester_name: 'José Peña Núñez',
        requester_email: 'jose@example.com',
      }),
      [
        { buffer: files.realPng(), name: 'foto.png' },
        { buffer: files.mp4(), name: 'humo.mp4' },
      ],
    );
    report = res.body.report;

    const video = await postReport(jose.token, validFields({ authority_id: sda }), [
      { buffer: files.mp4(), name: 'solo.mp4' },
    ]);
    videoOnly = video.body.report;
  });
  afterAll(async () => {
    await resetUsers();
    fs.rmSync(uploadDir, { recursive: true, force: true });
    await closeDb();
  });

  const get = (user, url) => request(app).get(url).set('Authorization', `Bearer ${user.token}`);

  it('text for the preview, with the authority and the mail mode', async () => {
    const res = await get(jose, `/api/reports/${report.id}/pqrsd`);

    expect(res.status).toBe(200);
    expect(res.body.mail_mode).toBe('test');
    expect(res.body.plate).toBe('ABC123');
    expect(res.body.status).toBe('generado');
    expect(res.body.authority).toMatchObject({ code: 'SDA', can_email: true });
    expect(res.body.authority).not.toHaveProperty('email');
    expect(res.body.text).toContain('Secretaría Distrital de Ambiente de Bogotá');
    expect(res.body.text).toContain(
      'ANEXOS\n1. Fotografía 1 (PNG, 1 KB) – Disponible a solicitud del peticionario.\n' +
        '2. Video 1 (MP4, 1 KB) – Disponible a solicitud del peticionario.',
    );
  });

  it('PDF: valid file, inline, with a server-generated name', async () => {
    const res = await get(jose, `/api/reports/${report.id}/pqrsd.pdf`).buffer(true).parse(binary);

    expect(res.status).toBe(200);
    expect(res.headers['content-type']).toBe('application/pdf');
    expect(res.headers['content-disposition']).toMatch(/^inline; filename="solicitud-[0-9A-F]{8}\.pdf"$/);
    expect(res.body.subarray(0, 5).toString()).toBe('%PDF-');
  });

  it('PDF keeps tildes, ñ, ü and Spanish signs (read back from the file)', async () => {
    const res = await get(jose, `/api/reports/${report.id}/pqrsd.pdf`).buffer(true).parse(binary);
    const text = pdfText(res.body);

    for (const expected of [
      'José Peña Núñez',
      'Barrio Güemes, Bogotá ciudad',
      '¿Humo? ¡Sí! Muy denso en la vía a Soacha; año 2026, nº 1',
      'Secretaría Distrital de Ambiente de Bogotá',
      'PETICIÓN',
      'emisión anómala',
      'Reporte n.º',
    ]) {
      expect(text).toContain(expected);
    }
  });

  it('PDF contains the art. 16 sections and the scope note', async () => {
    const res = await get(jose, `/api/reports/${report.id}/pqrsd.pdf`).buffer(true).parse(binary);
    const text = pdfText(res.body);

    for (const section of ['Asunto:', 'HECHOS', 'PETICIÓN', 'ANEXOS', 'NOTIFICACIONES', 'Atentamente,']) {
      expect(text).toContain(section);
    }
    expect(text).toContain('no constituyen una medición');
    expect(text.toLowerCase()).not.toContain('incumple');
  });

  it('the first photo is embedded in the PDF', async () => {
    const res = await get(jose, `/api/reports/${report.id}/pqrsd.pdf`).buffer(true).parse(binary);
    expect(res.body.toString('latin1')).toContain('/Subtype /Image');
  });

  it('a report with only a video also gets its PDF (no image)', async () => {
    const res = await get(jose, `/api/reports/${videoOnly.id}/pqrsd.pdf`).buffer(true).parse(binary);
    expect(res.status).toBe(200);
    expect(res.body.toString('latin1')).not.toContain('/Subtype /Image');
    expect(pdfText(res.body)).toContain('Video 1 (MP4');
  });

  it('PROPERTY (RB-01): another user gets 404 for the text and the PDF', async () => {
    expect((await get(otro, `/api/reports/${report.id}/pqrsd`)).status).toBe(404);
    expect((await get(otro, `/api/reports/${report.id}/pqrsd.pdf`)).status).toBe(404);
  });

  it('requires a token', async () => {
    expect((await request(app).get(`/api/reports/${report.id}/pqrsd.pdf`)).status).toBe(401);
  });
});
