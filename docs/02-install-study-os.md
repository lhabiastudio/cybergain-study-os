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

Importante: los scripts de ingesta solo copian el fichero al inbox. No hacen OCR ni transcripción por sí solos.

Si quieres procesar luego un archivo con Hermes, pídeselo tú de forma explícita. Ejemplo:

```powershell
hermes chat -q "Lee el PDF en C:\cybergain-study-os\student-local\vault\00_inbox\raw-pdf\tema-1.pdf y hazme un resumen claro en español"
```

## Paso 6 — Preparar la primera sesión
Ejecuta:

```powershell
cd C:\cybergain-study-os
powershell -ExecutionPolicy Bypass -File .\scripts\start-study.ps1
```

Resultado esperado: la terminal te recuerda tres rutas clave:
- `profiles\student\STUDY_TUTOR_PROMPT.md`
- `student-local\vault\99_state\SESSION_BRIEF.md`
- `student-local\vault\99_state\STUDY_STATE.md`

## Paso 7 — Proteger material de laboratorio
> Si guardas payloads, binarios o muestras de laboratorio, Windows Defender puede borrarlos o ponerlos en cuarentena. Añade una exclusión para `C:\cybergain-study-os\student-local` antes de pensar que Hermes o el repo han perdido tus archivos.

## Qué no hacer
- No metas todo el temario en el prompt manualmente.
- No uses Hermes como enciclopedia sin apoyarte en tus archivos.
- No prometas procesamiento automático a algo que solo has copiado al inbox.
