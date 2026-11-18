# Progreso

Documento vivo. Claude Code lo actualiza al cerrar cada sesión.

**Fecha límite de la actividad:** domingo 22 de noviembre de 2026. **Video:** a más tardar el día siguiente al inicio.

## Estado general
| Bloque | Estado | Notas |
|---|---|---|
| Planificación (docs 01–09) | Hecho | Ruta híbrida de envío aprobada (US-21/22). Correos y portales de autoridades verificados por Mateo (16-nov-2026). Pendiente: validar la regla de asignación de autoridad (`docs/05`) |
| Sprint 0 · Entorno | Pendiente | |
| Sprint 1 · Backend base y autenticación | Hecho | Rama `sprint-1`. Probado en el celular el 16-nov-2026. Pendiente con aprobación de Mateo: push, merge a `main` y tag `v0.1-sprint1` |
| Sprint 2 · Flujo de reporte | Hecho | Rama `sprint-2`, cerrado el 16-nov-2026: pruebas (a)–(d) aprobadas en el celular; merge a `main` y tag `v0.2-sprint2`. Revisión y retrospectiva en `docs/sprints/sprint-2.md` |
| Sprint 3 · PDF, mapa, pruebas | En curso | Rama `sprint-3`. Pruebas CP y video desde el jueves 19-nov; entrega el domingo 22-nov |
| Validación TRL 5 y video | Pendiente | |

