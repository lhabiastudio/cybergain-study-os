# Cybergain Setup Guide

## Qué es esto
Cybergain Study OS es un sistema de estudio local para una alumna de bootcamp de ciberseguridad en Windows.

Su idea es simple:
- Hermes hace de tutor socrático
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
C:\cybergain-study-os\profiles\student\STUDY_TUTOR_PROMPT.md
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
Copia tus archivos aquí:

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

No metas los archivos dentro del prompt. Mételos en estas carpetas.

Importante: los scripts de ingesta solo depositan el fichero en el inbox. No hacen OCR ni transcripción automática por sí solos.

Si quieres que Hermes procese luego un archivo, pídeselo tú con la ruta exacta. Ejemplo:

```powershell
hermes chat -q "Lee el PDF en C:\cybergain-study-os\student-local\vault\00_inbox\raw-pdf\tema-1.pdf y hazme un resumen claro en español"
```

Si tienes una skill instalada para OCR o transcripción, mírala con:

```powershell
hermes skills
```

---

## Paso 7 — Cargar la disciplina del tutor
El comportamiento base del tutor está aquí:

```text
C:\cybergain-study-os\profiles\student\STUDY_TUTOR_PROMPT.md
```

Ábrelo y úsalo como base de instrucciones fijas del tutor, o pégalo al iniciar la sesión.

La lógica del sistema es esta:
- primero pensar
- luego corregir
- luego resumir

---

## Paso 8 — Preparar y abrir la primera sesión
Primero ejecuta el script de arranque:

```powershell
cd C:\cybergain-study-os
powershell -ExecutionPolicy Bypass -File .\scripts\start-study.ps1
```

Ese script te recuerda tres rutas clave:
- `profiles\student\STUDY_TUTOR_PROMPT.md`
- `student-local\vault\99_state\SESSION_BRIEF.md`
- `student-local\vault\99_state\STUDY_STATE.md`

Después abre Hermes de forma interactiva con:

```powershell
hermes chat
```

Pega este arranque base:

```text
Quiero una sesión socrática. Usa el SESSION_BRIEF y el STUDY_STATE como contexto operativo. Objetivo de hoy: entender bien <tema>. No me des la respuesta demasiado pronto. Primero hazme pensar, luego corrige, luego resume.
```

---

## Paso 9 — Flujo recomendado dentro de cada sesión
Usa este patrón:
1. Define un único objetivo.
2. Señala qué archivo o material quieres trabajar.
3. Obliga al tutor a hacerte pensar antes de responder.
4. Cierra con resumen, lagunas y siguiente paso.

Ejemplos de peticiones útiles dentro de Hermes:

```text
Lee el PDF en C:\cybergain-study-os\student-local\vault\00_inbox\raw-pdf\redes-tema-2.pdf y hazme preguntas antes de explicármelo.
```

```text
Resume mis notas de C:\cybergain-study-os\student-local\vault\00_inbox\raw-notes\repaso-firewall.txt y sácame 10 flashcards.
```

---

## Paso 10 — Actualizar el estado al terminar
Al cerrar una sesión, actualiza como mínimo estos archivos:

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

Qué deberías dejar apuntado:
- qué has entendido
- qué no has entendido todavía
- qué toca en la próxima sesión

---

## Paso 11 — Generar un review pack semanal
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

---

## Paso 12 — Proteger material de laboratorio
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
Revisa que tus archivos estén exactamente en:
- `C:\cybergain-study-os\student-local\vault\00_inbox\raw-pdf`
- `C:\cybergain-study-os\student-local\vault\00_inbox\raw-audio`
- `C:\cybergain-study-os\student-local\vault\00_inbox\raw-notes`

### El tutor responde demasiado directo
Vuelve a cargar `STUDY_TUTOR_PROMPT.md` y repite el arranque socrático.

---

## Resumen final del flujo correcto
1. Instalar Git si hace falta.
2. Instalar Hermes.
3. Hacer login en Codex con `hermes model`.
4. Clonar el repo en `C:\cybergain-study-os`.
5. Ejecutar `setup.bat`.
6. Meter material en `student-local\vault\00_inbox`.
7. Ejecutar `start-study.ps1`.
8. Abrir Hermes con `hermes chat`.
9. Estudiar con disciplina socrática.
10. Actualizar `99_state`.
11. Generar review packs cuando toque.
