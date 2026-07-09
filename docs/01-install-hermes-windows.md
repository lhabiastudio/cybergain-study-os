# 01 — Instalar Hermes en Windows

## Objetivo
Dejar Hermes instalado, con login en OpenAI Codex y una comprobación básica real.

## Prerrequisitos
Necesitas esto:
- Windows 11 recomendado
- Git instalado
- plan ChatGPT activo
- PowerShell normal de usuario
- conexión a internet

Python y Node.js no son necesarios para usar Cybergain Study OS.

Solo te hacen falta si más adelante vas a regenerar tú misma el PDF de la guía.

Si no tienes Git y `winget` funciona en tu equipo, puedes instalarlo así:

```powershell
winget install -e --id Git.Git --accept-source-agreements --accept-package-agreements
```

Si además quieres preparar el equipo para regenerar el PDF de la guía, entonces sí puedes instalar opcionalmente Python y Node.js:

```powershell
winget install -e --id Python.Python.3.11 --accept-source-agreements --accept-package-agreements
winget install -e --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
```

## Paso 1 — Abrir PowerShell
Abre PowerShell normal. No hace falta abrirlo como administradora salvo que tu Windows bloquee instalaciones.

## Paso 2 — Instalar Hermes
Ejecuta esto tal cual:

```powershell
iex (irm https://hermes-agent.nousresearch.com/install.ps1)
```

Ese instalador prepara Hermes y su propio entorno. No necesitas instalar Python ni Node aparte para usar Hermes.

Cuando termine, cierra PowerShell y vuelve a abrirlo.

> Si después de instalar escribes `hermes` y Windows dice que no existe, cierra PowerShell por completo y vuelve a abrirlo. Muchas veces el PATH no se refresca hasta abrir una ventana nueva.

## Paso 3 — Comprobar que Hermes ha quedado instalado
Ejecuta:

```powershell
hermes --version
hermes doctor
```

Resultado esperado:
- `hermes --version` devuelve una versión
- `hermes doctor` termina sin bloquearse y te muestra el estado del sistema

## Paso 4 — Elegir proveedor y hacer login
Ejecuta:

```powershell
hermes model
```

Dentro del selector:
1. Elige `OpenAI Codex`.
2. Completa el login en el navegador cuando se abra.
3. Vuelve a la terminal cuando termine.

## Paso 5 — Smoke test real
Ejecuta:

```powershell
hermes chat -q "Di solo: Hermes listo"
```

Resultado esperado: una respuesta corta del modelo, por ejemplo `Hermes listo`.

## Paso 6 — Ver herramientas y skills disponibles
Ejecuta:

```powershell
hermes tools list
hermes skills
```

Resultado esperado:
- `hermes tools list` muestra las herramientas disponibles
- `hermes skills` muestra las skills instaladas

Si más adelante quieres usar OCR o transcripción, no des por hecho que ya existe una skill concreta: compruébalo con `hermes skills`.

## Si algo falla
Ve a `04-troubleshooting.md`.
