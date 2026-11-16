const request = require('supertest');
const app = require('../src/app');

describe('GET /api/health', () => {
  it('responds 200 with status ok', async () => {
    const res = await request(app).get('/api/health');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: 'ok' });
  });

  it('sets security headers (helmet)', async () => {
    const res = await request(app).get('/api/health');
    expect(res.headers['x-content-type-options']).toBe('nosniff');
    expect(res.headers['x-powered-by']).toBeUndefined();
  });

  it('sends rate limit headers', async () => {
    const res = await request(app).get('/api/health');
    expect(res.headers['ratelimit-policy']).toBeDefined();
  });
});

describe('error format', () => {
  it('returns 404 with the standard error body', async () => {
    const res = await request(app).get('/api/does-not-exist');
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('NOT_FOUND');
    expect(typeof res.body.error.message).toBe('string');
  });

  it('returns 400 for malformed JSON', async () => {
    const res = await request(app)
      .post('/api/health')
      .set('Content-Type', 'application/json')
      .send('{"bad": ');
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('INVALID_JSON');
  });
});
