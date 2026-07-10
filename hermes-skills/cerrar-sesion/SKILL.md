---
name: cerrar-sesion
description: "Cierra la sesión de estudio: resumen para la alumna (entendido, flojo, repasar, mini-ejercicio) y actualización de los ficheros de estado y la memoria."
version: 1.0.0
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [estudio, cierre, estado, memoria]
    related_skills: [estudiar, progreso]
---

# Cerrar sesión

## Para qué

Deja constancia de lo trabajado para que la próxima sesión arranque sabiendo por dónde va. Lo haces tú, no se lo pides a ella.

## Resumen para la alumna

Cierra siempre diciéndole, claro y breve:
- Qué ha entendido hoy.
- Qué sigue flojo.
- Qué conviene repasar.
- Un mini-ejercicio de comprobación para la próxima.

## Actualiza el estado (con el toolset file)

Escribe en `student-local/vault/99_state/`, respetando la estructura clave:valor y las plantillas existentes; edita lo que cambia, no reescribas lo demás:

1. `STUDY_STATE.md` — mueve conceptos entre Dominado / A medias / Pendiente, actualiza `objetivo_actual`, `objetivo_siguiente`, `modulo_actual` y `ultima_actualizacion` (fecha de hoy).
2. `SESSION_BRIEF.md` — deja preparado `objetivo` y `material_a_anclar` de la próxima sesión.
3. `LEARN_LOG.md` — añade una línea (append, no borres las anteriores) con el formato de la plantilla: fecha, tema, qué quedó más claro, qué sigue flojo, siguiente acción.
4. `MISCONCEPTIONS.md` — si ha aparecido un error conceptual, añádelo con su bloque (concepto, suposición equivocada, modelo correcto, ejemplo, estado abierto); si ha corregido uno anterior, márcalo resuelto.

## Anota en memoria

Guarda en tu memoria (toolset `memory`) lo esencial de la sesión: tema tratado, nivel alcanzado y qué retomar. Así mantienes contexto entre sesiones aunque no relea los ficheros.

## Reglas duras

- No pierdas datos anteriores: LEARN_LOG y MISCONCEPTIONS son acumulativos.
- Castellano de España, sin emojis. Cero rutas para la alumna.
