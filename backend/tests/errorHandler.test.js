const { errorHandler } = require('../src/middleware/errorHandler');

function fakeRes() {
  const res = {};
  res.status = jest.fn(() => res);
  res.json = jest.fn(() => res);
  return res;
}

describe('errorHandler with unexpected errors', () => {
  afterEach(() => jest.restoreAllMocks());

  it('responds 500 without exposing the internal message', () => {
    jest.spyOn(console, 'error').mockImplementation(() => {});
    const res = fakeRes();
    const err = Object.assign(new Error('invalid input syntax: "juan@example.com"'), { code: '22P02' });

    errorHandler(err, { method: 'GET', path: '/api/x' }, res, () => {});

    expect(res.status).toHaveBeenCalledWith(500);
    expect(JSON.stringify(res.json.mock.calls[0][0])).not.toContain('juan@example.com');
  });

  it('by default logs only method, path and error code (no personal data)', () => {
    const spy = jest.spyOn(console, 'error').mockImplementation(() => {});
    const err = Object.assign(new Error('invalid input syntax: "juan@example.com"'), { code: '22P02' });

    errorHandler(err, { method: 'GET', path: '/api/x' }, fakeRes(), () => {});

    const logged = spy.mock.calls.flat().join(' ');
    expect(logged).toBe('[error] GET /api/x: 22P02');
    expect(logged).not.toContain('juan@example.com');
  });

  it('logs the full message only when LOG_ERROR_DETAILS=true', () => {
    const spy = jest.spyOn(console, 'error').mockImplementation(() => {});
    process.env.LOG_ERROR_DETAILS = 'true';
    try {
      jest.isolateModules(() => {
        const { errorHandler: verbose } = require('../src/middleware/errorHandler');
        const err = Object.assign(new Error('mensaje completo'), { code: '22P02' });
        verbose(err, { method: 'GET', path: '/api/x' }, fakeRes(), () => {});
      });
    } finally {
      process.env.LOG_ERROR_DETAILS = 'false';
    }
    expect(spy.mock.calls.flat().join(' ')).toBe('[error] GET /api/x: 22P02 - mensaje completo');
  });
});
