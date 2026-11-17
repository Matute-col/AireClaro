const AppError = require('../../utils/AppError');
const authoritiesService = require('../authorities/authorities.service');
const { suggestAuthorityCode } = require('./authorityRule');
const { nominatim } = require('./nominatim.client');

const NO_GEOCODER_MESSAGE =
  'No pudimos obtener la dirección en este momento. Puedes continuar y elegir la autoridad.';

/** Short address for the screen and the PDF: «Carrera 7, La Candelaria, Bogotá». */
function shortAddress(result) {
  const a = result.address;
  const street = [a.road, a.house_number].filter(Boolean).join(' ');
  const area = a.neighbourhood || a.suburb || a.quarter;
  const city = a.city || a.town || a.village || a.municipality;
  const parts = [street, area, city].filter(Boolean);
  const unique = parts.filter((part, i) => parts.indexOf(part) === i);
  return unique.length > 0 ? unique.join(', ') : result.displayName;
}

/**
 * GET /geo/reverse: address and suggested authority for a point.
 * @returns {{address, municipality, state, suggested_authority_id}}
 */
async function reverse(lat, lng, client = nominatim) {
  let result;
  try {
    result = await client.reverse(lat, lng);
  } catch {
    // Timeout, network or Nominatim error: the user can still continue.
    throw new AppError(502, 'GEOCODER_UNAVAILABLE', NO_GEOCODER_MESSAGE);
  }

  if (!result) {
    return { address: null, municipality: null, state: null, suggested_authority_id: null };
  }

  const a = result.address;
  const code = suggestAuthorityCode(a);
  return {
    address: shortAddress(result),
    municipality: a.city || a.town || a.village || a.municipality || a.county || null,
    state: a.state || null,
    suggested_authority_id: await authoritiesService.getIdByCode(code),
  };
}

module.exports = { reverse, shortAddress };
