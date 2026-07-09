import fs from 'node:fs';
import PDFDocument from 'pdfkit';
import MarkdownIt from 'markdown-it';
import {dirname, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, '..');
const input = resolve(repoRoot, 'docs', 'Cybergain-Setup-Guide.md');
const output = resolve(repoRoot, 'docs', 'Cybergain-Setup-Guide.pdf');

const MARGIN_LEFT = 64;
const MARGIN_RIGHT = 64;
const MARGIN_TOP = 72;
const MARGIN_BOTTOM = 72;

const COLORS = {
  ink: '#1F2937',
  navy: '#111827',
  teal: '#0F766E',
  tealTint: '#F0FDFA',
  rule: '#CBD5E1',
  codeBg: '#F1F5F9',
  codeBorder: '#E2E8F0',
  codeText: '#0F172A',
  muted: '#64748B',
};

const md = new MarkdownIt({
  html: false,
  linkify: true,
  typographer: false,
});

const source = fs.readFileSync(input, 'utf8');
const tokens = md.parse(source, {});

const doc = new PDFDocument({
  size: 'A4',
  autoFirstPage: false,
  bufferPages: true,
  margins: {top: MARGIN_TOP, bottom: MARGIN_BOTTOM, left: MARGIN_LEFT, right: MARGIN_RIGHT},
  info: {
    Title: 'Cybergain Study OS — Guía de instalación y uso',
    Author: 'LhabiaStudio',
    Subject: 'Guía de instalación y uso en Windows para Cybergain Study OS',
  },
});

doc.pipe(fs.createWriteStream(output));
doc.lineGap(4);

let pageCount = 0;
let tocPageIndex = null;
let tocEntriesStartY = 0;
const tocEntries = [];

doc.on('pageAdded', () => {
  pageCount += 1;
  if (pageCount >= 3) {
    drawHeader();
  }
});

function fontFor(bold, italic) {
  if (bold) return 'Helvetica-Bold';
  if (italic) return 'Helvetica-Oblique';
  return 'Helvetica';
}

function buildRuns(children, baseColor, codeColor) {
  if (!children) return [];
  const runs = [];
  let bold = false;
  let italic = false;
  let linkHref = null;
  let linkTextBuf = '';

  for (const child of children) {
    switch (child.type) {
      case 'strong_open':
        bold = true;
        break;
      case 'strong_close':
        bold = false;
        break;
      case 'em_open':
        italic = true;
        break;
      case 'em_close':
        italic = false;
        break;
      case 'code_inline':
        runs.push({text: child.content, font: 'Courier', color: codeColor});
        break;
      case 'link_open':
        linkHref = child.attrGet('href') || '';
        linkTextBuf = '';
        break;
      case 'link_close':
        if (linkHref && linkTextBuf && linkHref !== linkTextBuf) {
          runs.push({text: ` (${linkHref})`, font: 'Helvetica', color: COLORS.muted});
        }
        linkHref = null;
        linkTextBuf = '';
        break;
      case 'softbreak':
      case 'hardbreak':
        runs.push({text: ' ', font: fontFor(bold, italic), color: linkHref ? COLORS.teal : baseColor});
        break;
      case 'text':
        if (linkHref) linkTextBuf += child.content;
        runs.push({text: child.content, font: fontFor(bold, italic), color: linkHref ? COLORS.teal : baseColor});
        break;
      default:
        break;
    }
  }

  return runs.filter((run) => run.text.length > 0);
}

function renderRuns(runs, x, y, size, width) {
  if (!runs.length) return;
  const opts = {continued: runs.length > 1};
  if (width) opts.width = width;
  doc.font(runs[0].font).fontSize(size).fillColor(runs[0].color);
  doc.text(runs[0].text, x, y, opts);
  for (let idx = 1; idx < runs.length; idx += 1) {
    const run = runs[idx];
    doc.font(run.font).fontSize(size).fillColor(run.color);
    doc.text(run.text, {continued: idx < runs.length - 1});
  }
}

