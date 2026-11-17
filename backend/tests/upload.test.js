const fs = require('fs');
const path = require('path');
const express = require('express');
const request = require('supertest');
const files = require('./helpers/files');

// Mini app with only the upload middleware (POST /reports arrives in US-09).
function buildApp() {
  const { receiveEvidence, checkEvidence } = require('../src/middleware/upload');
  const { errorHandler } = require('../src/middleware/errorHandler');
  const app = express();
  app.post('/upload', receiveEvidence, checkEvidence, (req, res) => {
    res.json({ files: req.files.map((f) => ({ ...f.evidence, name: f.filename })) });
  });
  app.use(errorHandler);
  return app;
}

const tmpDir = path.join(process.env.UPLOAD_DIR, 'tmp');
const tmpFiles = () => (fs.existsSync(tmpDir) ? fs.readdirSync(tmpDir) : []);

beforeEach(() => fs.rmSync(process.env.UPLOAD_DIR, { recursive: true, force: true }));
afterAll(() => fs.rmSync(process.env.UPLOAD_DIR, { recursive: true, force: true }));

describe('evidence upload', () => {
  it('accepts up to 3 valid files and ignores the original name', async () => {
    const res = await request(buildApp())
      .post('/upload')
      .attach('files', files.jpeg(), { filename: 'placa.jpg', contentType: 'image/jpeg' })
      .attach('files', files.mp4(), { filename: 'humo.mp4', contentType: 'video/mp4' })
      .attach('files', files.png(), { filename: 'otra.png', contentType: 'image/png' });

    expect(res.status).toBe(200);
    expect(res.body.files.map((f) => f.kind)).toEqual(['photo', 'video', 'photo']);
    for (const f of res.body.files) {
      expect(f.name).toMatch(/^[0-9a-f-]{36}$/);
    }
  });

  it('rejects a file whose content is not an image or video, and deletes the uploads', async () => {
    const res = await request(buildApp())
      .post('/upload')
      .attach('files', files.jpeg(), { filename: 'ok.jpg', contentType: 'image/jpeg' })
      .attach('files', files.text(), { filename: 'falsa.jpg', contentType: 'image/jpeg' });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('INVALID_FILE_TYPE');
    expect(tmpFiles()).toEqual([]);
  });

  it('rejects HEIC photos', async () => {
    const res = await request(buildApp())
      .post('/upload')
      .attach('files', files.heic(), { filename: 'foto.heic', contentType: 'image/heic' });
    expect(res.body.error.code).toBe('INVALID_FILE_TYPE');
  });

  it('rejects more than 3 files', async () => {
    const res = await request(buildApp())
      .post('/upload')
      .attach('files', files.jpeg(), 'a.jpg')
      .attach('files', files.jpeg(), 'b.jpg')
      .attach('files', files.jpeg(), 'c.jpg')
      .attach('files', files.jpeg(), 'd.jpg');

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('TOO_MANY_FILES');
    expect(tmpFiles()).toEqual([]);
  });

  it('requires at least one file', async () => {
    const res = await request(buildApp()).post('/upload').field('plate', 'ABC123');
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('EVIDENCE_REQUIRED');
  });

  describe('size limits (tiny limits for the test)', () => {
    let app;
    beforeAll(() => {
      process.env.MAX_PHOTO_MB = '0.00005'; // ~52 bytes
      process.env.MAX_VIDEO_MB = '0.0001'; // ~104 bytes
      jest.isolateModules(() => {
        app = buildApp();
      });
    });
    afterAll(() => {
      delete process.env.MAX_PHOTO_MB;
      delete process.env.MAX_VIDEO_MB;
    });

    it('rejects a photo above MAX_PHOTO_MB with 413', async () => {
      const res = await request(app).post('/upload').attach('files', files.jpeg(), 'grande.jpg');
      expect(res.status).toBe(413);
      expect(res.body.error.message).toContain('foto');
      expect(tmpFiles()).toEqual([]);
    });

    it('rejects a video above MAX_VIDEO_MB with 413', async () => {
      const big = Buffer.concat([files.mp4(), Buffer.alloc(200)]);
      const res = await request(app).post('/upload').attach('files', big, 'grande.mp4');
      expect(res.status).toBe(413);
      expect(res.body.error.message).toContain('video');
    });
  });
});
