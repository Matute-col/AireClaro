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

  it('logs only the error code outside development (no personal data)', () => {
    const spy = jest.spyOn(console, 'error').mockImplementation(() => {});
    const err = Object.assign(new Error('invalid input syntax: "juan@example.com"'), { code: '22P02' });

    errorHandler(err, { method: 'GET', path: '/api/x' }, fakeRes(), () => {});

    const logged = spy.mock.calls.flat().join(' ');
    expect(logged).toContain('22P02');
    expect(logged).not.toContain('juan@example.com');
  });
});
