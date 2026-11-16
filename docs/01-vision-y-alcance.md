# 01 · Visión y alcance

## Problema
En el corredor vial Soacha–Bogotá, motociclistas, ciclistas y peatones se exponen a diario al humo de
vehículos de transporte público y de carga con deficiente mantenimiento. Existen normas y canales de
queja, pero son dispersos, poco conocidos y no estructuran la evidencia (fecha, ubicación, placa, foto o
video) que facilitaría su trámite ante las autoridades competentes. Esa brecha reduce la efectividad del
control de fuentes móviles contaminantes.

Alineación: ODS 11 «Ciudades y comunidades sostenibles», meta 11.6.

## Objetivo general
Desarrollar un sistema de información móvil que permita a los ciudadanos reportar, de forma georreferenciada
y con evidencia audiovisual, vehículos de transporte público y de carga que emiten gases contaminantes de
forma anómala en el corredor Soacha–Bogotá, para facilitar la generación de solicitudes formales ante las
autoridades competentes.

## Objetivos específicos
1. Analizar la normativa vigente y los mecanismos de queja existentes para identificar la información que el
   sistema debe capturar.
2. Diseñar la arquitectura y los módulos funcionales del sistema.
3. Construir un prototipo funcional (TRL 5) aplicando la metodología ágil Scrum.
4. Evaluar el prototipo mediante una prueba piloto con motociclistas, ciclistas y peatones del corredor,
   midiendo usabilidad y utilidad percibida.

## Usuarios
- **Ciudadano reportante** (motociclista, ciclista o peatón del corredor). Es el único actor humano del sistema.
- **Autoridades** (CAR, Secretaría Distrital de Ambiente, Secretaría Distrital de Movilidad): destinatarias de
  la solicitud; **no interactúan con el sistema** en esta fase.

## Alcance del prototipo (MVP)

| Prioridad | Funcionalidad |
|---|---|
| Debe tener (Must) | Registro e inicio de sesión · consentimiento de datos · captura de evidencia · ubicación y hora · datos del vehículo · datos del peticionario · generación de solicitud PQRSD en PDF · autoridad destinataria · descargar/compartir PDF · historial de reportes |
| Debería tener (Should) | Mapa de reportes · detalle de reporte · pantalla de información · perfil |
| Podría tener (Could) | Eliminar reporte · APK para la demo · despliegue del API en la nube · mini prueba piloto con usuarios |

## Fuera de alcance (no implementar)
- Panel de administrador (RF-12) y gestión de usuarios por un administrador.
- Recuperación de contraseña y verificación de correo.
- Modo sin conexión / borradores sin red.
- Envío automático de la solicitud a las autoridades (el usuario descarga o comparte el PDF).
- Seguimiento del estado real del trámite ante la autoridad.
- Medición técnica o certificación de emisiones, sanciones o comparendos, seguimiento judicial.
- Lectura automática de placas (OCR), notificaciones push, iOS, versión web.

## Supuestos
- El usuario tiene un teléfono Android con cámara, GPS e internet.
- El prototipo se demuestra con el API ejecutándose en el equipo de Mateo (conexión por USB con `adb reverse`)
  o desplegado en la nube si hay tiempo.
- Las reglas para asignar la autoridad destinataria son una **propuesta** que Mateo debe validar.

## Criterios de éxito del prototipo
1. Un usuario puede completar, en un Android real, el flujo registrarse → reportar → generar PDF → ver historial.
2. El PDF generado contiene los datos del reporte, la autoridad destinataria y la aclaración de que no es una
   medición técnica.
3. El sistema se prueba en un entorno relevante (dispositivo real, API y base de datos integrados) y queda
   evidencia en `docs/08-plan-de-pruebas.md` y `docs/evidencias/` (criterio TRL 5).
4. El código está en GitHub y hay un video de máximo 10 minutos mostrando el funcionamiento.

## Riesgos principales

| Riesgo | Mitigación |
|---|---|
| Poco tiempo (entrega 22-nov) | MVP recortado, una historia por vez, orden de recorte en `docs/07` |
| Instalación del entorno (Flutter/Android Studio) | Sprint 0 con lista de verificación; instalar Node primero para avanzar el backend en paralelo |
| Cámara/GPS en el celular | Probar temprano en dispositivo real; permisos en AndroidManifest |
| Límites de servicios gratuitos (BD, Nominatim, tiles OSM) | Cache de geocodificación, uso ligero, plan B de BD local |
| Repositorio público con secretos | `.gitignore`, `.env.example`, revisión antes de cada push |

## Glosario
- **PQRSD:** petición, queja, reclamo, sugerencia o denuncia.
- **CAR:** Corporación Autónoma Regional de Cundinamarca.
- **SDA:** Secretaría Distrital de Ambiente de Bogotá.
- **TRL 5:** validación del sistema en un entorno relevante.
- **MVP:** producto mínimo viable.
