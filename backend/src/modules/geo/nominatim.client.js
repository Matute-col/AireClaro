const env = require('../../config/env');

// Reverse geocoding with Nominatim (OpenStreetMap), following its usage policy
// (CLAUDE.md, RNF-09):
// - at most 1 request per second for the whole server (requests wait in a queue);
// - identifiable User-Agent taken from NOMINATIM_USER_AGENT;
// - results cached in memory for 24 h, key = coordinates rounded to 4 decimals (~11 m);
// - only called from our API, never from the app, and never for autocomplete.

const ONE_DAY_MS = 24 * 60 * 60 * 1000;

/**
 * @param {object} options dependencies, replaceable in tests
 * @returns {{ reverse(lat: number, lng: number): Promise<object|null>, cacheSize(): number }}
 */
function createNominatimClient({
  baseUrl = env.NOMINATIM_BASE_URL,
  userAgent = env.NOMINATIM_USER_AGENT,
  fetchFn = (...args) => fetch(...args),
  now = () => Date.now(),
  sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms)),
  minIntervalMs = 1000,
  cacheTtlMs = ONE_DAY_MS,
  maxCacheEntries = 1000,
  timeoutMs = 5000,
} = {}) {
  const cache = new Map(); // key -> { value, expiresAt }
  const inFlight = new Map(); // key -> Promise (same point asked twice at once)
  let queue = Promise.resolve();
  let lastRequestAt = -Infinity;

  /** Runs fn after waiting so that two requests are at least minIntervalMs apart. */
  function schedule(fn) {
    const run = queue.then(async () => {
      const wait = lastRequestAt + minIntervalMs - now();
      if (wait > 0) await sleep(wait);
      lastRequestAt = now();
      return fn();
    });
    queue = run.catch(() => {}); // a failed request must not block the next ones
    return run;
  }

  async function request(lat, lng) {
    const url = new URL('/reverse', baseUrl);
    url.search = new URLSearchParams({
      format: 'jsonv2',
      lat: String(lat),
      lon: String(lng),
      addressdetails: '1',
      zoom: '16',
      'accept-language': 'es',
    }).toString();

    const response = await fetchFn(url, {
      headers: { 'User-Agent': userAgent, Accept: 'application/json' },
      signal: AbortSignal.timeout(timeoutMs),
    });
    if (!response.ok) {
      const error = new Error(`Nominatim respondió ${response.status}`);
      error.code = 'GEOCODER_HTTP_ERROR';
      throw error;
    }
    const body = await response.json();
    // Nominatim answers {"error": "Unable to geocode"} for points with no address (e.g. the sea).
    if (!body || body.error) return null;
    return { displayName: body.display_name || null, address: body.address || {} };
  }

  async function reverse(lat, lng) {
    const key = `${lat.toFixed(4)},${lng.toFixed(4)}`;

    const cached = cache.get(key);
    if (cached && cached.expiresAt > now()) return cached.value;
    if (inFlight.has(key)) return inFlight.get(key);

    const promise = schedule(() => request(Number(lat.toFixed(4)), Number(lng.toFixed(4))))
      .then((value) => {
        if (cache.size >= maxCacheEntries) cache.delete(cache.keys().next().value); // oldest first
        cache.set(key, { value, expiresAt: now() + cacheTtlMs });
        return value;
      })
      .finally(() => inFlight.delete(key));
    inFlight.set(key, promise);
    return promise;
  }

  return { reverse, cacheSize: () => cache.size };
}

// One shared client for the whole server, so the 1 request/second limit is global.
const nominatim = createNominatimClient();

module.exports = { createNominatimClient, nominatim };
