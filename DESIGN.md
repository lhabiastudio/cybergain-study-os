# DESIGN.md — Cybergain Study OS

## 1. Propósito

Este es el sistema de diseño (DS) del dashboard de estudio de Cybergain: una única página HTML autocontenida, generada por `scripts/dashboard.ps1` a partir del vault local de la alumna. La fuente de verdad del DS son los custom properties declarados en `:root`, dentro del bloque `<style>` de ese mismo script. Cualquier cambio visual empieza ahí, no en valores sueltos repartidos por el CSS. Ver también [[PRODUCT]] para el contexto de producto que justifica estas decisiones.

## 2. Color

| Token | Valor | Uso |
|---|---|---|
| `--surface-page` | `#F6F9F9` | Fondo general de la página y de los `<li>` de listas neutras |
| `--surface-card` | `#FCFEFE` | Fondo de paneles y de la tira de stats |
| `--surface-soft` | `#F0FAF9` | Fondo hover de filas (timeline, misconceptions) |
| `--border` | `#E3E9E9` | Bordes hairline de paneles, separadores, tira de stats |
| `--grid-line` | `#EEF2F2` | Líneas de rejilla de la gráfica de actividad |
| `--ink` | `#1F2937` | Texto de cuerpo por defecto |
| `--ink-muted` | `#5B6572` | Texto secundario, etiquetas, `.muted` |
| `--ink-strong` | `#16273A` | Titulares de panel, valores de stat, fondo del tooltip |
| `--on-accent` | `#FCFEFE` | Texto y detalles sobre fondo de acento (hero, punto de la gráfica) |
| `--accent` | `#0F766E` | El único acento de marca: hero, etiqueta del callout, fecha de bitácora |
| `--accent-soft` | `#F0FDFA` | Fondo del callout "Tu próximo paso" |
| `--state-mastered` / `-soft` | `#0F766E` / `#F0FDFA` | Estado "dominado" en gráfica, leyenda y listas |
| `--state-progress` | `#64748B` | Estado "a medias" en gráfica y leyenda |
| `--state-pending` / `-soft` | `#B45309` / `#FFFBEB` | Estado "pendiente", único uso de ámbar |
| `--badge-open-bg` / `-ink` | `#FEF3C7` / `#92400E` | Badge de error conceptual abierto |
| `--badge-done-bg` / `-ink` | `#F0FDFA` / `#0F766E` | Badge de error conceptual resuelto |

Regla: un solo acento de marca (teal, `--accent`). El ámbar (`--state-pending*`) está reservado exclusivamente para señalar "pendiente" — nunca se usa como acento decorativo. Contraste: `--ink` sobre `--surface-page/-card` y `--ink-muted` sobre esas mismas superficies cumplen 4.5:1 (texto de cuerpo); `--on-accent` sobre `--accent` también cumple 4.5:1. Ningún estado se comunica solo por color: cada badge y cada segmento de la gráfica de dominio lleva texto/etiqueta.

## 3. Tipografía

Escala geométrica de razón 1.25, sin fuentes web (offline-first): stack de sistema `-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif` (y `ui-monospace, "Cascadia Code", Consolas, monospace` para datos/fechas).

| Token | px | Uso |
|---|---|---|
| `--text-hero` | 28 | `<h1>` del hero |
| `--text-stat` | 22 | Valor de cada stat, `<h2>` de estado vacío |
| `--text-title` | 18 | Título de panel, texto del callout "próximo paso" |
| `--text-body` | 14 | Texto de cuerpo, kv, listas, timeline |
| `--text-small` | 12 | Fecha del hero, fecha de bitácora, tooltip, meta del callout |
| `--text-label` | 11 | Etiquetas en mayúscula: stat-label, section-heading, badges |

Line-heights: `--lh-tight` (1.15) para titulares grandes; `--lh-body` (1.5) para cuerpo de texto.

## 4. Espaciado

Escala fija: `--space-1` 8 · `--space-2` 16 · `--space-3` 24 · `--space-4` 32 · `--space-6` 48 · `--space-8` 64 (px). Regla de proximidad: elementos relacionados se separan ≤16px (`--space-2` o menos); bloques no relacionados se separan ≥32px (`--space-4` o más). Ningún valor de espaciado fuera de esta escala.

## 5. Radios, bordes, elevación

Bordes: hairline de 1px con `var(--border)` en paneles, tira de stats y separadores. Cero sombras (`box-shadow`): el estilo es plano y restrained, la jerarquía se lee por espaciado y contraste de fondo, no por elevación. Radios: `--radius-sm` (8px) para elementos pequeños (listas, tooltip, swatches), `--radius-md` (12px) para paneles y contenedores grandes, `--radius-pill` (999px) para badges.

## 6. Movimiento

Única transición: `background var(--dur-fast) var(--ease-out)` en hover de filas de timeline y de errores conceptuales (`--dur-fast` 120ms, `--ease-out` cubic-bezier(0.22,1,0.36,1)). Nada de animación decorativa. Respeta `prefers-reduced-motion: reduce` anulando esas transiciones.

## 7. Componentes

- **Hero**: banda superior de acento con `<h1>`, subtítulo y fecha de generación (+ nudge de frescura opcional).
- **Tira de stats**: fila de métricas clave (módulo, sesiones, conceptos a repasar, última actualización) en un único contenedor con separadores verticales.
- **Callout "próximo paso"**: superficie `--accent-soft` sin borde lateral de acento, con etiqueta + frase directiva + meta en muted. Es el componente directivo del dashboard.
- **Panel**: contenedor base (`--surface-card`, borde hairline, radio md) con título con borde inferior.
- **kv-row**: par clave/valor en fila, usado en los paneles de estado y brief.
- **section-heading**: etiqueta en mayúscula con variantes de color por estado (`dominado`, `pendiente`).
- **list-item**: `<li>` con fondo neutro o de estado (dominado/pendiente).
- **timeline-row**: fila fecha + texto para la bitácora.
- **misconception-row**: fila concepto + badge + detalle, sin tarjetas anidadas.
- **badge**: pill de estado (abierto/resuelto), siempre con texto además de color.
- **Gráfica de dominio**: barra 100% apilada (SVG) con leyenda y resumen "X de N temas dominados".
- **Gráfica de actividad**: área + línea de sesiones acumuladas (SVG), con rejilla y puntos interactivos.
- **Tooltip**: burbuja fija que sigue al ratón o se ancla al elemento con foco de teclado.
- **empty-state**: mensaje centrado cuando no hay datos todavía.

## 8. Principios UX

- **Dirigir, no solo informar**: el callout "próximo paso" antepone la acción siguiente a los datos históricos.
- **Framing positivo**: el progreso se expresa como proporción ("X de N temas dominados"), no como carencia.
- **Accesibilidad real**: contraste AA, foco visible, gráficas con `aria-label` descriptivo, tooltips también por teclado, `prefers-reduced-motion` respetado.
- **Imprimible**: `@media print` oculta lo puramente interactivo y evita cortes feos de panel.
- **Offline-first**: cero dependencias externas (sin CDN, sin fuentes web, sin librerías); todo vive en el propio HTML generado.

## 9. Anti-patrones

No se usan en este DS:
- Borde lateral de acento tipo "side-stripe" en tarjetas o callouts.
- Tarjetas anidadas dentro de otras tarjetas.
- Gradientes decorativos.
- Glassmorphism (blur, transparencias de cristal).
- Em dashes en el chrome de la interfaz (títulos, etiquetas, botones).
- Más de un acento de marca compitiendo por atención.
