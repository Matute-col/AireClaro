# 02 · Requerimientos

Origen: tablas 1 y 2 del documento maestro (Fase 3), ajustadas al alcance del prototipo. Los identificadores
RF-01…RF-12 y RNF-01…RNF-08 se conservan; los nuevos se agregan al final.

**Prioridad:** Alta = debe estar en el prototipo (Must) · Media = debería (Should) · Baja = podría (Could).

Cambios respecto al documento maestro (reflejarlos allí al final):
- RF-07 y RF-09 pasan de prioridad Media a **Alta** (sin autoridad no hay solicitud; sin historial no hay flujo completo).
- RF-12 queda **fuera de alcance** en esta fase.
- Se agregan RF-13 a RF-16 (perfil, información, detalle, eliminar) y RNF-09 / RNF-10.
- Se retira «versión web» de RNF-05: el prototipo es solo Android.

## Actores
- **Ciudadano reportante** (usuario con cuenta).
- **Servicios externos:** OpenStreetMap (mapas) y Nominatim (geocodificación inversa).
- **Autoridad destinataria:** recibe el PDF fuera del sistema; no es un actor del sistema.

## Requerimientos funcionales

| ID | Requerimiento | Prioridad | Criterios de aceptación |
|---|---|---|---|
| RF-01 | El sistema permitirá registrarse e iniciar sesión con correo y contraseña. | Alta | Registro con datos válidos crea la cuenta y abre sesión. Correo duplicado muestra error. Credenciales incorrectas muestran error sin revelar cuál dato falló. La sesión persiste al reabrir la app y se puede cerrar. |
| RF-02 | El sistema permitirá capturar o adjuntar fotografía o video del vehículo. | Alta | Se puede tomar foto, grabar video (máx. 15 s) o elegir de la galería; máximo 3 archivos; se ven miniaturas y se pueden quitar; no se avanza sin al menos 1 archivo. |
| RF-03 | El sistema registrará automáticamente ubicación, fecha y hora del reporte. | Alta | Al llegar al paso de ubicación se toma la posición GPS; se muestra en el mapa y la dirección aproximada; el usuario puede mover el pin; fecha y hora se llenan solas y no se editan. Sin permiso de ubicación se muestra un aviso con botón para activarla. |
| RF-04 | El sistema permitirá ingresar la placa y el tipo de vehículo. | Alta | Tipo obligatorio (bus, microbús, camión, tractomula, otro). Placa obligatoria, en mayúsculas, formato válido (`ABC123` o `ABC12D`); placa inválida muestra error. También se pide el color del humo (negro, gris, blanco). |
| RF-05 | El sistema permitirá agregar una descripción opcional. | Media | Campo opcional de hasta 500 caracteres con contador. |
| RF-06 | El sistema generará automáticamente una solicitud tipo PQRSD con los datos y la evidencia del reporte. | Alta | Para un reporte guardado, el API entrega un PDF con encabezado, hechos, petición, datos del peticionario y aclaración de que no es una medición técnica. El texto usa los datos reales del reporte. |
| RF-07 | El sistema determinará la autoridad destinataria según la ubicación. | Alta | Ubicación en Bogotá → Secretaría Distrital de Ambiente; en Soacha u otro municipio de Cundinamarca → CAR. Si no se puede determinar, el usuario elige de una lista. El usuario puede cambiarla antes de guardar. |
| RF-08 | El sistema permitirá descargar o compartir la solicitud generada. | Alta | Desde la vista previa se puede abrir/descargar el PDF y compartirlo con las apps del teléfono (correo, WhatsApp, etc.). |
| RF-09 | El sistema permitirá consultar el historial de reportes. | Alta | «Mis reportes» lista solo los reportes del usuario, del más reciente al más antiguo, con miniatura, placa, fecha y estado. Estado vacío con botón «Nuevo reporte». |
| RF-10 | El sistema mostrará los reportes registrados sobre un mapa. | Media | Mapa con pines; filtros por tipo de vehículo y fechas; al tocar un pin se ve tipo de vehículo, fecha y lugar. **No se muestran placa ni fotos.** Atribución de OpenStreetMap visible. |
| RF-11 | El sistema solicitará aceptar la política de tratamiento de datos antes de crear la cuenta. | Alta | El registro exige marcar la casilla de aceptación; se guarda la fecha y hora de aceptación. |
| RF-12 | Panel web de administración. | — | **Fuera de alcance en esta fase.** |
| RF-13 | El usuario podrá ver y editar sus datos de perfil y cerrar sesión. | Media | Se muestran nombre, documento, correo y teléfono; nombre, documento y teléfono se pueden editar; el correo no. |
| RF-14 | El sistema tendrá una pantalla informativa «¿Cómo funciona?». | Media | Explica los pasos, las autoridades destinatarias y el alcance (no mide emisiones ni sanciona); enlaza la política de datos. |
| RF-15 | El usuario podrá ver el detalle de un reporte. | Media | Muestra evidencia, datos, mapa pequeño, autoridad y estado; permite descargar la solicitud. |
| RF-16 | El usuario podrá eliminar un reporte propio. | Baja | Pide confirmación; el reporte y sus archivos desaparecen del historial y del mapa. |

