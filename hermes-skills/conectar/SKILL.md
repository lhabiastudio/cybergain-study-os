---
name: conectar
description: "Conecta los conceptos que la alumna ya ha estudiado: detecta cómo se relacionan entre módulos (qué construye sobre qué, qué se contradice, qué ejemplifica, qué requiere qué) y deja un mapa en texto con un orden de repaso sugerido."
version: 1.0.0
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [estudio, conceptos, relaciones, mapa, orden-repaso]
    related_skills: [repaso, progreso, estudiar]
---

# Conectar

## Para qué

El estudio va tema a tema, pero el conocimiento real está en cómo se enlazan. Esta skill lee lo que la alumna ya ha procesado y saca a la luz las relaciones entre conceptos que no son obvias leyendo un módulo aislado: qué idea se apoya en otra, dónde hay una contradicción que aclarar, qué es un ejemplo concreto de algo más general, y qué conviene dominar antes de seguir. El resultado no es un grafo bonito: es un mapa en texto, útil, que ordena el repaso.

## Qué lees (relativo a la carpeta del proyecto)

- `student-local/vault/01_modules/` — todo el material ya procesado. Es la fuente principal.
- `student-local/vault/99_state/STUDY_STATE.md` — qué domina, qué lleva a medias, qué está pendiente.
- `student-local/vault/99_state/MISCONCEPTIONS.md` — errores conceptuales abiertos.
- `student-local/vault/99_state/CONCEPT_MAP.md` — el mapa anterior, si existe; lo actualizas, no lo reescribes de cero.

## Cómo lo montas

1. Escanea `01_modules/` y localiza los conceptos clave de cada tema (no cada palabra: las ideas que sostienen el tema).
2. Para cada par de conceptos con evidencia clara en el texto, clasifica la relación con una de estas etiquetas:
   - `construye_sobre` — el concepto A extiende, refina o depende de B.
   - `contradice` — A choca con o corrige una posición de B (candidato a MISCONCEPTIONS).
   - `ejemplifica` — A es un ejemplo concreto de la idea general B.
   - `requiere` — hay que entender B antes de abordar A (prerrequisito).
   Solo emite una relación si el material la respalda; no inventes enlaces por asociación libre.
3. Calcula el orden de repaso: los conceptos de los que dependen muchos otros (más relaciones entrantes de tipo `requiere` y `construye_sobre`) van primero. Eso da la secuencia en la que conviene repasar para que lo demás cuadre.
4. Escribe el resultado en `99_state/CONCEPT_MAP.md` respetando su plantilla: una entrada por concepto con sus relaciones tipadas, más la sección de orden de repaso sugerido. Actualiza `ultima_actualizacion`.
5. Si detectas una contradicción real entre lo que dicen dos módulos, señálala a la alumna y deja constancia para que `cerrar-sesion` la valore como misconception.
6. Cierra explicándole en dos o tres frases qué has conectado y por dónde le conviene empezar el repaso, sin abrumarla con todo el mapa de golpe.

## Cuándo tiene sentido usarla

- Cuando ya hay al menos tres o cuatro temas procesados en `01_modules/` (con menos, no hay nada que conectar).
- Antes de un repaso amplio, para ordenarlo por dependencia en vez de por orden de llegada.
- Cuando la alumna dice cosas como "no veo cómo encaja esto con lo de antes" o "se me mezclan los temas".

## Reglas duras

- El mapa es una herramienta de estudio, no un adorno: texto claro, cero grafos decorativos.
- No inventes relaciones: cada enlace se apoya en el material del vault.
- No marques misconceptions como resueltos tú solo: eso pasa por `cerrar-sesion`.
- Todo en local, sin conexión. Cero rutas para la alumna: escaneas tú el vault.
- Castellano de España peninsular, sin emojis.