function extractPlainText(inlineToken) {
  if (!inlineToken || !inlineToken.children) return '';
  return inlineToken.children
    .map((child) => {
      if (child.type === 'softbreak' || child.type === 'hardbreak') return ' ';
      return child.content || '';
    })
    .join('')
    .trim();
}

function ensureSpace(minSpace) {
  const bottom = doc.page.height - MARGIN_BOTTOM;
  if (bottom - doc.y < minSpace) {
    doc.addPage();
  }
}

function drawHeader() {
  doc.fillColor(COLORS.teal).font('Helvetica').fontSize(8.5);
  doc.text('Cybergain Study OS', MARGIN_LEFT, 40, {lineBreak: false});
  doc.lineWidth(0.75);
  doc.moveTo(MARGIN_LEFT, 56).lineTo(doc.page.width - MARGIN_RIGHT, 56).stroke(COLORS.teal);
  doc.x = MARGIN_LEFT;
  doc.y = MARGIN_TOP;
  doc.fillColor(COLORS.ink);
  doc.lineGap(4);
}

function drawFooter(pageNum, total) {
  // Bajar el margen inferior a 0 evita que pdfkit dispare un salto de página
  // automático al escribir por debajo de maxY (causaba 1 página en blanco por footer).
  const savedBottom = doc.page.margins.bottom;
  doc.page.margins.bottom = 0;
  const y = doc.page.height - 40;
  doc.fillColor(COLORS.muted).font('Helvetica').fontSize(8.5);
  doc.text(`${pageNum} / ${total}`, MARGIN_LEFT, y, {
    width: doc.page.width - MARGIN_LEFT - MARGIN_RIGHT,
    align: 'center',
    lineBreak: false,
  });
  doc.page.margins.bottom = savedBottom;
}

function drawCover() {
  const bandHeight = 150;
  const contentWidth = doc.page.width - MARGIN_LEFT * 2;
  // La tagline se ancla cerca del pie; sin esto pdfkit añade una página en blanco.
  const savedBottom = doc.page.margins.bottom;
  doc.page.margins.bottom = 0;

  doc.rect(0, 0, doc.page.width, bandHeight).fill(COLORS.teal);

  doc.fillColor('#FFFFFF').font('Helvetica-Bold').fontSize(30);
  doc.text('Cybergain Study OS', MARGIN_LEFT, 55, {width: contentWidth});

  doc.fillColor(COLORS.muted).font('Helvetica').fontSize(15);
  doc.text('Guía de instalación y uso — Windows', MARGIN_LEFT, bandHeight + 30, {width: contentWidth});

  doc.fillColor(COLORS.muted).font('Helvetica').fontSize(11);
  doc.text('LhabiaStudio · Sistema de estudio para bootcamp de ciberseguridad', MARGIN_LEFT, bandHeight + 70, {
    width: contentWidth,
  });

  doc.fillColor(COLORS.muted).font('Courier').fontSize(9);
  doc.text('> primero pensar · luego corregir · luego resumir', MARGIN_LEFT, doc.page.height - 70, {
    width: contentWidth,
    lineBreak: false,
  });

  doc.page.margins.bottom = savedBottom;
  doc.fillColor(COLORS.ink);
}

function drawHeading(text, level) {
  const width = doc.page.width - MARGIN_LEFT - MARGIN_RIGHT;
  doc.lineGap(0);

  if (level === 1) {
    doc.font('Helvetica-Bold').fontSize(26).fillColor(COLORS.navy);
    doc.text(text, MARGIN_LEFT, doc.y, {width});
    doc.y += 14;
  } else if (level === 2) {
    doc.y += 18;
    doc.font('Helvetica-Bold').fontSize(17).fillColor(COLORS.teal);
    doc.text(text, MARGIN_LEFT, doc.y, {width});
    doc.y += 4;
    doc.lineWidth(0.75);
    doc.moveTo(MARGIN_LEFT, doc.y).lineTo(doc.page.width - MARGIN_RIGHT, doc.y).stroke(COLORS.teal);
    doc.y += 10;
  } else {
    doc.y += 12;
    doc.font('Helvetica-Bold').fontSize(13).fillColor(COLORS.navy);
    doc.text(text, MARGIN_LEFT, doc.y, {width});
    doc.y += 6;
  }

  doc.x = MARGIN_LEFT;
  doc.fillColor(COLORS.ink);
  doc.lineGap(4);
}

