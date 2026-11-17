const fs = require('fs/promises');

// Detects the REAL type of an evidence file from its first bytes ("magic numbers").
// The file name and the MIME type sent by the phone are not trusted.
//
// Accepted: photos JPEG, PNG, WebP; videos MP4 and MOV (QuickTime).
// HEIC/AVIF photos also start with an "ftyp" box like MP4, so their brands are rejected.

const HEADER_BYTES = 16;
const HEIF_BRANDS = new Set(['heic', 'heix', 'hevc', 'hevx', 'heim', 'heis', 'mif1', 'msf1', 'avif', 'avis']);

function startsWith(buffer, bytes, offset = 0) {
  return bytes.every((byte, i) => buffer[offset + i] === byte);
}

function ascii(buffer, start, end) {
  return buffer.subarray(start, end).toString('latin1');
}

/**
 * @param {Buffer} buffer first bytes of the file
 * @returns {{kind: 'photo'|'video', mime: string, ext: string} | null}
 */
function detectFileType(buffer) {
  if (!buffer || buffer.length < 12) return null;

  if (startsWith(buffer, [0xff, 0xd8, 0xff])) {
    return { kind: 'photo', mime: 'image/jpeg', ext: 'jpg' };
  }
  if (startsWith(buffer, [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])) {
    return { kind: 'photo', mime: 'image/png', ext: 'png' };
  }
  if (ascii(buffer, 0, 4) === 'RIFF' && ascii(buffer, 8, 12) === 'WEBP') {
    return { kind: 'photo', mime: 'image/webp', ext: 'webp' };
  }
  // MP4 / MOV: bytes 4-7 are "ftyp", bytes 8-11 the brand.
  if (ascii(buffer, 4, 8) === 'ftyp') {
    const brand = ascii(buffer, 8, 12);
    if (HEIF_BRANDS.has(brand)) return null;
    if (brand === 'qt  ') return { kind: 'video', mime: 'video/quicktime', ext: 'mov' };
    return { kind: 'video', mime: 'video/mp4', ext: 'mp4' };
  }
  return null;
}

/** Reads the first bytes of a file on disk and detects its type. */
async function detectFileTypeOfPath(filePath) {
  const handle = await fs.open(filePath, 'r');
  try {
    const buffer = Buffer.alloc(HEADER_BYTES);
    const { bytesRead } = await handle.read(buffer, 0, HEADER_BYTES, 0);
    return detectFileType(buffer.subarray(0, bytesRead));
  } finally {
    await handle.close();
  }
}

module.exports = { detectFileType, detectFileTypeOfPath };
