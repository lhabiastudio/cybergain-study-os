# 04 — Troubleshooting

## `hermes` no aparece después de instalar
1. Cierra PowerShell por completo.
2. Ábrelo otra vez.
3. Ejecuta:

```powershell
hermes --version
hermes doctor
```

> Si acabas de instalar Hermes y Windows sigue diciendo que `hermes` no existe, casi siempre es porque la ventana de PowerShell antigua no ha refrescado el PATH. Cierra y abre una nueva antes de hacer nada más.

## El login de Codex no aparece
Ejecuta otra vez:

```powershell
hermes model
```

Si sigue fallando:
- cambia de navegador por defecto
- desactiva temporalmente VPN o firewall corporativo
- repite el proceso con una conexión normal a internet

## Error de modelo o proveedor
Haz esta comprobación mínima:

```powershell
hermes model
hermes chat -q "ping"
```

Si `hermes chat -q "ping"` no devuelve nada útil, repite el login en `hermes model`.

## PowerShell bloquea scripts
Ejecuta los scripts así:

```powershell
cd C:\cybergain-study-os
powershell -ExecutionPolicy Bypass -File .\scripts\check-system.ps1
```

O usa directamente:

```text
C:\cybergain-study-os\setup.bat
```

## El sistema no encuentra tus archivos
Comprueba que están exactamente aquí:
- `C:\cybergain-study-os\student-local\vault\00_inbox\raw-pdf`
- `C:\cybergain-study-os\student-local\vault\00_inbox\raw-audio`
- `C:\cybergain-study-os\student-local\vault\00_inbox\raw-notes`

Si usaste `ingest-pdf.ps1` o `ingest-audio.ps1`, o si copiaste el archivo a mano, recuerda esto: el fichero solo queda depositado en el inbox, nadie lo procesa por sí solo hasta que se lo dices a Hermes.

Dentro del chat, dile simplemente:

```text
Tengo material nuevo.
```

Hermes escanea las tres carpetas del inbox él solo y lo procesa. No hace falta que le des ninguna ruta.

## El tutor responde demasiado directo
- recuérdaselo dentro de la misma conversación: "quiero que me hagas pensar antes de darme la respuesta"
- no hace falta reactivar nada ni pegar ningún prompt: su forma de trabajar por defecto está marcada en `AGENTS.md`
- usa el flujo recomendado en `03-first-session.md`
- registra el fallo en `MISCONCEPTIONS.md` si te ayuda

## El repo está en una ruta demasiado larga
Mueve o vuelve a clonar el repo aquí:

```text
C:\cybergain-study-os
```

Las rutas largas en Windows pueden romper scripts, copias de archivos o materiales de laboratorio.

## Windows Defender borra material de laboratorio
- añade una exclusión para `C:\cybergain-study-os\student-local`
- vuelve a copiar los archivos después de añadir la exclusión
- no des por hecho que el problema es Hermes si el archivo desaparece del disco

## No tienes Git instalado
Si `winget` funciona en tu equipo, instala Git así:

```powershell
winget install -e --id Git.Git --accept-source-agreements --accept-package-agreements
```

## Quieres regenerar el PDF de la guía
Esto es opcional. Solo hace falta si quieres reconstruir el PDF tú misma.

Instala Python y Node.js si no los tienes:

```powershell
winget install -e --id Python.Python.3.11 --accept-source-agreements --accept-package-agreements
winget install -e --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
```

Luego vuelve a lanzar el proceso de generación del PDF según la documentación del repo.
