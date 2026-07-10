$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$DateStamp = Get-Date -Format "yyyy-MM-dd"
$OutDir = Join-Path $RepoRoot "student-local\outputs\review-pack-$DateStamp"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$PromptPath = Join-Path $OutDir "review-pack-prompt.txt"
@"
Quiero generar un paquete de repaso semanal.

Usa el material del vault y produce:
1. Resumen corto del módulo activo
2. Lista de conceptos débiles
3. 10 preguntas de comprobación
4. 10 flashcards sugeridas
5. 1 esquema o diagrama recomendado
6. 1 siguiente bloque de estudio
"@ | Set-Content -Encoding UTF8 $PromptPath

Write-Host "Pack preparado en: $OutDir"
Write-Host "Prompt base: $PromptPath"
