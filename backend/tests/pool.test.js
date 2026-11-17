const { logIdleClientError } = require('../src/db/pool');

describe('pool idle-client error log', () => {
  afterEach(() => jest.restoreAllMocks());

  it('by default logs only the error code', () => {
    const spy = jest.spyOn(console, 'error').mockImplementation(() => {});
    const err = Object.assign(new Error('connect failed for host db.example.test'), { code: 'ECONNRESET' });

    logIdleClientError(err);

    const logged = spy.mock.calls.flat().join(' ');
    expect(logged).toBe('[db] error en conexión inactiva: ECONNRESET');
    expect(logged).not.toContain('db.example.test');
  });

  it('logs the full message only when LOG_ERROR_DETAILS=true', () => {
    const spy = jest.spyOn(console, 'error').mockImplementation(() => {});
    process.env.LOG_ERROR_DETAILS = 'true';
    try {
      jest.isolateModules(() => {
        const { logIdleClientError: verbose } = require('../src/db/pool');
        verbose(Object.assign(new Error('mensaje completo'), { code: 'ECONNRESET' }));
      });
    } finally {
      process.env.LOG_ERROR_DETAILS = 'false';
    }
    expect(spy.mock.calls.flat().join(' ')).toBe(
      '[db] error en conexión inactiva: ECONNRESET - mensaje completo',
    );
  });
});
