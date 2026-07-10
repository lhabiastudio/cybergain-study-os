$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$StateDir = Join-Path $RepoRoot "student-local\vault\99_state"

$StudyStatePath     = Join-Path $StateDir "STUDY_STATE.md"
$SessionBriefPath   = Join-Path $StateDir "SESSION_BRIEF.md"
$LearnLogPath       = Join-Path $StateDir "LEARN_LOG.md"
$MisconceptionsPath = Join-Path $StateDir "MISCONCEPTIONS.md"

if (-not (Test-Path $StudyStatePath)) {
    throw "No encuentro el vault. Ejecuta antes setup.bat / bootstrap-windows.ps1."
}

function Read-StateFile {
    param([string]$Path)
    if (Test-Path $Path) {
        return Get-Content -Raw -Encoding UTF8 -Path $Path
    }
    return ""
}

$StudyStateRaw     = Read-StateFile $StudyStatePath
$SessionBriefRaw   = Read-StateFile $SessionBriefPath
$LearnLogRaw       = Read-StateFile $LearnLogPath
$MisconceptionsRaw = Read-StateFile $MisconceptionsPath

function HtmlEscape {
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return "" }
    $Text = $Text -replace '&', '&amp;'
    $Text = $Text -replace '<', '&lt;'
    $Text = $Text -replace '>', '&gt;'
    return $Text
}

function Get-FieldValue {
    param([string]$Raw, [string]$Key)
    $pattern = "(?im)^" + [regex]::Escape($Key) + ":\s*(.+)$"
    $m = [regex]::Match($Raw, $pattern)
    if ($m.Success) {
        $val = $m.Groups[1].Value.Trim()
        if ($val -and $val -ne "TBD") { return $val }
    }
    return $null
}

# --- Derivar stats (best-effort, tolerante) ---

$Modulo = Get-FieldValue $StudyStateRaw "modulo_actual"
if (-not $Modulo) { $Modulo = "—" }

$ObjetivoSiguiente = Get-FieldValue $StudyStateRaw "objetivo_siguiente"
if (-not $ObjetivoSiguiente) { $ObjetivoSiguiente = Get-FieldValue $StudyStateRaw "objetivo_actual" }
if (-not $ObjetivoSiguiente) { $ObjetivoSiguiente = "—" }

$Ultima = Get-FieldValue $StudyStateRaw "ultima_actualizacion"
if (-not $Ultima) {
    if (Test-Path $StudyStatePath) {
        $Ultima = (Get-Item $StudyStatePath).LastWriteTime.ToString("yyyy-MM-dd")
    } else {
        $Ultima = "—"
    }
}

$SesionesMatches = [regex]::Matches($LearnLogRaw, '(?m)^-\s+.*\d{4}-\d{2}-\d{2}.*$')
$Sesiones = $SesionesMatches.Count

# --- Parseo de bloques de MISCONCEPTIONS (solo bloques con Concepto real, no la plantilla) ---
function Get-MisconceptionBlocks {
    param([string]$Raw)

    $lines = $Raw -split "`r?`n"
    $blocks = @()
    $current = $null

    foreach ($line in $lines) {
        $t = $line.Trim()

        if ($t -match '^-\s*Concepto:\s*(.*)$') {
            if ($current -and $current.Concepto) { $blocks += $current }
            $current = [PSCustomObject]@{
                Concepto   = $matches[1].Trim()
                Suposicion = ""
                Modelo     = ""
                Estado     = "abierto"
            }
            continue
        }
        if (-not $current) { continue }
        if ($t -match '^-\s*Suposici.n equivocada:\s*(.*)$') { $current.Suposicion = $matches[1].Trim(); continue }
        if ($t -match '^-\s*Modelo correcto:\s*(.*)$')       { $current.Modelo = $matches[1].Trim(); continue }
        if ($t -match '^-\s*Estado:\s*(.*)$')                { $current.Estado = $matches[1].Trim(); continue }
    }
    if ($current -and $current.Concepto) { $blocks += $current }

    return $blocks
}

$MisconceptionBlocks = @(Get-MisconceptionBlocks $MisconceptionsRaw)
$ConceptosAbiertos = @($MisconceptionBlocks | Where-Object { $_.Estado.ToLower() -notmatch 'resuel' }).Count

# --- Estado vacío ---
$ModuloEsTBD = -not (Get-FieldValue $StudyStateRaw "modulo_actual")
$SinSesiones = ($Sesiones -eq 0)
$EsVacio = $ModuloEsTBD -and $SinSesiones

