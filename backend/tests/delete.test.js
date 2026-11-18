const fs = require('fs');
const path = require('path');
const request = require('supertest');
const app = require('../src/app');
const mailer = require('../src/modules/mail/mailer');
const { query } = require('../src/db/pool');
const files = require('./helpers/files');
const { describeDb, resetUsers, closeDb } = require('./helpers/db');
const { registerUser, authorityId, validFields, postReport } = require('./helpers/reports');

// US-18 · DELETE /api/reports/:id (RF-16, RB-01, CP-17).

const uploadDir = process.env.UPLOAD_DIR;
const reportsDir = path.join(uploadDir, 'reports');
const NO_ID = '00000000-0000-4000-8000-000000000000';

/** Every file stored on disk under reports/, as «reports/<id>/<file>». */
function filesOnDisk() {
  if (!fs.existsSync(reportsDir)) return [];
  return fs
    .readdirSync(reportsDir, { recursive: true })
    .map((f) => `reports/${String(f).split(path.sep).join('/')}`)
    .filter((f) => fs.statSync(path.join(uploadDir, f)).isFile());
}

describeDb('DELETE /api/reports/:id (US-18, test database)', () => {
  let ana;
  let otro;
  let sda;

  beforeAll(async () => {
    await resetUsers();
    fs.rmSync(uploadDir, { recursive: true, force: true });
    ana = await registerUser('ana@example.com');
    otro = await registerUser('otro@example.com');
    sda = String(await authorityId('SDA'));
  });
  afterEach(() => jest.restoreAllMocks());
  afterAll(async () => {
    await resetUsers();
    fs.rmSync(uploadDir, { recursive: true, force: true });
    await closeDb();
  });

  /** A report with a photo, a video and the 4 frames of the video. */
  async function fullReport(user = ana) {
    const frames = [0, 10, 20, 30].map((extra) => files.realJpeg(extra));
    const res = await postReport(
      user.token,
      validFields({ authority_id: sda }),
      [
        { buffer: files.jpeg(), name: 'placa.jpg' },
        { buffer: files.mp4(), name: 'humo.mp4' },
      ],
      { 1: frames },
    );
    expect(res.status).toBe(201);
    return res.body.report;
  }
  const del = (user, id) => request(app).delete(`/api/reports/${id}`).set('Authorization', `Bearer ${user.token}`);
  const get = (user, url) => request(app).get(url).set('Authorization', `Bearer ${user.token}`);

  it('204: the owner deletes the report, its evidence and its frames (database and disk)', async () => {
    const report = await fullReport();
    const before = await query('SELECT count(*)::int AS n FROM report_media WHERE report_id = $1', [report.id]);
    expect(before.rows[0].n).toBe(6); // photo + video + 4 frames
    expect(fs.existsSync(path.join(reportsDir, report.id))).toBe(true);

    const res = await del(ana, report.id);

    expect(res.status).toBe(204);
    const after = await query('SELECT count(*)::int AS n FROM report_media WHERE report_id = $1', [report.id]);
    expect(after.rows[0].n).toBe(0);
    expect(fs.existsSync(path.join(reportsDir, report.id))).toBe(false);
  });

  it('it disappears from the detail, the evidence, the list and the map (CP-17)', async () => {
    const report = await fullReport();
    const mediaId = report.media[0].id;
    await del(ana, report.id).expect(204);

    expect((await get(ana, `/api/reports/${report.id}`)).status).toBe(404);
    expect((await get(ana, `/api/reports/${report.id}/media/${mediaId}`)).status).toBe(404);
    expect((await get(ana, `/api/reports/${report.id}/pqrsd.pdf`)).status).toBe(404);
    expect((await get(ana, '/api/reports')).body.items.map((r) => r.id)).not.toContain(report.id);
    expect((await get(ana, '/api/map/reports')).body.map((r) => r.id)).not.toContain(report.id);
  });

  it('no orphan files: what stays on disk is exactly what the database still points to', async () => {
    const keep = await fullReport();
    const gone = await fullReport();
    await del(ana, gone.id).expect(204);

    const { rows } = await query('SELECT file_path FROM report_media');
    expect(filesOnDisk().sort()).toEqual(rows.map((r) => r.file_path).sort());
    expect(filesOnDisk().some((f) => f.includes(gone.id))).toBe(false);
    expect(filesOnDisk().filter((f) => f.includes(keep.id))).toHaveLength(6);
  });

  it('404 (RB-01): another user cannot delete it, and nothing is touched', async () => {
    const report = await fullReport();
    const filesBefore = filesOnDisk().filter((f) => f.includes(report.id));

    const res = await del(otro, report.id);

    expect(res.status).toBe(404);
    expect((await get(ana, `/api/reports/${report.id}`)).status).toBe(200);
    expect(filesOnDisk().filter((f) => f.includes(report.id))).toEqual(filesBefore);
  });

  it('404 for a report that does not exist, or was already deleted', async () => {
    expect((await del(ana, NO_ID)).status).toBe(404);
    const report = await fullReport();
    await del(ana, report.id).expect(204);
    expect((await del(ana, report.id)).status).toBe(404);
  });

  it('404 for a malformed id and 401 without a token', async () => {
    expect((await del(ana, 'no-es-un-id')).status).toBe(404);
    const report = await fullReport();
    expect((await request(app).delete(`/api/reports/${report.id}`)).status).toBe(401);
  });

  it('a report already sent can be deleted from AireClaro', async () => {
    const report = await fullReport();
    jest.spyOn(mailer, 'sendMail').mockResolvedValue({ messageId: 'simulado' });
    jest.spyOn(console, 'log').mockImplementation(() => {});
    await request(app)
      .post(`/api/reports/${report.id}/send`)
      .set('Authorization', `Bearer ${ana.token}`)
      .send({ confirm: true })
      .expect(200);

    expect((await del(ana, report.id)).status).toBe(204);
  });

  it('409 while an email of that report is being sent (its files are being attached)', async () => {
    const report = await fullReport();
    let release;
    jest.spyOn(console, 'log').mockImplementation(() => {});
    jest.spyOn(mailer, 'sendMail').mockImplementation(
      () => new Promise((resolve) => (release = () => resolve({ messageId: 'simulado' }))),
    );

    const sending = request(app)
      .post(`/api/reports/${report.id}/send`)
      .set('Authorization', `Bearer ${ana.token}`)
      .send({ confirm: true })
      .then((r) => r);
    // Wait until the email is «on its way» (the fake transport was called).
    for (let i = 0; i < 100 && !release; i++) await new Promise((r) => setTimeout(r, 50));

    const res = await del(ana, report.id);
    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('SEND_IN_PROGRESS');

    release();
    expect((await sending).status).toBe(200);
    expect(fs.existsSync(path.join(reportsDir, report.id))).toBe(true);
  });
});
