# Cybergain Setup Guide

## Qué es esto
Cybergain Study OS es un sistema de estudio local para una alumna de bootcamp de ciberseguridad en Windows.

Su idea es simple:
- Hermes hace de tutor socrático y carga ese rol solo, sin que tengas que pegar ningún prompt
- tus archivos mandan más que la memoria del modelo
- el vault local guarda el estado real de tu estudio
- los scripts solo quitan fricción operativa

Con este documento deberías poder pasar de cero a primera sesión sin ayuda.

---

## Requisitos previos reales
Necesitas esto:
- Windows 11 recomendado
- conexión a internet
- plan ChatGPT activo
- PowerShell normal de usuario
- Git

Hermes instala su propio entorno. No necesitas instalar Python ni Node.js para usar el sistema de estudio.

Si no tienes Git y `winget` funciona en tu equipo, instálalo así:

```powershell
winget install -e --id Git.Git --accept-source-agreements --accept-package-agreements
```

Python y Node.js solo son opcionales si vas a regenerar tú misma el PDF de esta guía.

```powershell
winget install -e --id Python.Python.3.11 --accept-source-agreements --accept-package-agreements
winget install -e --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
```

---

## Paso 1 — Instalar Hermes
Abre PowerShell y ejecuta esto tal cual:

```powershell
iex (irm https://hermes-agent.nousresearch.com/install.ps1)
```

Cuando termine, cierra PowerShell y vuelve a abrirlo.

> Si después de instalar escribes `hermes` y Windows dice que no existe, cierra PowerShell por completo y ábrelo otra vez. Muchas veces el PATH no se refresca hasta una ventana nueva.

Comprueba la instalación:

```powershell
hermes --version
hermes doctor
```

Resultado esperado:
- `hermes --version` devuelve una versión
- `hermes doctor` termina y muestra el estado del sistema

---

## Paso 2 — Hacer login en OpenAI Codex
Ejecuta:

```powershell
hermes model
```

Dentro del selector:
1. Elige `OpenAI Codex`.
2. Completa el login en el navegador.
3. Vuelve a PowerShell cuando acabe.

Haz un smoke test real:

```powershell
hermes chat -q "Di solo: Hermes listo"
```

Resultado esperado: una respuesta corta del modelo.

Opcionalmente, mira las herramientas y skills instaladas:

```powershell
hermes tools list
hermes skills
```

---

## Paso 3 — Clonar el repo en una ruta corta
Abre PowerShell y ejecuta:

```powershell
cd C:\
git clone https://github.com/lhabiastudio/cybergain-study-os.git
cd cybergain-study-os
```

Resultado esperado: trabajas desde esta carpeta:

```text
C:\cybergain-study-os
```

> No uses rutas largas tipo `C:\Users\TuNombre\Documents\...`. Quédate con `C:\cybergain-study-os` para evitar problemas de `MAX_PATH`.

---

## Paso 4 — Ejecutar el setup inicial
La forma más simple es abrir el Explorador y hacer doble clic en:

```text
C:\cybergain-study-os\setup.bat
```

Si prefieres hacerlo desde PowerShell:

```powershell
cd C:\cybergain-study-os
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap-windows.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\check-system.ps1
```

Qué deja preparado este paso:
- `student-local`
- `student-local\vault`
- `student-local\outputs`
- `student-local\exports`
- `student-local\vault\00_inbox\raw-pdf`
- `student-local\vault\00_inbox\raw-audio`
- `student-local\vault\00_inbox\raw-notes`
- `student-local\vault\99_state`
- las skills del tutor instaladas en Hermes (copiadas a `~/.hermes/skills/cybergain/`), listas para que las use sola sin que tengas que hacer nada más

Puedes relanzar la comprobación cuando quieras:

```powershell
cd C:\cybergain-study-os
powershell -ExecutionPolicy Bypass -File .\scripts\check-system.ps1
```

---

## Paso 5 — Verificar la estructura que debes tener
Comprueba estas rutas:

Raíz del proyecto:
```text
C:\cybergain-study-os
```

Perfil del tutor:
```text
C:\cybergain-study-os\AGENTS.md
```

Vault local:
```text
C:\cybergain-study-os\student-local\vault
```

Entrada de PDFs:
```text
C:\cybergain-study-os\student-local\vault\00_inbox\raw-pdf
```

Entrada de audios:
```text
C:\cybergain-study-os\student-local\vault\00_inbox\raw-audio
```

Entrada de notas:
```text
C:\cybergain-study-os\student-local\vault\00_inbox\raw-notes
```

Estado vivo:
```text
C:\cybergain-study-os\student-local\vault\99_state
```

Outputs:
```text
C:\cybergain-study-os\student-local\outputs
```

Exports:
```text
C:\cybergain-study-os\student-local\exports
```

---

## Paso 6 — Meter tu material real de estudio
No hace falta que le des ninguna ruta a Hermes ni que la escribas en ningún sitio. Solo suelta el archivo en la carpeta que le corresponda:

PDFs del bootcamp:
```text
C:\cybergain-study-os\student-local\vault\00_inbox\raw-pdf
```

Audios o clases grabadas:
```text
C:\cybergain-study-os\student-local\vault\00_inbox\raw-audio
```

Notas personales o material suelto:
```text
C:\cybergain-study-os\student-local\vault\00_inbox\raw-notes
```

Después, dentro de Hermes, dile simplemente:

```text
Tengo material nuevo.
```

Hermes escanea esas tres carpetas él solo, lee lo que encuentra, lo resume y lo archiva en tu vault. No copies rutas ni pegues ficheros en el chat: solo suéltalos en la carpeta y avísale.

---

## Paso 7 — Abrir tu tutor y estudiar
Abre Hermes dentro de la carpeta del proyecto:

