---
name: progreso
description: "Resume a la alumna por dónde va: módulo actual, qué domina, qué lleva a medias, qué queda pendiente y cuál es el próximo objetivo. Solo lectura."
version: 1.0.0
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [estudio, progreso, estado]
    related_skills: [estudiar, cerrar-sesion, repaso]
---

# Progreso

## Para qué

Darle una foto clara de dónde está sin que tenga que abrir ningún fichero. No modifica nada: solo lee y resume.

## Qué lees (relativo a la carpeta del proyecto)

- `student-local/vault/99_state/STUDY_STATE.md` — módulo, objetivos, dominado / a medias / pendiente, bloqueos.
- `student-local/vault/99_state/LEARN_LOG.md` — la bitácora, para ver la evolución de las últimas sesiones.

## Qué le cuentas

1. En qué módulo y objetivo está ahora.
2. Qué ya domina, qué lleva a medias y qué queda pendiente (en frases, no en volcado literal).
3. Cómo ha ido evolucionando según la bitácora (últimas sesiones).
4. Si hay bloqueos, nómbralos y sugiere cómo desatascarlos.
5. Cierra proponiendo el próximo objetivo concreto.

## Reglas duras

- Solo lectura: no toques los ficheros de estado.
- Si el estado está casi vacío (instalación nueva), dilo con naturalidad y anima a empezar.
- Castellano de España, sin emojis. Cero rutas para la alumna.