function drawTocEntry(text, pageNum, y) {
  const size = 10.5;
  doc.font('Helvetica').fontSize(size).fillColor(COLORS.ink);
  const numStr = String(pageNum);
  const numWidth = doc.widthOfString(numStr);
  const rightX = doc.page.width - MARGIN_RIGHT;
  const titleMaxWidth = rightX - MARGIN_LEFT - numWidth - 10;

  doc.text(text, MARGIN_LEFT, y, {width: titleMaxWidth, lineBreak: false, ellipsis: true});
  const titleWidth = Math.min(doc.widthOfString(text), titleMaxWidth);

  const dotsStartX = MARGIN_LEFT + titleWidth + 4;
  const dotsEndX = rightX - numWidth - 4;
  const dotWidth = doc.widthOfString('.');
  const available = dotsEndX - dotsStartX;
  const count = Math.max(0, Math.floor(available / dotWidth));

  doc.fillColor(COLORS.rule);
  doc.text('.'.repeat(count), dotsStartX, y, {lineBreak: false});

  doc.fillColor(COLORS.ink);
  doc.text(numStr, rightX - numWidth, y, {lineBreak: false});
}

function consumeListItem(startIndex) {
  let i = startIndex + 1;
  let inlineToken = null;
  while (i < tokens.length && tokens[i].type !== 'list_item_close') {
    if (tokens[i].type === 'inline' && !inlineToken) inlineToken = tokens[i];
    i += 1;
  }
  return {inlineToken, nextIndex: i};
}

function renderParagraph(inlineToken) {
  const runs = buildRuns(inlineToken.children, COLORS.ink, COLORS.codeText);
  if (!runs.length) return;
  doc.lineGap(4);
  renderRuns(runs, MARGIN_LEFT, doc.y, 10.5);
  doc.y += 8;
  doc.x = MARGIN_LEFT;
}

function renderListItem(inlineToken, marker, indentWidth) {
  const bulletX = MARGIN_LEFT;
  const textX = MARGIN_LEFT + indentWidth;
  const startY = doc.y;

  doc.font('Helvetica').fontSize(10.5).fillColor(COLORS.teal);
  doc.text(marker, bulletX, startY, {continued: false, lineBreak: false});

  const runs = buildRuns(inlineToken.children, COLORS.ink, COLORS.codeText);
  const savedMarginLeft = doc.page.margins.left;
  doc.page.margins.left = textX;
  doc.lineGap(4);
  renderRuns(runs, textX, startY, 10.5);
  doc.page.margins.left = savedMarginLeft;

  doc.x = MARGIN_LEFT;
  doc.y += 5;
}

function drawCodeBox(code, x, y, boxWidth, boxHeight, textWidth, pad) {
  doc.lineWidth(1);
  doc.roundedRect(x, y, boxWidth, boxHeight, 8).fillAndStroke(COLORS.codeBg, COLORS.codeBorder);
  doc.fillColor(COLORS.codeText).font('Courier').fontSize(9);
  doc.text(code, x + pad, y + pad, {width: textWidth, lineGap: 2});
}

function renderCodeBlockAcrossPages(code, boxWidth, textWidth, pad, pageContentHeight) {
  const lines = code.split('\n');
  const maxTextHeight = pageContentHeight - pad * 2 - 10;
  let chunk = [];
  let first = true;

  const flush = () => {
    if (!chunk.length) return;
    if (!first) doc.addPage();
    const chunkText = chunk.join('\n');
    doc.font('Courier').fontSize(9);
    const h = doc.heightOfString(chunkText, {width: textWidth, lineGap: 2}) + pad * 2;
    drawCodeBox(chunkText, MARGIN_LEFT, doc.y, boxWidth, h, textWidth, pad);
    doc.y += h + 10;
    chunk = [];
    first = false;
  };

  for (const line of lines) {
    const trial = [...chunk, line].join('\n');
    doc.font('Courier').fontSize(9);
    const h = doc.heightOfString(trial, {width: textWidth, lineGap: 2});
    if (h > maxTextHeight && chunk.length) {
      flush();
      chunk = [line];
    } else {
      chunk.push(line);
    }
  }
  flush();
}

