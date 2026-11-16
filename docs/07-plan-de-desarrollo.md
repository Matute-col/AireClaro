# 07 · Plan de desarrollo

Metodología: Scrum comprimido en sprints de pocas horas, con ciclo de vida de software (SDLC) por sprint.
Una historia a la vez. Cada historia termina con su «definición de hecho» y un commit.

## Sprint 0 · Preparación del equipo (Mateo, en Windows)

Orden pensado para que el backend pueda arrancar mientras Flutter se descarga e instala.
**Verifica siempre la guía oficial vigente de cada herramienta.**

- [ ] Git para Windows instalado; `git config` con nombre y correo; repositorio clonado en `C:\proyectos\AireClaro`
      (sin OneDrive, sin espacios ni tildes).
- [ ] Visual Studio Code + extensión **Claude Code**.
- [ ] Node.js LTS (verificar con `node -v` y `npm -v`).
- [ ] Proveedor de PostgreSQL en la nube elegido (condiciones verificadas el mismo día), base `aireclaro` creada,
      cadena de conexión guardada **solo** en `backend/.env`.
- [ ] Flutter SDK + Android Studio (SDK de Android y herramientas de línea de comandos); `flutter doctor` sin
      errores relevantes; licencias aceptadas.
- [ ] Celular: opciones de desarrollador activadas, depuración USB activa, `adb devices` lo lista.
- [ ] Paquete de planificación copiado en la raíz del repositorio; primer commit y push.
- [ ] Proveedor de correo (SMTP) elegido con condiciones verificadas el mismo día, y buzón de prueba propio
      para `MAIL_TEST_TO`. Credenciales solo en `backend/.env`.
- [ ] **Mateo:** verificar en los sitios oficiales los correos y portales de CAR, SDA y SDM (`docs/05`).

**Hecho cuando:** `node -v`, `flutter doctor`, `adb devices` y la conexión a la BD responden bien.
Evidencia: capturas en `docs/evidencias/sprint0/`.

## Historias de usuario

| ID | Historia | RF | Prioridad | Sprint |
|---|---|---|---|---|
| TS-01 | Esqueleto del backend (Express, config, errores, `/health`, límites, helmet) | RNF-03 | Alta | 1 |
| TS-02 | Migración inicial y semillas de autoridades | — | Alta | 1 |
| TS-03 | Esqueleto de la app (tema, router, cliente HTTP, almacenamiento seguro) | — | Alta | 1 |
| US-01 | Registro con consentimiento | RF-01, RF-11 | Alta | 1 |
| US-02 | Iniciar y cerrar sesión (sesión persistente) | RF-01 | Alta | 1 |
| US-03 | Ver y editar perfil | RF-13 | Media | 1 |
| US-04 | Bienvenida, inicio y barra de navegación | — | Alta | 1 |
| US-05 | Paso 1: evidencia (foto, video, galería) | RF-02 | Alta | 2 |
| US-06 | Paso 2: vehículo, placa, humo, descripción | RF-04, RF-05 | Alta | 2 |
| US-07 | Paso 3: ubicación, mapa, dirección | RF-03 | Alta | 2 |
| US-08 | Paso 4: datos del peticionario | RF-01 | Alta | 2 |
| US-09 | Revisión, autoridad y creación del reporte | RF-07 | Alta | 2 |
| US-10 | Mis reportes | RF-09 | Alta | 2 |
| US-11 | Detalle del reporte | RF-15 | Media | 2 |
| US-12 | Texto y PDF de la solicitud | RF-06 | Alta | 3 |
| US-13 | Vista previa, descarga y compartir | RF-08 | Alta | 3 |
| US-14 | Confirmación y «marcar como enviado» | RF-08 | Media | 3 |
| US-15 | Mapa de reportes con filtros | RF-10 | Media | 3 |
| US-16 | Pantalla «¿Cómo funciona?» | RF-14 | Media | 3 |
| US-17 | Estados de error, vacíos y carga | RNF-01 | Media | 3 |
| US-18 | Eliminar reporte | RF-16 | Baja | 3 |
| US-19 | Pruebas automáticas y análisis estático | RNF-10 | Media | 3 |
| US-20 | README, APK y evidencias | RNF-07 | Media | 3 |
| US-21 | Enviar la solicitud por correo a la autoridad (modo prueba/live, confirmación, adjuntos) | RF-17, RF-08 | Alta | 3 |
| US-22 | Botón «Radicar en el portal oficial» | RF-18 | Media | 3 |

Criterios de aceptación: los de `docs/02` (RF) y los pasos de `docs/03` (UC).

## Cronograma comprimido

| Bloque | Meta | Tag de Git |
|---|---|---|
| Sprint 0 | Entorno listo | — |
| Sprint 1 | Backend base + autenticación + app base con login y registro | `v0.1-sprint1` |
| Sprint 2 | Flujo completo de creación de reporte, historial y detalle | `v0.2-sprint2` |
| Sprint 3 | PDF, mapa, información, pruebas, pulido, APK | `v0.3-sprint3` |
| Validación | Casos de `docs/08`, evidencias y video | `v1.0-trl5` |

Calendario: hoy se planifica y se prepara el entorno, y se construye mientras alcance el tiempo; la
grabación del video es lo más tarde mañana. Si el tiempo no alcanza, se aplica el **orden de recorte**.

## Orden de recorte (de lo primero que se sacrifica a lo último)
1. US-18 Eliminar reporte · 2. APK (se demuestra por cable) · 3. Filtros del mapa · 4. US-03 Editar perfil ·
5. US-16 Información · 6. US-22 Botón al portal · 7. US-11 Detalle (queda la lista) · 8. Miniatura del PDF.
**Nunca se recorta:** registro/login, flujo de reporte, autoridad, PDF, **envío por correo (US-21)**, historial,
seguridad del repositorio.

## Riesgos

| Riesgo | Mitigación |
|---|---|
| Instalación de Flutter lenta o con errores | Empezar por Node y el backend; seguir la guía oficial; `flutter doctor` |
| BD en la nube no disponible | Plan B: PostgreSQL local |
| Nominatim lento o bloqueado | Cache, límite de 1 petición/s, selección manual de autoridad |
| Fallos con el GPS en interior | Probar al aire libre; permitir mover el pin |
| Correo rechazado o enviado a una dirección equivocada | `MAIL_MODE=test` por defecto; `email_verified`; probar con buzón propio |
| Límites del proveedor de correo gratuito | Verificar condiciones el día; adjuntar solo PDF si la evidencia es pesada |
| Secretos subidos al repo público | `.gitignore`, `.env.example`, revisión antes de cada push (`docs/09`) |
| Falta de tiempo | Orden de recorte; sprints pequeños; nunca dejar la rama principal rota |

## Flujo de Git
Rama `main` estable. Una rama por sprint (`sprint-1`, …) y se fusiona al terminar. Commits pequeños y en inglés,
estilo `feat:`, `fix:`, `docs:`, `test:`, `chore:`. Tag al cerrar cada sprint.

## Definición de hecho (por historia)
- Cumple los criterios de aceptación y no rompe lo anterior.
- `npm test` y `flutter analyze` sin errores en lo tocado.
- Sin secretos ni datos personales en código, logs o commits.
- `docs/progreso.md` actualizado y commit realizado.
- Probado en el celular físico cuando toca la app.
