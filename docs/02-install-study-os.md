# 02 — Instalar Cybergain Study OS

## Objetivo
Clonar el repo, preparar la estructura local y dejar listo el arranque diario.

## Paso 1 — Clonar el repo en una ruta corta
Abre PowerShell y ejecuta esto tal cual:

```powershell
cd C:\
git clone https://github.com/lhabiastudio/cybergain-study-os.git
cd cybergain-study-os
```

Resultado esperado: acabas dentro de esta ruta:

```text
C:\cybergain-study-os
```

> No clones el repo dentro de `Documents`, `Desktop` o rutas largas tipo `C:\Users\TuNombre\Documents\...`. Usa `C:\cybergain-study-os` para evitar problemas de `MAX_PATH`.

## Paso 2 — Ejecutar el setup inicial
La opción más simple es hacer doble clic en este archivo desde el Explorador:

```text
C:\cybergain-study-os\setup.bat
```

Alternativa desde PowerShell:

```powershell
cd C:\cybergain-study-os
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap-windows.ps1
```

Resultado esperado:
- se crea `student-local`
- se crea `student-local\vault`
- se copia la plantilla inicial del vault
- se crean las carpetas de entradas, outputs y exports
- se instalan las skills del tutor en Hermes (`~/.hermes/skills/cybergain/`), listas para usarse solas sin configuración adicional

## Paso 3 — Revisar el estado inicial
Ejecuta:

```powershell
cd C:\cybergain-study-os
powershell -ExecutionPolicy Bypass -File .\scripts\check-system.ps1
```

Resultado esperado: ves una comprobación rápida del sistema y la presencia de `STUDY_STATE.md`.

## Paso 4 — Confirmar las carpetas importantes
Comprueba que existen estas rutas:

```text
C:\cybergain-study-os\student-local\vault
C:\cybergain-study-os\student-local\vault\00_inbox\raw-pdf
C:\cybergain-study-os\student-local\vault\00_inbox\raw-audio
C:\cybergain-study-os\student-local\vault\00_inbox\raw-notes
C:\cybergain-study-os\student-local\vault\99_state
C:\cybergain-study-os\student-local\outputs
C:\cybergain-study-os\student-local\exports
```

## Paso 5 — Meter material real
Copia o mueve tus archivos a estas carpetas:
- PDFs del bootcamp → `C:\cybergain-study-os\student-local\vault\00_inbox\raw-pdf`
- audios o clases grabadas → `C:\cybergain-study-os\student-local\vault\00_inbox\raw-audio`
- notas personales → `C:\cybergain-study-os\student-local\vault\00_inbox\raw-notes`

No hace falta que teclees ninguna ruta ni que hagas nada más: la próxima vez que abras Hermes en esta carpeta, o si le dices "tengo material nuevo", él escanea el inbox solo, lo lee y lo archiva en tu vault.

## Paso 6 — Abrir la primera sesión
Abre Hermes directamente dentro de la carpeta del proyecto:

```powershell
cd C:\cybergain-study-os
hermes chat
```

Resultado esperado: Hermes carga su rol de tutor solo (a partir de `AGENTS.md`), te saluda y te pregunta cuál es tu objetivo de hoy. No hace falta pegar ningún prompt.

Si quieres ver un recordatorio en texto de las rutas de estado antes de entrar, puedes ejecutar opcionalmente:

```powershell
cd C:\cybergain-study-os
powershell -ExecutionPolicy Bypass -File .\scripts\start-study.ps1
```

## Paso 7 — Proteger material de laboratorio
> Si guardas payloads, binarios o muestras de laboratorio, Windows Defender puede borrarlos o ponerlos en cuarentena. Añade una exclusión para `C:\cybergain-study-os\student-local` antes de pensar que Hermes o el repo han perdido tus archivos.

## Qué no hacer
- No metas todo el temario en el prompt manualmente.
- No uses Hermes como enciclopedia sin apoyarte en tus archivos.
- No prometas procesamiento automático a algo que solo has copiado al inbox.
