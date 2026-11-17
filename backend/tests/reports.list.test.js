const fs = require('fs');
const request = require('supertest');
const app = require('../src/app');
const files = require('./helpers/files');
const { describeDb, resetUsers, closeDb } = require('./helpers/db');
const { registerUser, authorityId, validFields, postReport } = require('./helpers/reports');

const uploadDir = process.env.UPLOAD_DIR;
const NO_ID = '00000000-0000-4000-8000-000000000000';

describe('GET /api/reports without a token', () => {
  it('401', async () => {
    expect((await request(app).get('/api/reports')).status).toBe(401);
  });
});

describeDb('GET /api/reports and evidence files (US-10, test database)', () => {
  let ana;
  let otro;
  const anaReports = []; // oldest first

  async function create(user, plate, attachments) {
    const res = await postReport(
      user.token,
      validFields({ plate, authority_id: String(await authorityId('CAR')) }),
      attachments,
    );
    expect(res.status).toBe(201);
    return res.body.report;
  }

  beforeAll(async () => {
    await resetUsers();
    fs.rmSync(uploadDir, { recursive: true, force: true });
    ana = await registerUser('ana@example.com');
    otro = await registerUser('otro@example.com');
    anaReports.push(await create(ana, 'AAA111'));
    anaReports.push(await create(ana, 'AAA222', [{ buffer: files.mp4(), name: 'solo-video.mp4' }]));
    anaReports.push(await create(ana, 'AAA333'));
    await create(otro, 'ZZZ999');
  });
  afterAll(async () => {
    await resetUsers();
    fs.rmSync(uploadDir, { recursive: true, force: true });
    await closeDb();
  });

  const get = (user, url) => request(app).get(url).set('Authorization', `Bearer ${user.token}`);

  it('lists only my reports, newest first, with total and page', async () => {
    const res = await get(ana, '/api/reports');

    expect(res.status).toBe(200);
    expect(res.body.total).toBe(3);
    expect(res.body.page).toBe(1);
    expect(res.body.items.map((r) => r.plate)).toEqual(['AAA333', 'AAA222', 'AAA111']);
    expect(res.body.items[0]).toMatchObject({
      status: 'generado',
      vehicle_type: 'bus',
      authority: { code: 'CAR' },
      media_count: 1,
    });
  });

  it('thumbnail is a photo; null when the report only has videos', async () => {
    const res = await get(ana, '/api/reports');
    const byPlate = Object.fromEntries(res.body.items.map((r) => [r.plate, r]));
    expect(byPlate.AAA333.thumbnail_media_id).toBe(anaReports[2].media[0].id);
    expect(byPlate.AAA222.thumbnail_media_id).toBeNull();
  });

  it('paginates with page and limit', async () => {
    const page1 = await get(ana, '/api/reports?limit=2&page=1');
    const page2 = await get(ana, '/api/reports?limit=2&page=2');
    expect(page1.body.items.map((r) => r.plate)).toEqual(['AAA333', 'AAA222']);
    expect(page2.body.items.map((r) => r.plate)).toEqual(['AAA111']);
    expect(page2.body.total).toBe(3);
  });

  it('filters by status', async () => {
    expect((await get(ana, '/api/reports?status=enviado')).body).toMatchObject({ total: 0, items: [] });
    expect((await get(ana, '/api/reports?status=generado')).body.total).toBe(3);
  });

  it('rejects invalid query values', async () => {
    const res = await get(ana, '/api/reports?limit=500&status=borrado');
    expect(res.status).toBe(400);
    expect(res.body.error.details.map((d) => d.field).sort()).toEqual(['limit', 'status']);
  });

  it('a new user sees an empty list', async () => {
    const nuevo = await registerUser('nuevo@example.com');
    expect((await get(nuevo, '/api/reports')).body).toEqual({ items: [], page: 1, total: 0 });
  });

  describe('GET /api/reports/:id/media/:mediaId', () => {
    it('the owner gets the file with its type', async () => {
      const { id, media } = anaReports[0];
      const res = await get(ana, `/api/reports/${id}/media/${media[0].id}`);

      expect(res.status).toBe(200);
      expect(res.headers['content-type']).toBe('image/jpeg');
      expect(res.headers['x-content-type-options']).toBe('nosniff');
      expect(Buffer.from(res.body).subarray(0, 3)).toEqual(Buffer.from([0xff, 0xd8, 0xff]));
    });

    it('another user gets 404, the same as for a file that does not exist (RB-01)', async () => {
      const { id, media } = anaReports[0];
      const res = await get(otro, `/api/reports/${id}/media/${media[0].id}`);
      const missing = await get(ana, `/api/reports/${id}/media/${NO_ID}`);

      expect(res.status).toBe(404);
      expect(missing.status).toBe(404);
      expect(res.body).toEqual(missing.body);
    });

    it('a media id of another report gets 404', async () => {
      const res = await get(ana, `/api/reports/${anaReports[1].id}/media/${anaReports[0].media[0].id}`);
      expect(res.status).toBe(404);
    });

    it('malformed ids get 404 (not 500)', async () => {
      expect((await get(ana, '/api/reports/abc/media/def')).status).toBe(404);
    });

    it('requires a token', async () => {
      const { id, media } = anaReports[0];
      expect((await request(app).get(`/api/reports/${id}/media/${media[0].id}`)).status).toBe(401);
    });
  });
});
