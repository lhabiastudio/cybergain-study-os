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
if (-not $Modulo) { $Modulo = "-" }

$ObjetivoSiguiente = Get-FieldValue $StudyStateRaw "objetivo_siguiente"
if (-not $ObjetivoSiguiente) { $ObjetivoSiguiente = Get-FieldValue $StudyStateRaw "objetivo_actual" }
if (-not $ObjetivoSiguiente) { $ObjetivoSiguiente = "-" }

$Ultima = Get-FieldValue $StudyStateRaw "ultima_actualizacion"
if (-not $Ultima) {
    if (Test-Path $StudyStatePath) {
        $Ultima = (Get-Item $StudyStatePath).LastWriteTime.ToString("yyyy-MM-dd")
    } else {
        $Ultima = "-"
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

# --- Extraer items de una seccion de STUDY_STATE (## Heading) para el grafico de dominio ---
function Get-SectionItems {
    param([string]$Raw, [string]$HeadingName)

    $pattern = '(?ims)^##\s*' + [regex]::Escape($HeadingName) + '\s*$(.*?)(?=^##\s|\z)'
    $m = [regex]::Match($Raw, $pattern)
    if (-not $m.Success) { return @() }

    $itemMatches = [regex]::Matches($m.Groups[1].Value, '(?m)^-\s*(.+)$')
    $items = @($itemMatches | ForEach-Object { $_.Groups[1].Value.Trim() } | Where-Object { $_ -and $_ -ne "TBD" })
    return $items
}

# --- Extraer entradas estructuradas {Fecha, Tema} de LEARN_LOG para el grafico de actividad ---
function Get-LearnLogEntries {
    param([string]$Raw)

    $pattern = '(?m)^-\s+(\d{4}-\d{2}-\d{2})\s*[—-]+\s*(.+)$'
    $entryMatches = [regex]::Matches($Raw, $pattern)

    $entries = @()
    foreach ($m in $entryMatches) {
        $fecha = $m.Groups[1].Value.Trim()
        $rest  = $m.Groups[2].Value.Trim()
        $parts = $rest -split '\s+—\s+'
        $tema  = $parts[0].Trim()
        if (-not $tema) { $tema = $rest }
        $entries += [PSCustomObject]@{ Fecha = $fecha; Tema = $tema }
    }

    return @($entries | Sort-Object Fecha)
}

# --- Viz 1: barra 100% apilada de dominio (Dominado / A medias / Pendiente) ---
function New-DominioViz {
    param([int]$NDominado, [int]$NAMedias, [int]$NPendiente)

    $total = $NDominado + $NAMedias + $NPendiente
    if ($total -eq 0) { return $null }

    $totalUnits = 1000
    $gap = 4
    $usable = $totalUnits - (2 * $gap)

    $wDominado  = [math]::Round($usable * $NDominado  / $total, 1)
    $wAMedias   = [math]::Round($usable * $NAMedias   / $total, 1)
    $wPendiente = [math]::Round($usable - $wDominado - $wAMedias, 1)

    $x1 = 0
    $x2 = [math]::Round($wDominado + $gap, 1)
    $x3 = [math]::Round($x2 + $wAMedias + $gap, 1)

    $labelThreshold = 70

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('<div class="dominio-viz">')
    [void]$sb.Append('<svg class="dominio-bar" viewBox="0 0 1000 28" preserveAspectRatio="none" role="img" aria-label="Distribucion de dominio">')
    [void]$sb.Append("<defs><clipPath id=`"dominioClip`"><rect x=`"0`" y=`"0`" width=`"1000`" height=`"28`" rx=`"6`" ry=`"6`"></rect></clipPath></defs>")
    [void]$sb.Append("<g clip-path=`"url(#dominioClip)`">")

    if ($wDominado -gt 0) {
        [void]$sb.Append("<rect data-tip-domain x=`"$x1`" y=`"0`" width=`"$wDominado`" height=`"28`" fill=`"#0F766E`" data-label=`"Dominado`" data-value=`"$NDominado`"></rect>")
        if ($wDominado -ge $labelThreshold) {
            $cx = [math]::Round($x1 + $wDominado / 2, 1)
            [void]$sb.Append("<text x=`"$cx`" y=`"14`" text-anchor=`"middle`" dominant-baseline=`"central`" class=`"dominio-inline-label`">$NDominado</text>")
        }
    }
    if ($wAMedias -gt 0) {
        [void]$sb.Append("<rect data-tip-domain x=`"$x2`" y=`"0`" width=`"$wAMedias`" height=`"28`" fill=`"#64748B`" data-label=`"A medias`" data-value=`"$NAMedias`"></rect>")
        if ($wAMedias -ge $labelThreshold) {
            $cx = [math]::Round($x2 + $wAMedias / 2, 1)
            [void]$sb.Append("<text x=`"$cx`" y=`"14`" text-anchor=`"middle`" dominant-baseline=`"central`" class=`"dominio-inline-label`">$NAMedias</text>")
        }
    }
    if ($wPendiente -gt 0) {
        [void]$sb.Append("<rect data-tip-domain x=`"$x3`" y=`"0`" width=`"$wPendiente`" height=`"28`" fill=`"#B45309`" data-label=`"Pendiente`" data-value=`"$NPendiente`"></rect>")
        if ($wPendiente -ge $labelThreshold) {
            $cx = [math]::Round($x3 + $wPendiente / 2, 1)
            [void]$sb.Append("<text x=`"$cx`" y=`"14`" text-anchor=`"middle`" dominant-baseline=`"central`" class=`"dominio-inline-label`">$NPendiente</text>")
        }
    }

    [void]$sb.Append("</g></svg>")

    [void]$sb.Append('<div class="dominio-legend">')
    [void]$sb.Append("<span class=`"legend-item`"><span class=`"legend-swatch`" style=`"background:#0F766E`"></span>Dominado $NDominado</span>")
    [void]$sb.Append("<span class=`"legend-item`"><span class=`"legend-swatch`" style=`"background:#64748B`"></span>A medias $NAMedias</span>")
    [void]$sb.Append("<span class=`"legend-item`"><span class=`"legend-swatch`" style=`"background:#B45309`"></span>Pendiente $NPendiente</span>")
    [void]$sb.Append('</div>')
    [void]$sb.Append('</div>')

    return $sb.ToString()
}

