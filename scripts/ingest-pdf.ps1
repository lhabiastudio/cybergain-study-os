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
Write-Host "Opcional: no hace falta que hagas nada más. Si no quieres esperar a tu próxima sesión, abre Hermes en esta carpeta y dile: tengo material nuevo."
Write-Host "Él escanea el inbox solo y lo procesa. Si tienes una skill de OCR instalada, mírala con: hermes skills"
