const { z } = require('zod');
const { vehicleFields, normalizePlate } = require('../src/modules/reports/reports.schema');

const vehicleSchema = z.object(vehicleFields);
const valid = { vehicle_type: 'bus', plate: 'ABC123', smoke_color: 'negro' };

function errorsOf(data) {
  const result = vehicleSchema.safeParse(data);
  return result.success ? {} : Object.fromEntries(result.error.issues.map((i) => [i.path[0], i.message]));
}

describe('report vehicle fields (US-06)', () => {
  it('accepts car plates (ABC123) and motorcycle plates (ABC12D)', () => {
    expect(vehicleSchema.parse(valid).plate).toBe('ABC123');
    expect(vehicleSchema.parse({ ...valid, plate: 'ABC12D' }).plate).toBe('ABC12D');
  });

  it('normalizes the plate: uppercase, no spaces or dashes', () => {
    expect(normalizePlate(' abc-12 3 ')).toBe('ABC123');
    expect(vehicleSchema.parse({ ...valid, plate: 'abc 12d' }).plate).toBe('ABC12D');
  });

  it.each(['AB123', 'ABCD12', '123ABC', 'ABC1234', 'ABC1D2', ''])('rejects plate %p', (plate) => {
    expect(errorsOf({ ...valid, plate }).plate).toBe('La placa debe tener el formato ABC123 o ABC12D.');
  });

  it('requires a valid vehicle type and smoke color', () => {
    const errors = errorsOf({ ...valid, vehicle_type: 'moto', smoke_color: 'azul' });
    expect(errors.vehicle_type).toBe('Elige un tipo de vehículo válido.');
    expect(errors.smoke_color).toBe('Elige el color del humo (negro, gris o blanco).');
  });

  it('description is optional, trimmed and up to 500 characters', () => {
    expect(vehicleSchema.parse(valid).description).toBeNull();
    expect(vehicleSchema.parse({ ...valid, description: '   ' }).description).toBeNull();
    expect(vehicleSchema.parse({ ...valid, description: ' humo denso ' }).description).toBe('humo denso');
    expect(vehicleSchema.parse({ ...valid, description: 'a'.repeat(500) }).description).toHaveLength(500);
    expect(errorsOf({ ...valid, description: 'a'.repeat(501) }).description).toBe(
      'La descripción puede tener máximo 500 caracteres.',
    );
  });
});

describe('report requester fields (US-08)', () => {
  const { requesterFields } = require('../src/modules/reports/reports.schema');
  const requesterSchema = z.object(requesterFields);
  const requester = {
    requester_name: 'Ana Prueba',
    requester_doc_type: 'CC',
    requester_doc_number: '0000000',
    requester_email: 'Ana@Ejemplo.test',
  };

  function requesterErrors(data) {
    const result = requesterSchema.safeParse(data);
    return result.success ? {} : Object.fromEntries(result.error.issues.map((i) => [i.path[0], i.message]));
  }

  it('accepts the profile data and normalizes email and phone', () => {
    const parsed = requesterSchema.parse({ ...requester, requester_phone: '300 000-0000' });
    expect(parsed.requester_email).toBe('ana@ejemplo.test');
    expect(parsed.requester_phone).toBe('3000000000');
  });

  it('phone is optional (empty → null)', () => {
    expect(requesterSchema.parse({ ...requester, requester_phone: '' }).requester_phone).toBeNull();
  });

  it('there is no anonymous option: name, document and email are required', () => {
    const errors = requesterErrors({});
    expect(Object.keys(errors).sort()).toEqual([
      'requester_doc_number',
      'requester_doc_type',
      'requester_email',
      'requester_name',
    ]);
  });

  it('uses the same rules as the profile', () => {
    const errors = requesterErrors({ ...requester, requester_doc_number: '1.234', requester_email: 'x' });
    expect(errors.requester_doc_number).toMatch(/entre 4 y 20/);
    expect(errors.requester_email).toBe('Escribe un correo electrónico válido.');
  });
});
