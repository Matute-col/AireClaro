# Progreso

Documento vivo. Claude Code lo actualiza al cerrar cada sesión.

**Fecha límite de la actividad:** domingo 22 de noviembre de 2026. **Video:** a más tardar el día siguiente al inicio.

## Estado general
| Bloque | Estado | Notas |
|---|---|---|
| Planificación (docs 01–09) | Hecho | Ruta híbrida de envío aprobada (US-21/22). Pendiente: Mateo verifica correos/portales y reglas de autoridad |
| Sprint 0 · Entorno | Pendiente | |
| Sprint 1 · Backend base y autenticación | En curso | Rama `sprint-1` |
| Sprint 2 · Flujo de reporte | Pendiente | |
| Sprint 3 · PDF, mapa, pruebas | Pendiente | |
| Validación TRL 5 y video | Pendiente | |

## Historias
| ID | Estado (Pendiente / En curso / Hecha) | Commit | Notas |
|---|---|---|---|
| TS-01 | Hecha | 5e8a585 | `GET /api/health`, helmet, límites, formato de errores; 5 pruebas con jest |
| TS-02 | Hecha | 5e90df1 | Migraciones aplicadas en Neon el 16-nov-2026: 4 tablas + 3 autoridades con `email_verified=false` |
| TS-03 | Hecha | eb812fd | App Flutter en `app/` (id `com.aireclaro.app`): tema M3, `go_router`, `dio` con token y manejo de 401, `flutter_secure_storage`, validadores iguales al API. URL del API por `--dart-define=API_BASE_URL` |
| US-01 | Hecha | eb47f5c, ec86672 | API: `POST /api/auth/register`. App: pantalla de registro con consentimiento y política (Ley 1581). Probado en el celular el 16-nov-2026: botón deshabilitado, contraseñas distintas, registro válido, correo duplicado, API apagado |
| US-02 | Hecha (falta prueba en celular) | 3d02e25, 224abe7 | App: login, `/splash` que valida el token con `GET /me` (sin red → «Reintentar»), 401 → login con «Tu sesión expiró». Pruebas automáticas; pendiente la prueba en el celular junto con US-04 |
| US-03 | Hecha (falta prueba en celular) | 1a1bd53, 26d96a0 | App: Perfil, editar (nombre, documento, teléfono; correo solo lectura), política y cerrar sesión con confirmación. Pendiente la prueba en el celular |
| US-04 | Hecha (falta prueba en celular) | fb93657 | Bienvenida, Inicio y barra inferior (`StatefulShellRoute`). Mapa, Mis reportes e Info son pantallas «Muy pronto»; «Nuevo reporte» muestra un aviso hasta el Sprint 2. La tarjeta «Mis reportes» aún no muestra el número (llega con `GET /reports`, US-10) |
| US-05…US-22 | Pendiente | | |

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

## Problemas abiertos
(Descripción · estado)
- `channel_binding=require` de Neon funciona con `pg` · resuelto.
- `pg` avisa que `sslmode=require` se trata hoy como `verify-full` y cambiará en pg v9 · opcional: usar `sslmode=verify-full` en `DATABASE_URL` (lo decide Mateo).
 También aplica a `TEST_DATABASE_URL`; el aviso aparece en la salida de `npm test`.
- `NOMINATIM_USER_AGENT` en `backend/.env` lleva un marcador `<tu-correo>` · Mateo lo completa a mano.

## Proveedor de base de datos elegido
(Se registra en el Sprint 0; **sin** la cadena de conexión.)
Neon (PostgreSQL gestionado), conexión con SSL.
