-- Seed authorities (docs/05-modelo-de-datos-y-api.md, research of 2026-11-16).
-- Emails are CANDIDATES taken from public institutional pages, not verified.
-- email_verified stays false until Mateo checks each one on the official site;
-- until then only MAIL_MODE=test can send. SDM has no known email (NULL).

-- Up Migration
INSERT INTO authorities (code, name, email, email_verified, portal_url, note) VALUES
  ('CAR',
   'Corporación Autónoma Regional de Cundinamarca (CAR)',
   'sau@car.gov.co',
   false,
   'https://www.car.gov.co',
   'Correo candidato tomado del pie de una carta de respuesta de la CAR; pendiente de verificar.'),
  ('SDA',
   'Secretaría Distrital de Ambiente de Bogotá',
   'correspondencia@ambientebogota.gov.co',
   false,
   'https://forest.ambientebogota.gov.co/ventanillaVirtual/app',
   'Correo candidato de la página oficial de canales de atención; no dice expresamente que sirva para radicar PQRS.'),
  ('SDM',
   'Secretaría Distrital de Movilidad de Bogotá',
   NULL,
   false,
   'https://www.movilidadbogota.gov.co/peticiones-quejas-reclamos-solicitudes-y-denuncias-pqrsd',
   'Sin correo hallado; radicar por el portal oficial.')
ON CONFLICT (code) DO NOTHING;

-- Down Migration
DELETE FROM authorities WHERE code IN ('CAR', 'SDA', 'SDM');
