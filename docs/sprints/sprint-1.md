# Sprint 1 · Backend base, autenticación y app base

**Meta:** un usuario puede registrarse e iniciar sesión desde el celular contra el API conectado a la BD en la nube.

## Backlog
TS-01, TS-02, TS-03, US-01, US-02, US-03, US-04.

## Definición de hecho
- `GET /health` responde; migración y semillas aplicadas en la BD en la nube.
- Registro, login y `GET/PUT /me` con pruebas automáticas.
- App: Bienvenida, Login, Registro, Inicio y Perfil funcionando en el celular; sesión persistente.
- Sin secretos en el repositorio. Tag `v0.1-sprint1`.

## Revisión (al terminar)
Cerrado el 16-nov-2026.

- Qué se logró:
  - **Backend (TS-01, TS-02, API de US-01…US-03):** Express con helmet, límites y formato de errores; migraciones
    en Neon; registro con consentimiento, login con mensaje genérico, `GET/PUT /me`. 32 pruebas con jest contra una
    rama `test` de Neon.
  - **Autoridades:** correos y portales verificados por Mateo y cargados con una nueva migración (SDA y CAR con
    correo verificado; SDM solo portal). `MAIL_MODE=test`.
  - **App (TS-03, US-01…US-04):** Flutter solo Android (`com.aireclaro.app`): tema, router con redirección por
    sesión, cliente `dio` con token y manejo del 401, token en almacenamiento seguro; Bienvenida, Registro, Login,
    sesión persistente, Inicio con barra inferior y Perfil con edición y cierre de sesión. 40 pruebas
    (`flutter test`) y `flutter analyze` sin problemas.
  - **Prueba en el celular** (Android 16, por USB con `adb reverse`): US-01 (5 casos) y US-02…US-04 (11 casos), todos
    correctos.
- Qué quedó pendiente:
  - Push, merge a `main` y tag `v0.1-sprint1` (esperan la aprobación de Mateo).
  - La tarjeta «Mis reportes» de Inicio aún no muestra el número de reportes (llega con US-10).
  - Pestañas Mapa, Mis reportes e Info con pantalla «Muy pronto» (US-15, US-10, US-16).
  - Comparar las pantallas con Figma; validar la regla de asignación de autoridad (`docs/05`); aviso de `sslmode`
    de `pg` (opcional).

## Retrospectiva
- Qué funcionó:
  - Una historia por vez con commit propio: el historial cuenta qué se hizo y es fácil de revisar.
  - Rama `test` de Neon separada para las pruebas; las migraciones se aplican primero ahí.
  - Dobles de prueba escritos a mano (sin paquetes de mocks) y validadores con las mismas reglas que el API.
  - Dos puntos de control en el celular (tras US-01 y tras US-04) en vez de uno por historia: menos esperas.
- Qué mejorar:
  - Finales de línea: el repositorio mezclaba CRLF y LF; conviene un `.gitattributes` para fijarlo.
  - Verificar antes el entorno (`adb` en el PATH, versión de Flutter): Flutter 3.50 trajo Material como paquete
    aparte (`material_ui`) y hubo que ajustarse.
  - Tener el Figma a mano antes del Sprint 2, que tiene más pantallas.
