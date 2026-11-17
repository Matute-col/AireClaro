const crypto = require('crypto');
const multer = require('multer');
const env = require('../config/env');
const AppError = require('../utils/AppError');
const { detectFileTypeOfPath } = require('../utils/fileType');
const { ensureTmpDir, removeFiles } = require('../utils/storage');

// Evidence upload (US-05, docs/05): 1 to 3 files in the "files" field.
// Photos JPEG/PNG/WebP up to MAX_PHOTO_MB; videos MP4/MOV up to MAX_VIDEO_MB.

const MAX_FILES = 3;
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
    files: MAX_FILES,
    // No file can be bigger than a video; photos are checked again below.
    fileSize: maxVideoBytes,
    fields: 30,
    fieldSize: 2 * 1024,
    parts: 40,
  },
});

function toAppError(err) {
  if (err instanceof multer.MulterError) {
    switch (err.code) {
      case 'LIMIT_FILE_SIZE':
        return new AppError(413, 'FILE_TOO_LARGE', `Cada video puede pesar máximo ${env.MAX_VIDEO_MB} MB.`);
      case 'LIMIT_FILE_COUNT':
      case 'LIMIT_UNEXPECTED_FILE':
        return new AppError(400, 'TOO_MANY_FILES', `Puedes adjuntar máximo ${MAX_FILES} archivos.`);
      default:
        return new AppError(400, 'INVALID_UPLOAD', 'La información enviada no es válida.');
    }
  }
  return err;
}

/** Receives the multipart request and saves the files in the temporary folder. */
function receiveEvidence(req, res, next) {
  upload.array('files', MAX_FILES)(req, res, (err) => (err ? next(toAppError(err)) : next()));
}

/**
 * Checks each received file by its real content and size. Adds `file.evidence =
 * {kind, mime, ext}`. If anything is wrong, all temporary files are deleted.
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
    return next();
  } catch (err) {
    await removeFiles(files.map((f) => f.path));
    return next(err);
  }
}

module.exports = { MAX_FILES, receiveEvidence, checkEvidence };
