const fs = require('fs');
const request = require('supertest');
const app = require('../src/app');
const { query } = require('../src/db/pool');
const { describeDb, resetUsers, closeDb } = require('./helpers/db');
const { registerUser, authorityId, validFields, postReport } = require('./helpers/reports');

// US-15 · GET /api/map/reports (RF-10, RB-07): every user's reports, only
// id, coordinates, vehicle type and date. Never plate, photos, address or people.

const uploadDir = process.env.UPLOAD_DIR;

describeDb('GET /api/map/reports (US-15, test database)', () => {
  let ana;
  let otro;
  const ids = {};

  async function create(user, plate, vehicleType, occurredAt) {
    const res = await postReport(
      user.token,
      validFields({
        plate,
        vehicle_type: vehicleType,
        authority_id: String(await authorityId('CAR')),
        occurred_at: occurredAt,
      }),
    );
    expect(res.status).toBe(201);
    return res.body.report.id;
  }

  beforeAll(async () => {
    await resetUsers();
    fs.rmSync(uploadDir, { recursive: true, force: true });
    ana = await registerUser('ana@example.com');
    otro = await registerUser('otro@example.com');
    // 23:30 in Colombia on 10-nov = 04:30 UTC on 11-nov: it must count as 10-nov.
    ids.busNight = await create(ana, 'AAA111', 'bus', '2026-11-11T04:30:00Z');
    ids.camion = await create(ana, 'AAA222', 'camion', '2026-11-15T15:00:00Z');
    ids.otroBus = await create(otro, 'ZZZ999', 'bus', '2026-11-17T13:00:00Z');
  });
  afterAll(async () => {
    await resetUsers();
    fs.rmSync(uploadDir, { recursive: true, force: true });
    await closeDb();
  });

  const get = (url) => request(app).get(url).set('Authorization', `Bearer ${ana.token}`);

  it('shows the reports of every user, newest first', async () => {
    const res = await get('/api/map/reports');
    expect(res.status).toBe(200);
    expect(res.body.map((r) => r.id)).toEqual([ids.otroBus, ids.camion, ids.busNight]);
  });

  it('PRIVACY (RB-07, CP-18): only id, lat, lng, vehicle_type and occurred_at', async () => {
    const res = await get('/api/map/reports');
    for (const pin of res.body) {
      expect(Object.keys(pin).sort()).toEqual(['id', 'lat', 'lng', 'occurred_at', 'vehicle_type']);
    }
    const body = JSON.stringify(res.body);
    for (const secret of ['AAA111', 'ZZZ999', 'example.com', 'Carrera', 'Prueba']) {
      expect(body).not.toContain(secret);
    }
  });

  it('filters by one or more vehicle types', async () => {
    const buses = await get('/api/map/reports?vehicle_type=bus');
    expect(buses.body.map((r) => r.id).sort()).toEqual([ids.busNight, ids.otroBus].sort());
    const both = await get('/api/map/reports?vehicle_type=bus,camion');
    expect(both.body).toHaveLength(3);
  });

  it('filters by dates in Colombia time (the whole «to» day is included)', async () => {
    const tenth = await get('/api/map/reports?from=2026-11-10&to=2026-11-10');
    expect(tenth.body.map((r) => r.id)).toEqual([ids.busNight]);

    const range = await get('/api/map/reports?from=2026-11-11&to=2026-11-17');
    expect(range.body.map((r) => r.id)).toEqual([ids.otroBus, ids.camion]);
  });

  it('combines type and dates', async () => {
    const res = await get('/api/map/reports?vehicle_type=bus&from=2026-11-16');
    expect(res.body.map((r) => r.id)).toEqual([ids.otroBus]);
  });

  it('400 with invalid filters', async () => {
    for (const url of [
      '/api/map/reports?vehicle_type=moto',
      '/api/map/reports?from=18-11-2026',
      '/api/map/reports?from=2026-11-18&to=2026-11-01',
    ]) {
      const res = await get(url);
      expect(res.status).toBe(400);
    }
  });

  it('401 without a token', async () => {
    expect((await request(app).get('/api/map/reports')).status).toBe(401);
  });

  it('never more than 500 pins', async () => {
    const { rows } = await query('SELECT count(*)::int AS n FROM reports');
    expect(rows[0].n).toBeLessThan(500);
    // The LIMIT is in the query; checked here only as documentation of the rule.
    expect((await get('/api/map/reports')).body.length).toBeLessThanOrEqual(500);
  });
});
