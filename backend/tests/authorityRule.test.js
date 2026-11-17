const { suggestAuthorityCode } = require('../src/modules/geo/authorityRule');
const samples = require('./helpers/nominatim');

describe('authority rule (RF-07)', () => {
  it('Soacha → CAR', () => {
    expect(suggestAuthorityCode(samples.soacha.address)).toBe('CAR');
  });

  it('Bogotá → SDA (with or without accent)', () => {
    expect(suggestAuthorityCode(samples.bogota.address)).toBe('SDA');
    expect(suggestAuthorityCode({ city: 'BOGOTA' })).toBe('SDA');
  });

  it('a neighbourhood named «UPZs de Bogotá» does not count, only the city does', () => {
    expect(suggestAuthorityCode({ neighbourhood: 'UPZs de Bogotá', town: 'Soacha' })).toBe('CAR');
  });

  it('Soacha only in «subregion» is still CAR', () => {
    expect(suggestAuthorityCode({ subregion: 'Soacha' })).toBe('CAR');
  });

  it('another Cundinamarca municipality → CAR', () => {
    expect(suggestAuthorityCode({ town: 'Mosquera', state: 'Cundinamarca' })).toBe('CAR');
  });

  it('a street called «Bogotá» in Soacha is not taken as Bogotá', () => {
    expect(
      suggestAuthorityCode({ road: 'Avenida Bogotá', town: 'Soacha', state: 'Cundinamarca' }),
    ).toBe('CAR');
  });

  it('outside the corridor → no suggestion', () => {
    expect(suggestAuthorityCode({ city: 'Medellín', state: 'Antioquia' })).toBeNull();
    expect(suggestAuthorityCode({})).toBeNull();
  });

  it('ambiguous (Bogotá and Cundinamarca at the same time) → no suggestion', () => {
    expect(suggestAuthorityCode({ city: 'Bogotá', state: 'Cundinamarca' })).toBeNull();
  });
});