## Historias
| ID | Estado (Pendiente / En curso / Hecha) | Commit | Notas |
|---|---|---|---|
| TS-01 | Hecha | 5e8a585 | `GET /api/health`, helmet, límites, formato de errores; 5 pruebas con jest |
| TS-02 | Hecha | 5e90df1 | Migraciones aplicadas en Neon el 16-nov-2026: 4 tablas + 3 autoridades con `email_verified=false` |
| TS-03 | Hecha | eb812fd | App Flutter en `app/` (id `com.aireclaro.app`): tema M3, `go_router`, `dio` con token y manejo de 401, `flutter_secure_storage`, validadores iguales al API. URL del API por `--dart-define=API_BASE_URL` |
| US-01 | Hecha | eb47f5c, ec86672 | API: `POST /api/auth/register`. App: pantalla de registro con consentimiento y política (Ley 1581). Probado en el celular el 16-nov-2026: botón deshabilitado, contraseñas distintas, registro válido, correo duplicado, API apagado |
| US-02 | Hecha | 3d02e25, 224abe7 | App: login, `/splash` que valida el token con `GET /me` (sin red → «Reintentar»), 401 → login con «Tu sesión expiró». Probado en el celular el 16-nov-2026 |
| US-03 | Hecha | 1a1bd53, 26d96a0 | App: Perfil, editar (nombre, documento, teléfono; correo solo lectura), política y cerrar sesión con confirmación. Probado en el celular el 16-nov-2026 |
| US-04 | Hecha | fb93657 | Bienvenida, Inicio y barra inferior (`StatefulShellRoute`). Mapa, Mis reportes e Info son pantallas «Muy pronto»; «Nuevo reporte» muestra un aviso hasta el Sprint 2. La tarjeta «Mis reportes» aún no muestra el número (llega con `GET /reports`, US-10). Probado en el celular el 16-nov-2026 |
| US-05 | Hecha | 6e0baad | App: paso 1 (foto, video ≤ 15 s, galería; máx. 3; miniaturas; tarjeta «Video» con tamaño). API: `multer` a carpeta temporal, nombres UUID, tipo real por bytes iniciales, límites 8/25 MB. Prueba (a) en el celular aprobada el 16-nov-2026 (cámara sin permiso, corte de video a 15 s) |
| US-06 | Hecha | 680709c | App: paso 2 (tipo, placa ABC123/ABC12D, humo, descripción ≤ 500). API: esquema `zod` del vehículo. Prueba (a) aprobada el 16-nov-2026 |
| US-07 | Hecha | ceea7a3 | API: `GET /geo/reverse` (Nominatim con cola de 1 petición/s, caché 24 h, `User-Agent`), regla de autoridad sobre campos administrativos, `GET /authorities`. App: paso 3 con GPS, mapa OSM, pin movible, dirección, fecha fija. Consulta real: Soacha → CAR, Bogotá → SDA. Prueba (b) aprobada el 16-nov-2026 (11/11) |
| US-08 | Hecha | 4f0c7f4 | App: paso 4 precargado del perfil y editable solo para el reporte. API: mismas reglas del perfil. Prueba (c) aprobada el 16-nov-2026 |
| US-09 | Hecha | f246904 | API: `POST /reports` multipart en una transacción (archivos a `reports/<id>/`, limpieza ante cualquier error, dueño desde el token, autoridad elegida o regla de `docs/05`). App: revisión con mapa pequeño, autoridad sugerida y «Cambiar», progreso de subida, «Reporte creado» en Inicio. Prueba (c) aprobada el 16-nov-2026 (evidencia en `backend/uploads/reports/<id>/`) |
| US-10 | Hecha | 3d34ebd | API: `GET /reports` (solo los del usuario, más reciente primero, `page/limit/status`, miniatura) y `GET /reports/:id/media/:mediaId` solo para el dueño (404 si no). App: «Mis reportes» con miniaturas autenticadas, chips de estado, paginación al desplazar, recarga, vacío y error; número en Inicio. Prueba (d) aprobada el 16-nov-2026 |
| US-11 | Hecha | c40a929 | API: `GET /reports/:id` con prueba de propiedad (otro usuario → 404 igual que inexistente; sin correo de la autoridad ni rutas de archivo). App: detalle con carrusel, datos, mapa pequeño, autoridad, estado y peticionario; tras crear un reporte se abre su detalle. Prueba (d) aprobada el 16-nov-2026 |
| US-12 | Hecha | a7c2bef, a378120 | API: `GET /reports/:id/pqrsd` (texto, autoridad, placa, estado, modo de correo) y `.pdf` con `pdfkit` según `docs/05` y la Ley 1755 art. 16 (sección ANEXOS, encabezado solo con fecha, primera foto ≈ 6 cm). Solo el dueño (404). Pruebas leen el PDF real: tildes, eñ y signos. ANEXOS con etiqueta según el canal. Prueba (e) aprobada el 17-nov-2026 |
| US-13 | Hecha | 3c2e941 | App: vista previa tras crear el reporte, «Descargar PDF» (abre el visor), «Compartir» (menú del teléfono), «Continuar» al detalle; en el detalle «Ver solicitud», PDF y «Abrir video» (CP-07). Prueba (e) aprobada el 17-nov-2026 |
| US-14…US-22 | Pendiente | | |
| US-23 | Hecha (falta prueba en celular) | aa7f81f | Agregada por Mateo el 17-nov-2026 (RF-19, CP-30). App: 4 fotogramas JPEG por video (10/35/65/90 %, ≤ 300 KB) enviados en `frames_v<N>`; si falla, sigue sin ellos y avisa. API: validación por bytes y tamaño, máx. 4 por video, fuera del límite de 3; guardados como evidencia derivada con posición; PDF con «Fotogramas del video N (4)» en cuadrícula; detalle con la fila de fotogramas. Migración aplicada en `test` y, con autorización de Mateo, en la base principal el 18-nov-2026 (estructura idéntica; los 4 reportes existentes cargan detalle, texto y PDF). Prueba (f) pendiente |

## Decisiones tomadas durante el desarrollo
(Fecha · decisión · motivo)
- 16-nov-2026 · Semillas de autoridades como segunda migración (D-15 en `docs/04`) · un solo comando, versionado.
- 16-nov-2026 · Se conserva `users.updated_at` del SQL y se corrige el diagrama ER de `docs/05` · lo usará `PUT /me`.
- 16-nov-2026 · `npm run migrate` lee `DATABASE_URL` desde `backend/.env` (`--envPath`); probado que un error de conexión no imprime la contraseña.

- 16-nov-2026 · Commits con correo *noreply* de GitHub (se reescribió el autor de los 4 primeros commits de `sprint-1` antes del push) · no exponer el correo personal en el repositorio público.
- 16-nov-2026 · El manejador de errores registra solo el código del error fuera de `development` · los mensajes del driver pueden incluir datos personales.

