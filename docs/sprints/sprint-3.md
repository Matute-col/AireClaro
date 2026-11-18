# Sprint 3 · PDF, mapa, pruebas y cierre

**Meta:** prototipo completo en TRL 5, con evidencias, README y listo para grabar el video.

## Backlog
US-12, US-13, US-14, **US-21 (envío por correo)**, US-22, US-15, US-16, US-17, US-19, US-20 y, si hay tiempo, US-18.

## Definición de hecho
- PDF según la plantilla de `docs/05`; descarga y compartir funcionando en el celular.
- Envío por correo en modo prueba verificado (CP-23…CP-29) con el buzón de prueba; botón al portal oficial.
- Ningún correo real enviado a una autoridad sin decisión explícita de Mateo.
- Mapa con filtros y sin datos sensibles; pantalla de información; estados de error.
- `npm test` y `flutter analyze` sin errores; casos CP-01…CP-22 ejecutados con evidencia en `docs/evidencias/`.
- README con instrucciones de ejecución; APK opcional. Tag `v0.3-sprint3`, luego `v1.0-trl5`.

## Revisión (al terminar)
Cerrado el 18-nov-2026.

- Qué se logró:
  - **US-12 PDF de la solicitud:** texto y PDF con `pdfkit` según `docs/05` y la Ley 1755, art. 16 (autoridad,
    peticionario y notificación, objeto, hechos, ANEXOS, firma), encabezado solo con la fecha, primera foto
    incrustada, nota de alcance; ANEXOS con etiqueta según el canal («Disponible a solicitud del peticionario» o
    «Archivo adjunto al correo» solo si la evidencia viaja adjunta). Pruebas que leen el PDF real (tildes y eñ).
  - **US-13 Vista previa, descargar y compartir:** vista previa tras crear el reporte, PDF descargado con la
    sesión y abierto en el visor, menú «Compartir», «Abrir video» en el detalle (CP-07).
  - **US-21 Envío por correo:** `POST /reports/:id/send` con confirmación; `MAIL_MODE=test` → buzón de prueba con
    `[PRUEBA]`; ciudadano en copia y «responder a»; evidencia adjunta solo si ≤ 15 MB; fotogramas dentro del PDF;
    respuestas 400/404/409/422/502/503. Verificado con Gmail real en modo de prueba (CP-23, CP-25, CP-26).
  - **US-22 y US-14:** «Radicar en el portal oficial» para toda autoridad con portal; pantalla de confirmación con
    el seguimiento (Ley 1755); «Marcar como enviado» (`sent_via = manual`).
  - **US-15 Mapa:** pines de todos los reportes con solo tipo y fecha (RB-07), filtros por tipo y por periodo.
  - **US-16 «¿Cómo funciona?»**, **US-17 revisión de estados** (tabla en `docs/08`), **US-18 eliminar** (sin
    archivos huérfanos), **US-19 evidencias** (`docs/evidencias/` con CP-01…CP-30) y **US-20 README y APK**
    (`--profile`, compilado y verificado).
  - **US-23 Fotogramas del video (agregada por Mateo):** 4 fotogramas JPEG por video (10/35/65/90 %), validados por
    bytes, guardados como evidencia derivada (migración aditiva probada en `test` y aplicada en la principal con
    autorización), mostrados en el detalle y en el PDF.
  - Pruebas: 192 del API, 135 de la app, `flutter analyze` sin problemas; pruebas (e), (f), (g) y (h) aprobadas en el
    celular. Revisión de seguridad limpia antes del push.
- Qué quedó pendiente:
  - Ejecutar los casos CP-01…CP-30 y guardar la evidencia; grabar el video (desde el jueves 19-nov).
  - Probar en el celular el borrado (US-18): está cubierto por pruebas automáticas, sin prueba manual todavía.
  - Opcional: `sslmode=verify-full` en las URL de la base (aviso de `pg`); `.gitattributes` para los finales de línea.

## Retrospectiva
- Qué funcionó:
  - Trabajar por bloques con una prueba en el celular al final de cada uno: los fallos aparecieron pronto.
  - Las pruebas automáticas encontraron errores reales antes del celular: el doble envío de correo con un doble
    toque, el desborde de la tarjeta de video y el orden aleatorio de los anexos.
  - Correo siempre simulado en `npm test` (y host `.invalid`), y primer envío real solo en modo de prueba.
  - Migraciones probadas en la rama `test` (subir, bajar y subir) y aplicadas en la principal solo con autorización.
- Qué mejorar:
  - La credencial de la rama `test` de Neon dejó de funcionar a mitad del sprint: revisar la conexión al empezar.
  - Se escribieron fechas con un día de más en la documentación y hubo que corregirlas.
  - Comandos largos de Bash con comillas fallaron varias veces: mejor scripts en archivos.
  - Finales de línea CRLF/LF mezclados: agregar `.gitattributes`.
  - US-23 entró a mitad del sprint: alcance nuevo con poco margen antes de las pruebas finales.
