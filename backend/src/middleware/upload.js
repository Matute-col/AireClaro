const crypto = require('crypto');
const multer = require('multer');
const env = require('../config/env');
const AppError = require('../utils/AppError');
const { detectFileTypeOfPath } = require('../utils/fileType');
const { ensureTmpDir, removeFiles } = require('../utils/storage');

// Evidence upload (US-05, docs/05): 1 to 3 files in the "files" field.
// Photos JPEG/PNG/WebP up to MAX_PHOTO_MB; videos MP4/MOV up to MAX_VIDEO_MB.
//
// Video frames (US-23): up to 4 JPEG frames (≤ 300 KB each) per video, in the field
// "frames_v<N>", where N is the position (0, 1, 2) of the video in "files". Their order
// in the field is their position (1 to 4). Frames do NOT count toward the 3 files.

const MAX_FILES = 3;
const MAX_FRAMES_PER_VIDEO = 4;
const MAX_FRAME_BYTES = 300 * 1024;
const FRAME_FIELDS = Array.from({ length: MAX_FILES }, (_, i) => `frames_v${i}`);

const MB = 1024 * 1024;
const maxPhotoBytes = Math.floor(env.MAX_PHOTO_MB * MB);
const maxVideoBytes = Math.floor(env.MAX_VIDEO_MB * MB);

const TYPE_MESSAGE = 'Solo se aceptan fotos JPG, PNG o WebP y videos MP4 o MOV.';

const upload = multer({
  storage: multer.diskStorage({
    destination: (req, file, cb) => cb(null, ensureTmpDir()),
    // Server-generated name: the original name is ignored.
    filename: (req, file, cb) => cb(null, crypto.randomUUID()),
  }),
  limits: {
    files: MAX_FILES + MAX_FILES * MAX_FRAMES_PER_VIDEO,
    // No file can be bigger than a video; photos and frames are checked again below.
    fileSize: maxVideoBytes,
    fields: 30,
    fieldSize: 2 * 1024,
    parts: 50,
  },
});

function toAppError(err) {
  if (err instanceof multer.MulterError) {
    switch (err.code) {
      case 'LIMIT_FILE_SIZE':
        return new AppError(413, 'FILE_TOO_LARGE', `Cada video puede pesar máximo ${env.MAX_VIDEO_MB} MB.`);
      case 'LIMIT_FILE_COUNT':
        return new AppError(400, 'TOO_MANY_FILES', `Puedes adjuntar máximo ${MAX_FILES} archivos.`);
      case 'LIMIT_UNEXPECTED_FILE':
        if (err.field === 'files') {
          return new AppError(400, 'TOO_MANY_FILES', `Puedes adjuntar máximo ${MAX_FILES} archivos.`);
        }
        if (FRAME_FIELDS.includes(err.field)) {
          return new AppError(
            400,
            'TOO_MANY_FRAMES',
            `Puedes enviar máximo ${MAX_FRAMES_PER_VIDEO} fotogramas por video.`,
          );
        }
        return new AppError(400, 'INVALID_UPLOAD', 'Se envió un archivo en un campo no permitido.');
      default:
        return new AppError(400, 'INVALID_UPLOAD', 'La información enviada no es válida.');
    }
  }
  return err;
}

/** All temporary files of the request (evidence and frames), for cleanup. */
function uploadedPaths(req) {
  return [...(req.files || []), ...(req.frames || []).map((f) => f.file)].map((f) => f.path);
}

/**
 * Receives the multipart request and saves the files in the temporary folder.
 * Afterwards: req.files = evidence files (array, in order) and
 * req.frames = [{file, videoIndex, position}].
 */
function receiveEvidence(req, res, next) {
  const fields = [
    { name: 'files', maxCount: MAX_FILES },
    ...FRAME_FIELDS.map((name) => ({ name, maxCount: MAX_FRAMES_PER_VIDEO })),
  ];
  upload.fields(fields)(req, res, (err) => {
    const grouped = req.files || {};
    req.files = grouped.files || [];
    req.frames = FRAME_FIELDS.flatMap((name, videoIndex) =>
      (grouped[name] || []).map((file, i) => ({ file, videoIndex, position: i + 1 })),
    );
    return err ? next(toAppError(err)) : next();
  });
}

/**
 * Checks each received file by its real content and size. Adds `file.evidence =
 * {kind, mime, ext}` to evidence and frames. If anything is wrong, all temporary
 * files are deleted.
 */
async function checkEvidence(req, res, next) {
  const files = req.files || [];
  try {
    if (files.length === 0) {
      throw new AppError(400, 'EVIDENCE_REQUIRED', 'Agrega al menos una foto o un video.');
    }
    for (const file of files) {
      const type = await detectFileTypeOfPath(file.path);
      if (!type) throw new AppError(400, 'INVALID_FILE_TYPE', TYPE_MESSAGE);
      if (type.kind === 'photo' && file.size > maxPhotoBytes) {
        throw new AppError(413, 'FILE_TOO_LARGE', `Cada foto puede pesar máximo ${env.MAX_PHOTO_MB} MB.`);
      }
      file.evidence = type;
    }

    for (const frame of req.frames || []) {
      const source = files[frame.videoIndex];
      if (!source || source.evidence.kind !== 'video') {
        throw new AppError(
          400,
          'INVALID_FRAME_SOURCE',
          'Los fotogramas deben corresponder a un video del reporte.',
        );
      }
      const type = await detectFileTypeOfPath(frame.file.path);
      if (!type || type.mime !== 'image/jpeg') {
        throw new AppError(400, 'INVALID_FRAME_TYPE', 'Los fotogramas deben ser imágenes JPG.');
      }
      if (frame.file.size > MAX_FRAME_BYTES) {
        throw new AppError(413, 'FRAME_TOO_LARGE', 'Cada fotograma puede pesar máximo 300 KB.');
      }
      frame.file.evidence = { kind: 'frame', mime: 'image/jpeg', ext: 'jpg' };
    }
    return next();
  } catch (err) {
    await removeFiles(uploadedPaths(req));
    return next(err);
  }
}

module.exports = {
  MAX_FILES,
  MAX_FRAMES_PER_VIDEO,
  MAX_FRAME_BYTES,
  receiveEvidence,
  checkEvidence,
  uploadedPaths,
};