- 16-nov-2026 · Pruebas contra una rama `test` de Neon (`TEST_DATABASE_URL`); jest se detiene si apunta al mismo host que la base principal y vacía `users` solo en esa rama · no ensuciar la base principal.
- 16-nov-2026 · Jest corre en serie (`--runInBand`) · evitar que dos archivos de pruebas se borren los datos entre sí.
- 16-nov-2026 · Login compara contra un hash ficticio si el correo no existe · mismo mensaje y tiempo de respuesta.
- 16-nov-2026 · `PUT /me` reemplaza el perfil completo (sin `phone` → null); `doc_number` se guarda en mayúsculas.

- 16-nov-2026 · App: Flutter 3.50 trae Material como paquete aparte (`material_ui`); se usa el import de la plantilla oficial · es lo que genera `flutter create`.
- 16-nov-2026 · App: `android:allowBackup="false"` · recomendado por `flutter_secure_storage`; el token cifrado no se restaura en otro equipo.
- 16-nov-2026 · App: Riverpod sin generación de código y dobles de prueba escritos a mano (sin paquetes de mocks) · menos dependencias y más fácil de explicar.
- 16-nov-2026 · App: HTTP sin cifrar solo en los manifiestos `debug` y `profile`; prueba en el celular con `adb reverse tcp:3000 tcp:3000`.

- 16-nov-2026 · App: ruta `/splash` adicional para validar la sesión al abrir (D-17 en `docs/04`).
- 16-nov-2026 · Autoridades verificadas por Mateo: SDA y CAR con `email_verified=true`, SDM sin correo (solo portal). Nueva migración `1794876283606_update-authorities-verified`, aplicada primero en `test` (`npm test` en verde) y luego en la base principal · los datos de autoridades solo cambian por migración. `MAIL_MODE` sigue en `test`.

- 16-nov-2026 · Límite global de peticiones 300 cada 15 min (antes 100); `/auth/*` sigue en 10 · cada miniatura es una petición (`docs/05`).
- 16-nov-2026 · Sin `video_player`: los videos se muestran como tarjeta «Video» con tamaño; el límite de 15 s lo aplica la cámara al grabar y el tope real es 25 MB (`docs/02`, `docs/06`).
- 16-nov-2026 · No se declara el permiso `CAMERA`: `image_picker` usa la cámara del sistema (`docs/04`).
- 16-nov-2026 · Después de crear un reporte: Inicio con «Reporte creado» (US-09); al detalle desde US-11; a la vista previa en el Sprint 3.

- 16-nov-2026 · Regla de autoridad solo sobre campos administrativos de Nominatim (no calle ni barrio; ambiguo → sin sugerencia) · los datos reales traen un barrio «UPZs de Bogotá» (`docs/05`).

- 16-nov-2026 · `GET /reports/:id/media/:mediaId` se adelantó a US-10 (lo necesitan las miniaturas); `GET /reports/:id` en US-11.
- 16-nov-2026 · Tras crear un reporte: Inicio con «Reporte creado» y el detalle encima (desde US-11). En el Sprint 3 pasará a la vista previa.

## Sprint 2 · Revisión y retrospectiva (resumen; detalle en `docs/sprints/sprint-2.md`)
- **Qué se hizo:** US-05…US-11 de punta a punta (API + app): evidencia, vehículo, ubicación con mapa y Nominatim,
  peticionario, revisión con autoridad y `POST /reports` en una transacción, «Mis reportes» y detalle. 117 pruebas
  del API y 76 de la app; cuatro pruebas en el celular (a)–(d) aprobadas.
- **Qué salió bien:** una historia por commit; pruebas de propiedad (404) y de limpieza de archivos; la consulta
  real a Nominatim confirmó la regla (Soacha → CAR, Bogotá → SDA); las pruebas de widget detectaron un fallo real
  del mapa antes de llegar al celular.
- **Qué mejorar:** comandos largos de Bash fallaron dos veces por comillas (se usaron archivos en su lugar); finales
  de línea mezclados (falta `.gitattributes`); `.vscode/extensions.json` no está ignorado (solo sin commit).
