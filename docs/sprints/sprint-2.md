# Sprint 2 · Flujo de creación de reporte

**Meta:** el usuario crea un reporte completo (evidencia, vehículo, ubicación, peticionario, autoridad) y lo ve en su historial.

## Backlog
US-05, US-06, US-07, US-08, US-09, US-10, US-11.

## Definición de hecho
- `POST /reports` multipart con validaciones, `GET /reports`, `GET /reports/:id`, `GET /geo/reverse`, `GET /authorities`.
- Reglas de autoridad probadas con coordenadas de Soacha y Bogotá; Nominatim con cache y límite.
- Pruebas automáticas de creación y de propiedad de recursos.
- Flujo probado en el celular con GPS y cámara reales. Tag `v0.2-sprint2`.

## Revisión (al terminar)
Cerrado el 16-nov-2026.

- Qué se logró:
  - **US-05 Evidencia:** foto, video (≤ 15 s al grabar) y galería; máx. 3 archivos; el API verifica el tipo real por
    los primeros bytes, los límites (8 MB foto, 25 MB video) y guarda con nombres UUID.
  - **US-06 Vehículo:** tipo, placa `ABC123`/`ABC12D` normalizada, color del humo y descripción ≤ 500.
  - **US-07 Ubicación:** GPS, mapa OSM con pin movible, fecha y hora fijas, `GET /geo/reverse` con Nominatim
    (1 petición/s, caché 24 h, `User-Agent`) y la regla de autoridad sobre campos administrativos; consulta real:
    Soacha → CAR, Bogotá → SDA. `GET /authorities` sin exponer correos.
  - **US-08 Peticionario:** precargado del perfil, editable solo para el reporte.
  - **US-09 Revisión y creación:** autoridad sugerida con «Cambiar»; `POST /reports` guarda reporte y evidencia en
    una sola transacción y borra archivos ante cualquier error; el dueño sale del token.
  - **US-10 Mis reportes:** lista paginada, miniaturas autenticadas, chips de estado y número en Inicio.
  - **US-11 Detalle:** carrusel, datos, mapa pequeño, autoridad y estado; prueba de propiedad: otro usuario → 404
    igual que un reporte inexistente (también para la evidencia).
  - Mejoras transversales: `pool.js` con `LOG_ERROR_DETAILS`; límite global de 300 peticiones/15 min.
  - Pruebas: 117 del API (`npm test`) y 76 de la app (`flutter test`), `flutter analyze` sin problemas; pruebas
    (a)–(d) aprobadas en el celular. Revisión de seguridad limpia antes del push.
- Qué quedó pendiente:
  - La vista previa y el PDF (Sprint 3): por ahora, tras crear un reporte se abre su detalle.
  - Reproducción de video en la app (fuera de alcance: sin `video_player`).
  - Mapa de reportes, información, envío por correo y portal (Sprint 3).

## Retrospectiva
- Qué funcionó:
  - Una historia por commit y cuatro puntos de control en el celular: los fallos se encontraron pronto.
  - Probar el cliente de Nominatim con reloj y `fetch` falsos (sin red) y validar la regla con una consulta real.
  - Pruebas de widget que encontraron un fallo real (el mapa se reconstruía con un controlador viejo).
  - Helpers compartidos de pruebas del API (`tests/helpers/reports.js`).
- Qué mejorar:
  - Comandos largos de Bash con comillas fallaron dos veces; escribir archivos con la herramienta es más seguro.
  - Fijar finales de línea con `.gitattributes` para evitar diffs de CRLF/LF.
  - Guardar el orden de la evidencia (columna de posición) si en el futuro importa cuál es la miniatura.
  - Revisar antes si un endpoint planeado para una historia lo necesita otra (la evidencia se adelantó a US-10).
