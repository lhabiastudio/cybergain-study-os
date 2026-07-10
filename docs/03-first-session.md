# 03 — Primera sesión de estudio

## Objetivo
Tener una primera sesión útil, socrática y apoyada en tus archivos reales.

## Antes de empezar
Abre y revisa estas dos rutas:
- `C:\cybergain-study-os\student-local\vault\99_state\STUDY_STATE.md`
- `C:\cybergain-study-os\student-local\vault\99_state\SESSION_BRIEF.md`

Si todavía no has abierto el script de arranque, ejecútalo primero:

```powershell
cd C:\cybergain-study-os
powershell -ExecutionPolicy Bypass -File .\scripts\start-study.ps1
```

## Abrir Hermes
Abre una sesión interactiva con:

```powershell
hermes chat
```

## Cargar la disciplina base del tutor
Ten a mano este archivo:

```text
C:\cybergain-study-os\profiles\student\STUDY_TUTOR_PROMPT.md
```

Si todavía no has fijado ese comportamiento dentro de Hermes, pégalo al empezar la sesión.

## Prompt de apertura recomendado
Pega esto al arrancar:

```text
Quiero una sesión socrática. Usa el SESSION_BRIEF y el STUDY_STATE como contexto operativo. Objetivo de hoy: entender bien <tema>. No me des la respuesta demasiado pronto. Primero hazme pensar, luego corrige, luego resume.
```

## Si quieres que Hermes trabaje sobre un archivo concreto
Dile la ruta exacta. Ejemplos:

```text
Lee el PDF en C:\cybergain-study-os\student-local\vault\00_inbox\raw-pdf\tema-1.pdf y ayúdame a entenderlo paso a paso.
```

```text
Resume estas notas de C:\cybergain-study-os\student-local\vault\00_inbox\raw-notes\clase-02.txt y sácame 5 preguntas trampa.
```

## Flujo recomendado dentro de la sesión
1. Define un único objetivo.
2. Usa un material real del vault.
3. Obliga al tutor a hacerte pensar antes de resolver.
4. Cierra con resumen, lagunas y siguiente paso.

## Qué debería salir de una buena sesión
- una explicación clara del tema
- detección de lagunas
- preguntas de comprobación
- un siguiente paso concreto
- cambios en tus archivos de estado

## Cierre recomendado
Forma recomendada: ejecuta `scripts\close-session.ps1` y pega el prompt que genera en esta misma sesión de Hermes; actualiza estos ficheros por ti automáticamente.

A mano, esto es lo que se actualiza como mínimo:
- `C:\cybergain-study-os\student-local\vault\99_state\STUDY_STATE.md`
- `C:\cybergain-study-os\student-local\vault\99_state\SESSION_BRIEF.md`
- `C:\cybergain-study-os\student-local\vault\99_state\LEARN_LOG.md`
- `C:\cybergain-study-os\student-local\vault\99_state\MISCONCEPTIONS.md` si aplica

## Review pack
Cuando ya tengas varias sesiones, genera un pack de repaso así:

```powershell
cd C:\cybergain-study-os
powershell -ExecutionPolicy Bypass -File .\scripts\generate-review-pack.ps1
```
