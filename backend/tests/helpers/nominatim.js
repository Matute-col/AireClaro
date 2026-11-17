// Real Nominatim answers (format=jsonv2, addressdetails=1, accept-language=es, zoom=16)
// for the test points of docs/05, queried on 16-nov-2026. No personal data.
const soacha = {
  display_name:
    'Carrera 3A, Ubaté, Comuna San Humberto, Soacha ciudad, Soacha, Cundinamarca, ' +
    'RAP (Especial) Central, 250053, Colombia',
  address: {
    road: 'Carrera 3A',
    neighbourhood: 'Ubaté',
    suburb: 'Comuna San Humberto',
    city: 'Soacha ciudad',
    subregion: 'Soacha',
    state: 'Cundinamarca',
    'ISO3166-2-lvl4': 'CO-CUN',
    region: 'RAP (Especial) Central',
    postcode: '250053',
    country: 'Colombia',
    country_code: 'co',
  },
};

const bogota = {
  display_name:
    'Carrera 19, UPZs de Bogotá, Localidad Los Mártires, Bogotá ciudad, Bogotá, Distrito Capital, ' +
    'RAP (Especial) Central, 111411, Colombia',
  address: {
    road: 'Carrera 19',
    neighbourhood: 'UPZs de Bogotá',
    suburb: 'Localidad Los Mártires',
    city: 'Bogotá ciudad',
    state: 'Bogotá, Distrito Capital',
    'ISO3166-2-lvl4': 'CO-DC',
    region: 'RAP (Especial) Central',
    postcode: '111411',
    country: 'Colombia',
    country_code: 'co',
  },
};

function jsonResponse(body, status = 200) {
  return { ok: status >= 200 && status < 300, status, json: async () => body };
}

module.exports = { soacha, bogota, jsonResponse };
