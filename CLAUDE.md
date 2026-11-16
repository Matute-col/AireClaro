# AireClaro — contexto para Claude Code

Lee este archivo completo al iniciar cada sesión. Es corto a propósito: el detalle vive en `docs/`.

## Qué es el proyecto
AireClaro es un sistema de información (app móvil Android + API) para el **reporte ciudadano de emisiones
vehiculares contaminantes en el corredor Soacha–Bogotá**. El usuario captura evidencia (foto o video), la
ubicación y los datos del vehículo, y la app genera una **solicitud tipo PQRSD en PDF** dirigida a la autoridad
ambiental competente.

Es el prototipo funcional (nivel de madurez **TRL 5**) del proyecto de grado de Ingeniería de Sistemas de
Mateo Alejandro Bernal Cardona (UNAD). Mateo es desarrollador junior: **explica brevemente qué haces y por qué**
cuando tomes decisiones, sin sermonear.

## Plazo y prioridad
- Video del prototipo: martes 17 / miércoles 18 de noviembre de 2026. Entrega final: domingo 22 de noviembre.
- **Prioridad absoluta: un flujo que funcione de punta a punta en un celular Android real** (registrarse →
  crear reporte → generar PDF → ver historial) antes que funcionalidades extra.
- Si vas atrasado, recorta en este orden: mapa (RF-10), eliminar reporte, editar perfil, imagen dentro del PDF,
  pruebas automatizadas extra. Ver `docs/07-plan-de-desarrollo.md`.

## Idioma
- Interfaz de usuario, mensajes de error visibles y documentación: **español (Colombia)**.
- Código, nombres de variables/funciones/tablas, rutas del API y mensajes de commit: **inglés**
  (Conventional Commits: `feat:`, `fix:`, `docs:`, `test:`, `chore:`).

## Stack (decidido; no lo cambies sin avisar y sin registrarlo en `docs/04-arquitectura-y-stack.md`)
- **App:** Flutter (Dart), solo Android en este alcance. Mapas con `flutter_map` + OpenStreetMap.
- **API:** Node.js (LTS) + Express. Autenticación con JWT. Validación con `zod`.
- **Base de datos:** PostgreSQL (servicio gestionado gratuito en la nube; ver Sprint 0).
- **PDF:** generado en el servidor con `pdfkit`.
- **Geocodificación inversa:** Nominatim (OpenStreetMap), siempre a través de nuestro API, nunca directo desde la app.
- Control de versiones: Git/GitHub (repositorio público).

## Estructura del repositorio (monorepo)
```
AireClaro/
├── CLAUDE.md
├── README.md
├── .gitignore
├── docs/          # planificación, diseño, pruebas, progreso (fuente de verdad)
├── backend/       # API Node.js
└── app/           # app Flutter
```

## Documentos de referencia (en este orden de autoridad)
1. `docs/02-requerimientos.md` — qué debe hacer el sistema (RF/RNF, criterios de aceptación).
2. `docs/03-casos-de-uso.md` — flujos de usuario.
3. `docs/05-modelo-de-datos-y-api.md` — tablas, endpoints y reglas de negocio.
4. `docs/06-diseno-front.md` — pantallas, textos, navegación y estilo.
5. `docs/04-arquitectura-y-stack.md` — decisiones técnicas y estructura de carpetas.
6. `docs/07-plan-de-desarrollo.md` — sprints e historias de usuario. **Trabaja una historia a la vez.**
7. `docs/08-plan-de-pruebas.md` — qué se debe probar y qué evidencia guardar.
8. `docs/09-contexto-ia.md` — protocolo de trabajo contigo y prompts de arranque.
9. `docs/progreso.md` — estado actual. **Léelo al empezar y actualízalo al terminar cada sesión.**

Si el diseño de Figma y `docs/06` difieren, manda Figma (el enlace está en el documento maestro).
Si dos documentos se contradicen, avisa a Mateo antes de elegir.

## Reglas de trabajo
- **Una historia de usuario por vez**, con su criterio de aceptación. Termina, prueba, haz commit, y recién ahí sigue.
- Antes de escribir código en un sprint nuevo, entra en **modo plan** y propón el plan; espera aprobación.
- **No amplíes el alcance.** Fuera de alcance: panel de administrador, recuperación de contraseña, modo sin
  conexión, envío automático de correos, iOS, lectura automática de placas (OCR), medición de emisiones.
- No agregues dependencias sin necesidad. Si agregas una, anótala en `docs/04-arquitectura-y-stack.md`.
- Mantén el código simple y legible: es un proyecto académico que Mateo debe poder explicar.
- Cada tarea termina con: código funcionando + prueba (automática o pasos manuales) + commit pequeño.

## Seguridad (el repositorio es PÚBLICO)
- **Nunca** subas claves, contraseñas, tokens ni cadenas de conexión. Usa variables de entorno.
- Mantén `backend/.env` en `.gitignore` y un `backend/.env.example` sin valores reales.
- Contraseñas con hash (bcrypt). JWT con secreto desde el entorno. `helmet` y límite de peticiones activos.
- La carpeta de archivos subidos (`backend/uploads/`) no se versiona.
- No registres en logs contraseñas, tokens ni datos personales.

## Reglas de servicios externos (OpenStreetMap)
- Mostrar siempre la atribución «© OpenStreetMap contributors» en el mapa.
- Nominatim: máximo 1 petición por segundo, enviar un `User-Agent` identificable (`AireClaro-UNAD/1.0`),
  cachear resultados y no usarlo para autocompletar mientras se escribe.
- Los tiles públicos de OSM son solo para un uso ligero (prototipo/demo).

## Entorno de Mateo
Windows, VS Code, PowerShell. Celular Android físico por USB (depuración activada). Usa comandos que
funcionen en PowerShell y rutas compatibles con Windows. No uses rutas con espacios ni tildes.

## Comandos (se completan al crear cada paquete; mantenlos al día)
- Backend (desde `backend/`): `npm install` · `npm run dev` · `npm test` · `npm run migrate`
- App (desde `app/`): `flutter pub get` · `flutter run` · `flutter test` · `flutter analyze`
- Ver dispositivos: `flutter devices` · Puente al API local por USB: `adb reverse tcp:3000 tcp:3000`

## Definición de terminado (resumen; completa en `docs/07`)
Funciona en el celular real · cumple el criterio de aceptación · tiene prueba · `flutter analyze` y
`npm test` sin errores · commit hecho · `docs/progreso.md` actualizado.
