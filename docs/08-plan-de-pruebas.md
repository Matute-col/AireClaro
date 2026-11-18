# 08 · Plan de pruebas y validación (TRL 5)

## Estrategia
- **Automáticas:** `jest` + `supertest` en el backend (autenticación, creación de reporte, propiedad de recursos,
  generación del PDF, validaciones); `flutter test` para validadores y widgets clave; `flutter analyze`.
- **Manuales en entorno relevante:** celular Android físico, GPS real, cámara real, API conectado a una base
  PostgreSQL en la nube, datos y lugares reales del corredor Soacha–Bogotá.
- **Entorno relevante (TRL 5):** el prototipo integrado (app + API + BD en la nube + servicios de mapa) se
  valida fuera del computador de desarrollo aislado, con usuarios y condiciones cercanas a las reales, e
  identificando seguridad, limitaciones y aspectos regulatorios.

## Casos de prueba

| ID | Caso | Pasos resumidos | Resultado esperado | RF |
|---|---|---|---|---|
| CP-01 | Registro válido | Completar formulario y aceptar datos | Cuenta creada, sesión abierta, Inicio | RF-01, 11 |
| CP-02 | Correo duplicado | Registrar un correo existente | Error «Este correo ya está registrado» | RF-01 |
| CP-03 | Sin aceptar tratamiento de datos | Dejar casilla vacía | Botón deshabilitado | RF-11 |
| CP-04 | Login válido y persistencia | Ingresar, cerrar y reabrir la app | Sesión se mantiene | RF-01 |
| CP-05 | Login inválido | Contraseña errónea | Mensaje genérico | RF-01 |
| CP-06 | Reporte con foto | Recorrer los 4 pasos con 1 foto | Reporte creado en estado `generado` | RF-02..05 |
| CP-07 | Reporte con video | Video ≤ 15 s | Reporte creado; video descargable | RF-02 |
| CP-08 | Placa inválida | Escribir `12ABC` | Error en el campo, no avanza | RF-04 |
| CP-09 | Permiso de ubicación denegado | Negar permiso | Aviso y botón para activar | RF-03 |
| CP-10 | Ajustar pin | Mover el pin en el mapa | Coordenadas y dirección se actualizan | RF-03 |
| CP-11 | Autoridad en Soacha | Ubicación en Soacha | Sugiere CAR | RF-07 |
| CP-12 | Autoridad en Bogotá | Ubicación en Bogotá | Sugiere SDA | RF-07 |
| CP-13 | Contenido del PDF | Abrir el PDF | Hechos, petición, peticionario y nota de alcance correctos | RF-06 |
| CP-14 | Compartir | Pulsar «Compartir» | Se abre el menú del teléfono con el PDF | RF-08 |
| CP-15 | Historial | Crear 2 reportes | Aparecen ordenados, solo los míos | RF-09 |
| CP-16 | Detalle | Abrir un reporte | Evidencia, datos, mapa y autoridad | RF-15 |
| CP-17 | Eliminar | En el detalle, «Eliminar reporte» y confirmar | Pide confirmación; desaparece del historial y del mapa; su evidencia y fotogramas se borran del servidor; otro usuario recibe 404 | RF-16 |
| CP-18 | Mapa sin datos sensibles | Tocar un pin | Sin placa ni foto | RF-10 |
| CP-19 | Sin conexión | Apagar datos al guardar | Mensaje y «Reintentar» | RNF-01 |
| CP-20 | Sesión expirada | Token inválido | Vuelve a login con aviso | RNF-03 |
| CP-21 | Acceso a reporte ajeno | Pedir el id de otro usuario | 404, sin datos | RB-01 |
| CP-22 | Tiempo del flujo | Cronometrar un reporte completo | ≈ 3 minutos o menos | RNF-01 |
| CP-23 | Envío en modo prueba | `MAIL_MODE=test`; confirmar «Enviar a la autoridad» | Llega al buzón de prueba con asunto `[PRUEBA]`, PDF adjunto, Reply-To y copia al ciudadano; el reporte pasa a `enviado` (`email`, `test`) | RF-17 |
| CP-24 | Autoridad sin correo verificado | Reporte dirigido a SDM | No aparece «Enviar a la autoridad»; sí «Radicar en el portal oficial» | RF-17, RF-18 |
| CP-25 | Reenvío bloqueado | Enviar dos veces el mismo reporte | Segundo intento: 409 y mensaje | RF-17 |
| CP-26 | Fallo del correo | Credenciales SMTP inválidas (entorno de prueba) | 502, mensaje con «Reintentar», estado sin cambios | RF-17 |
| CP-27 | Portal oficial | Pulsar «Radicar en el portal oficial» | Abre la URL oficial en el navegador | RF-18 |
| CP-28 | Modo live protegido | `MAIL_MODE=live` con autoridad `email_verified=false` | Rechaza el envío (422); nunca sale correo real | RB-08, RB-09 |
| CP-29 | Dueño del reporte | Intentar enviar el reporte de otro usuario | 404 | RB-01 |
| CP-30 | Fotogramas del video (US-23) | Crear un reporte con un video | 4 fotogramas en el detalle bajo el video y en ANEXOS del PDF («Fotogramas del video 1 (4)»), en cuadrícula; si la extracción falla, el reporte se crea sin ellos y la app lo avisa | RF-19 |

