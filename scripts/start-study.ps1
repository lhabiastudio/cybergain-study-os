$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$Brief = Join-Path $RepoRoot "student-local\vault\99_state\SESSION_BRIEF.md"
$State = Join-Path $RepoRoot "student-local\vault\99_state\STUDY_STATE.md"
$PromptFile = Join-Path $RepoRoot "profiles\student\STUDY_TUTOR_PROMPT.md"

Write-Host "Abre una nueva sesión Hermes con esta disciplina:"
Write-Host "- Tutor prompt: $PromptFile"
Write-Host "- Session brief: $Brief"
Write-Host "- Study state: $State"
Write-Host ""
Write-Host "Paso recomendado:"
Write-Host 'hermes'
Write-Host ""
Write-Host "Y pega al empezar:"
Write-Host "Quiero una sesión socrática. Usa el SESSION_BRIEF y el STUDY_STATE como contexto operativo."
