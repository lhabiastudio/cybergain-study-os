# 03 — Primera sesión de estudio

## Objetivo
Tener una primera sesión útil, socrática y apoyada en tus archivos reales.

## Abrir Hermes
No hace falta preparar nada antes. Abre PowerShell dentro de la carpeta del proyecto y arranca Hermes ahí mismo:

```powershell
cd C:\cybergain-study-os
hermes chat
```

Hermes lee `AGENTS.md` al abrirse en esta carpeta y ya carga solo su rol de tutor. No pegues ningún prompt: te saluda, revisa `STUDY_STATE.md` y `SESSION_BRIEF.md` por su cuenta y te pregunta cuál es tu objetivo de hoy.

## Qué te dice al empezar
En una primera instalación, el vault está casi vacío. Hermes lo nota y te lo dice con naturalidad, sin bloquearse: te propone empezar por meter tu primer material o por definir el objetivo del día directamente.

## Si quieres que Hermes trabaje sobre un archivo concreto
No hace falta que le des la ruta. Suelta el fichero en la carpeta que le corresponda del inbox y dile:

```text
Tengo material nuevo.
```

Si el fichero ya está en el inbox de una sesión anterior, puedes pedírselo también así:

```text
Tengo un PDF nuevo sobre redes, échale un ojo.
```

Hermes escanea `student-local\vault\00_inbox\` él solo, lo lee, lo resume y te propone estudiarlo.

## Flujo recomendado dentro de la sesión
1. Define un único objetivo (o confirma el que te propone Hermes).
2. Trabaja sobre un material real de tu vault.
3. Deja que el tutor te haga pensar antes de darte la respuesta.
4. Cierra con resumen, lagunas y siguiente paso.

## Qué debería salir de una buena sesión
- una explicación clara del tema
- detección de lagunas
- preguntas de comprobación
- un siguiente paso concreto
- cambios en tus archivos de estado, hechos por Hermes

## Cierre recomendado
Dile a Hermes, en la misma conversación donde has estudiado:

```text
Cerramos.
```

Él actualiza estos ficheros por ti, sin que tengas que tocarlos a mano:
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

También puedes pedirle un repaso directamente dentro del chat.

Para ver tu progreso y los apuntes de Hermes, ejecuta `scripts\dashboard.ps1` o pregúntale a Hermes "¿por dónde voy?" cuando quieras.