## Requerimientos no funcionales

| ID | Categoría | Requerimiento | Medida / criterio |
|---|---|---|---|
| RNF-01 | Usabilidad | Completar un reporte debe ser rápido y claro, incluso en movimiento. | Flujo de reporte en ≤ 4 pasos y ≈ 3 minutos o menos en condiciones normales; botones de al menos 48 dp. |
| RNF-02 | Rendimiento | La evidencia se optimiza para conexiones móviles. | Fotos reducidas (lado máximo 1600 px, calidad ~80 %); video máx. 15 s y 25 MB; fotos ≤ 8 MB; respuestas del API < 2 s sin contar la carga de archivos. |
| RNF-03 | Seguridad | Comunicación y credenciales protegidas. | HTTPS en producción (HTTP solo en desarrollo local); contraseñas con hash; JWT; límite de peticiones; cada usuario solo accede a sus reportes. |
| RNF-04 | Privacidad | Tratamiento de datos conforme a la Ley 1581 de 2012. | Consentimiento registrado con fecha; el mapa público no muestra placa ni fotos; sin datos personales en logs. |
| RNF-05 | Compatibilidad | La aplicación móvil funciona en Android. | Probado en el celular físico de Mateo. (Web: trabajo futuro.) |
| RNF-06 | Disponibilidad | El servicio está disponible durante la demostración y la prueba. | API y BD operativos durante las pruebas y el video. |
| RNF-07 | Mantenibilidad | Código versionado y organizado en módulos documentados. | Repositorio en GitHub, commits pequeños, estructura de `docs/04`, README con instrucciones de ejecución. |
| RNF-08 | Legalidad / alcance | El sistema no emite juicios técnicos sobre emisiones ni impone sanciones. | El PDF y la pantalla «Información» incluyen la aclaración; el lenguaje de la solicitud es factual y no acusatorio. |
| RNF-09 | Uso responsable de servicios externos | Cumplir las políticas de OpenStreetMap y Nominatim. | Atribución visible; Nominatim ≤ 1 petición/s con `User-Agent` identificable y cache; uso ligero de tiles. |
| RNF-10 | Calidad | El código se valida con pruebas automáticas y análisis estático. | `npm test` y `flutter analyze` sin errores; pruebas de autenticación, creación de reporte y generación de PDF. |

## Reglas de negocio
- RB-01: Un reporte pertenece a un único usuario; solo ese usuario puede verlo, descargarlo o eliminarlo.
- RB-02: La placa se normaliza (mayúsculas, sin espacios ni guiones) antes de validarla y guardarla.
- RB-03: Un reporte requiere al menos 1 y como máximo 3 archivos de evidencia.
- RB-04: La fecha y hora del reporte son las del momento de captura (no editable); no puede ser futura.
- RB-05: Los datos del peticionario se guardan como copia (snapshot) dentro del reporte, para que el PDF no
  cambie si luego se edita el perfil.
- RB-06: El estado de un reporte es `generado` al crearlo y pasa a `enviado` solo cuando el usuario lo marca
  (el sistema no puede saber si realmente lo radicó).
- RB-07: El mapa público solo expone id, coordenadas, tipo de vehículo y fecha.

## Matriz de trazabilidad

| Requerimiento | Caso de uso | Pantalla(s) | Endpoint(s) | Historia (sprint) |
|---|---|---|---|---|
| RF-01, RF-11 | UC-01, UC-02, UC-03 | 01, 02, 03 | `POST /auth/register`, `POST /auth/login` | US-01, US-02 (S1) |
| RF-13 | UC-04 | 16 | `GET/PUT /me` | US-03 (S1) |
| RF-02 | UC-05 | 05 | `POST /reports` (multipart) | US-05 (S2) |
| RF-04, RF-05 | UC-05 | 06 | `POST /reports` | US-06 (S2) |
| RF-03 | UC-05 | 07 | `GET /geo/reverse` | US-07 (S2) |
| RF-01 (datos peticionario) | UC-05 | 08 | `POST /reports` | US-08 (S2) |
| RF-07 | UC-05 | 09 | `GET /authorities`, `POST /reports` | US-09 (S2) |
| RF-09 | UC-08 | 04, 12 | `GET /reports` | US-10 (S2) |
| RF-15 | UC-09 | 13 | `GET /reports/:id` | US-11 (S2) |
| RF-06 | UC-06 | 10 | `GET /reports/:id/pqrsd`, `.../pqrsd.pdf` | US-12 (S3) |
| RF-08 | UC-07 | 10, 11 | `GET /reports/:id/pqrsd.pdf`, `PATCH /reports/:id/status` | US-13, US-14 (S3) |
| RF-10 | UC-11 | 14 | `GET /map/reports` | US-15 (S3) |
| RF-14 | UC-12 | 15 | — | US-16 (S3) |
| RF-16 | UC-10 | 13 | `DELETE /reports/:id` | US-18 (S3) |
| RNF-01…10 | transversal | 17 | — | US-17, US-19 (S3) |