## Revisión de estados (US-17, 17-nov-2026)
Cada pantalla que habla con el API tiene estado de carga con texto, estado vacío cuando aplica y error con
mensaje en español y «Reintentar». Los errores de red y del servidor pasan por `toApiException` (con prueba).

| Pantalla | Cargando | Vacío | Error / sin conexión | Otros |
|---|---|---|---|---|
| Arranque (sesión) | «Verificando tu sesión…» | — | `ErrorState` + Reintentar | 401 → Bienvenida |
| Login / Registro | botón con indicador | — | aviso + Reintentar | correo duplicado y credenciales en el campo |
| Inicio | «Cargando…» en la tarjeta | «0 reportes» | texto por defecto | — |
| Paso 1 Evidencia | indicador al abrir cámara/galería | «0 de 3 archivos» | aviso al fallar cámara o galería | HEIC y tamaño; fotogramas: «Sin fotogramas» + aviso |
| Paso 3 Ubicación | indicador sobre el mapa | «Marca en el mapa…» | dirección no disponible → se puede seguir | permiso denegado / GPS apagado → «Activar ubicación» |
| Revisión | progreso de subida en % | — | aviso + Reintentar | autoridades: carga y Reintentar |
| Mis reportes | «Cargando tus reportes…» | «Aún no tienes reportes» + Nuevo reporte | `ErrorState` + Reintentar; error al paginar al final | recarga deslizando |
| Detalle | «Cargando el reporte…» | — | Reintentar; 404 «No encontramos este reporte» | — |
| Vista previa | «Generando la solicitud…» | — | Reintentar; 404 | descarga, envío (409/422/502/503) |
| Confirmación | «Cargando…» | — | Reintentar | — |
| Mapa | «Cargando reportes…» | «No hay reportes con estos filtros.» | aviso + Reintentar | — |
| ¿Cómo funciona? | «Cargando autoridades…» | — | aviso + Reintentar (el resto funciona) | — |
| Cualquier pantalla | — | — | 401 con sesión → Login «Tu sesión expiró» (CP-20) | 429 y 500 con mensaje claro |

## Registro de evidencias
Carpeta `docs/evidencias/`: capturas por caso (`CP-06.png`), resultados de `npm test` y `flutter analyze`,
y la tabla de resultados.

| Caso | Fecha | Resultado (Pasó / Falló) | Evidencia | Observaciones |
|---|---|---|---|---|
| CP-01 | | | | |

## Seguridad, limitaciones y aspectos regulatorios (para el documento maestro)
- **Seguridad:** contraseñas con hash, JWT, límites de peticiones, `helmet`, validación de entradas, archivos con
  nombre generado y acceso autenticado, repositorio sin secretos, HTTP solo en desarrollo.
- **Limitaciones:** solo Android; sin modo sin conexión; la asignación de autoridad es por reglas simples; el
  sistema no verifica que la solicitud sea radicada; no mide emisiones; dependencia de OSM/Nominatim y de la
  BD gratuita; archivos en disco local.
- **Regulatorio:** Ley 1581 de 2012 (consentimiento y finalidad, mapa sin datos sensibles; confirmación explícita
  antes de compartir datos con una entidad); derecho de petición (art. 23 de la Constitución; Ley 1755 de 2015,
  arts. 14–16 y 21: medio electrónico válido, contenido mínimo, remisión por competencia); Resolución 762 de 2022 y
  Ley 769 de 2002 sobre control de emisiones y tránsito (competencia compartida con tránsito); políticas de uso de
  OpenStreetMap y Nominatim; el documento aclara que no es una medición técnica.
- **Limitación adicional:** que el correo salga no garantiza que la entidad lo radique ni genere un número de
  radicado; se mitiga con la copia al ciudadano y el acceso al portal oficial.

## Mini piloto (opcional)
Si hay tiempo, 3 a 5 personas completan un reporte y responden la escala SUS (10 preguntas). Registrar
resultados en `docs/evidencias/piloto.md` sin datos personales.
