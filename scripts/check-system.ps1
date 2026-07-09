$ErrorActionPreference = "Stop"

$checks = @(
    @{ Name = "git"; Command = "git" },
    @{ Name = "python"; Command = "python" },
    @{ Name = "node"; Command = "node" },
    @{ Name = "hermes"; Command = "hermes" }
)

Write-Host "Comprobando sistema..."
foreach ($check in $checks) {
    $exists = Get-Command $check.Command -ErrorAction SilentlyContinue
    if ($exists) {
        Write-Host "OK  - $($check.Name)"
    } else {
        Write-Host "FAIL- $($check.Name)"
    }
}

$RepoRoot = Split-Path -Parent $PSScriptRoot
$StateFile = Join-Path $RepoRoot "student-local\vault\99_state\STUDY_STATE.md"
if (Test-Path $StateFile) {
    Write-Host "OK  - STUDY_STATE presente"
} else {
    Write-Host "FAIL- STUDY_STATE ausente"
}
