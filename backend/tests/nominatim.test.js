const { createNominatimClient } = require('../src/modules/geo/nominatim.client');
const { soacha, bogota, jsonResponse } = require('./helpers/nominatim');

// Fake clock: sleep() advances time instead of waiting.
function fakeClock() {
  let time = 0;
  return {
    now: () => time,
    sleep: async (ms) => {
      time += ms;
    },
  };
}

function setup(answers = [soacha, bogota]) {
  const clock = fakeClock();
  const calls = [];
  const fetchFn = jest.fn(async (url, options) => {
    calls.push({ url: new URL(url), options, at: clock.now() });
    return jsonResponse(answers[(calls.length - 1) % answers.length]);
  });
  const client = createNominatimClient({
    baseUrl: 'https://nominatim.example.test',
    userAgent: 'AireClaro-UNAD/1.0 (test)',
    fetchFn,
    now: clock.now,
    sleep: clock.sleep,
  });
  return { client, calls, clock, fetchFn };
}

describe('Nominatim client', () => {
  it('sends the identifiable User-Agent and the documented parameters', async () => {
    const { client, calls } = setup();
    await client.reverse(4.579, -74.217);

    const { url, options } = calls[0];
    expect(options.headers['User-Agent']).toBe('AireClaro-UNAD/1.0 (test)');
    expect(url.pathname).toBe('/reverse');
    expect(Object.fromEntries(url.searchParams)).toEqual({
      format: 'jsonv2',
      lat: '4.579',
      lon: '-74.217',
      addressdetails: '1',
      zoom: '16',
      'accept-language': 'es',
    });
  });

  it('caches by coordinates rounded to 4 decimals (no second request)', async () => {
    const { client, fetchFn } = setup();
    await client.reverse(4.57901, -74.21702);
    const again = await client.reverse(4.57904, -74.21698);

    expect(fetchFn).toHaveBeenCalledTimes(1);
    expect(again.address.subregion).toBe('Soacha');
  });

  it('cache entries expire after 24 h', async () => {
    const { client, fetchFn, clock } = setup();
    await client.reverse(4.579, -74.217);
    await clock.sleep(24 * 60 * 60 * 1000 + 1);
    await client.reverse(4.579, -74.217);
    expect(fetchFn).toHaveBeenCalledTimes(2);
  });

  it('never sends more than 1 request per second', async () => {
    const { client, calls } = setup();
    await Promise.all([
      client.reverse(4.579, -74.217),
      client.reverse(4.61, -74.082),
      client.reverse(4.7, -74.05),
    ]);

    const times = calls.map((c) => c.at);
    expect(times).toHaveLength(3);
    for (let i = 1; i < times.length; i += 1) {
      expect(times[i] - times[i - 1]).toBeGreaterThanOrEqual(1000);
    }
  });

  it('the same point asked twice at once makes a single request', async () => {
    const { client, fetchFn } = setup();
    await Promise.all([client.reverse(4.579, -74.217), client.reverse(4.579, -74.217)]);
    expect(fetchFn).toHaveBeenCalledTimes(1);
  });

  it('returns null when Nominatim cannot geocode the point', async () => {
    const { client } = setup([{ error: 'Unable to geocode' }]);
    expect(await client.reverse(0, -30)).toBeNull();
  });

  it('a failed request rejects but does not block the queue', async () => {
    const clock = fakeClock();
    const fetchFn = jest
      .fn()
      .mockResolvedValueOnce(jsonResponse({}, 503))
      .mockResolvedValueOnce(jsonResponse(soacha));
    const client = createNominatimClient({ fetchFn, now: clock.now, sleep: clock.sleep });

    await expect(client.reverse(1, 1)).rejects.toMatchObject({ code: 'GEOCODER_HTTP_ERROR' });
    await expect(client.reverse(4.579, -74.217)).resolves.toMatchObject({
      address: { subregion: 'Soacha' },
    });
  });
});
