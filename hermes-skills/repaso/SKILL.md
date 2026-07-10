---
name: repaso
description: "Monta un repaso activo de lo que la alumna lleva a medias y de sus errores conceptuales abiertos, con preguntas de recuerdo en lugar de releer."
version: 1.0.0
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [estudio, repaso, recuerdo-activo, misconceptions]
    related_skills: [estudiar, progreso, conectar]
---

# Repaso

## Para qué

Consolidar lo aprendido con recuerdo activo, no releyendo. Se centra en lo flojo y en los errores de modelo mental pendientes.

## Qué lees (relativo a la carpeta del proyecto)

- `student-local/vault/99_state/STUDY_STATE.md` — la sección A medias y Pendiente.
- `student-local/vault/99_state/MISCONCEPTIONS.md` — los errores conceptuales abiertos.
- `student-local/vault/01_modules/` — el material de los temas a repasar, como fuente.
- `student-local/vault/99_state/CONCEPT_MAP.md` — el orden de repaso sugerido por dependencia, si existe. Úsalo para priorizar qué repasar primero.

## Cómo lo montas

1. Elige los conceptos que lleva a medias y los misconceptions abiertos como foco del repaso. Si existe `CONCEPT_MAP.md`, respeta su orden de repaso sugerido (lo básico primero).
2. En lugar de explicárselos, hazle preguntas de recuerdo: que reconstruya el concepto con sus palabras.
3. Cuando falle o dude, guíala con pistas antes que con la respuesta; apóyate en su material del vault.
4. Para cada misconception, comprueba si ya lo tiene corregido; si es así, díselo para poder marcarlo resuelto al cerrar.
5. Cierra con una lectura honesta: qué ya está firme y qué toca volver a ver.

## Reglas duras

- Recuerdo activo primero; explicar solo cuando se atasca.
- No marques nada resuelto tú solo: eso pasa por `cerrar-sesion`.
- Castellano de España, sin emojis. Cero rutas para la alumna.
