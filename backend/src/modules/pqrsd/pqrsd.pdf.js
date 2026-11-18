const PDFDocument = require('pdfkit');

// PDF of the request (docs/05): letter size, 2.5 cm margins, Helvetica.
// Helvetica (a standard PDF font) covers Spanish: tildes, ñ, ü, ¿, ¡, «», º and –.

const CM = 72 / 2.54;
const MARGIN = 2.5 * CM;
const PHOTO_WIDTH = 6 * CM;
const BODY_SIZE = 11;

/**
 * @param {object} content   result of buildRequest()
 * @param {object} [options]
 * @param {string} [options.photoPath] first JPG/PNG photo to embed (≈ 6 cm wide)
 * @returns {Promise<Buffer>}
 */
function renderPdf(content, { photoPath } = {}) {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({
      size: 'LETTER',
      margins: { top: MARGIN, bottom: MARGIN, left: MARGIN, right: MARGIN },
      info: { Title: content.subject, Author: 'AireClaro', Creator: 'AireClaro' },
    });
    const chunks = [];
    doc.on('data', (chunk) => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);

    const paragraph = (text, options = {}) => {
      doc.font('Helvetica').fontSize(BODY_SIZE).text(text, { align: 'justify', ...options });
      doc.moveDown(0.6);
    };
    const heading = (text) => {
      doc.moveDown(0.4);
      doc.font('Helvetica-Bold').fontSize(BODY_SIZE).text(text);
      doc.moveDown(0.3);
    };
    const list = (items) => items.forEach((item, i) => paragraph(`${i + 1}. ${item}`, { indent: 0 }));

    paragraph(content.date, { align: 'left' });
    doc.moveDown(0.4);
    doc.font('Helvetica').fontSize(BODY_SIZE).text(content.recipient.join('\n'));
    doc.moveDown(1);

    doc.font('Helvetica-Bold').fontSize(BODY_SIZE).text('Asunto: ', { continued: true });
    doc.font('Helvetica').text(content.subject, { align: 'justify' });
    doc.moveDown(1);

    paragraph(content.greeting, { align: 'left' });
    paragraph(content.intro);

    heading('HECHOS');
    list(content.facts);

    heading('PETICIÓN');
    paragraph('Solicito respetuosamente a la entidad:', { align: 'left' });
    list(content.petition);

    heading('ANEXOS');
    list(content.annexes);
    if (photoPath) embedPhoto(doc, photoPath);

    heading('NOTIFICACIONES');
    paragraph(content.notifications);

    doc.moveDown(0.6);
    paragraph(content.closing, { align: 'left' });
    doc.moveDown(1.2);
    doc.font('Helvetica-Bold').fontSize(BODY_SIZE).text(content.signature[0]);
    doc.font('Helvetica').text(content.signature.slice(1).join('\n'));
    doc.moveDown(1.5);

    doc.font('Helvetica-Oblique').fontSize(9).fillColor('#444444').text(content.note, { align: 'justify' });
    doc.end();
  });
}

/** First photo, reduced to ≈ 6 cm wide; skipped if the file cannot be read. */
function embedPhoto(doc, photoPath) {
  let image;
  try {
    image = doc.openImage(photoPath);
  } catch {
    return; // missing or unsupported file: the annex list is still there
  }
  const height = (PHOTO_WIDTH * image.height) / image.width;
  if (doc.y + height + 20 > doc.page.height - MARGIN) doc.addPage();
  doc.font('Helvetica-Oblique').fontSize(9).text('Fotografía 1 (reducida):');
  doc.moveDown(0.3);
  doc.image(image, doc.page.margins.left, doc.y, { width: PHOTO_WIDTH });
  doc.y += height;
  doc.moveDown(0.6);
}

module.exports = { renderPdf };
