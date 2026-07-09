# Cybergain Study OS

Sistema de estudio local para una alumna de bootcamp de ciberseguridad en Windows, usando Hermes como tutor socrático y un vault local como fuente de verdad.

## Qué trae este repo
- `vault-template/` — plantilla inicial del vault
- `profiles/student/` — prompt base del tutor
- `scripts/` — scripts PowerShell para setup y uso diario
- `docs/` — guía maestra, instalación, primera sesión y troubleshooting

## Límites del producto
Esto no es una app compleja ni un sistema multiagente.

Sí incluye:
- instalación en Windows paso a paso
- login en Hermes con OpenAI Codex
- vault local para estudiar con tus propios materiales
- scripts simples para preparar, revisar y arrancar sesiones

No incluye:
- daemons
- automatizaciones opacas
- swarms
- depender de la memoria del modelo en vez de tus archivos

## Flujo recomendado
1. Instala Hermes en Windows con `docs/Cybergain-Setup-Guide.md`.
2. En `hermes model`, elige `OpenAI Codex`.
3. Clona este repo en `C:\cybergain-study-os`.
4. Ejecuta `setup.bat`.
5. Mete tus PDFs, audios y notas en `student-local\vault\00_inbox`.
6. Ejecuta `scripts\start-study.ps1`.
7. Abre Hermes con `hermes chat`.
8. Estudia con un objetivo concreto.
9. Actualiza `STUDY_STATE.md` y `SESSION_BRIEF.md`.
10. Genera packs de repaso con `scripts\generate-review-pack.ps1`.

## Prerrequisitos reales
- Git
- PowerShell normal de usuario
- conexión a internet
- plan ChatGPT activo

Hermes instala su propio Python y su propio entorno. No necesitas instalar Python ni Node.js para usar el sistema de estudio.

Python y Node.js solo son opcionales si vas a regenerar tú misma el PDF de la guía.

## Notas de Windows
- Usa una ruta corta como `C:\cybergain-study-os`.
- `setup.bat` ya llama a PowerShell con `-ExecutionPolicy Bypass`.
- Si guardas material de laboratorio, añade exclusión de Defender para `student-local`.

## Documentación principal
- `docs/Cybergain-Setup-Guide.md` — guía maestra autosuficiente
- `docs/01-install-hermes-windows.md`
- `docs/02-install-study-os.md`
- `docs/03-first-session.md`
- `docs/04-troubleshooting.md`
