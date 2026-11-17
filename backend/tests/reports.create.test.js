const fs = require('fs');
const path = require('path');
const request = require('supertest');
const app = require('../src/app');
const storage = require('../src/utils/storage');
const { nominatim } = require('../src/modules/geo/nominatim.client');
const { query } = require('../src/db/pool');
const files = require('./helpers/files');
const { soacha } = require('./helpers/nominatim');
const { describeDb, resetUsers, closeDb } = require('./helpers/db');

// Uploads go to the temporary folder set in tests/setup.js, never backend/uploads/.
const uploadDir = process.env.UPLOAD_DIR;
const tmpDir = path.join(uploadDir, 'tmp');
const tmpFiles = () => (fs.existsSync(tmpDir) ? fs.readdirSync(tmpDir) : []);

const MB = 1024 * 1024;

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

describe('POST /api/reports without a token', () => {
  it('401 and nothing is stored', async () => {
    const res = await request(app).post('/api/reports').field('plate', 'ABC123');
    expect(res.status).toBe(401);
  });
});

describeDb('POST /api/reports (US-09, test database)', () => {
  let user;
  let car;

  beforeAll(async () => {
    await resetUsers();
    fs.rmSync(uploadDir, { recursive: true, force: true });
    user = await registerUser('luis@example.com');
    car = await authorityId('CAR');
  });
  afterEach(() => jest.restoreAllMocks());
  afterAll(async () => {
    await resetUsers();
    fs.rmSync(uploadDir, { recursive: true, force: true });
    await closeDb();
  });

  it('201: creates the report «generado» with its files, in the report folder', async () => {
    const res = await postReport(user.token, validFields({ authority_id: String(car) }), [
      { buffer: files.jpeg(), name: 'placa.jpg' },
      { buffer: files.mp4(), name: 'humo.mp4' },
    ]);

    expect(res.status).toBe(201);
    const { report } = res.body;
    expect(report).toMatchObject({
      vehicle_type: 'bus',
      plate: 'ABC123',
      smoke_color: 'negro',
      status: 'generado',
      lat: 4.579,
      lng: -74.217,
      authority: { id: car, code: 'CAR' },
    });
    expect(report.media.map((m) => m.kind)).toEqual(['photo', 'video']);

    // Stored with server-generated names under reports/<id>/, owned by the token user.
    const { rows } = await query(
      `SELECT r.user_id, m.file_path FROM reports r JOIN report_media m ON m.report_id = r.id
        WHERE r.id = $1`,
      [report.id],
    );
    expect(rows).toHaveLength(2);
    for (const row of rows) {
      expect(row.user_id).toBe(user.id);
      expect(row.file_path).toMatch(new RegExp(`^reports/${report.id}/[0-9a-f-]{36}\\.(jpg|mp4)$`));
      expect(fs.existsSync(storage.resolveStored(row.file_path))).toBe(true);
    }
    expect(tmpFiles()).toEqual([]);
  });

  it('ignores user_id and status sent in the body', async () => {
    const other = await registerUser('otro@example.com');
    const res = await postReport(
      user.token,
      validFields({ authority_id: String(car), user_id: other.id, status: 'enviado' }),
    );

    expect(res.status).toBe(201);
    expect(res.body.report.status).toBe('generado');
    const { rows } = await query('SELECT user_id FROM reports WHERE id = $1', [res.body.report.id]);
    expect(rows[0].user_id).toBe(user.id);
  });

  it('without authority_id the server applies the rule (Soacha → CAR)', async () => {
    jest
      .spyOn(nominatim, 'reverse')
      .mockResolvedValue({ displayName: soacha.display_name, address: soacha.address });
    const res = await postReport(user.token, validFields());

    expect(res.status).toBe(201);
    expect(res.body.report.authority.code).toBe('CAR');
  });

  it('without authority_id and no suggestion → 400 «Elige la autoridad»', async () => {
    jest.spyOn(nominatim, 'reverse').mockResolvedValue(null);
    const res = await postReport(user.token, validFields());

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('AUTHORITY_REQUIRED');
    expect(tmpFiles()).toEqual([]);
  });

  it('rejects an authority that does not exist', async () => {
    const res = await postReport(user.token, validFields({ authority_id: '999' }));
    expect(res.status).toBe(400);
    expect(res.body.error.details[0].field).toBe('authority_id');
  });

  it('rejects a fake file type (text named .jpg)', async () => {
    const res = await postReport(user.token, validFields({ authority_id: String(car) }), [
      { buffer: files.text(), name: 'falsa.jpg' },
    ]);
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('INVALID_FILE_TYPE');
    expect(tmpFiles()).toEqual([]);
  });

  it('rejects more than 3 files', async () => {
    const four = Array.from({ length: 4 }, (_, i) => ({ buffer: files.jpeg(), name: `f${i}.jpg` }));
    const res = await postReport(user.token, validFields({ authority_id: String(car) }), four);
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('TOO_MANY_FILES');
    expect(tmpFiles()).toEqual([]);
  });

  it('rejects a photo of more than 8 MB with 413', async () => {
    const big = Buffer.concat([files.jpeg(), Buffer.alloc(8 * MB)]);
    const res = await postReport(user.token, validFields({ authority_id: String(car) }), [
      { buffer: big, name: 'grande.jpg' },
    ]);
    expect(res.status).toBe(413);
    expect(res.body.error.code).toBe('FILE_TOO_LARGE');
    expect(tmpFiles()).toEqual([]);
  });

  it('requires at least one file', async () => {
    const res = await postReport(user.token, validFields({ authority_id: String(car) }), []);
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('EVIDENCE_REQUIRED');
  });

  it('rejects an invalid plate and deletes the uploads', async () => {
    const res = await postReport(user.token, validFields({ authority_id: String(car), plate: 'AB123' }));
    expect(res.status).toBe(400);
    expect(res.body.error.details).toContainEqual({
      field: 'plate',
      message: 'La placa debe tener el formato ABC123 o ABC12D.',
    });
    expect(tmpFiles()).toEqual([]);
  });

  it('rejects a date in the future', async () => {
    const tomorrow = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
    const res = await postReport(user.token, validFields({ authority_id: String(car), occurred_at: tomorrow }));
    expect(res.status).toBe(400);
    expect(res.body.error.details).toContainEqual({
      field: 'occurred_at',
      message: 'La fecha y hora del reporte no pueden estar en el futuro.',
    });
  });

  it('rejects missing coordinates and requester data', async () => {
    const res = await postReport(
      user.token,
      validFields({ authority_id: String(car), lat: '', requester_email: 'x' }),
    );
    expect(res.status).toBe(400);
    const fields = res.body.error.details.map((d) => d.field);
    expect(fields).toEqual(expect.arrayContaining(['lat', 'requester_email']));
  });

  it('if saving a file fails, nothing is stored (transaction rolled back)', async () => {
    const before = (await query('SELECT count(*)::int AS n FROM reports')).rows[0].n;
    const realMove = storage.moveToReport;
    let calls = 0;
    jest.spyOn(storage, 'moveToReport').mockImplementation(async (...args) => {
      calls += 1;
      if (calls === 2) throw new Error('disk full');
      return realMove(...args);
    });
    jest.spyOn(console, 'error').mockImplementation(() => {});

    const res = await postReport(user.token, validFields({ authority_id: String(car) }), [
      { buffer: files.jpeg(), name: 'a.jpg' },
      { buffer: files.png(), name: 'b.png' },
    ]);

    expect(res.status).toBe(500);
    const after = (await query('SELECT count(*)::int AS n FROM reports')).rows[0].n;
    expect(after).toBe(before);
    const reportsDir = path.join(uploadDir, 'reports');
    const stored = fs.existsSync(reportsDir)
      ? fs.readdirSync(reportsDir, { recursive: true }).filter((f) => /\.(jpg|png|mp4)$/.test(f))
      : [];
    const { rows } = await query('SELECT file_path FROM report_media');
    expect(stored.length).toBe(rows.length); // no orphan files on disk
    expect(tmpFiles()).toEqual([]);
  });
});
