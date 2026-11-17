# Progreso

Documento vivo. Claude Code lo actualiza al cerrar cada sesión.

**Fecha límite de la actividad:** domingo 22 de noviembre de 2026. **Video:** a más tardar el día siguiente al inicio.

## Estado general
| Bloque | Estado | Notas |
|---|---|---|
| Planificación (docs 01–09) | Hecho | Ruta híbrida de envío aprobada (US-21/22). Correos y portales de autoridades verificados por Mateo (16-nov-2026). Pendiente: validar la regla de asignación de autoridad (`docs/05`) |
| Sprint 0 · Entorno | Pendiente | |
| Sprint 1 · Backend base y autenticación | Hecho | Rama `sprint-1`. Probado en el celular el 16-nov-2026. Pendiente con aprobación de Mateo: push, merge a `main` y tag `v0.1-sprint1` |
| Sprint 2 · Flujo de reporte | En curso | Rama `sprint-2` |
| Sprint 3 · PDF, mapa, pruebas | Pendiente | |
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
| US-07 | Hecha (falta prueba en celular) | ceea7a3 | API: `GET /geo/reverse` (Nominatim con cola de 1 petición/s, caché 24 h, `User-Agent`), regla de autoridad sobre campos administrativos, `GET /authorities`. App: paso 3 con GPS, mapa OSM, pin movible, dirección, fecha fija. Consulta real: Soacha → CAR, Bogotá → SDA. Prueba (b) pendiente |
| US-08…US-22 | Pendiente | | |

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

## Problemas abiertos
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