function renderCodeBlock(code) {
  if (!code) return;
  const pad = 10;
  const boxWidth = doc.page.width - MARGIN_LEFT - MARGIN_RIGHT;
  const textWidth = boxWidth - pad * 2;

  doc.font('Courier').fontSize(9);
  const textHeight = doc.heightOfString(code, {width: textWidth, lineGap: 2});
  const boxHeight = textHeight + pad * 2;
  const pageContentHeight = doc.page.height - MARGIN_TOP - MARGIN_BOTTOM;
  const availableHeight = doc.page.height - MARGIN_BOTTOM - doc.y;

  if (boxHeight <= availableHeight) {
    drawCodeBox(code, MARGIN_LEFT, doc.y, boxWidth, boxHeight, textWidth, pad);
    doc.y += boxHeight + 10;
  } else if (boxHeight <= pageContentHeight) {
    doc.addPage();
    drawCodeBox(code, MARGIN_LEFT, doc.y, boxWidth, boxHeight, textWidth, pad);
    doc.y += boxHeight + 10;
  } else {
    renderCodeBlockAcrossPages(code, boxWidth, textWidth, pad, pageContentHeight);
  }

  doc.fillColor(COLORS.ink);
  doc.font('Helvetica').fontSize(10.5);
  doc.lineGap(4);
  doc.x = MARGIN_LEFT;
}

function renderBlockquote(inlineTokens) {
  if (!inlineTokens.length) return;
  const pad = 10;
  const barWidth = 3;
  const boxWidth = doc.page.width - MARGIN_LEFT - MARGIN_RIGHT;
  const textWidth = boxWidth - pad * 2 - barWidth;

  doc.font('Helvetica').fontSize(10.5);
  const runsList = inlineTokens.map((t) => buildRuns(t.children, COLORS.ink, COLORS.codeText));
  let totalHeight = pad * 2;
  for (const runs of runsList) {
    const text = runs.map((r) => r.text).join('');
    totalHeight += doc.heightOfString(text, {width: textWidth, lineGap: 4}) + 4;
  }

  const availableHeight = doc.page.height - MARGIN_BOTTOM - doc.y;
  if (totalHeight > availableHeight) doc.addPage();

  const boxY = doc.y;
  doc.rect(MARGIN_LEFT, boxY, boxWidth, totalHeight).fill(COLORS.tealTint);
  doc.rect(MARGIN_LEFT, boxY, barWidth, totalHeight).fill(COLORS.teal);

  let y = boxY + pad;
  doc.lineGap(4);
  for (const runs of runsList) {
    renderRuns(runs, MARGIN_LEFT + barWidth + pad, y, 10.5, textWidth);
    y = doc.y + 4;
  }

  doc.y = boxY + totalHeight + 10;
  doc.x = MARGIN_LEFT;
  doc.fillColor(COLORS.ink);
}

function renderTable(rows) {
  ensureSpace(60);
  doc.font('Helvetica').fontSize(10.5).fillColor(COLORS.ink).lineGap(4);
  for (const row of rows) {
    doc.text(row.join('  |  '), MARGIN_LEFT, doc.y, {width: doc.page.width - MARGIN_LEFT - MARGIN_RIGHT});
    doc.y += 4;
  }
  doc.y += 8;
  doc.x = MARGIN_LEFT;
}

doc.addPage();
drawCover();

doc.addPage();
tocPageIndex = doc.bufferedPageRange().count - 1;
drawHeading('Contenido', 2);
tocEntriesStartY = doc.y;

doc.addPage();

