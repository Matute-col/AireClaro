# 09 · Plan de contexto para IA (Claude Code en VS Code)

## Protocolo de trabajo
1. Abrir la carpeta del repositorio en VS Code. Claude Code lee `CLAUDE.md` automáticamente.
2. **Una historia por sesión.** Empezar con una sesión nueva cuando cambie de historia o el contexto se llene.
3. Pedir primero un **plan** (modo plan) y aprobarlo antes de que escriba código.
4. Después de cada tarea: ejecutar pruebas, hacer commit y actualizar `docs/progreso.md`.
5. Al terminar un sprint: revisión de seguridad (prompt abajo), merge y tag.
6. Si algo en los documentos contradice la realidad, se corrige el documento antes de seguir (el orden de
   autoridad está en `CLAUDE.md`).

## Prompt de inicio de cada sesión
```
Lee CLAUDE.md, docs/progreso.md y docs/07-plan-de-desarrollo.md.
Vamos a trabajar la historia <US-XX>. Lee los documentos que apliquen (02, 03, 05, 06).
Primero propón un plan corto con los archivos que vas a crear o cambiar. No escribas código hasta que lo apruebe.
```

## Prompts por sprint

**Sprint 1.** «Ejecuta TS-01 y TS-02: crea el backend según docs/04 y docs/05, con `.env.example`, migración 001
y semillas. Luego US-01 y US-02 en el API con pruebas. No toques la app todavía.» Después: «TS-03 y US-01…US-04 en
la app según docs/06.»

**Sprint 2.** «Implementa US-05…US-09 de extremo a extremo (app + API) una historia por vez. Para US-07 respeta las
reglas de Nominatim del CLAUDE.md. Prueba en el celular con `adb reverse`.» Luego US-10 y US-11.

**Sprint 3.** «Implementa US-12 (PDF con la plantilla de docs/05) y US-13/US-14. Luego US-15, US-16, US-17.
Después US-19 y US-20 y, si hay tiempo, US-18.»

## Reglas para la IA
- No inventar requisitos ni pantallas; si falta algo, preguntar.
- No agregar dependencias sin anotarlo en `docs/04` (con motivo).
- No subir ni escribir secretos; no imprimir datos personales en logs.
- Respetar el orden de recorte de `docs/07` si el tiempo se acaba.
- Mensajes de commit en inglés; textos de la app en español.
- No modificar los documentos `docs/01`–`docs/06` sin avisar y sin registrar el cambio.

## Consejos en Windows
- Usar PowerShell; las rutas con `\`. Si un comando de `npm` está bloqueado por la política de scripts,
  consultar la documentación de PowerShell antes de cambiar políticas.
- Mantener el teléfono conectado y ejecutar `adb reverse tcp:3000 tcp:3000` cada vez que se reconecte.
- Dos terminales: una para el API (`npm run dev`) y otra para la app (`flutter run`).

## Prompt de cierre de sesión
```
Actualiza docs/progreso.md con lo hecho, lo pendiente y los problemas encontrados.
Ejecuta las pruebas y dime si algo falla. Propón el mensaje de commit.
```

## Prompt de revisión de seguridad (antes de cada push)
```
Revisa los cambios sin commit y el historial reciente: busca secretos, cadenas de conexión, tokens, contraseñas,
datos personales o archivos de uploads que no deban subirse. Verifica que .env no esté versionado y que los
logs no impriman datos personales. Reporta hallazgos; no hagas push.
```
