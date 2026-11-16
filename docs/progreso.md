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
| TS-01 | Hecha | c46665b | `GET /api/health`, helmet, límites, formato de errores; 5 pruebas con jest |
| TS-02 | En curso | 3c7d8c0 | Migraciones escritas; falta ejecutar `npm run migrate` en Neon cuando Mateo pegue `DATABASE_URL` |
| TS-03 | Pendiente | | |
| US-01…US-22 | Pendiente | | |

## Decisiones tomadas durante el desarrollo
(Fecha · decisión · motivo)
- 16-nov-2026 · Semillas de autoridades como segunda migración (D-15 en `docs/04`) · un solo comando, versionado.
- 16-nov-2026 · Se conserva `users.updated_at` del SQL y se corrige el diagrama ER de `docs/05` · lo usará `PUT /me`.
- 16-nov-2026 · `npm run migrate` lee `DATABASE_URL` desde `backend/.env` (`--envPath`); probado que un error de conexión no imprime la contraseña.

## Problemas abiertos
(Descripción · estado)
- Por confirmar: si `pg` acepta `channel_binding=require` de la cadena de Neon · se verifica al migrar.
- `NOMINATIM_USER_AGENT` en `backend/.env` lleva un marcador `<tu-correo>` · Mateo lo completa a mano.

## Proveedor de base de datos elegido
(Se registra en el Sprint 0; **sin** la cadena de conexión.)
