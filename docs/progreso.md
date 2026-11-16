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
| TS-03 | Pendiente | | |
| US-01 | En curso | eb47f5c | API hecha: `POST /api/auth/register` (zod, bcrypt, `consent_at`, 409 correo duplicado). Falta la pantalla en la app |
| US-02 | En curso | 3d02e25 | API hecha: `POST /api/auth/login` con mensaje genérico. Falta la app (sesión persistente) |
| US-03 | En curso | 1a1bd53 | API hecha: `GET/PUT /api/me` (mismas reglas que el registro, el correo no cambia). Falta la app |
| US-04…US-22 | Pendiente | | |

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

## Problemas abiertos
(Descripción · estado)
- `channel_binding=require` de Neon funciona con `pg` · resuelto.
- `pg` avisa que `sslmode=require` se trata hoy como `verify-full` y cambiará en pg v9 · opcional: usar `sslmode=verify-full` en `DATABASE_URL` (lo decide Mateo). También aplica a `TEST_DATABASE_URL`; el aviso aparece en la salida de `npm test`.
- `NOMINATIM_USER_AGENT` en `backend/.env` lleva un marcador `<tu-correo>` · Mateo lo completa a mano.

## Proveedor de base de datos elegido
(Se registra en el Sprint 0; **sin** la cadena de conexión.)
Neon (PostgreSQL gestionado), conexión con SSL.