- **Para el Sprint 3:** US-12 (texto y PDF), US-13 (vista previa, descarga y compartir), US-14 (confirmación y
  «marcar como enviado»), **US-21 (envío por correo, siempre `MAIL_MODE=test`)**, US-22 (portal oficial), US-15
  (mapa), US-16, US-17, US-19, US-20 y, si hay tiempo, US-18. Tras crear un reporte se irá a la vista previa.

- 17-nov-2026 · Decisiones del Sprint 3 registradas en `docs/02`–`06` y `CLAUDE.md` (24171d2): fechas, encabezado del PDF solo con fecha, ANEXOS, mapa con tipo y fecha (RB-07), portal para toda autoridad con `portal_url`, SMTP con Gmail y contraseña de aplicación.
- 17-nov-2026 · ANEXOS del PDF en orden fijo: fotos y luego videos · los nombres guardados son UUID aleatorios y el orden cambiaba entre ejecuciones.
- 17-nov-2026 · Las pruebas leen el PDF con `pdf-parse` en un proceso de Node aparte (`tests/helpers/pdfText.js`) · Jest no permite el `import()` dinámico que usa `pdfjs`.
- 17-nov-2026 · Mateo recreó la rama `test` de Neon (conexión directa, sin pooler) y actualizó `TEST_DATABASE_URL`; la credencial anterior daba `28P01`.

- 17-nov-2026 · ANEXOS según el canal: PDF descargado/compartido/portal → «Disponible a solicitud del peticionario»; PDF del correo → «Archivo adjunto al correo» solo si la evidencia viaja adjunta (≤ 15 MB) · nunca afirmar un adjunto que no existe.

- 17-nov-2026 · US-23 usa `video_player` solo para leer la duración del video (revisa la decisión «sin `video_player`» del 16-nov) y `fc_native_video_thumbnail` para extraer los fotogramas (`docs/04`).
- 17-nov-2026 · Los fotogramas viajan en campos `frames_v<N>` (N = posición del video en `files`); su orden en el campo es su posición · sin leer nombres de archivo.

## Problemas abiertos
- Migración `1794970815342_add-video-frames` en la base principal · resuelto el 18-nov-2026 con autorización de Mateo: antes estaban aplicadas las 3 migraciones previas; después, `report_media` quedó idéntica a la rama `test` (columnas, CHECK e índices) y los 4 reportes existentes cargan detalle, texto y PDF.
- SMTP sin configurar en `backend/.env` · Mateo lo llena el martes 17 por la mañana (Gmail con contraseña de aplicación; `MAIL_TEST_TO` = su buzón). Bloquea la prueba (f) de US-21, no su desarrollo.
- `.vscode/extensions.json` aparece como «sin seguimiento» porque `.gitignore` lo excluye a propósito de la regla `.vscode/*` · Mateo decidió no subirlo; opcional: agregarlo a `.git/info/exclude` (local).
- La miniatura de «Mis reportes» es una foto cualquiera (siempre la misma) del reporte: `report_media` no guarda el orden de subida · aceptable para el prototipo.
- `backend/src/db/pool.js` registraba `err.message` sin pasar por `LOG_ERROR_DETAILS` · resuelto el 16-nov-2026 (ece1a24).
- Diferencias visuales con Figma sin revisar (Claude no tiene acceso al Figma) · Mateo compara cuando pueda.
(Descripción · estado)
- `channel_binding=require` de Neon funciona con `pg` · resuelto.
- `pg` avisa que `sslmode=require` se trata hoy como `verify-full` y cambiará en pg v9 · opcional: usar `sslmode=verify-full` en `DATABASE_URL` (lo decide Mateo).
 También aplica a `TEST_DATABASE_URL`; el aviso aparece en la salida de `npm test`.
- `NOMINATIM_USER_AGENT` en `backend/.env` lleva un marcador `<tu-correo>` · Mateo lo completa a mano.

## Proveedor de base de datos elegido
(Se registra en el Sprint 0; **sin** la cadena de conexión.)
Neon (PostgreSQL gestionado), conexión con SSL.
