# Documentación de AireClaro

Esta carpeta es la **fuente de verdad** del proyecto y la evidencia del ciclo de vida del software
(planificación, análisis, diseño, implementación, pruebas y despliegue) que exige la Fase 4 del curso
Proyecto de Grado (UNAD).

## Ciclo de vida del software → documentos

| Fase del ciclo de vida | Qué se hace | Documentos |
|---|---|---|
| Planificación | Visión, alcance, plan, contexto para IA | `01-vision-y-alcance.md`, `07-plan-de-desarrollo.md`, `09-contexto-ia.md`, `../CLAUDE.md` |
| Análisis | Requerimientos y casos de uso | `02-requerimientos.md`, `03-casos-de-uso.md` |
| Diseño | Arquitectura, datos, API, interfaz | `04-arquitectura-y-stack.md`, `05-modelo-de-datos-y-api.md`, `06-diseno-front.md` |
| Implementación | Código en sprints (Scrum comprimido) | `07-plan-de-desarrollo.md`, `sprints/`, `progreso.md`, código en `../backend` y `../app` |
| Pruebas / validación TRL 5 | Casos de prueba y evidencias | `08-plan-de-pruebas.md`, `evidencias/` |
| Despliegue y mantenimiento | Cómo ejecutar, versiones | `../README.md`, etiquetas (tags) de Git por sprint |

## Índice
1. [Visión y alcance](01-vision-y-alcance.md)
2. [Requerimientos](02-requerimientos.md)
3. [Casos de uso](03-casos-de-uso.md)
4. [Arquitectura y stack](04-arquitectura-y-stack.md)
5. [Modelo de datos y API](05-modelo-de-datos-y-api.md)
6. [Diseño del front](06-diseno-front.md)
7. [Plan de desarrollo](07-plan-de-desarrollo.md)
8. [Plan de pruebas](08-plan-de-pruebas.md)
9. [Contexto para IA](09-contexto-ia.md)
10. [Progreso](progreso.md)
11. Sprints: [1](sprints/sprint-1.md) · [2](sprints/sprint-2.md) · [3](sprints/sprint-3.md)

## Nota sobre el documento maestro
Estos archivos salen del documento maestro de la Fase 3 (requerimientos RF-01…RF-12 y RNF-01…RNF-08,
actores, pantallas y stack). Cambios respecto a ese documento, que deben reflejarse allí antes de la
entrega final:
- Mapas: **OpenStreetMap** (con `flutter_map` y Nominatim) en lugar de Google Maps Platform.
- **Fuera de alcance** en esta fase: panel de administrador (RF-12), recuperación de contraseña, modo sin
  conexión, automatización de portales web.
- **Envío:** RF-08 se amplía («descargar, compartir o enviar») con RF-17 (envío por correo a la autoridad) y
  RF-18 (acceso al portal oficial), según la investigación legal y de canales del 16-nov-2026 (`docs/05`).
- La app es **solo Android** en el prototipo (la versión web queda como trabajo futuro).
