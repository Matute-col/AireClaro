const { getPool } = require('../../db/pool');
const AppError = require('../../utils/AppError');
const storage = require('../../utils/storage');
const authoritiesService = require('../authorities/authorities.service');
const geoService = require('../geo/geo.service');

/**
 * Authority for a new report: the one chosen in the app, or the rule of
 * docs/05 applied again on the server. Without either, the user must choose.
 */
async function resolveAuthority(data) {
  if (data.authority_id !== undefined) {
    const authority = await authoritiesService.getById(data.authority_id);
    if (!authority) {
      throw new AppError(400, 'VALIDATION_ERROR', 'Revisa los datos ingresados.', [
        { field: 'authority_id', message: 'Elige una autoridad válida.' },
      ]);
    }
    return authority;
  }

  let suggestedId = null;
  try {
    suggestedId = (await geoService.reverse(data.lat, data.lng)).suggested_authority_id;
  } catch {
    suggestedId = null; // geocoder down: the user chooses
  }
  const authority = suggestedId ? await authoritiesService.getById(suggestedId) : null;
  if (!authority) {
    throw new AppError(400, 'AUTHORITY_REQUIRED', 'Elige la autoridad a la que va dirigida la solicitud.', [
      { field: 'authority_id', message: 'Elige la autoridad a la que va dirigida la solicitud.' },
    ]);
  }
  return authority;
}

/**
 * Creates the report and its evidence in ONE transaction (US-09).
 * Files are moved from the temporary folder to <UPLOAD_DIR>/reports/<id>/.
 * If anything fails, the database changes are rolled back and the moved files deleted.
 *
 * @param {string} userId owner, taken from the token (never from the request body)
 * @param {object} data   fields validated by createReportSchema
 * @param {Array}  files  multer files already checked by checkEvidence
 */
async function create(userId, data, files) {
  const authority = await resolveAuthority(data);

  const client = await getPool().connect();
  const movedPaths = [];
  try {
    await client.query('BEGIN');

    const { rows } = await client.query(
      `INSERT INTO reports (
         user_id, authority_id, vehicle_type, plate, smoke_color, description,
         lat, lng, address, occurred_at,
         requester_name, requester_doc_type, requester_doc_number, requester_email, requester_phone)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
       RETURNING id, vehicle_type, plate, smoke_color, description, lat, lng, address,
                 occurred_at, status, created_at`,
      [
        userId,
        authority.id,
        data.vehicle_type,
        data.plate,
        data.smoke_color,
        data.description,
        data.lat,
        data.lng,
        data.address,
        data.occurred_at,
        data.requester_name,
        data.requester_doc_type,
        data.requester_doc_number,
        data.requester_email,
        data.requester_phone,
      ],
    );
    const report = rows[0];

    const media = [];
    for (const file of files) {
      // Server-generated name: the multer UUID plus the extension of the REAL type.
      const relativePath = await storage.moveToReport(
        file.path,
        report.id,
        `${file.filename}.${file.evidence.ext}`,
      );
      movedPaths.push(storage.resolveStored(relativePath));
      const inserted = await client.query(
        `INSERT INTO report_media (report_id, kind, file_path, mime_type, size_bytes)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING id, kind, mime_type, size_bytes`,
        [report.id, file.evidence.kind, relativePath, file.evidence.mime, file.size],
      );
      media.push(inserted.rows[0]);
    }

    await client.query('COMMIT');
    return { ...report, authority, media };
  } catch (err) {
    await client.query('ROLLBACK').catch(() => {});
    await storage.removeFiles(movedPaths);
    throw err;
  } finally {
    client.release();
  }
}

module.exports = { create, resolveAuthority };