```powershell
cd C:\cybergain-study-os
hermes chat
```

No hace falta pegar ningún prompt. Hermes lee `AGENTS.md` al arrancar en esta carpeta y ya sabe que es tu tutor: revisa por dónde vas, te saluda, te recuerda cómo trabajáis juntos y te pregunta cuál es tu objetivo de hoy.

Dentro de la sesión:
1. Confirma o cambia el objetivo que te propone.
2. Pídele directamente el tema que quieras trabajar; él busca primero en tu vault antes que en su memoria general.
3. Deja que te haga pensar antes de darte la respuesta completa.
4. Si has soltado material nuevo en el inbox, dile "tengo material nuevo" y lo procesa él (ver Paso 6).

> Si tienes dudas de cómo funciona esto por dentro, `profiles\student\COMO_TRABAJAMOS.md` explica la disciplina que sigue Hermes contigo.

---

## Paso 8 — Cerrar la sesión
No hace falta que edites nada a mano. Al terminar, dile a Hermes:

```text
Cerramos.
```

Hermes te resume qué has entendido, qué sigue flojo, qué conviene repasar y te deja un mini ejercicio de comprobación. Después actualiza él mismo estos ficheros de estado:

Estado general de estudio:
```text
C:\cybergain-study-os\student-local\vault\99_state\STUDY_STATE.md
```

Brief operativo de la siguiente sesión:
```text
C:\cybergain-study-os\student-local\vault\99_state\SESSION_BRIEF.md
```

Log de lo aprendido:
```text
C:\cybergain-study-os\student-local\vault\99_state\LEARN_LOG.md
```

Errores conceptuales o ideas mal entendidas:
```text
C:\cybergain-study-os\student-local\vault\99_state\MISCONCEPTIONS.md
```

> Revisa lo que Hermes escriba. La memoria del vault es tu fuente de verdad: si algo quedó mal, corrígelo a mano.

---

## Paso 9 — Ver tu dashboard de progreso
Cuando quieras ver de un vistazo tu progreso, los apuntes que ha dejado Hermes para la próxima sesión y los errores conceptuales que tienes que repasar, ejecuta:

```powershell
cd C:\cybergain-study-os
powershell -ExecutionPolicy Bypass -File .\scripts\dashboard.ps1
```

Esto genera una página y la abre en tu navegador. Se construye a partir de tu vault local: no sube nada a internet.

También puedes pedírselo directamente a Hermes dentro del chat: "¿por dónde voy?" te da el mismo resumen en texto, sin abrir nada.

> El dashboard es una foto de tu vault en este momento. Vuelve a ejecutarlo cuando quieras verlo actualizado.

---

## Paso 10 — Generar un review pack semanal
Cuando quieras preparar material de repaso, ejecuta:

```powershell
cd C:\cybergain-study-os
powershell -ExecutionPolicy Bypass -File .\scripts\generate-review-pack.ps1
```

Resultado esperado: se crea una carpeta con fecha dentro de:

```text
C:\cybergain-study-os\student-local\outputs
```

Ahí tendrás un pack base para repasar y seguir trabajando con Hermes.

También puedes pedirle un repaso directamente dentro del chat, por ejemplo "hazme un repaso de lo que llevo flojo": Hermes monta la sesión de recuerdo activo él solo, apoyándose en tus errores conceptuales abiertos.

---

## Paso 11 — Proteger material de laboratorio
> Si vas a guardar payloads, binarios o muestras de laboratorio, Windows Defender puede borrarlos o ponerlos en cuarentena. Añade una exclusión para `C:\cybergain-study-os\student-local` antes de pensar que el sistema ha perdido tus archivos.

---

## Troubleshooting rápido

### `hermes` no aparece
```powershell
hermes --version
hermes doctor
```
Si no existe, cierra PowerShell y vuelve a abrirlo.

### El login no aparece
```powershell
hermes model
```
Si sigue fallando, cambia de navegador por defecto o revisa VPN/firewall.

### PowerShell bloquea scripts
Ejecuta así:

```powershell
cd C:\cybergain-study-os
powershell -ExecutionPolicy Bypass -File .\scripts\check-system.ps1
```

### El sistema no encuentra material
Revisa que tus archivos estén exactamente en la carpeta `raw-*` que toque:
- `C:\cybergain-study-os\student-local\vault\00_inbox\raw-pdf`
- `C:\cybergain-study-os\student-local\vault\00_inbox\raw-audio`
- `C:\cybergain-study-os\student-local\vault\00_inbox\raw-notes`

Si están ahí y Hermes no los menciona, dile dentro del chat "tengo material nuevo" para que vuelva a escanear el inbox.

### El tutor responde demasiado directo
Recuérdaselo dentro de la misma conversación: "quiero que me hagas pensar antes de darme la respuesta". No hace falta reactivar nada ni pegar ningún prompt: es su forma de trabajar por defecto, marcada en `AGENTS.md`.

---

## Resumen final del flujo correcto
1. Instalar Git si hace falta.
2. Instalar Hermes.
3. Hacer login en Codex con `hermes model`.
4. Clonar el repo en `C:\cybergain-study-os`.
5. Ejecutar `setup.bat` una vez: crea tu vault local e instala las skills del tutor.
6. Soltar material nuevo en `student-local\vault\00_inbox\raw-*` cuando lo tengas.
7. Abrir Hermes con `hermes chat` dentro de la carpeta del proyecto: te saluda y te guía él solo.
8. Estudiar con disciplina socrática.
9. Al terminar, decirle "cerramos": Hermes actualiza tu estado por ti.
10. Ver el progreso con `dashboard.ps1` o preguntándoselo directamente a Hermes.
11. Generar review packs cuando toque.
