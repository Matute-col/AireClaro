const fs = require('fs');
const env = require('../../config/env');
const { query } = require('../../db/pool');
const AppError = require('../../utils/AppError');
const storage = require('../../utils/storage');
const reportsService = require('../reports/reports.service');
const pqrsdService = require('../pqrsd/pqrsd.service');
const { formatDate, shortId } = require('../pqrsd/pqrsd.text');
const mailer = require('./mailer');

// US-21 · POST /reports/:id/send — sends the request by email to the authority (RF-17).
// Rules (RB-08, RB-09, docs/05):
// - only the owner (404), only once (409), only to authorities with a verified email (422);
// - MAIL_MODE=test: everything goes to MAIL_TEST_TO with «[PRUEBA]» in the subject;
//   live: to the authority (only by Mateo's explicit decision); off: nothing is sent (503);
// - attachments: the PDF always; the evidence only if it adds up to ≤ 15 MB. Video frames
//   (US-23) are never attached separately: they travel inside the PDF;
// - if SMTP fails nothing changes (502). Email bodies and addresses are never logged.

const MAX_ATTACHED_EVIDENCE_BYTES = 15 * 1024 * 1024;

/** Reports being sent right now: a double tap cannot send twice. */
const sending = new Set();

const EXTENSIONS = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
  'video/mp4': 'mp4',
  'video/quicktime': 'mov',
};

/** Email of the authority, only if it is verified (never sent to the app). */
async function verifiedAuthorityEmail(authorityId) {
  const { rows } = await query(
    'SELECT email FROM authorities WHERE id = $1 AND email IS NOT NULL AND email_verified',
    [authorityId],
  );
  return rows[0]?.email ?? null;
}

/** Evidence files (no frames) with their absolute paths, in the PDF order (photos, videos). */
async function evidenceFiles(reportId) {
  const { rows } = await query(
    `SELECT kind, file_path, mime_type, size_bytes FROM report_media
      WHERE report_id = $1 AND kind <> 'frame'
      ORDER BY (kind = 'video'), file_path`,
    [reportId],
  );
  return rows.map((row, i) => ({
    filename: `evidencia-${i + 1}.${EXTENSIONS[row.mime_type] || 'bin'}`,
    path: storage.resolveStored(row.file_path),
    contentType: row.mime_type,
    size: row.size_bytes,
  }));
}

function buildBody(report, evidenceAttached) {
  const place = report.address || `las coordenadas ${Number(report.lat).toFixed(5)}, ${Number(report.lng).toFixed(5)}`;
  const evidence = evidenceAttached
    ? 'con la evidencia registrada'
    : 'La evidencia (fotografías o video) está disponible a solicitud del peticionario por su tamaño';
  return [
    'Respetados señores:',
    '',
    `Adjunto la petición ciudadana (PDF) sobre un vehículo de placa ${report.plate} observado el ` +
      `${formatDate(new Date(report.occurred_at))} en ${place}` +
      (evidenceAttached ? `, ${evidence}.` : `. ${evidence}.`) +
      ' Solicito atender la petición conforme a sus competencias y responder al correo del ' +
      'peticionario, que va en copia. Si no es la entidad competente, les ruego remitirla a la que ' +
      'corresponda (Ley 1755 de 2015, art. 21).',
    '',
    'Este mensaje fue generado con la aplicación AireClaro a nombre del peticionario, con su ' +
      'autorización. Las observaciones no constituyen una medición técnica de emisiones.',
    '',
    `${report.requester_name} · ${report.requester_doc_type} ${report.requester_doc_number}`,
  ].join('\n');
}

/**
 * @returns {{report: object, delivery: {mode, sent_at, evidence_attached}}}
 */
async function sendReport(userId, reportId) {
  // The lock is taken BEFORE reading the status: a second request arriving at the same
  // time gets 409 here, and one arriving later reads the status already «enviado».
  const key = String(reportId).toLowerCase();
  if (sending.has(key)) {
    throw new AppError(409, 'SEND_IN_PROGRESS', 'El envío de esta solicitud ya está en curso.');
  }
  sending.add(key);
  try {
    return await sendLocked(userId, reportId);
  } finally {
    sending.delete(key);
  }
}

async function sendLocked(userId, reportId) {
  // 404 if the report does not exist or is not the user's.
  const detail = await reportsService.getById(userId, reportId);
  const { report } = detail;

  if (report.status === 'enviado') {
    throw new AppError(409, 'ALREADY_SENT', 'Esta solicitud ya fue enviada.');
  }
  const authorityEmail = await verifiedAuthorityEmail(detail.authority.id);
  if (!authorityEmail) {
    throw new AppError(
      422,
      'AUTHORITY_WITHOUT_EMAIL',
      'Esta autoridad no tiene un correo verificado. Usa «Radicar en el portal oficial».',
    );
  }
  const mode = env.MAIL_MODE;
  if (mode === 'off') {
    throw new AppError(503, 'MAIL_DISABLED', 'El envío por correo está desactivado en el servidor.');
  }
  if (!mailer.isConfigured()) {
    throw new AppError(503, 'MAIL_NOT_CONFIGURED', 'El envío por correo no está configurado en el servidor.');
  }

  const evidence = (await evidenceFiles(report.id)).filter((f) => fs.existsSync(f.path));
  const evidenceBytes = evidence.reduce((total, f) => total + f.size, 0);
  const evidenceAttached = evidence.length > 0 && evidenceBytes <= MAX_ATTACHED_EVIDENCE_BYTES;

  const pdf = await pqrsdService.getPdf(userId, report.id, { channel: 'email', evidenceAttached });
  const subject =
    `${mode === 'test' ? '[PRUEBA] ' : ''}Petición ciudadana – presunta emisión anómala de gases – ` +
    `vehículo de placa ${report.plate} – Reporte ${shortId(report.id)}`;

  try {
    await mailer.sendMail({
      from: env.MAIL_FROM,
      to: mode === 'test' ? env.MAIL_TEST_TO : authorityEmail,
      cc: report.requester_email,
      replyTo: report.requester_email,
      subject,
      text: buildBody(report, evidenceAttached),
      attachments: [
        { filename: pdf.fileName, content: pdf.buffer, contentType: 'application/pdf' },
        ...(evidenceAttached
          ? evidence.map(({ filename, path, contentType }) => ({ filename, path, contentType }))
          : []),
      ],
    });
  } catch (err) {
    // Only the error code: SMTP errors can contain addresses.
    console.error(`[mail] envío fallido del reporte ${shortId(report.id)}: ${err.code || err.name}`);
    throw new AppError(
      502,
      'MAIL_SEND_FAILED',
      'No pudimos enviar el correo. Inténtalo de nuevo en unos minutos.',
    );
  }

  const { rows } = await query(
    `UPDATE reports SET status = 'enviado', sent_via = 'email', sent_at = now(), send_mode = $3
      WHERE id = $1 AND user_id = $2 AND status = 'generado'
      RETURNING id, status, sent_via, send_mode, sent_at`,
    [report.id, userId, mode],
  );
  if (!rows[0]) {
    // Should not happen with the lock above; never answer 500 for it.
    throw new AppError(409, 'ALREADY_SENT', 'Esta solicitud ya fue enviada.');
  }
  console.log(`[mail] reporte ${shortId(report.id)} enviado (modo ${mode})`);
  return {
    report: rows[0],
    delivery: { mode, sent_at: rows[0].sent_at, evidence_attached: evidenceAttached },
  };
}

module.exports = { sendReport, MAX_ATTACHED_EVIDENCE_BYTES };
