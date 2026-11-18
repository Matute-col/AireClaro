const { buildRequest, toPlainText, formatTime } = require('../src/modules/pqrsd/pqrsd.text');

// 14:30 UTC = 9:30 a. m. in Colombia (UTC-5).
const report = {
  id: '3f2a9c1b-0000-4000-8000-000000000000',
  vehicle_type: 'tractomula',
  plate: 'XYZ12A',
  smoke_color: 'negro',
  description: 'Humo denso al subir la pendiente',
  lat: 4.579,
  lng: -74.217,
  address: 'Carrera 3A, Ubaté, Soacha ciudad',
  occurred_at: '2026-11-16T14:30:00Z',
  created_at: '2026-11-16T14:45:00Z',
  requester_name: 'José Peña Núñez',
  requester_doc_type: 'CC',
  requester_doc_number: 'TEST0001',
  requester_email: 'jose@example.com',
  requester_phone: '3000000000',
};
const media = [
  { kind: 'photo', mime_type: 'image/jpeg', size_bytes: 1258291 },
  { kind: 'video', mime_type: 'video/mp4', size_bytes: 3355443 },
];
const authority = { name: 'Corporación Autónoma Regional de Cundinamarca (CAR)' };

describe('request text (US-12, Ley 1755 art. 16)', () => {
  const text = toPlainText(buildRequest(report, media, authority));

  it('1 · authority: addressed to the authority', () => {
    expect(text).toContain('Señores\nCorporación Autónoma Regional de Cundinamarca (CAR)\nCiudad');
  });

  it('2 · requester: full name, document and electronic address for notifications', () => {
    expect(text).toContain('José Peña Núñez\nCC TEST0001');
    expect(text).toContain(
      'Recibiré notificaciones en el correo jose@example.com y en el teléfono 3000000000.',
    );
  });

  it('3 · object of the request (subject and PETICIÓN)', () => {
    expect(text).toContain('Asunto: Denuncia ciudadana por presunta emisión anómala');
    expect(text).toContain('vehículo de placa XYZ12A');
    expect(text).toContain('PETICIÓN\nSolicito respetuosamente a la entidad:\n1. Verificar los hechos');
  });

  it('4 · reasons (HECHOS) with the real report data, in Colombia time', () => {
    expect(text).toContain(
      '1. El día 16 de noviembre de 2026 a las 9:30 a. m., en Carrera 3A, Ubaté, Soacha ciudad ' +
        '(coordenadas 4.57900, -74.21700), observé un vehículo de tipo tractomula con placa XYZ12A ' +
        'que emitía humo de color negro.',
    );
    expect(text).toContain('2. Descripción del peticionario: «Humo denso al subir la pendiente».');
    expect(text).toContain('3. Como soporte se anexan 2 archivos de evidencia (fotografía y video)');
  });

  it('5 · list of documents (ANEXOS), one line per file', () => {
    expect(text).toContain(
      'ANEXOS\n1. Fotografía 1 (JPG, 1,2 MB) – Disponible a solicitud del peticionario.\n' +
        '2. Video 1 (MP4, 3,2 MB) – Disponible a solicitud del peticionario.',
    );
  });

  it('6 · signature: closing, name and document', () => {
    expect(text).toContain('Atentamente,\n\nJosé Peña Núñez\nCC TEST0001');
  });

  it('header has only the generation date (no city)', () => {
    expect(text.split('\n')[0]).toBe('16 de noviembre de 2026');
  });

  it('scope note and short report number', () => {
    expect(text).toContain('no constituyen una medición técnica de emisiones. Reporte n.º 3F2A9C1B.');
  });

  it('factual tone: never says that the vehicle «incumple»', () => {
    expect(text.toLowerCase()).not.toMatch(/incumpl|infractor|culpable/);
  });

  it('without description, phone or address the text stays correct', () => {
    const minimal = toPlainText(
      buildRequest(
        { ...report, description: null, requester_phone: null, address: null },
        [media[1]],
        authority,
      ),
    );
    expect(minimal).not.toContain('Descripción del peticionario');
    expect(minimal).toContain('Recibiré notificaciones en el correo jose@example.com.');
    expect(minimal).toContain('en el punto de coordenadas 4.57900, -74.21700');
    expect(minimal).toContain('2. Como soporte se anexan 1 archivo de evidencia (video)');
  });

  it('times use normal spaces (the PDF font has no narrow no-break space)', () => {
    expect(formatTime(new Date('2026-11-16T19:05:00Z'))).toBe('2:05 p. m.');
    expect(text).not.toMatch(/[\u00a0\u202f]/);
  });
});

describe('ANEXOS order', () => {
  it('photos first, then videos, whatever the stored order', () => {
    const text = toPlainText(buildRequest(report, [media[1], media[0]], authority));
    expect(text).toMatch(/ANEXOS\n1\. Fotografía 1 \(JPG[^\n]*\n2\. Video 1 \(MP4/);
  });
});

describe('ANEXOS label by delivery channel (Mateo, 17-nov-2026)', () => {
  const annexLines = (delivery) =>
    toPlainText(buildRequest(report, media, authority, delivery))
      .split('ANEXOS\n')[1]
      .split('\n\n')[0]
      .split('\n');

  it('downloaded, shared or portal PDF: «Disponible a solicitud del peticionario»', () => {
    for (const line of annexLines()) {
      expect(line).toMatch(/– Disponible a solicitud del peticionario\.$/);
    }
  });

  it('PDF sent by email with the evidence attached (≤ 15 MB): «Archivo adjunto al correo»', () => {
    for (const line of annexLines({ channel: 'email', evidenceAttached: true })) {
      expect(line).toMatch(/– Archivo adjunto al correo\.$/);
    }
  });

  it('PDF sent by email without the evidence (> 15 MB): never claims it is attached', () => {
    for (const line of annexLines({ channel: 'email', evidenceAttached: false })) {
      expect(line).toMatch(/– Disponible a solicitud del peticionario\.$/);
    }
  });

  it('a download never says «adjunto al correo», even if evidenceAttached is passed', () => {
    const lines = annexLines({ channel: 'download', evidenceAttached: true });
    expect(lines.join('\n')).not.toContain('adjunto');
  });
});

describe('US-23 · video frames in ANEXOS', () => {
  const withFrames = [
    media[0],
    {
      ...media[1],
      id: 'video-1',
      frames: [1, 2, 3, 4].map((position) => ({ id: `f${position}`, position, size_bytes: 40000 })),
    },
  ];

  it('adds «Fotogramas del video 1 (4)» right after the video, inside this document', () => {
    const lines = toPlainText(buildRequest(report, withFrames, authority, { channel: 'email', evidenceAttached: true }))
      .split('ANEXOS\n')[1]
      .split('\n\n')[0]
      .split('\n');

    expect(lines[1]).toBe('2. Video 1 (MP4, 3,2 MB) – Archivo adjunto al correo.');
    expect(lines[2]).toBe(
      '3. Fotogramas del video 1 (4) – fotogramas extraídos automáticamente del video; ' +
        'se muestran en este documento.',
    );
    // Frames travel inside the PDF: never «adjunto» nor «disponible a solicitud».
    expect(lines[2]).not.toMatch(/adjunto|solicitud/);
  });

  it('reports which video each group of frames belongs to (for the PDF grid)', () => {
    const content = buildRequest(report, withFrames, authority);
    expect(content.frameGroups).toEqual([{ videoNumber: 1, sourceMediaId: 'video-1', count: 4 }]);
    expect(buildRequest(report, media, authority).frameGroups).toEqual([]);
  });
});
