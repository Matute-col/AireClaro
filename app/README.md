# AireClaro · app Android (Flutter)

## Correr la app en el celular (USB)

```powershell
# Terminal 1: el API
cd C:\proyectos\AireClaro\backend
npm run dev

# Terminal 2: celular conectado por USB con depuración activa
adb devices                       # el celular debe aparecer como "device"
adb reverse tcp:3000 tcp:3000     # repetir cada vez que se reconecte el cable
cd C:\proyectos\AireClaro\app
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
```

En VS Code también se puede usar **F5** con la configuración «AireClaro (celular por USB)»
(`.vscode/launch.json`).

- Sin `--dart-define=API_BASE_URL` la app muestra un aviso y no arranca.
- HTTP sin cifrar solo está permitido en las compilaciones *debug* y *profile*.
- Otras opciones (Wi-Fi, emulador): ver `docs/04-arquitectura-y-stack.md`.

## Verificar

```powershell
flutter analyze
flutter test
```
