const request = require('supertest');
const app = require('../src/app');
const { signToken } = require('../src/utils/jwt');
const { nominatim } = require('../src/modules/geo/nominatim.client');
const { soacha, bogota } = require('./helpers/nominatim');
const { describeDb, closeDb } = require('./helpers/db');

// requireAuth only checks the token signature, so any id works here.
const token = signToken('00000000-0000-4000-8000-000000000001');
const auth = { Authorization: `Bearer ${token}` };

const asClientResult = (sample) => ({ displayName: sample.display_name, address: sample.address });

afterEach(() => jest.restoreAllMocks());

describe('GET /api/geo/reverse (no database needed)', () => {
  it('401 without a token', async () => {
    const res = await request(app).get('/api/geo/reverse?lat=4.579&lng=-74.217');
    expect(res.status).toBe(401);
  });

  it('400 with invalid coordinates', async () => {
    const res = await request(app).get('/api/geo/reverse?lat=95&lng=abc').set(auth);
    expect(res.status).toBe(400);
    expect(res.body.error.details.map((d) => d.field).sort()).toEqual(['lat', 'lng']);
  });

  it('502 with a clear message when Nominatim fails', async () => {
    jest.spyOn(nominatim, 'reverse').mockRejectedValue(new Error('timeout'));
    const res = await request(app).get('/api/geo/reverse?lat=4.579&lng=-74.217').set(auth);
    expect(res.status).toBe(502);
    expect(res.body.error.code).toBe('GEOCODER_UNAVAILABLE');
  });

  it('point without address → all null, no suggestion', async () => {
    jest.spyOn(nominatim, 'reverse').mockResolvedValue(null);
    const res = await request(app).get('/api/geo/reverse?lat=0&lng=-30').set(auth);
    expect(res.status).toBe(200);
    expect(res.body).toEqual({
      address: null,
      municipality: null,
      state: null,
      suggested_authority_id: null,
    });
  });
});

describeDb('GET /api/geo/reverse and /api/authorities (test database)', () => {
  afterAll(closeDb);

  async function authorityIdOf(code) {
    const res = await request(app).get('/api/authorities').set(auth);
    return res.body.find((a) => a.code === code).id;
  }

  it('Soacha → CAR suggested, with a short address', async () => {
    jest.spyOn(nominatim, 'reverse').mockResolvedValue(asClientResult(soacha));
    const res = await request(app).get('/api/geo/reverse?lat=4.579&lng=-74.217').set(auth);

    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({
      address: 'Carrera 3A, Ubaté, Soacha ciudad',
      municipality: 'Soacha ciudad',
      state: 'Cundinamarca',
    });
    expect(res.body.suggested_authority_id).toBe(await authorityIdOf('CAR'));
  });

  it('Bogotá → SDA suggested', async () => {
    jest.spyOn(nominatim, 'reverse').mockResolvedValue(asClientResult(bogota));
    const res = await request(app).get('/api/geo/reverse?lat=4.61&lng=-74.082').set(auth);
    expect(res.body.suggested_authority_id).toBe(await authorityIdOf('SDA'));
  });

  it('GET /api/authorities lists the 3 authorities without exposing emails', async () => {
    const res = await request(app).get('/api/authorities').set(auth);

    expect(res.status).toBe(200);
    expect(res.body.map((a) => a.code).sort()).toEqual(['CAR', 'SDA', 'SDM']);
    for (const authority of res.body) {
      expect(Object.keys(authority).sort()).toEqual(['can_email', 'code', 'id', 'name', 'portal_url']);
    }
    const canEmail = Object.fromEntries(res.body.map((a) => [a.code, a.can_email]));
    expect(canEmail).toEqual({ CAR: true, SDA: true, SDM: false });
  });

  it('GET /api/authorities requires a token', async () => {
    expect((await request(app).get('/api/authorities')).status).toBe(401);
  });
});
