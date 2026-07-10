---
name: ingerir
description: "Procesa el material nuevo que la alumna suelta en el inbox (PDF, audio, notas) sin pedirle rutas: lo lee, lo resume y lo archiva en el vault."
version: 1.0.0
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [estudio, ingesta, vault, ocr, transcripcion]
    related_skills: [estudiar, progreso]
---

# Ingerir material del inbox

## Para qué

La alumna solo suelta ficheros en una carpeta. Tú los procesas. Nunca le pidas que teclee la ruta de un fichero: los encuentras tú escaneando el inbox.

## Prerrequisitos

Toolsets `file` (escanear y escribir), `vision` (leer PDF e imágenes) y `code_execution`/`terminal` (transcribir audio si hace falta). Todo local, sin conexión.

## Dónde miras (relativo a la carpeta del proyecto)

- `student-local/vault/00_inbox/raw-pdf/` — documentos PDF.
- `student-local/vault/00_inbox/raw-audio/` — audios de clase o notas de voz.
- `student-local/vault/00_inbox/raw-notes/` — apuntes sueltos (txt, md).
- Destino de lo procesado: `student-local/vault/01_modules/<tema>/`.
- Estado a actualizar: `student-local/vault/99_state/STUDY_STATE.md`.

## Cómo procesas

1. Escanea las tres carpetas `raw-*`. Si están vacías, dilo con naturalidad y ofrece seguir con el estudio.
2. Para cada fichero nuevo:
   - PDF o imagen: léelo con vision. Saca las ideas clave, no lo copies entero.
   - Audio: transcríbelo con un script local (whisper/ffmpeg si está disponible); si no lo está, dilo y no lo des por hecho.
   - Notas: léelas directo.
3. Resume cada pieza en un fichero markdown claro dentro de `01_modules/<tema>/`, con el tema deducido del contenido. Nombra el fichero de forma legible.
4. Deja el original donde está (no borres nada de la alumna) y anota en `STUDY_STATE.md`, en Pendiente o A medias, el material recién anclado.
5. Cierra diciéndole en una frase qué has añadido y proponle empezar a estudiarlo.

## Reglas duras

- Cero rutas para la alumna: tú localizas el fichero.
- Todo en local. Nada de subir su material a servicios externos.
- Castellano de España, sin emojis. No inventes contenido que no esté en la fuente.
