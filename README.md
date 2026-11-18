# AireClaro

Sistema de información para el **reporte ciudadano de emisiones vehiculares contaminantes en el corredor
Soacha–Bogotá**. El ciudadano captura evidencia (foto o video), la ubicación y los datos del vehículo; la app genera
una **solicitud tipo PQRSD en PDF** dirigida a la autoridad competente (CAR, Secretaría Distrital de Ambiente o
Secretaría Distrital de Movilidad) y la **envía por correo**, con confirmación del usuario, o lleva al ciudadano al
**portal oficial** para radicarla.

> AireClaro no mide emisiones ni impone sanciones. Genera una solicitud con la evidencia que el ciudadano aporta.

Prototipo funcional (TRL 5) del proyecto de grado de Ingeniería de Sistemas de Mateo Alejandro Bernal Cardona (UNAD).

## Estructura del repositorio

```
AireClaro/
├── backend/   API REST: Node.js + Express, PostgreSQL, PDF con pdfkit, correo con nodemailer
├── app/       App Android: Flutter (Riverpod, go_router, dio, flutter_map)
└── docs/      Requerimientos, casos de uso, modelo de datos y API, diseño, plan, pruebas y progreso
```

La documentación completa está en `docs/` (empieza por `docs/README.md` y `docs/progreso.md`).

## Requisitos

- **Node.js** LTS (20 o superior) y npm.
- **PostgreSQL**: una base en la nube (en el proyecto se usa Neon) con una rama aparte para las pruebas.
- **Flutter** 3.50 (Dart 3.14) y el **SDK de Android** (Android Studio).
- Un **celular Android** (7.0 o superior) con depuración USB activada.
- Windows, VS Code y PowerShell (los comandos de abajo son para PowerShell).

## 1. API (`backend/`)

```powershell
cd C:\proyectos\AireClaro\backend
npm install
copy .env.example .env      # luego llena .env con tus valores (ver la tabla)
npm run migrate             # crea las tablas y las autoridades en la base principal
npm run dev                 # API en http://localhost:3000/api
```

Variables de `backend/.env` (**nunca** se suben al repositorio; `.env` está en `.gitignore`):

| Variable | Para qué |
|---|---|
| `DATABASE_URL` | Base principal (secreto) |
| `TEST_DATABASE_URL` | Base **solo para pruebas** (otra rama; `npm test` se detiene si apunta al mismo servidor) |
| `JWT_SECRET` | Firma de las sesiones; cadena larga y aleatoria (secreto) |
| `UPLOAD_DIR` | Carpeta de la evidencia (por defecto `./uploads`, no se versiona) |
| `NOMINATIM_USER_AGENT` | Identificación ante Nominatim, p. ej. `AireClaro-UNAD/1.0 (contacto: …)` |
| `MAIL_MODE` | `test` (por defecto: todo va a `MAIL_TEST_TO`), `live` (a la autoridad, solo por decisión explícita) u `off` |
| `MAIL_TEST_TO` | Buzón de prueba que recibe todos los correos en modo `test` |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `MAIL_FROM` | Servidor de correo (con Gmail: `smtp.gmail.com`, `587` y una contraseña de aplicación) |

Otros comandos:

```powershell
npm test               # pruebas automáticas (usan TEST_DATABASE_URL y un servidor de correo simulado)
npm run migrate:test   # aplica las migraciones en la base de pruebas
```

## 2. App Android (`app/`)

Con el celular conectado por USB y el API encendido:

```powershell
adb devices                       # el celular debe aparecer como "device"
adb reverse tcp:3000 tcp:3000     # el celular llega al API del PC por el cable (repetir al reconectar)
cd C:\proyectos\AireClaro\app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
```

En VS Code también se puede usar **F5** con la configuración «AireClaro (celular por USB)» (`.vscode/launch.json`).

```powershell
flutter analyze   # análisis estático
flutter test      # pruebas automáticas (sin red: API, cámara, GPS y mapa simulados)
```

### APK para instalar sin cable

El APK se compila en modo **profile**: el modo *release* bloquea HTTP sin cifrar y el API de desarrollo usa HTTP.

1. Averigua la IP de tu PC en la red Wi-Fi: `ipconfig` (por ejemplo `192.168.1.20`).
2. Permite el puerto 3000 en el firewall de Windows **solo para redes privadas**.
3. Compila con esa IP:
   ```powershell
   cd C:\proyectos\AireClaro\app
   flutter build apk --profile --dart-define=API_BASE_URL=http://192.168.1.20:3000/api
   ```
4. El archivo queda en `app\build\app\outputs\flutter-apk\app-profile.apk` (≈ 80 MB). Cópialo al celular e
   instálalo (Android pedirá permitir «instalar apps desconocidas»).
5. El celular y el PC deben estar en la **misma red Wi-Fi** y el API encendido (`npm run dev`).

Si la IP del PC cambia, hay que volver a compilar el APK. Con cable sigue funcionando
`--dart-define=API_BASE_URL=http://localhost:3000/api` y `adb reverse tcp:3000 tcp:3000`.

## Correo y seguridad

- `MAIL_MODE=test` por defecto: **ningún correo llega a una autoridad real**; todos van a `MAIL_TEST_TO` con
  `[PRUEBA]` en el asunto. Solo se envía a autoridades con correo verificado (`email_verified = true`).
- El repositorio es público: no se suben claves, contraseñas, tokens, cadenas de conexión ni la carpeta de evidencia.
- Contraseñas con bcrypt, sesiones con JWT, `helmet` y límite de peticiones activos. Cada usuario solo puede ver,
  descargar o enviar sus propios reportes (los demás reciben 404).
- Mapa con OpenStreetMap («© OpenStreetMap contributors») y direcciones con Nominatim a través del API
  (máximo 1 petición por segundo, con caché).

## Pruebas y evidencias

- Plan de pruebas y casos CP-01 a CP-30: `docs/08-plan-de-pruebas.md`.
- Tabla de resultados para llenar y salidas de las pruebas automáticas: `docs/evidencias/`.
