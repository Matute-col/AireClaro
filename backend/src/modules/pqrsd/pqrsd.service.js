const fs = require('fs');
const { query } = require('../../db/pool');
const storage = require('../../utils/storage');
const reportsService = require('../reports/reports.service');
const { buildRequest, toPlainText, shortId } = require('./pqrsd.text');
const { renderPdf } = require('./pqrsd.pdf');

/** Report data for the request. Only the owner: otherwise 404 (from getById). */
async function load(userId, reportId) {
  const detail = await reportsService.getById(userId, reportId);
  const content = buildRequest(detail.report, detail.media, detail.authority);
  return { detail, content };
}

/** GET /reports/:id/pqrsd → text for the preview. */
async function getText(userId, reportId) {
  const { detail, content } = await load(userId, reportId);
  return {
    authority: detail.authority,
    plate: detail.report.plate,
    status: detail.report.status,
    text: toPlainText(content),
  };
}

/** First JPG/PNG photo of the report (pdfkit cannot embed WebP). */
async function firstPhotoPath(reportId) {
  const { rows } = await query(
    `SELECT file_path FROM report_media
      WHERE report_id = $1 AND kind = 'photo' AND mime_type IN ('image/jpeg', 'image/png')
      ORDER BY file_path LIMIT 1`,
    [reportId],
  );
  if (!rows[0]) return undefined;
  const absolute = storage.resolveStored(rows[0].file_path);
  return fs.existsSync(absolute) ? absolute : undefined;
}

/** US-23 · Frame files of each video, in order: {videoMediaId: [absolutePath, …]}. */
async function framePathsByVideo(reportId) {
  const { rows } = await query(
    `SELECT source_media_id, file_path FROM report_media
      WHERE report_id = $1 AND kind = 'frame'
      ORDER BY source_media_id, position`,
    [reportId],
  );
  const byVideo = {};
  for (const row of rows) {
    const absolute = storage.resolveStored(row.file_path);
    if (fs.existsSync(absolute)) (byVideo[row.source_media_id] ||= []).push(absolute);
  }
  return byVideo;
}

/** GET /reports/:id/pqrsd.pdf → {buffer, fileName}. */
async function getPdf(userId, reportId) {
  const { detail, content } = await load(userId, reportId);
  const framePaths = await framePathsByVideo(detail.report.id);
  const buffer = await renderPdf(content, {
    photoPath: await firstPhotoPath(detail.report.id),
    frameGroups: content.frameGroups.map((group) => ({
      videoNumber: group.videoNumber,
      paths: framePaths[group.sourceMediaId] || [],
    })),
  });
  return { buffer, fileName: `solicitud-${shortId(detail.report.id)}.pdf` };
}

module.exports = { getText, getPdf };