let i = 0;
while (i < tokens.length) {
  const token = tokens[i];

  if (token.type === 'heading_open') {
    const level = Number(token.tag.slice(1));
    const inlineToken = tokens[i + 1];
    const text = extractPlainText(inlineToken);
    ensureSpace(90);
    if (level === 2 && text) tocEntries.push({text, page: pageCount});
    if (text) drawHeading(text, level);
    i += 3;
    continue;
  }

  if (token.type === 'paragraph_open') {
    const inlineToken = tokens[i + 1];
    renderParagraph(inlineToken);
    i += 3;
    continue;
  }

  if (token.type === 'bullet_list_open') {
    i += 1;
    while (i < tokens.length && tokens[i].type !== 'bullet_list_close') {
      if (tokens[i].type === 'list_item_open') {
        const {inlineToken, nextIndex} = consumeListItem(i);
        if (inlineToken) renderListItem(inlineToken, '•', 16);
        i = nextIndex + 1;
        continue;
      }
      i += 1;
    }
    i += 1;
    doc.y += 4;
    continue;
  }

  if (token.type === 'ordered_list_open') {
    let idx = Number(token.attrGet('start') || 1);
    i += 1;
    while (i < tokens.length && tokens[i].type !== 'ordered_list_close') {
      if (tokens[i].type === 'list_item_open') {
        const {inlineToken, nextIndex} = consumeListItem(i);
        if (inlineToken) renderListItem(inlineToken, `${idx}.`, 22);
        idx += 1;
        i = nextIndex + 1;
        continue;
      }
      i += 1;
    }
    i += 1;
    doc.y += 4;
    continue;
  }

  if (token.type === 'fence' || token.type === 'code_block') {
    renderCodeBlock(token.content.replace(/\s+$/, ''));
    i += 1;
    continue;
  }

  if (token.type === 'blockquote_open') {
    let j = i + 1;
    const inlineTokens = [];
    while (j < tokens.length && tokens[j].type !== 'blockquote_close') {
      if (tokens[j].type === 'inline') inlineTokens.push(tokens[j]);
      j += 1;
    }
    renderBlockquote(inlineTokens);
    i = j + 1;
    continue;
  }

  if (token.type === 'table_open') {
    let j = i + 1;
    const rows = [];
    let currentRow = null;
    while (j < tokens.length && tokens[j].type !== 'table_close') {
      const t = tokens[j];
      if (t.type === 'tr_open') currentRow = [];
      else if (t.type === 'tr_close') {
        if (currentRow) rows.push(currentRow);
        currentRow = null;
      } else if (t.type === 'inline' && currentRow) currentRow.push(t.content);
      j += 1;
    }
    renderTable(rows);
    i = j + 1;
    continue;
  }

  if (token.type === 'hr') {
    doc.y += 6;
    doc.lineWidth(0.75);
    doc.moveTo(MARGIN_LEFT, doc.y).lineTo(doc.page.width - MARGIN_RIGHT, doc.y).stroke(COLORS.rule);
    doc.y += 12;
    i += 1;
    continue;
  }

  i += 1;
}

const total = doc.bufferedPageRange().count;

doc.switchToPage(tocPageIndex);
const entryHeight = 20;
const availableTocHeight = doc.page.height - MARGIN_BOTTOM - tocEntriesStartY;

if (tocEntries.length * entryHeight <= availableTocHeight) {
  let y = tocEntriesStartY;
  for (const entry of tocEntries) {
    drawTocEntry(entry.text, entry.page, y);
    y += entryHeight;
  }
} else {
  doc.font('Helvetica').fontSize(10.5).fillColor(COLORS.ink);
  let y = tocEntriesStartY;
  let n = 1;
  for (const entry of tocEntries) {
    if (y + entryHeight > doc.page.height - MARGIN_BOTTOM) break;
    doc.text(`${n}. ${entry.text}`, MARGIN_LEFT, y, {
      width: doc.page.width - MARGIN_LEFT - MARGIN_RIGHT,
      lineBreak: false,
      ellipsis: true,
    });
    y += entryHeight;
    n += 1;
  }
}

for (let p = 1; p < total; p += 1) {
  doc.switchToPage(p);
  drawFooter(p + 1, total);
}

doc.end();
console.log(`PDF generado: ${output} (${total} páginas)`);
