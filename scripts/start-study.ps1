$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$Brief = Join-Path $RepoRoot "student-local\vault\99_state\SESSION_BRIEF.md"
$State = Join-Path $RepoRoot "student-local\vault\99_state\STUDY_STATE.md"
$PromptFile = Join-Path $RepoRoot "profiles\student\ACTIVATION_PROMPT.md"
$ComoTrabajamos = Join-Path $RepoRoot "profiles\student\COMO_TRABAJAMOS.md"

Write-Host "Abre Hermes dentro de esta carpeta y listo: carga su rol de tutor él solo."
Write-Host ""
Write-Host "Paso recomendado:"
Write-Host 'hermes chat'
Write-Host ""
Write-Host "Se apoya en:"
Write-Host "- Session brief: $Brief"
Write-Host "- Study state: $State"
Write-Host ""
Write-Host "No hace falta pegar ningún prompt. Si alguna vez quieres verlo como respaldo:"
Write-Host $PromptFile
Write-Host ""
Write-Host "Si tienes dudas de cómo funciona esto, abre:"
Write-Host $ComoTrabajamos
