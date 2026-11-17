-- Verified authority contact data (docs/05-modelo-de-datos-y-api.md).
-- Emails and portals confirmed by Mateo on the official sites (2026-11-16).
-- email_verified = true only allows sending when MAIL_MODE=live; with the
-- default MAIL_MODE=test every email goes to MAIL_TEST_TO.

-- Up Migration
UPDATE authorities SET
  email = 'atencionalciudadano@ambientebogota.gov.co',
  email_verified = true,
  portal_url = 'https://www.bogota.gov.co/sdqs',
  note = 'Correo y portal (Bogotá te escucha - SDQS) verificados por Mateo en el sitio oficial el 16-nov-2026.'
WHERE code = 'SDA';

UPDATE authorities SET
  email = 'sau@car.gov.co',
  email_verified = true,
  portal_url = 'https://sidcar.car.gov.co/Modulos/Buzon/RadicarPQR.aspx',
  note = 'Correo y portal de radicación de PQR verificados por Mateo en el sitio oficial el 16-nov-2026.'
WHERE code = 'CAR';

UPDATE authorities SET
  email = NULL,
  email_verified = false,
  portal_url = 'https://www.movilidadbogota.gov.co/radicacionwebsdm/formulario.php',
  note = 'Sin correo para radicar; usar el formulario oficial de radicación web (verificado por Mateo el 16-nov-2026).'
WHERE code = 'SDM';

-- Down Migration
-- Back to the unverified candidates of 1794830400001_seed-authorities.sql.
UPDATE authorities SET
  email = 'correspondencia@ambientebogota.gov.co',
  email_verified = false,
  portal_url = 'https://forest.ambientebogota.gov.co/ventanillaVirtual/app',
  note = 'Correo candidato de la página oficial de canales de atención; no dice expresamente que sirva para radicar PQRS.'
WHERE code = 'SDA';

UPDATE authorities SET
  email = 'sau@car.gov.co',
  email_verified = false,
  portal_url = 'https://www.car.gov.co',
  note = 'Correo candidato tomado del pie de una carta de respuesta de la CAR; pendiente de verificar.'
WHERE code = 'CAR';

UPDATE authorities SET
  email = NULL,
  email_verified = false,
  portal_url = 'https://www.movilidadbogota.gov.co/peticiones-quejas-reclamos-solicitudes-y-denuncias-pqrsd',
  note = 'Sin correo hallado; radicar por el portal oficial.'
WHERE code = 'SDM';
