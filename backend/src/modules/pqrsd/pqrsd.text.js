// Text of the request (PQRSD), template of docs/05. Shared by the PDF, the preview
// (GET /reports/:id/pqrsd) and, later, the email. Factual tone: it never says that the
// vehicle «incumple» a rule, and it states that this is not a technical measurement.
//
// Minimum content of Ley 1755 de 2015, art. 16: authority (recipient) · names, ID and
// electronic address for notifications (signature, NOTIFICACIONES) · object (subject,
// PETICIÓN) · reasons (HECHOS) · list of documents (ANEXOS) · signature (name and ID).

const TIME_ZONE = 'America/Bogota';

const VEHICLE_TYPES = {
  bus: 'bus o buseta',
  microbus: 'microbús',
  camion: 'camión',
  tractomula: 'tractomula',
  otro: 'otro',
};

const FORMATS = {
  'image/jpeg': 'JPG',
  'image/png': 'PNG',
  'image/webp': 'WEBP',
  'video/mp4': 'MP4',
  'video/quicktime': 'MOV',
};

/** Intl uses no-break spaces («9:30 a. m.»); the PDF font only has the normal one. */
function plainSpaces(text) {
  return text.replace(/[\u00a0\u202f]/g, ' ');
}

/** «16 de noviembre de 2026» (Colombia time). */
function formatDate(date) {
  return plainSpaces(
    new Intl.DateTimeFormat('es-CO', {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
      timeZone: TIME_ZONE,
    }).format(date),
  );
}

/** «9:30 a. m.» (Colombia time). */
function formatTime(date) {
  return plainSpaces(
    new Intl.DateTimeFormat('es-CO', {
      hour: 'numeric',
      minute: '2-digit',
      hour12: true,
      timeZone: TIME_ZONE,
    }).format(date),
  );
}

/** «1,2 MB» or «850 KB». */
function formatSize(bytes) {
  if (bytes >= 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(1).replace('.', ',')} MB`;
  return `${Math.max(1, Math.round(bytes / 1024))} KB`;
}

/** First 8 characters of the report id, e.g. «3F2A9C1B». */
function shortId(id) {
  return String(id).replace(/-/g, '').slice(0, 8).toUpperCase();
}

function evidenceKinds(media) {
  const photos = media.filter((m) => m.kind === 'photo').length;
  const videos = media.length - photos;
  if (photos && videos) return 'fotografía y video';
  if (videos) return videos > 1 ? 'videos' : 'video';
  return photos > 1 ? 'fotografías' : 'fotografía';
}

/**
 * @param {object} report    report row (snapshot of the requester data, RB-05)
 * @param {Array}  media     [{kind, mime_type, size_bytes}]
 * @param {object} authority {name}
 * @returns structured content of the request
 */
function buildRequest(report, media, authority) {
  const occurred = new Date(report.occurred_at);
  const lat = Number(report.lat).toFixed(5);
  const lng = Number(report.lng).toFixed(5);
  const place = report.address
    ? `en ${report.address} (coordenadas ${lat}, ${lng})`
    : `en el punto de coordenadas ${lat}, ${lng}`;
  const vehicle = VEHICLE_TYPES[report.vehicle_type] || report.vehicle_type;

  const facts = [
    `El día ${formatDate(occurred)} a las ${formatTime(occurred)}, ${place}, observé un vehículo de ` +
      `tipo ${vehicle} con placa ${report.plate} que emitía humo de color ${report.smoke_color}.`,
  ];
  if (report.description) facts.push(`Descripción del peticionario: «${report.description}».`);
  const files = media.length === 1 ? '1 archivo' : `${media.length} archivos`;
  facts.push(
    `Como soporte se anexan ${files} de evidencia (${evidenceKinds(media)}) registrados con la ` +
      'fecha, la hora y la ubicación indicadas.',
  );

  // Stable order for ANEXOS: photos first, then videos (stored file names are random).
  const ordered = [
    ...media.filter((m) => m.kind === 'photo'),
    ...media.filter((m) => m.kind !== 'photo'),
  ];
  let photoNumber = 0;
  let videoNumber = 0;
  const annexes = ordered.map((m) => {
    const label = m.kind === 'photo' ? `Fotografía ${++photoNumber}` : `Video ${++videoNumber}`;
    return `${label} (${FORMATS[m.mime_type] || m.mime_type}, ${formatSize(m.size_bytes)}).`;
  });

  const phone = report.requester_phone ? ` y en el teléfono ${report.requester_phone}` : '';

  return {
    date: formatDate(new Date(report.created_at)),
    recipient: ['Señores', authority.name, 'Ciudad'],
    subject:
      'Denuncia ciudadana por presunta emisión anómala de gases contaminantes de una fuente móvil – ' +
      `vehículo de placa ${report.plate}`,
    greeting: 'Respetados señores:',
    intro:
      'En ejercicio del derecho fundamental de petición consagrado en el artículo 23 de la Constitución ' +
      'Política de Colombia, y con el fin de que se adelanten las verificaciones que sean de su ' +
      'competencia, presento la siguiente denuncia ciudadana.',
    facts,
    petition: [
      'Verificar los hechos descritos dentro del ámbito de sus competencias.',
      'Adelantar, si hay lugar a ello, las actuaciones administrativas correspondientes.',
      'Informarme sobre el trámite dado a esta solicitud. Si no es la entidad competente, remitirla a ' +
        'la autoridad que corresponda e informarme de ello.',
    ],
    annexes,
    notifications: `Recibiré notificaciones en el correo ${report.requester_email}${phone}.`,
    closing: 'Atentamente,',
    signature: [report.requester_name, `${report.requester_doc_type} ${report.requester_doc_number}`],
    note:
      'Nota: Este documento fue generado con la aplicación AireClaro a partir de un reporte ciudadano. ' +
      'Las observaciones corresponden a lo percibido por el peticionario y no constituyen una medición ' +
      `técnica de emisiones. Reporte n.º ${shortId(report.id)}.`,
  };
}

const numbered = (items) => items.map((item, i) => `${i + 1}. ${item}`).join('\n');

/** The same content as plain text (preview in the app and, later, the email). */
function toPlainText(c) {
  return [
    c.date,
    c.recipient.join('\n'),
    `Asunto: ${c.subject}`,
    c.greeting,
    c.intro,
    `HECHOS\n${numbered(c.facts)}`,
    `PETICIÓN\nSolicito respetuosamente a la entidad:\n${numbered(c.petition)}`,
    `ANEXOS\n${numbered(c.annexes)}`,
    `NOTIFICACIONES\n${c.notifications}`,
    `${c.closing}\n\n${c.signature.join('\n')}`,
    c.note,
  ].join('\n\n');
}

module.exports = { buildRequest, toPlainText, formatDate, formatTime, formatSize, shortId };
