const fs = require('fs');
const path = require('path');
const request = require('supertest');
const app = require('../src/app');
const { query } = require('../src/db/pool');
const files = require('./helpers/files');
const { pdfText } = require('./helpers/pdfText');
const { describeDb, resetUsers, closeDb } = require('./helpers/db');
const { registerUser, authorityId, validFields, postReport } = require('./helpers/reports');

// US-23 · Video frames. Frames are sent in frames_v<N> (N = position of the video in
// `files`), at most 4 per video, real JPEG ≤ 300 KB, stored as derived evidence.

const uploadDir = process.env.UPLOAD_DIR;
const tmpDir = path.join(uploadDir, 'tmp');
const tmpFiles = () => (fs.existsSync(tmpDir) ? fs.readdirSync(tmpDir) : []);

/** Four real JPEG frames with different sizes, so their order can be checked. */
const fourFrames = () => [0, 10, 20, 30].map((extra) => files.realJpeg(extra));

function binary(res, callback) {
  const chunks = [];
  res.on('data', (chunk) => chunks.push(chunk));
  res.on('end', () => callback(null, Buffer.concat(chunks)));
}

describeDb('US-23 · video frames (test database)', () => {
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
  afterAll(async () => {
    await resetUsers();
    fs.rmSync(uploadDir, { recursive: true, force: true });
    await closeDb();
  });

  const fields = () => validFields({ authority_id: sda });
  const video = { buffer: files.mp4(), name: 'humo.mp4' };
  const photo = { buffer: files.jpeg(), name: 'placa.jpg' };
  const get = (user, url) => request(app).get(url).set('Authorization', `Bearer ${user.token}`);

  describe('creation and order', () => {
    let report;

    beforeAll(async () => {
      const res = await postReport(ana.token, fields(), [photo, video], { 1: fourFrames() });
      expect(res.status).toBe(201);
      report = res.body.report;
    });

    it('stores 4 frames linked to the video, positions 1..4 in the order sent', async () => {
      const videoId = report.media.find((m) => m.kind === 'video').id;
      const { rows } = await query(
        `SELECT kind, source_media_id, position, size_bytes, mime_type FROM report_media
          WHERE report_id = $1 AND kind = 'frame' ORDER BY position`,
        [report.id],
      );
      expect(rows.map((r) => r.position)).toEqual([1, 2, 3, 4]);
      expect(rows.every((r) => r.source_media_id === videoId && r.mime_type === 'image/jpeg')).toBe(true);
      // Sizes grow by 10 bytes in the order they were sent: the order is kept.
      expect(rows.map((r) => r.size_bytes - rows[0].size_bytes)).toEqual([0, 10, 20, 30]);
      expect(tmpFiles()).toEqual([]);
    });

    it('frames do not count as evidence: the list still says 2 files', async () => {
      const list = await get(ana, '/api/reports');
      expect(list.body.items.find((r) => r.id === report.id).media_count).toBe(2);
    });

    it('the detail shows the frames inside their video, in order', async () => {
      const res = await get(ana, `/api/reports/${report.id}`);
      const videoItem = res.body.media.find((m) => m.kind === 'video');
      const photoItem = res.body.media.find((m) => m.kind === 'photo');

      expect(res.body.media).toHaveLength(2);
      expect(videoItem.frames.map((f) => f.position)).toEqual([1, 2, 3, 4]);
      expect(photoItem.frames).toEqual([]);
    });

    it('a frame is served only to the owner (404 for another user)', async () => {
      const res = await get(ana, `/api/reports/${report.id}`);
      const frameId = res.body.media.find((m) => m.kind === 'video').frames[0].id;

      const own = await get(ana, `/api/reports/${report.id}/media/${frameId}`).buffer(true).parse(binary);
      expect(own.status).toBe(200);
      expect(own.headers['content-type']).toBe('image/jpeg');
      expect((await get(otro, `/api/reports/${report.id}/media/${frameId}`)).status).toBe(404);
    });

    it('PDF lists «Fotogramas del video 1 (4)», says they were extracted and draws them', async () => {
      const res = await get(ana, `/api/reports/${report.id}/pqrsd.pdf`).buffer(true).parse(binary);
      const text = pdfText(res.body);

      expect(text).toContain('Fotogramas del video 1 (4)');
      expect(text).toContain('extraídos automáticamente del video al 10 %, 35 %, 65 % y 90 % de su duración');
      expect(text).toContain('no son fotografías independientes');
      const images = res.body.toString('latin1').match(/\/Subtype \/Image/g) || [];
      expect(images.length).toBeGreaterThanOrEqual(4);
    });
  });

  it('3 evidence files + 4 frames are accepted (frames do not count toward the 3)', async () => {
    const res = await postReport(ana.token, fields(), [photo, photo, video], { 2: fourFrames() });
    expect(res.status).toBe(201);
    expect(res.body.report.frames).toHaveLength(4);
  });

  it('a video without frames (extraction failed on the phone) is still accepted', async () => {
    const res = await postReport(ana.token, fields(), [video]);
    expect(res.status).toBe(201);
    expect(res.body.report.frames).toEqual([]);

    const pdf = await get(ana, `/api/reports/${res.body.report.id}/pqrsd.pdf`).buffer(true).parse(binary);
    expect(pdfText(pdf.body)).not.toContain('Fotogramas');
  });

  it('more than 4 frames for a video → 400 TOO_MANY_FRAMES, nothing stored', async () => {
    const five = [...fourFrames(), files.realJpeg(40)];
    const res = await postReport(ana.token, fields(), [video], { 0: five });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('TOO_MANY_FRAMES');
    expect(tmpFiles()).toEqual([]);
  });

  it('a frame that is not a real JPEG → 400 (PNG or a renamed text)', async () => {
    for (const bad of [files.realPng(), files.text()]) {
      const res = await postReport(ana.token, fields(), [video], { 0: [bad] });
      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe('INVALID_FRAME_TYPE');
    }
    expect(tmpFiles()).toEqual([]);
  });

  it('a frame of more than 300 KB → 413 FRAME_TOO_LARGE', async () => {
    const big = files.realJpeg(300 * 1024);
    const res = await postReport(ana.token, fields(), [video], { 0: [big] });
    expect(res.status).toBe(413);
    expect(res.body.error.code).toBe('FRAME_TOO_LARGE');
    expect(tmpFiles()).toEqual([]);
  });

  it('frames must belong to a video of the report', async () => {
    const forPhoto = await postReport(ana.token, fields(), [photo, video], { 0: fourFrames() });
    expect(forPhoto.status).toBe(400);
    expect(forPhoto.body.error.code).toBe('INVALID_FRAME_SOURCE');

    const forMissing = await postReport(ana.token, fields(), [video], { 1: fourFrames() });
    expect(forMissing.status).toBe(400);
    expect(forMissing.body.error.code).toBe('INVALID_FRAME_SOURCE');
    expect(tmpFiles()).toEqual([]);
  });

  it('the database refuses a frame without its video or with a position outside 1..4', async () => {
    const { rows } = await query(`SELECT id, report_id FROM report_media WHERE kind = 'video' LIMIT 1`);
    const { id: videoId, report_id: reportId } = rows[0];
    const insert = (source, position) =>
      query(
        `INSERT INTO report_media (report_id, kind, file_path, mime_type, size_bytes, source_media_id, position)
         VALUES ($1, 'frame', 'x.jpg', 'image/jpeg', 1, $2, $3)`,
        [reportId, source, position],
      );
    await expect(insert(null, 1)).rejects.toMatchObject({ code: '23514' });
    await expect(insert(videoId, 5)).rejects.toMatchObject({ code: '23514' });
  });
});
