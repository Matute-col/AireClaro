const express = require('express');
const request = require('supertest');
const { createLimiter } = require('../src/middleware/rateLimit');

// The real /auth limit is 10 per 15 min; here a mini app with limit 2
// checks the behavior without a database.
describe('rate limiter', () => {
  it('returns 429 with a Spanish message after the limit', async () => {
    const app = express();
    app.use(createLimiter(2));
    app.get('/x', (req, res) => res.json({ ok: true }));

    expect((await request(app).get('/x')).status).toBe(200);
    expect((await request(app).get('/x')).status).toBe(200);
    const res = await request(app).get('/x');

    expect(res.status).toBe(429);
    expect(res.body.error.code).toBe('TOO_MANY_REQUESTS');
    expect(res.body.error.message).toMatch(/Demasiadas peticiones/);
  });
});
