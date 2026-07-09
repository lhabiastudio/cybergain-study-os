param(
    [Parameter(Mandatory = $true)]
    [string]$File
)

$ErrorActionPreference = "Stop"
if (-not (Test-Path $File)) {
    throw "No existe el fichero: $File"
}

$RepoRoot = Split-Path -Parent $PSScriptRoot
$DestDir = Join-Path $RepoRoot "student-local\vault\00_inbox\raw-audio"
New-Item -ItemType Directory -Force -Path $DestDir | Out-Null
Copy-Item -Path $File -Destination $DestDir -Force

Write-Host "Audio colocado en el inbox del vault."
Write-Host "Para transcribirlo, abre Hermes y pideselo, por ejemplo:"
Write-Host '  hermes chat -q "Transcribe el audio en <ruta> y resume los puntos clave"'
Write-Host "Si tienes una skill de transcripcion instalada, mirala con: hermes skills"
