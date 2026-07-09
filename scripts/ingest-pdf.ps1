param(
    [Parameter(Mandatory = $true)]
    [string]$File
)

$ErrorActionPreference = "Stop"
if (-not (Test-Path $File)) {
    throw "No existe el fichero: $File"
}

$RepoRoot = Split-Path -Parent $PSScriptRoot
$DestDir = Join-Path $RepoRoot "student-local\vault\00_inbox\raw-pdf"
New-Item -ItemType Directory -Force -Path $DestDir | Out-Null
Copy-Item -Path $File -Destination $DestDir -Force

Write-Host "Archivo colocado en el inbox del vault."
Write-Host "Para procesarlo, abre Hermes y pídele que lo lea, por ejemplo:"
Write-Host '  hermes chat -q "Lee el PDF en <ruta> y hazme un resumen socratico con lagunas"'
Write-Host "Si tienes una skill de OCR instalada, mírala con: hermes skills"
