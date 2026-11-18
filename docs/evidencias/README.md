# Evidencias de las pruebas · AireClaro

Registro de la ejecución de los casos CP-01 a CP-30 de `docs/08-plan-de-pruebas.md` (validación TRL 5).

## Cómo llenarla
- **Fecha:** día de la ejecución (AAAA-MM-DD).
- **Resultado:** «Pasó», «Falló» o «No aplica» (con el motivo en Observaciones).
- **Evidencia:** nombre del archivo guardado en esta carpeta, p. ej. `CP-06.png` (captura) o `CP-23.pdf`.
  Los videos **no** se guardan aquí (pesan y `.gitignore` los excluye): se enlazan en el documento final.
- **Antes de subir una captura**, revisa que no muestre datos personales reales (correo, documento, teléfono) ni
  credenciales; usa cuentas y datos de prueba.
- La columna «Prueba automática» indica qué pruebas de `backend/tests/` (`.test.js`) o `app/test/` (`_test`)
  cubren además ese caso.

## Resultados

| Caso | Nombre | Req. | Prueba automática | Fecha | Resultado | Evidencia | Observaciones |
|---|---|---|---|---|---|---|---|
| CP-01 | Registro válido | RF-01, 11 | register.test.js · register_screen_test | | | |  |
| CP-02 | Correo duplicado | RF-01 | register.test.js · register_screen_test | | | |  |
| CP-03 | Sin aceptar tratamiento de datos | RF-11 | register_screen_test | | | |  |
| CP-04 | Login válido y persistencia | RF-01 | login.test.js · auth_controller_test | | | |  |
| CP-05 | Login inválido | RF-01 | login.test.js · login_screen_test | | | |  |
| CP-06 | Reporte con foto | RF-02..05 | reports.create.test.js · review_screen_test | | | |  |
| CP-07 | Reporte con video | RF-02 | reports.create.test.js · report_detail_screen_test | | | |  |
| CP-08 | Placa inválida | RF-04 | reports.schema.test.js · vehicle_step_test | | | |  |
| CP-09 | Permiso de ubicación denegado | RF-03 | location_step_test | | | |  |
| CP-10 | Ajustar pin | RF-03 | location_step_test | | | |  |
| CP-11 | Autoridad en Soacha | RF-07 | authorityRule.test.js · geo.test.js | | | |  |
| CP-12 | Autoridad en Bogotá | RF-07 | authorityRule.test.js · geo.test.js | | | |  |
| CP-13 | Contenido del PDF | RF-06 | pqrsd.text.test.js · pqrsd.test.js | | | |  |
| CP-14 | Compartir | RF-08 | preview_screen_test | | | |  |
| CP-15 | Historial | RF-09 | reports.list.test.js · reports_screen_test | | | |  |
| CP-16 | Detalle | RF-15 | reports.detail.test.js · report_detail_screen_test | | | |  |
| CP-17 | Eliminar | RF-16 | delete.test.js · delete_report_test | | | | |
| CP-18 | Mapa sin datos sensibles | RF-10 | map.test.js · map_screen_test | | | |  |
| CP-19 | Sin conexión | RNF-01 | review_screen_test · api_error_test | | | |  |
| CP-20 | Sesión expirada | RNF-03 | me.test.js · api_client_test · login_screen_test | | | |  |
| CP-21 | Acceso a reporte ajeno | RB-01 | reports.detail.test.js · reports.list.test.js | | | |  |
| CP-22 | Tiempo del flujo | RNF-01 | — (manual, con cronómetro) | | | |  |
| CP-23 | Envío en modo prueba | RF-17 | send.test.js · preview_screen_test | | | |  |
| CP-24 | Autoridad sin correo verificado | RF-17, RF-18 | send.test.js · portal_and_manual_test | | | |  |
| CP-25 | Reenvío bloqueado | RF-17 | send.test.js · status.test.js | | | |  |
| CP-26 | Fallo del correo | RF-17 | send.test.js · preview_screen_test | | | |  |
| CP-27 | Portal oficial | RF-18 | portal_and_manual_test | | | |  |
| CP-28 | Modo live protegido | RB-08, RB-09 | send.test.js | | | |  |
| CP-29 | Dueño del reporte | RB-01 | send.test.js · status.test.js | | | |  |
| CP-30 | Fotogramas del video (US-23) | RF-19 | frames.test.js · evidence_step_test · report_detail_screen_test | | | |  |

## Pruebas automáticas

Salidas guardadas el 17-nov-2026 (se pueden regenerar con los mismos comandos):

| Archivo | Comando | Resultado |
|---|---|---|
| `npm-test.txt` | `cd backend; npm test` | 23 archivos, 192/192 pruebas |
| `flutter-test.txt` | `cd app; flutter test` | 135/135 pruebas |
| `flutter-analyze.txt` | `cd app; flutter analyze` | «No issues found!» |