# --- Viz 2: sesiones acumuladas en el tiempo (area + linea) ---
function New-ActividadViz {
    param([array]$Entries)

    if ($Entries.Count -eq 0) { return $null }

    $chartW = 1000; $chartH = 240
    $marginL = 40; $marginR = 16; $marginT = 16; $marginB = 16
    $plotW = $chartW - $marginL - $marginR
    $plotH = $chartH - $marginT - $marginB
    $maxY = $Entries.Count

    $points = @()
    for ($i = 0; $i -lt $Entries.Count; $i++) {
        $value = $i + 1
        if ($Entries.Count -gt 1) {
            $x = $marginL + ($i * ($plotW / ($Entries.Count - 1)))
        } else {
            $x = $marginL + ($plotW / 2)
        }
        $y = $marginT + $plotH - ($value / $maxY * $plotH)
        $temaEscapado = (HtmlEscape $Entries[$i].Tema) -replace '"', '&quot;'
        $points += [PSCustomObject]@{
            X     = [math]::Round($x, 1)
            Y     = [math]::Round($y, 1)
            Value = $value
            Fecha = $Entries[$i].Fecha
            Tema  = $temaEscapado
        }
    }

    $linePath = ""
    foreach ($p in $points) {
        if ($linePath -eq "") { $linePath = "M $($p.X),$($p.Y)" }
        else { $linePath += " L $($p.X),$($p.Y)" }
    }
    $bottomY = $marginT + $plotH
    $areaPath = "$linePath L $($points[-1].X),$bottomY L $($points[0].X),$bottomY Z"

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('<svg class="actividad-chart" viewBox="0 0 1000 240" preserveAspectRatio="none" role="img" aria-label="Sesiones acumuladas en el tiempo">')

    for ($g = 0; $g -le 3; $g++) {
        $frac = $g / 3
        $gy = [math]::Round($marginT + $plotH - ($frac * $plotH), 1)
        $gval = [math]::Round($maxY * $frac)
        [void]$sb.Append("<line x1=`"$marginL`" y1=`"$gy`" x2=`"$($chartW - $marginR)`" y2=`"$gy`" class=`"actividad-grid`"></line>")
        [void]$sb.Append("<text x=`"$([math]::Round($marginL - 8, 1))`" y=`"$($gy + 4)`" text-anchor=`"end`" class=`"actividad-axis-label`">$gval</text>")
    }

    [void]$sb.Append("<path d=`"$areaPath`" class=`"actividad-area`"></path>")
    [void]$sb.Append("<path d=`"$linePath`" class=`"actividad-line`"></path>")

    foreach ($p in $points) {
        [void]$sb.Append("<circle data-tip-activity cx=`"$($p.X)`" cy=`"$($p.Y)`" r=`"5`" class=`"actividad-point`" data-date=`"$($p.Fecha)`" data-index=`"$($p.Value)`" data-topic=`"$($p.Tema)`"></circle>")
    }

    [void]$sb.Append('</svg>')
    return $sb.ToString()
}

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
                $item = '<span class="muted">-</span>'
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
            $kRaw = ($matches[1].Trim() -replace '_', ' ')
            $k = HtmlEscape ($kRaw.Substring(0,1).ToUpper() + $kRaw.Substring(1))
            $v = $matches[2].Trim()
            if ($v -eq "TBD" -or $v -eq "") {
                $v = '<span class="muted">-</span>'
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

# --- MISCONCEPTIONS -> filas (sin nested cards) ---
function Convert-MisconceptionsToRows {
    param([string]$Raw)

    $blocks = @(Get-MisconceptionBlocks $Raw)

    if ($blocks.Count -eq 0) {
        return '<p class="muted">No hay errores conceptuales registrados todavia.</p>'
    }

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append("<div class=`"misc-rows`">`n")
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

        [void]$sb.Append("<div class=`"misc-row-item`"><div class=`"misc-row-head`"><span class=`"misc-concept`">$concepto</span><span class=`"badge $badgeClass`">$badgeText</span></div>")
        if ($suposicion) {
            [void]$sb.Append("<div class=`"misc-detail`"><span class=`"misc-label`">Suposición equivocada</span><span>$suposicion</span></div>")
        }
        if ($modelo) {
            [void]$sb.Append("<div class=`"misc-detail`"><span class=`"misc-label`">Modelo correcto</span><span>$modelo</span></div>")
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
$MisconceptionsRowsHtml  = Convert-MisconceptionsToRows $MisconceptionsRaw

# --- Datos para el panel "Tu progreso" ---
$NDominado  = @(Get-SectionItems $StudyStateRaw "Dominado").Count
$NAMedias   = (@(Get-SectionItems $StudyStateRaw "A medias")).Count + (@(Get-SectionItems $StudyStateRaw "En progreso")).Count
$NPendiente = (@(Get-SectionItems $StudyStateRaw "Pendiente")).Count + (@(Get-SectionItems $StudyStateRaw "Bloqueos")).Count

$LearnLogEntries = @(Get-LearnLogEntries $LearnLogRaw)

$DominioVizHtml   = New-DominioViz -NDominado $NDominado -NAMedias $NAMedias -NPendiente $NPendiente
$ActividadVizHtml = New-ActividadViz -Entries $LearnLogEntries

$SinProgresoDatos = (-not $DominioVizHtml) -and (-not $ActividadVizHtml)

if ($SinProgresoDatos) {
    $ProgresoPanelBody = '<p class="muted">Aún sin datos para graficar. Cierra tu primera sesión.</p>'
} else {
    if ($DominioVizHtml) { $DominioBlock = $DominioVizHtml } else { $DominioBlock = '<p class="muted">Aún sin dominio registrado.</p>' }
    if ($ActividadVizHtml) { $ActividadBlock = $ActividadVizHtml } else { $ActividadBlock = '<p class="muted">Aún sin sesiones registradas.</p>' }
    $ProgresoPanelBody = @"
<div class="progreso-grid">
  <div class="progreso-col">
    <h3 class="section-heading">Dominio</h3>
    $DominioBlock
  </div>
  <div class="progreso-col">
    <h3 class="section-heading">Actividad</h3>
    $ActividadBlock
  </div>
</div>
"@
}

# --- Shell HTML (CSS + JS estaticos, sin interpolacion) ---
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
    background: #F6F9F9;
    color: #1F2937;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    line-height: 1.5;
    font-size: 14px;
  }
  .mono { font-family: ui-monospace, "Cascadia Code", Consolas, monospace; }
  .muted { color: #5B6572; }

  .hero { background: #0F766E; color: #FCFEFE; }
  .hero-inner {
    max-width: 1080px;
    margin: 0 auto;
    padding: 32px 24px;
    display: flex;
    justify-content: space-between;
    align-items: flex-end;
    flex-wrap: wrap;
    gap: 16px;
  }
  .hero h1 { margin: 0 0 8px; font-size: 28px; font-weight: 700; line-height: 1.15; }
  .hero .subtitle { margin: 0; font-size: 14px; color: rgba(252,254,254,0.92); }
  .hero-date { font-size: 13px; color: rgba(252,254,254,0.92); }

  .wrap { max-width: 1080px; margin: 0 auto; padding: 0 24px 48px; }

  .stats-strip {
    display: flex;
    flex-wrap: wrap;
    margin: 32px 0;
    background: #FCFEFE;
    border: 1px solid #E3E9E9;
    border-radius: 12px;
  }
  .stat-item { flex: 1 1 160px; padding: 16px 24px; }
  .stat-item + .stat-item { border-left: 1px solid #E3E9E9; }
  .stat-label {
    font-size: 11px;
    text-transform: uppercase;
    letter-spacing: 0.06em;
    color: #5B6572;
    margin-bottom: 8px;
  }
  .stat-value { font-size: 22px; font-weight: 700; color: #16273A; }

  .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 32px; }
  .panel-wide { grid-column: 1 / -1; }
  @media (max-width: 720px) {
    .grid { grid-template-columns: 1fr; }
    .hero-inner { align-items: flex-start; }
    .stats-strip { flex-direction: column; }
    .stat-item + .stat-item { border-left: none; border-top: 1px solid #E3E9E9; }
    .progreso-grid { grid-template-columns: 1fr; }
  }

  .panel {
    background: #FCFEFE;
    border: 1px solid #E3E9E9;
    border-radius: 12px;
    padding: 24px;
  }
  .panel-title {
    margin: 0 0 16px;
    font-size: 18px;
    font-weight: 700;
    color: #16273A;
    padding-bottom: 12px;
    border-bottom: 1px solid #E3E9E9;
  }

  .kv {
    display: flex;
    justify-content: space-between;
    gap: 8px;
    padding: 8px 0;
    border-bottom: 1px solid #E3E9E9;
    font-size: 14px;
  }
  .kv:last-of-type { border-bottom: none; }
  .kv .k { color: #5B6572; }
  .kv .v { color: #1F2937; font-weight: 600; text-align: right; }

  .section-heading {
    font-size: 12px;
    text-transform: uppercase;
    letter-spacing: 0.06em;
    font-weight: 700;
    color: #5B6572;
    margin: 16px 0 8px;
  }
  .section-heading.dominado { color: #0F766E; }
  .section-heading.pendiente { color: #B45309; }

  .list { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 8px; }
  .list li { font-size: 14px; padding: 8px 8px; background: #F6F9F9; border-radius: 8px; }
  .list.dominado li { background: #F0FDFA; }
  .list.pendiente li { background: #FFFBEB; }

  .timeline { display: flex; flex-direction: column; }
  .timeline-row {
    display: grid;
    grid-template-columns: 110px 1fr;
    gap: 16px;
    padding: 16px 0;
    border-bottom: 1px solid #E3E9E9;
  }
  .timeline-row:last-child { border-bottom: none; }
  .timeline-row:hover { background: #F0FAF9; transition: background 120ms ease-out; }
  .timeline-date { color: #0F766E; font-size: 13px; font-weight: 600; }
  .timeline-text { font-size: 14px; color: #1F2937; }

  .misc-rows { display: flex; flex-direction: column; }
  .misc-row-item { padding: 16px 0; border-top: 1px solid #E3E9E9; }
  .misc-row-item:first-child { border-top: none; padding-top: 0; }
  .misc-row-item:hover { background: #F0FAF9; transition: background 120ms ease-out; }
  .misc-row-head { display: flex; justify-content: space-between; align-items: center; gap: 16px; }
  .misc-concept { font-weight: 700; color: #16273A; font-size: 14px; }
  .misc-detail { font-size: 14px; margin-top: 8px; }
  .misc-label {
    display: block;
    color: #5B6572;
    font-size: 11px;
    text-transform: uppercase;
    letter-spacing: 0.06em;
    margin-bottom: 8px;
  }
  .badge {
    font-size: 11px;
    text-transform: uppercase;
    letter-spacing: 0.04em;
    padding: 8px 8px;
    border-radius: 999px;
    font-weight: 600;
    flex-shrink: 0;
    line-height: 1;
  }
  .badge-open { background: #FEF3C7; color: #92400E; }
  .badge-resolved { background: #F0FDFA; color: #0F766E; }

  .progreso-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
  .progreso-col { display: flex; flex-direction: column; }

  .dominio-viz { display: flex; flex-direction: column; gap: 16px; }
  .dominio-bar { width: 100%; height: 28px; display: block; }
  .dominio-inline-label { fill: #FCFEFE; font-size: 13px; font-weight: 700; }
  .dominio-legend { display: flex; flex-wrap: wrap; gap: 16px; margin: 0; padding: 0; }
  .legend-item { display: flex; align-items: center; gap: 8px; font-size: 14px; color: #1F2937; }
  .legend-swatch { width: 12px; height: 12px; border-radius: 3px; display: inline-block; }

  .actividad-chart { width: 100%; height: 240px; display: block; }
  .actividad-grid { stroke: #EEF2F2; stroke-width: 1; }
  .actividad-axis-label { font-size: 11px; fill: #5B6572; }
  .actividad-area { fill: rgba(15, 118, 110, 0.10); stroke: none; }
  .actividad-line { fill: none; stroke: #0F766E; stroke-width: 2; }
  .actividad-point { fill: #0F766E; stroke: #FCFEFE; stroke-width: 2; cursor: pointer; }

  #cg-tooltip {
    position: fixed;
    display: none;
    background: #16273A;
    color: #FCFEFE;
    font-size: 12px;
    padding: 8px 8px;
    border-radius: 8px;
    pointer-events: none;
    z-index: 999;
    white-space: nowrap;
  }

  .empty-state { text-align: center; padding: 64px 24px; color: #5B6572; }
  .empty-state h2 { color: #16273A; font-size: 22px; margin-bottom: 8px; }
  .empty-state code {
    font-family: ui-monospace, "Cascadia Code", Consolas, monospace;
    background: #E3E9E9;
    padding: 2px 8px;
    border-radius: 4px;
  }

  .foot { text-align: center; color: #5B6572; font-size: 12px; margin-top: 32px; }
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
  <div id="cg-tooltip"></div>
  <script>
  (function () {
    var tip = document.getElementById('cg-tooltip');

    function place(e) {
      tip.style.left = (e.clientX + 14) + 'px';
      tip.style.top = (e.clientY + 14) + 'px';
    }

    function show(e, text) {
      tip.textContent = text;
      tip.style.display = 'block';
      place(e);
    }

    function hide() {
      tip.style.display = 'none';
    }

    document.querySelectorAll('[data-tip-domain]').forEach(function (el) {
      var label = el.getAttribute('data-label');
      var value = parseInt(el.getAttribute('data-value'), 10);
      var word = value === 1 ? 'tema' : 'temas';
      var text = label + ': ' + value + ' ' + word;
      el.addEventListener('mouseenter', function (e) { show(e, text); });
      el.addEventListener('mousemove', place);
      el.addEventListener('mouseleave', hide);
    });

    document.querySelectorAll('[data-tip-activity]').forEach(function (el) {
      var date = el.getAttribute('data-date');
      var index = el.getAttribute('data-index');
      var topic = el.getAttribute('data-topic');
      var text = date + ' · sesion ' + index + ' · ' + topic;
      el.addEventListener('mouseenter', function (e) { show(e, text); });
      el.addEventListener('mousemove', place);
      el.addEventListener('mouseleave', hide);
    });
  })();
  </script>
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
  <section class="stats-strip">
    <div class="stat-item"><div class="stat-label">Módulo actual</div><div class="stat-value">$Modulo</div></div>
    <div class="stat-item"><div class="stat-label">Sesiones registradas</div><div class="stat-value">$Sesiones</div></div>
    <div class="stat-item"><div class="stat-label">Conceptos a repasar</div><div class="stat-value">$ConceptosAbiertos</div></div>
    <div class="stat-item"><div class="stat-label">Última actualización</div><div class="stat-value mono">$Ultima</div></div>
  </section>

  <main class="grid">
    <section class="panel panel-wide">
      <h2 class="panel-title">Tu progreso</h2>
      $ProgresoPanelBody
    </section>

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
      $MisconceptionsRowsHtml
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
