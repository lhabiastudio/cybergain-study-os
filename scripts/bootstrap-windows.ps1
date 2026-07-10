$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$StudentRoot = Join-Path $RepoRoot "student-local"
$VaultRoot = Join-Path $StudentRoot "vault"
$TemplateRoot = Join-Path $RepoRoot "vault-template"
$OutputsRoot = Join-Path $StudentRoot "outputs"
$ExportsRoot = Join-Path $StudentRoot "exports"
$RecommendedRoot = "C:\StudyOS"

if ($RepoRoot.Length -gt 120) {
    Write-Warning "La ruta actual es larga ($($RepoRoot.Length) caracteres). En Windows conviene clonar este repo en una ruta corta como $RecommendedRoot para evitar problemas de MAX_PATH."
}

Write-Host "[1/4] Validando herramientas base..."
$required = @("git")
foreach ($cmd in $required) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        throw "Falta la herramienta requerida: $cmd"
    }
}

foreach ($opt in @("python", "node")) {
    if (-not (Get-Command $opt -ErrorAction SilentlyContinue)) {
        Write-Warning "$opt no está instalado. No hace falta para el estudio diario; solo si vas a regenerar el PDF de la guía."
    }
}

if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "winget detectado: si falta Git/Node/Python en otro equipo, puedes instalarlos sin buscar instaladores manuales."
} else {
    Write-Host "winget no detectado. Si faltan dependencias en Windows, instálalas manualmente o actualiza App Installer."
}

Write-Host "[2/4] Creando carpetas locales..."
New-Item -ItemType Directory -Force -Path $StudentRoot | Out-Null
New-Item -ItemType Directory -Force -Path $VaultRoot | Out-Null
New-Item -ItemType Directory -Force -Path $OutputsRoot | Out-Null
New-Item -ItemType Directory -Force -Path $ExportsRoot | Out-Null

Write-Host "[3/4] Copiando plantilla del vault si falta..."
if (-not (Test-Path (Join-Path $VaultRoot "99_state\STUDY_STATE.md"))) {
    Copy-Item -Path (Join-Path $TemplateRoot "*") -Destination $VaultRoot -Recurse -Force
}

$rawPdf = Join-Path $VaultRoot "00_inbox\raw-pdf"
$rawAudio = Join-Path $VaultRoot "00_inbox\raw-audio"
$rawNotes = Join-Path $VaultRoot "00_inbox\raw-notes"
New-Item -ItemType Directory -Force -Path $rawPdf | Out-Null
New-Item -ItemType Directory -Force -Path $rawAudio | Out-Null
New-Item -ItemType Directory -Force -Path $rawNotes | Out-Null

Write-Host "[4/4] Bootstrap completado."
Write-Host "Vault local: $VaultRoot"
Write-Host "Sugerencia: añade una exclusión de Windows Defender para la carpeta del vault si vas a guardar laboratorios o payloads."
Write-Host "Siguiente paso: powershell -ExecutionPolicy Bypass -File .\scripts\check-system.ps1"