# --- Convertidor markdown -> HTML minimo (para paneles de STUDY_STATE / SESSION_BRIEF) ---
function Convert-MarkdownToHtml {
    param([string]$Raw)

    $lines = $Raw -split "`r?`n"
    $sb = New-Object System.Text.StringBuilder
    $inList = $false
    $lastHeadingClass = ""

    foreach ($line in $lines) {
        $trimmed = $line.Trim()

        if ($trimmed -eq "") {
            if ($inList) { [void]$sb.Append("</ul>`n"); $inList = $false }
            continue
        }

        if ($trimmed -match '^##\s+(.+)$') {
            if ($inList) { [void]$sb.Append("</ul>`n"); $inList = $false }
            $heading = HtmlEscape $matches[1].Trim()
            $cls = ""
            if ($heading -match '(?i)dominado') { $cls = " dominado" }
            elseif ($heading -match '(?i)pendiente|bloqueos') { $cls = " pendiente" }
            $lastHeadingClass = $cls
            [void]$sb.Append("<h3 class=`"section-heading$cls`">$heading</h3>`n")
            continue
        }

        if ($trimmed -match '^#\s+(.+)$') {
            continue
        }

        if ($trimmed -match '^-\s*(.*)$') {
            $item = $matches[1].Trim()
            if ($item -eq "TBD" -or $item -eq "") {
                $item = '<span class="muted">—</span>'
            } else {
                $item = HtmlEscape $item
            }
            if (-not $inList) {
                [void]$sb.Append("<ul class=`"list$lastHeadingClass`">`n")
                $inList = $true
            }
            [void]$sb.Append("<li>$item</li>`n")
            continue
        }

        if ($trimmed -match '^([^:]+):\s*(.*)$') {
            if ($inList) { [void]$sb.Append("</ul>`n"); $inList = $false }
            $k = HtmlEscape $matches[1].Trim()
            $v = $matches[2].Trim()
            if ($v -eq "TBD" -or $v -eq "") {
                $v = '<span class="muted">—</span>'
            } else {
                $v = HtmlEscape $v
            }
            [void]$sb.Append("<div class=`"kv`"><span class=`"k`">$k</span><span class=`"v`">$v</span></div>`n")
            continue
        }

        if ($inList) { [void]$sb.Append("</ul>`n"); $inList = $false }
        [void]$sb.Append("<p>" + (HtmlEscape $trimmed) + "</p>`n")
    }

    if ($inList) { [void]$sb.Append("</ul>`n") }

    return $sb.ToString()
}

# --- LEARN_LOG -> timeline ---
function Convert-LearnLogToTimeline {
    param([string]$Raw)

    $pattern = '(?m)^-\s+(\d{4}-\d{2}-\d{2})\s*[—-]+\s*(.+)$'
    $entryMatches = [regex]::Matches($Raw, $pattern)

    if ($entryMatches.Count -eq 0) {
        return '<p class="muted">Todavia no hay entradas en la bitacora.</p>'
    }

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append("<div class=`"timeline`">`n")
    foreach ($m in $entryMatches) {
        $date = HtmlEscape $m.Groups[1].Value.Trim()
        $text = HtmlEscape $m.Groups[2].Value.Trim()
        [void]$sb.Append("<div class=`"timeline-row`"><div class=`"timeline-date mono`">$date</div><div class=`"timeline-text`">$text</div></div>`n")
    }
    [void]$sb.Append("</div>")
    return $sb.ToString()
}

# --- MISCONCEPTIONS -> tarjetas ---
function Convert-MisconceptionsToCards {
    param([string]$Raw)

    $blocks = @(Get-MisconceptionBlocks $Raw)

    if ($blocks.Count -eq 0) {
        return '<p class="muted">No hay errores conceptuales registrados todavia.</p>'
    }

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append("<div class=`"misc-grid`">`n")
    foreach ($b in $blocks) {
        $concepto = HtmlEscape $b.Concepto
        if ($b.Estado.ToLower() -match 'resuel') {
            $badgeClass = "badge-resolved"
            $badgeText  = "resuelto"
        } else {
            $badgeClass = "badge-open"
            $badgeText  = "abierto"
        }
        $suposicion = HtmlEscape $b.Suposicion
        $modelo     = HtmlEscape $b.Modelo

        [void]$sb.Append("<div class=`"misc-card`"><div class=`"misc-head`"><span class=`"misc-concept`">$concepto</span><span class=`"badge $badgeClass`">$badgeText</span></div>")
        if ($suposicion) {
            [void]$sb.Append("<div class=`"misc-row`"><span class=`"misc-label`">Suposicion equivocada</span><span>$suposicion</span></div>")
        }
        if ($modelo) {
            [void]$sb.Append("<div class=`"misc-row`"><span class=`"misc-label`">Modelo correcto</span><span>$modelo</span></div>")
        }
        [void]$sb.Append("</div>`n")
    }
    [void]$sb.Append("</div>")
    return $sb.ToString()
}

# --- Paneles ---
$StudyStateForPanel = $StudyStateRaw -replace '(?im)^estado:.*$', ''
$StudyStateForPanel = $StudyStateForPanel -replace '(?im)^modulo_actual:.*$', ''
$StudyStateForPanel = $StudyStateForPanel -replace '(?im)^ultima_actualizacion:.*$', ''
$StudyStateForPanel = $StudyStateForPanel -replace '(?im)^objetivo_siguiente:.*$', ('objetivo_siguiente: ' + $ObjetivoSiguiente)

$StudyStatePanelHtml     = Convert-MarkdownToHtml $StudyStateForPanel
$SessionBriefPanelHtml   = Convert-MarkdownToHtml $SessionBriefRaw
$LearnLogTimelineHtml    = Convert-LearnLogToTimeline $LearnLogRaw
$MisconceptionsCardsHtml = Convert-MisconceptionsToCards $MisconceptionsRaw

# --- Shell HTML (CSS estatico, sin interpolacion) ---
$Shell = @'
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Cybergain · Tu progreso</title>
<style>
  * { box-sizing: border-box; }
  body {
    margin: 0;
    background: #F8FAFC;
    color: #1F2937;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    line-height: 1.5;
  }
  .mono { font-family: ui-monospace, "Cascadia Code", Consolas, monospace; }
  .muted { color: #94A3B8; }

  .hero { background: #0F766E; color: #fff; }
  .hero-inner {
    max-width: 1080px;
    margin: 0 auto;
    padding: 32px 24px;
    display: flex;
    justify-content: space-between;
    align-items: flex-end;
    flex-wrap: wrap;
    gap: 12px;
  }
  .hero h1 { margin: 0 0 4px; font-size: 26px; font-weight: 700; }
  .hero .subtitle { margin: 0; font-size: 14px; color: rgba(255,255,255,0.92); }
  .hero-date { font-size: 13px; color: rgba(255,255,255,0.92); }

  .wrap { max-width: 1080px; margin: 0 auto; padding: 0 24px 48px; }

  .stats {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
    gap: 16px;
    margin: 24px 0;
  }
  .stat-card {
    background: #FFFFFF;
    border: 1px solid #E2E8F0;
    border-radius: 12px;
    padding: 16px 18px;
    box-shadow: 0 1px 2px rgba(0,0,0,0.04);
  }
  .stat-label {
    font-size: 11px;
    text-transform: uppercase;
    letter-spacing: 0.06em;
    color: #64748B;
    margin-bottom: 6px;
  }
  .stat-value { font-size: 22px; font-weight: 700; color: #111827; }

  .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
  .panel-wide { grid-column: 1 / -1; }
  @media (max-width: 720px) {
    .grid { grid-template-columns: 1fr; }
    .hero-inner { align-items: flex-start; }
  }

  .panel {
    background: #FFFFFF;
    border: 1px solid #E2E8F0;
    border-radius: 12px;
    padding: 24px;
    box-shadow: 0 1px 2px rgba(0,0,0,0.04);
  }
  .panel-title {
    margin: 0 0 16px;
    font-size: 15px;
    font-weight: 700;
    color: #111827;
    padding-left: 10px;
    border-left: 3px solid #0F766E;
  }

  .kv {
    display: flex;
    justify-content: space-between;
    gap: 12px;
    padding: 8px 0;
    border-bottom: 1px solid #F1F5F9;
    font-size: 14px;
  }
  .kv:last-of-type { border-bottom: none; }
  .kv .k { color: #64748B; }
  .kv .v { color: #1F2937; font-weight: 600; text-align: right; }

  .section-heading {
    font-size: 12px;
    text-transform: uppercase;
    letter-spacing: 0.04em;
    color: #64748B;
    margin: 18px 0 8px;
    padding-left: 10px;
    border-left: 2px solid #E2E8F0;
  }
  .section-heading.dominado { color: #0F766E; border-left-color: #0F766E; }
  .section-heading.pendiente { color: #B45309; border-left-color: #B45309; }

  .list { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 6px; }
  .list li { font-size: 14px; padding: 6px 10px; background: #F8FAFC; border-radius: 8px; }
  .list.dominado li { background: #F0FDFA; }
  .list.pendiente li { background: #FFFBEB; }

  .timeline { display: flex; flex-direction: column; }
  .timeline-row {
    display: grid;
    grid-template-columns: 110px 1fr;
    gap: 16px;
    padding: 12px 0;
    border-bottom: 1px solid #F1F5F9;
  }
  .timeline-row:last-child { border-bottom: none; }
  .timeline-date { color: #0F766E; font-size: 13px; font-weight: 600; }
  .timeline-text { font-size: 14px; color: #1F2937; }

  .misc-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
    gap: 16px;
  }
  .misc-card {
    border: 1px solid #FDE9C8;
    background: #FFFBEB;
    border-radius: 10px;
    padding: 16px;
  }
  .misc-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }
  .misc-concept { font-weight: 700; color: #111827; font-size: 14px; }
  .badge {
    font-size: 11px;
    text-transform: uppercase;
    letter-spacing: 0.04em;
    padding: 3px 8px;
    border-radius: 999px;
    font-weight: 600;
  }
  .badge-open { background: #FEF3C7; color: #92400E; }
  .badge-resolved { background: #F0FDFA; color: #0F766E; }
  .misc-row { font-size: 13px; margin-top: 6px; }
  .misc-label {
    display: block;
    color: #64748B;
    font-size: 11px;
    text-transform: uppercase;
    letter-spacing: 0.04em;
    margin-bottom: 2px;
  }

  .empty-state { text-align: center; padding: 64px 24px; color: #64748B; }
  .empty-state h2 { color: #111827; font-size: 20px; margin-bottom: 8px; }
  .empty-state code {
    font-family: ui-monospace, "Cascadia Code", Consolas, monospace;
    background: #F1F5F9;
    padding: 2px 6px;
    border-radius: 4px;
  }

  .foot { text-align: center; color: #64748B; font-size: 12px; margin-top: 32px; }
</style>
</head>
<body>
  <header class="hero">
    <div class="hero-inner">
      <div>
        <h1>Cybergain · Tu progreso</h1>
        <p class="subtitle">Sistema de estudio · datos de tu vault local</p>
      </div>
      <div class="hero-date">Generado el <span class="mono">{{FECHA}}</span></div>
    </div>
  </header>
  {{BODY}}
</body>
</html>
'@

# --- Cuerpo dinamico ---
if ($EsVacio) {
    $Body = @"
<div class="wrap">
  <div class="empty-state">
    <h2>Aún no hay datos de estudio</h2>
    <p>Cierra tu primera sesión con <code>close-session.ps1</code> y vuelve aquí.</p>
  </div>
  <footer class="foot">Generado por dashboard.ps1 · tus datos no salen de este equipo.</footer>
</div>
"@
} else {
    $Body = @"
<div class="wrap">
  <section class="stats">
    <div class="stat-card"><div class="stat-label">Módulo actual</div><div class="stat-value">$Modulo</div></div>
    <div class="stat-card"><div class="stat-label">Sesiones registradas</div><div class="stat-value">$Sesiones</div></div>
    <div class="stat-card"><div class="stat-label">Conceptos a repasar</div><div class="stat-value">$ConceptosAbiertos</div></div>
    <div class="stat-card"><div class="stat-label">Última actualización</div><div class="stat-value mono">$Ultima</div></div>
  </section>

  <main class="grid">
    <section class="panel">
      <h2 class="panel-title">Estado actual</h2>
      $StudyStatePanelHtml
    </section>

    <section class="panel">
      <h2 class="panel-title">Próxima sesión · preparada por Hermes</h2>
      $SessionBriefPanelHtml
    </section>

    <section class="panel panel-wide">
      <h2 class="panel-title">Bitácora · lo que has aprendido</h2>
      $LearnLogTimelineHtml
    </section>

    <section class="panel panel-wide">
      <h2 class="panel-title">A vigilar · errores conceptuales</h2>
      $MisconceptionsCardsHtml
    </section>
  </main>

  <footer class="foot">Generado por dashboard.ps1 · tus datos no salen de este equipo.</footer>
</div>
"@
}

$FechaGenerado = Get-Date -Format "yyyy-MM-dd"

$Html = $Shell.Replace('{{FECHA}}', $FechaGenerado)
$Html = $Html.Replace('{{BODY}}', $Body)

$HtmlPath = Join-Path $RepoRoot "student-local\dashboard.html"
Set-Content -Encoding UTF8 -Path $HtmlPath -Value $Html

Start-Process $HtmlPath

Write-Host "Dashboard generado en:"
Write-Host "  $HtmlPath"
