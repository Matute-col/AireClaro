// Authority suggestion (RF-07, rule confirmed by Mateo on 16-nov-2026):
// - the place is in Bogotá                 → SDA (Secretaría Distrital de Ambiente)
// - the place is in Soacha or Cundinamarca → CAR
// - otherwise, or if both match (ambiguous) → no suggestion: the user chooses.
// The user can always change the authority before saving.
//
// Only the administrative fields (city, municipality, department...) are checked,
// never the street or the neighbourhood: an «Avenida Bogotá» in Soacha must not be
// taken as Bogotá (real Nominatim data even has a neighbourhood «UPZs de Bogotá»).

const PLACE_FIELDS = [
  'city',
  'town',
  'village',
  'municipality',
  'county',
  'subregion',
  'state_district',
  'state',
  'region',
];

/** Lowercase and without accents: «Bogotá» → «bogota». */
function normalize(text) {
  return String(text)
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase();
}

/** Administrative place names from a Nominatim `address` object, normalized. */
function placeText(address = {}) {
  return PLACE_FIELDS.filter((field) => address[field])
    .map((field) => normalize(address[field]))
    .join(' | ');
}

/**
 * @param {object} address Nominatim `address` (addressdetails=1)
 * @returns {'SDA'|'CAR'|null}
 */
function suggestAuthorityCode(address) {
  const text = placeText(address);
  const isBogota = text.includes('bogota');
  const isCar = text.includes('soacha') || text.includes('cundinamarca');
  if (isBogota && isCar) return null; // ambiguous: let the user choose
  if (isBogota) return 'SDA';
  if (isCar) return 'CAR';
  return null;
}

module.exports = { suggestAuthorityCode, normalize, placeText };
