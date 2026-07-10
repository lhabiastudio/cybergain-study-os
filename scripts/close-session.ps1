$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$StateDir = Join-Path $RepoRoot "student-local\vault\99_state"

$StudyState     = Join-Path $StateDir "STUDY_STATE.md"
$SessionBrief   = Join-Path $StateDir "SESSION_BRIEF.md"
$LearnLog       = Join-Path $StateDir "LEARN_LOG.md"
$Misconceptions = Join-Path $StateDir "MISCONCEPTIONS.md"

if (-not (Test-Path $StudyState)) {
    throw "No encuentro el estado del vault en $StateDir. Ejecuta antes bootstrap-windows.ps1 (o setup.bat)."
}

$DateStamp = Get-Date -Format "yyyy-MM-dd"
$PromptFile = Join-Path $StateDir "_close-session-prompt.txt"

$prompt = @"
Cierre de sesion de estudio ($DateStamp). Actualiza mi memoria del vault a partir de la conversacion de HOY.

Edita directamente estos 4 ficheros (rutas exactas de este equipo):
1. $StudyState
   Estado general: modulo activo, temas ya dominados vs pendientes, sensacion real de avance. No inventes progreso.
2. $SessionBrief
   Prepara la PROXIMA sesion: UN objetivo concreto + que material del vault repasar.
3. $LearnLog
   Anade una entrada fechada [$DateStamp] con lo aprendido hoy (2-4 lineas).
4. $Misconceptions
   Anade o corrige errores conceptuales detectados hoy. Marca como resueltos los que ya he entendido.

Reglas: escribe austero y concreto. Si un fichero no necesita cambios, dilo y no lo toques. Manten la estructura de campos de cada fichero (lineas 'clave: valor' y los encabezados de seccion) para que el dashboard pueda leerlos. Al terminar, resumeme en 3 lineas que actualizaste.
"@

Set-Content -Encoding UTF8 $PromptFile $prompt

Write-Host "Prompt de cierre generado en:"
Write-Host "  $PromptFile"
Write-Host ""
Write-Host "IMPORTANTE: pega este prompt al FINAL de tu sesion de estudio, en la MISMA"
Write-Host "conversacion de Hermes (necesita el contexto de hoy para actualizar bien)."
Write-Host "Un chat nuevo NO sirve: no tendria la conversacion que resumir."
Write-Host ""
Write-Host "----- PROMPT (copia desde aqui) -----"
Write-Host $prompt
Write-Host "----- fin del prompt -----"
Write-Host ""
Write-Host "Hermes actualizara los 4 ficheros de estado por ti. Revisa que lo que escribio es correcto."
Write-Host ""
Write-Host "Cuando Hermes termine de actualizar, mira tu progreso con:"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\scripts\dashboard.ps1"
