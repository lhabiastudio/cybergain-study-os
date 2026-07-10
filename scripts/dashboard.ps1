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

function Get-MesEs {
    param([int]$Mes)
    $meses = @('enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre')
    return $meses[$Mes - 1]
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

# --- Nudge de frescura: dias desde la ultima actualizacion ---
$DiasSinActualizar = $null
if ($Ultima -and $Ultima -ne "-") {
    $ParsedUltima = $null
    if ([DateTime]::TryParseExact($Ultima, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$ParsedUltima)) {
        $DiasSinActualizar = [int][math]::Floor(((Get-Date).Date - $ParsedUltima.Date).TotalDays)
    }
}

$FreshnessHtml = ""
if ($DiasSinActualizar -and $DiasSinActualizar -gt 7) {
    if ($DiasSinActualizar -eq 1) { $DiaLabel = "día" } else { $DiaLabel = "días" }
    $FreshnessHtml = "<br><span class=`"freshness-nudge`">Hace $DiasSinActualizar $DiaLabel sin actualizar. Cierra una sesión para ponerlo al día.</span>"
}

# --- Callout "Tu proximo paso": objetivo_siguiente de STUDY_STATE, si no, objetivo de SESSION_BRIEF ---
$ObjetivoSesionBrief = Get-FieldValue $SessionBriefRaw "objetivo"
$MaterialAnclar      = Get-FieldValue $SessionBriefRaw "material_a_anclar"

$ProximoPasoTexto = Get-FieldValue $StudyStateRaw "objetivo_siguiente"
if (-not $ProximoPasoTexto) { $ProximoPasoTexto = $ObjetivoSesionBrief }

if ($ProximoPasoTexto) {
    $ProximoPasoTextoEsc = HtmlEscape $ProximoPasoTexto
    $NextStepMeta = "Preparado por Hermes para tu próxima sesión."
    if ($MaterialAnclar) {
        $NextStepMeta = $NextStepMeta + " Material: " + (HtmlEscape $MaterialAnclar)
    }
    $NextStepHtml = @"
<span class="next-step-label">Tu próximo paso</span>
<p class="next-step-text">$ProximoPasoTextoEsc</p>
<p class="next-step-meta muted">$NextStepMeta</p>
"@
} else {
    $NextStepHtml = @'
<span class="next-step-label">Tu próximo paso</span>
<p class="next-step-text">Cierra tu primera sesión con <code>close-session.ps1</code> para que Hermes te prepare el siguiente paso.</p>
'@
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

# --- Estado vacio ---
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

    $AriaDominio = HtmlEscape "Dominio: $NDominado temas dominados, $NAMedias a medias, $NPendiente pendientes"

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('<div class="dominio-viz">')
    [void]$sb.Append("<p class=`"progreso-summary`">$NDominado de $total temas dominados</p>")
    [void]$sb.Append("<svg class=`"dominio-bar`" viewBox=`"0 0 1000 28`" preserveAspectRatio=`"none`" role=`"img`" aria-label=`"$AriaDominio`">")
    [void]$sb.Append("<defs><clipPath id=`"dominioClip`"><rect x=`"0`" y=`"0`" width=`"1000`" height=`"28`" rx=`"6`" ry=`"6`"></rect></clipPath></defs>")
    [void]$sb.Append("<g clip-path=`"url(#dominioClip)`">")

    if ($wDominado -gt 0) {
        [void]$sb.Append("<rect data-tip-domain tabindex=`"0`" x=`"$x1`" y=`"0`" width=`"$wDominado`" height=`"28`" style=`"fill:var(--state-mastered)`" data-label=`"Dominado`" data-value=`"$NDominado`"></rect>")
        if ($wDominado -ge $labelThreshold) {
            $cx = [math]::Round($x1 + $wDominado / 2, 1)
            [void]$sb.Append("<text x=`"$cx`" y=`"14`" text-anchor=`"middle`" dominant-baseline=`"central`" class=`"dominio-inline-label`">$NDominado</text>")
        }
    }
    if ($wAMedias -gt 0) {
        [void]$sb.Append("<rect data-tip-domain tabindex=`"0`" x=`"$x2`" y=`"0`" width=`"$wAMedias`" height=`"28`" style=`"fill:var(--state-progress)`" data-label=`"A medias`" data-value=`"$NAMedias`"></rect>")
        if ($wAMedias -ge $labelThreshold) {
            $cx = [math]::Round($x2 + $wAMedias / 2, 1)
            [void]$sb.Append("<text x=`"$cx`" y=`"14`" text-anchor=`"middle`" dominant-baseline=`"central`" class=`"dominio-inline-label`">$NAMedias</text>")
        }
    }
    if ($wPendiente -gt 0) {
        [void]$sb.Append("<rect data-tip-domain tabindex=`"0`" x=`"$x3`" y=`"0`" width=`"$wPendiente`" height=`"28`" style=`"fill:var(--state-pending)`" data-label=`"Pendiente`" data-value=`"$NPendiente`"></rect>")
        if ($wPendiente -ge $labelThreshold) {
            $cx = [math]::Round($x3 + $wPendiente / 2, 1)
            [void]$sb.Append("<text x=`"$cx`" y=`"14`" text-anchor=`"middle`" dominant-baseline=`"central`" class=`"dominio-inline-label`">$NPendiente</text>")
        }
    }

    [void]$sb.Append("</g></svg>")

    [void]$sb.Append('<div class="dominio-legend">')
    [void]$sb.Append("<span class=`"legend-item`"><span class=`"legend-swatch`" style=`"background:var(--state-mastered)`"></span>Dominado $NDominado</span>")
    [void]$sb.Append("<span class=`"legend-item`"><span class=`"legend-swatch`" style=`"background:var(--state-progress)`"></span>A medias $NAMedias</span>")
    [void]$sb.Append("<span class=`"legend-item`"><span class=`"legend-swatch`" style=`"background:var(--state-pending)`"></span>Pendiente $NPendiente</span>")
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

    $primeraFecha = [DateTime]::ParseExact($Entries[0].Fecha, 'yyyy-MM-dd', $null)
    $ultimaFechaEntry = [DateTime]::ParseExact($Entries[-1].Fecha, 'yyyy-MM-dd', $null)
    if ($primeraFecha.Month -eq $ultimaFechaEntry.Month -and $primeraFecha.Year -eq $ultimaFechaEntry.Year) {
        $RangoTexto = "del $($primeraFecha.Day) al $($ultimaFechaEntry.Day) de $(Get-MesEs $ultimaFechaEntry.Month)"
    } else {
        $RangoTexto = "del $($primeraFecha.Day) de $(Get-MesEs $primeraFecha.Month) al $($ultimaFechaEntry.Day) de $(Get-MesEs $ultimaFechaEntry.Month)"
    }
    $AriaActividad = HtmlEscape "Actividad: $($Entries.Count) sesiones acumuladas $RangoTexto"

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append("<svg class=`"actividad-chart`" viewBox=`"0 0 1000 240`" preserveAspectRatio=`"none`" role=`"img`" aria-label=`"$AriaActividad`">")

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
        [void]$sb.Append("<circle cx=`"$($p.X)`" cy=`"$($p.Y)`" r=`"5`" class=`"actividad-point`" aria-hidden=`"true`"></circle>")
        [void]$sb.Append("<circle data-tip-activity tabindex=`"0`" cx=`"$($p.X)`" cy=`"$($p.Y)`" r=`"12`" class=`"actividad-hit`" data-date=`"$($p.Fecha)`" data-index=`"$($p.Value)`" data-topic=`"$($p.Tema)`"></circle>")
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
  :root{
    /* superficies */
    --surface-page:#F6F9F9; --surface-card:#FCFEFE; --surface-soft:#F0FAF9; --border:#E3E9E9; --grid-line:#EEF2F2;
    /* tinta */
    --ink:#1F2937; --ink-muted:#5B6572; --ink-strong:#16273A; --on-accent:#FCFEFE;
    /* acento + estados */
    --accent:#0F766E; --accent-soft:#F0FDFA;
    --state-mastered:#0F766E; --state-progress:#64748B; --state-pending:#B45309;
    --state-mastered-soft:#F0FDFA; --state-pending-soft:#FFFBEB;
    --badge-open-bg:#FEF3C7; --badge-open-ink:#92400E; --badge-done-bg:#F0FDFA; --badge-done-ink:#0F766E;
    /* tipografia (escala 1.25) */
    --text-hero:28px; --text-stat:22px; --text-title:18px; --text-body:14px; --text-small:12px; --text-label:11px;
    --lh-tight:1.15; --lh-body:1.5;
    /* espaciado (escala) */
    --space-1:8px; --space-2:16px; --space-3:24px; --space-4:32px; --space-6:48px; --space-8:64px;
    /* radios + motion */
    --radius-sm:8px; --radius-md:12px; --radius-pill:999px;
    --ease-out:cubic-bezier(0.22,1,0.36,1); --dur-fast:120ms;
    --maxw:1080px;
  }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    background: var(--surface-page);
    color: var(--ink);
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    line-height: var(--lh-body);
    font-size: var(--text-body);
  }
  .mono { font-family: ui-monospace, "Cascadia Code", Consolas, monospace; }
  .muted { color: var(--ink-muted); }

  .hero { background: var(--accent); color: var(--on-accent); }
  .hero-inner {
    max-width: var(--maxw);
    margin: 0 auto;
    padding: var(--space-4) var(--space-3);
    display: flex;
    justify-content: space-between;
    align-items: flex-end;
    flex-wrap: wrap;
    gap: var(--space-2);
  }
  .hero h1 { margin: 0 0 var(--space-1); font-size: var(--text-hero); font-weight: 700; line-height: var(--lh-tight); }
  .hero .subtitle { margin: 0; font-size: var(--text-body); color: rgba(252,254,254,0.92); }
  .hero-date { font-size: var(--text-small); color: rgba(252,254,254,0.92); }
  .freshness-nudge { color: rgba(252,254,254,0.78); }

  .wrap { max-width: var(--maxw); margin: 0 auto; padding: 0 var(--space-3) var(--space-6); }

  .stats-strip {
    display: flex;
    flex-wrap: wrap;
    margin: var(--space-4) 0;
    background: var(--surface-card);
    border: 1px solid var(--border);
    border-radius: var(--radius-md);
  }
  .stat-item { flex: 1 1 160px; padding: var(--space-2) var(--space-3); }
  .stat-item + .stat-item { border-left: 1px solid var(--border); }
  .stat-label {
    font-size: var(--text-label);
    text-transform: uppercase;
    letter-spacing: 0.06em;
    color: var(--ink-muted);
    margin-bottom: var(--space-1);
  }
  .stat-value { font-size: var(--text-stat); font-weight: 700; color: var(--ink-strong); }

  .callout-next-step {
    background: var(--accent-soft);
    border-radius: var(--radius-md);
    padding: var(--space-3);
    margin: var(--space-3) 0;
  }
  .next-step-label {
    display: block;
    font-size: var(--text-label);
    text-transform: uppercase;
    letter-spacing: 0.06em;
    font-weight: 700;
    color: var(--accent);
    margin-bottom: var(--space-1);
  }
  .next-step-text {
    margin: 0 0 var(--space-1);
    font-size: var(--text-title);
    font-weight: 700;
    color: var(--ink-strong);
    line-height: var(--lh-tight);
  }
  .next-step-meta { margin: 0; font-size: var(--text-small); }

  .grid { display: grid; grid-template-columns: 1fr 1fr; gap: var(--space-4); }
  .panel-wide { grid-column: 1 / -1; }
  @media (max-width: 720px) {
    .grid { grid-template-columns: 1fr; }
    .hero-inner { align-items: flex-start; }
    .stats-strip { flex-direction: column; }
    .stat-item + .stat-item { border-left: none; border-top: 1px solid var(--border); }
    .progreso-grid { grid-template-columns: 1fr; }
  }

  .panel {
    background: var(--surface-card);
    border: 1px solid var(--border);
    border-radius: var(--radius-md);
    padding: var(--space-3);
  }
  .panel-title {
    margin: 0 0 var(--space-2);
    font-size: var(--text-title);
    font-weight: 700;
    color: var(--ink-strong);
    padding-bottom: var(--space-2);
    border-bottom: 1px solid var(--border);
  }

  .kv {
    display: flex;
    justify-content: space-between;
    gap: var(--space-1);
    padding: var(--space-1) 0;
    border-bottom: 1px solid var(--border);
    font-size: var(--text-body);
  }
  .kv:last-of-type { border-bottom: none; }
  .kv .k { color: var(--ink-muted); }
  .kv .v { color: var(--ink); font-weight: 600; text-align: right; }

  .section-heading {
    font-size: var(--text-label);
    text-transform: uppercase;
    letter-spacing: 0.06em;
    font-weight: 700;
    color: var(--ink-muted);
    margin: var(--space-2) 0 var(--space-1);
  }
  .section-heading.dominado { color: var(--state-mastered); }
  .section-heading.pendiente { color: var(--state-pending); }

  .progreso-summary { margin: 0 0 var(--space-2); font-size: var(--text-body); color: var(--ink); font-weight: 600; }

  .list { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: var(--space-1); }
  .list li { font-size: var(--text-body); padding: var(--space-1) var(--space-1); background: var(--surface-page); border-radius: var(--radius-sm); }
  .list.dominado li { background: var(--state-mastered-soft); }
  .list.pendiente li { background: var(--state-pending-soft); }

  .timeline { display: flex; flex-direction: column; }
  .timeline-row {
    display: grid;
    grid-template-columns: 110px 1fr;
    gap: var(--space-2);
    padding: var(--space-2) 0;
    border-bottom: 1px solid var(--border);
    transition: background var(--dur-fast) var(--ease-out);
  }
  .timeline-row:last-child { border-bottom: none; }
  .timeline-row:hover { background: var(--surface-soft); }
  .timeline-date { color: var(--accent); font-size: var(--text-small); font-weight: 600; }
  .timeline-text { font-size: var(--text-body); color: var(--ink); }

  .misc-rows { display: flex; flex-direction: column; }
  .misc-row-item { padding: var(--space-2) 0; border-top: 1px solid var(--border); transition: background var(--dur-fast) var(--ease-out); }
  .misc-row-item:first-child { border-top: none; padding-top: 0; }
  .misc-row-item:hover { background: var(--surface-soft); }
  .misc-row-head { display: flex; justify-content: space-between; align-items: center; gap: var(--space-2); }
  .misc-concept { font-weight: 700; color: var(--ink-strong); font-size: var(--text-body); }
  .misc-detail { font-size: var(--text-body); margin-top: var(--space-1); }
  .misc-label {
    display: block;
    color: var(--ink-muted);
    font-size: var(--text-label);
    text-transform: uppercase;
    letter-spacing: 0.06em;
    margin-bottom: var(--space-1);
  }
  .badge {
    font-size: var(--text-label);
    text-transform: uppercase;
    letter-spacing: 0.04em;
    padding: var(--space-1) var(--space-1);
    border-radius: var(--radius-pill);
    font-weight: 600;
    flex-shrink: 0;
    line-height: 1;
  }
  .badge-open { background: var(--badge-open-bg); color: var(--badge-open-ink); }
  .badge-resolved { background: var(--badge-done-bg); color: var(--badge-done-ink); }

  .progreso-grid { display: grid; grid-template-columns: 1fr 1fr; gap: var(--space-2); }
  .progreso-col { display: flex; flex-direction: column; }

  .dominio-viz { display: flex; flex-direction: column; gap: var(--space-2); }
  .dominio-bar { width: 100%; height: 28px; display: block; }
  .dominio-inline-label { fill: var(--on-accent); font-size: var(--text-small); font-weight: 700; }
  .dominio-legend { display: flex; flex-wrap: wrap; gap: var(--space-2); margin: 0; padding: 0; }
  .legend-item { display: flex; align-items: center; gap: var(--space-1); font-size: var(--text-body); color: var(--ink); }
  .legend-swatch { width: 12px; height: 12px; border-radius: var(--radius-sm); display: inline-block; }

  .actividad-chart { width: 100%; height: 240px; display: block; }
  .actividad-grid { stroke: var(--grid-line); stroke-width: 1; }
  .actividad-axis-label { font-size: var(--text-label); fill: var(--ink-muted); }
  .actividad-area { fill: rgba(15, 118, 110, 0.10); stroke: none; }
  .actividad-line { fill: none; stroke: var(--accent); stroke-width: 2; }
  .actividad-point { fill: var(--accent); stroke: var(--on-accent); stroke-width: 2; }
  .actividad-hit { fill: transparent; cursor: pointer; outline: none; }

  .dominio-bar rect:focus-visible,
  .actividad-hit:focus-visible {
    outline: 2px solid var(--ink-strong);
    outline-offset: 2px;
  }

  #cg-tooltip {
    position: fixed;
    display: none;
    background: var(--ink-strong);
    color: var(--on-accent);
    font-size: var(--text-small);
    padding: var(--space-1) var(--space-1);
    border-radius: var(--radius-sm);
    pointer-events: none;
    z-index: 999;
    white-space: nowrap;
  }

  .empty-state { text-align: center; padding: var(--space-8) var(--space-3); color: var(--ink-muted); }
  .empty-state h2 { color: var(--ink-strong); font-size: var(--text-stat); margin-bottom: var(--space-1); }
  .empty-state code {
    font-family: ui-monospace, "Cascadia Code", Consolas, monospace;
    background: var(--border);
    padding: 2px var(--space-1);
    border-radius: var(--radius-sm);
  }

  .foot { text-align: center; color: var(--ink-muted); font-size: var(--text-small); margin-top: var(--space-4); }

  @media (prefers-reduced-motion: reduce) {
    .timeline-row, .misc-row-item { transition: none; }
  }

  @media print {
    body { background: var(--surface-page); }
    .hero { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    #cg-tooltip { display: none !important; }
    .panel, .callout-next-step, .stats-strip { break-inside: avoid; }
  }
</style>
</head>
<body>
  <header class="hero">
    <div class="hero-inner">
      <div>
        <h1>Cybergain · Tu progreso</h1>
        <p class="subtitle">Sistema de estudio · datos de tu vault local</p>
      </div>
      <div class="hero-date">Generado el <span class="mono">{{FECHA}}</span>{{FRESHNESS}}</div>
    </div>
  </header>
  {{BODY}}
  <div id="cg-tooltip"></div>
  <script>
  (function () {
    var tip = document.getElementById('cg-tooltip');

    function placeAtMouse(e) {
      tip.style.left = (e.clientX + 14) + 'px';
      tip.style.top = (e.clientY + 14) + 'px';
    }

    function placeAtElement(el) {
      var rect = el.getBoundingClientRect();
      tip.style.left = (rect.left + rect.width / 2 + 14) + 'px';
      tip.style.top = (rect.top - 8) + 'px';
    }

    function show(text) {
      tip.textContent = text;
      tip.style.display = 'block';
    }

    function hide() {
      tip.style.display = 'none';
    }

    function wire(selector, textFn) {
      document.querySelectorAll(selector).forEach(function (el) {
        var text = textFn(el);
        el.addEventListener('mouseenter', function (e) { show(text); placeAtMouse(e); });
        el.addEventListener('mousemove', placeAtMouse);
        el.addEventListener('mouseleave', hide);
        el.addEventListener('focus', function () { show(text); placeAtElement(el); });
        el.addEventListener('blur', hide);
      });
    }

    wire('[data-tip-domain]', function (el) {
      var label = el.getAttribute('data-label');
      var value = parseInt(el.getAttribute('data-value'), 10);
      var word = value === 1 ? 'tema' : 'temas';
      return label + ': ' + value + ' ' + word;
    });

    wire('[data-tip-activity]', function (el) {
      var date = el.getAttribute('data-date');
      var index = el.getAttribute('data-index');
      var topic = el.getAttribute('data-topic');
      return date + ' · sesion ' + index + ' · ' + topic;
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

  <section class="callout-next-step">
    $NextStepHtml
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
$Html = $Html.Replace('{{FRESHNESS}}', $FreshnessHtml)
$Html = $Html.Replace('{{BODY}}', $Body)

$HtmlPath = Join-Path $RepoRoot "student-local\dashboard.html"
Set-Content -Encoding UTF8 -Path $HtmlPath -Value $Html

Start-Process $HtmlPath

Write-Host "Dashboard generado en:"
Write-Host "  $HtmlPath"
