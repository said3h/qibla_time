const fs = require('fs');
const https = require('https');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');
const inputPath = path.join(repoRoot, 'assets', 'data', 'quran_offline.json');
const markdownReportPath = path.join(repoRoot, 'scripts', 'quran_translation_audit_report.md');
const jsonReportPath = path.join(repoRoot, 'scripts', 'quran_translation_audit_report.json');

const coranIndexUrl =
  'https://coran.org.ar/wp-json/wp/v2/posts?per_page=100&page={page}&_fields=link,title';

const data = JSON.parse(fs.readFileSync(inputPath, 'utf8'));

const allowedSingleLetterWords = new Set(['a', 'e', 'o', 'u', 'y']);
const suspiciousEndingPatterns = [
  /\bya que$/iu,
  /\bporque$/iu,
  /\bpara que$/iu,
  /\bde$/iu,
  /\bcon$/iu,
  /\bsin$/iu,
  /\by$/iu,
  /\bo$/iu,
];

function decodeHtmlEntities(value) {
  const named = {
    Aacute: 'Á',
    Eacute: 'É',
    Iacute: 'Í',
    Ntilde: 'Ñ',
    Oacute: 'Ó',
    Uacute: 'Ú',
    aacute: 'á',
    amp: '&',
    apos: "'",
    eacute: 'é',
    gt: '>',
    iacute: 'í',
    iexcl: '¡',
    iquest: '¿',
    lt: '<',
    nbsp: ' ',
    ntilde: 'ñ',
    oacute: 'ó',
    quot: '"',
    uacute: 'ú',
  };

  return value
    .replace(/&#(\d+);/g, (_, code) => String.fromCodePoint(Number(code)))
    .replace(/&#x([0-9a-f]+);/gi, (_, code) => String.fromCodePoint(parseInt(code, 16)))
    .replace(/&([a-z]+);/gi, (match, name) => named[name] || match);
}

function stripHtml(value) {
  return decodeHtmlEntities(value.replace(/<[^>]*>/g, ' '))
    .replace(/\s+/g, ' ')
    .trim();
}

function normalizeReferenceText(value) {
  return value
    .replace(/^\d+\.\s*/u, '')
    .replace(/\s+/gu, ' ')
    .trim();
}

function normalizeForComparison(value) {
  return value
    .normalize('NFKC')
    .normalize('NFD')
    .replace(/\p{Diacritic}/gu, '')
    .toLowerCase()
    .replace(/[“”«»]/gu, '"')
    .replace(/[‘’]/gu, "'")
    .replace(/[^\p{L}\p{N}]+/gu, ' ')
    .replace(/\s+/gu, ' ')
    .trim();
}

function cleanToken(token) {
  return token.replace(/^[^\p{L}]+|[^\p{L}]+$/gu, '');
}

function fetchText(url) {
  return new Promise((resolve, reject) => {
    https
      .get(url, { headers: { 'User-Agent': 'qibla-time-quran-audit/2.0' } }, (response) => {
        if (
          response.statusCode >= 300 &&
          response.statusCode < 400 &&
          response.headers.location
        ) {
          response.resume();
          fetchText(new URL(response.headers.location, url).toString()).then(resolve, reject);
          return;
        }

        if (response.statusCode !== 200) {
          response.resume();
          reject(new Error(`HTTP ${response.statusCode} for ${url}`));
          return;
        }

        let body = '';
        response.setEncoding('utf8');
        response.on('data', (chunk) => {
          body += chunk;
        });
        response.on('end', () => resolve(body));
      })
      .on('error', reject);
  });
}

async function fetchCoranSuraLinks() {
  const links = new Map();

  for (let page = 1; page <= 2; page += 1) {
    const body = await fetchText(coranIndexUrl.replace('{page}', String(page)));
    const posts = JSON.parse(body);
    for (const post of posts) {
      const title = stripHtml(post.title?.rendered || '');
      const match = title.match(/^(\d+)\./u);
      if (!match || !post.link) continue;
      links.set(Number(match[1]), post.link);
    }
  }

  return links;
}

function parseCoranTranslations(html, surahNumber) {
  const translations = new Map();
  const rowRegex =
    /<tr\b[^>]*>\s*<td\b[^>]*>\s*([^<]+?)\s*<\/td>\s*<td\b[^>]*>\s*([\s\S]*?)\s*<\/td>\s*<\/tr>/gi;
  let match;

  while ((match = rowRegex.exec(html)) !== null) {
    const verseRef = stripHtml(match[1]);
    const rawText = stripHtml(match[2]);
    const refMatch = verseRef.match(/^(\d+)\.(\d+)$/u);
    if (!refMatch) continue;

    const surah = Number(refMatch[1]);
    const ayah = Number(refMatch[2]);
    if (surah !== surahNumber) continue;
    if (!rawText.match(new RegExp(`^${ayah}\\.`, 'u'))) continue;

    const text = normalizeReferenceText(rawText);
    if (text) translations.set(`${surah}:${ayah}`, text);
  }

  return translations;
}

async function fetchCoranReference() {
  const links = await fetchCoranSuraLinks();
  const reference = new Map();
  const sourceUrls = new Map();

  for (const [surahNumber, url] of [...links.entries()].sort((a, b) => a[0] - b[0])) {
    const html = await fetchText(url);
    const translations = parseCoranTranslations(html, surahNumber);
    for (const [key, text] of translations.entries()) {
      reference.set(key, text);
      sourceUrls.set(key, url);
    }
  }

  return { reference, sourceUrls, suraCount: links.size };
}

function buildAppAyahMap() {
  const app = new Map();

  for (const [surahNumber, surah] of Object.entries(data.surahs || {})) {
    for (const ayah of surah.ayahs || []) {
      const key = `${Number(surahNumber)}:${Number(ayah.numberInSurah)}`;
      app.set(key, {
        key,
        surah: Number(surahNumber),
        ayah: Number(ayah.numberInSurah),
        entry: ayah,
        text: typeof ayah.translation === 'string' ? ayah.translation : '',
      });
    }
  }

  return app;
}

function hasBalancedPairs(text, open, close) {
  let count = 0;
  for (const char of text) {
    if (char === open) count += 1;
    if (char === close) count -= 1;
    if (count < 0) return false;
  }
  return count === 0;
}

function countMatches(text, regex) {
  return (text.match(regex) || []).length;
}

function auditSpanishText(text) {
  const reasons = [];
  const trimmed = text.trim();

  if (!trimmed) reasons.push('texto vacio');
  if (text.includes('\uFFFD')) reasons.push('caracter de reemplazo Unicode');
  if (/&(?:[a-z]+|#\d+|#x[0-9a-f]+);/iu.test(text)) reasons.push('HTML visible');
  if (/[ÃÂ�]|â[€™€œ€�]/u.test(text)) reasons.push('mojibake/corrupcion de encoding');
  if (/\s{2,}/u.test(text)) reasons.push('dobles espacios');
  if (suspiciousEndingPatterns.some((pattern) => pattern.test(trimmed))) {
    reasons.push('frase terminada con patron sospechoso');
  }
  if (!hasBalancedPairs(text, '[', ']')) reasons.push('corchetes desbalanceados');
  if (!hasBalancedPairs(text, '(', ')')) reasons.push('parentesis desbalanceados');

  const tokens = trimmed.split(/\s+/u).map((token) => cleanToken(token));
  for (const token of tokens) {
    const lower = token.toLowerCase();
    if (lower.length === 1 && /[\p{L}]/u.test(lower) && !allowedSingleLetterWords.has(lower)) {
      reasons.push(`palabra de una sola letra sospechosa: ${token}`);
    }
  }

  for (let i = 0; i < tokens.length - 1; i += 1) {
    const current = normalizeForComparison(tokens[i]);
    const previous = normalizeForComparison(tokens[i - 1] || '');
    const next = normalizeForComparison(tokens[i + 1]);
    if (current !== 'e') continue;
    if (!next || next.startsWith('i') || next.startsWith('hi')) continue;
    if (previous === 'y') {
      reasons.push(`palabra incompleta probable: y e ${tokens[i + 1]}`);
    } else {
      reasons.push(`uso sospechoso de "e" antes de ${tokens[i + 1]}`);
    }
  }

  return [...new Set(reasons)];
}

function getLengthDiff(currentText, referenceText) {
  const currentLength = normalizeForComparison(currentText).length;
  const referenceLength = normalizeForComparison(referenceText).length;
  const min = Math.max(1, Math.min(currentLength, referenceLength));
  const max = Math.max(currentLength, referenceLength);
  return {
    currentLength,
    referenceLength,
    ratio: Number((max / min).toFixed(2)),
    delta: Math.abs(currentLength - referenceLength),
  };
}

function isSuspiciousLengthDiff(currentText, referenceText) {
  const diff = getLengthDiff(currentText, referenceText);
  return diff.delta >= 120 && diff.ratio >= 2.1;
}

function isSourceTextComplete(referenceText) {
  return auditSpanishText(referenceText).length === 0;
}

function isAutoFixable(appItem, sourceText) {
  const reasons = auditSpanishText(appItem.text);
  const endsWithCutPhrase = /\bya que$/iu.test(appItem.text.trim());
  return reasons.length > 0 && endsWithCutPhrase && isSourceTextComplete(sourceText);
}

function pushCategory(categories, category, item) {
  categories[category].push({
    category,
    surah: item.surah,
    ayah: item.ayah,
    currentText: item.currentText || '',
    sourceText: item.sourceText || '',
    sourceUrl: item.sourceUrl || '',
    reasons: item.reasons || [],
    recommendation: item.recommendation || '',
    length: item.length || undefined,
  });
}

function runProAudit({ appMap, sourceMap, sourceUrls }) {
  const categories = {
    critical_auto_fixable: [],
    critical_manual_review: [],
    suspicious_length_diff: [],
    normal_translation_difference: [],
    source_missing: [],
    app_missing: [],
  };
  const appliedCorrections = [];

  for (const [key, appItem] of [...appMap.entries()].sort((a, b) => {
    if (a[1].surah !== b[1].surah) return a[1].surah - b[1].surah;
    return a[1].ayah - b[1].ayah;
  })) {
    const sourceText = sourceMap.get(key);
    const sourceUrl = sourceUrls.get(key) || '';
    const appReasons = auditSpanishText(appItem.text);

    if (!sourceText) {
      pushCategory(categories, 'source_missing', {
        ...appItem,
        currentText: appItem.text,
        reasons: ['coran.org.ar no tiene esta aleya parseada'],
        recommendation: 'No corregir automaticamente; falta confirmar en fuente externa.',
      });
      continue;
    }

    if (appReasons.length > 0) {
      if (isAutoFixable(appItem, sourceText)) {
        const before = appItem.text;
        appItem.entry.translation = sourceText;
        appItem.text = sourceText;
        appliedCorrections.push({
          surah: appItem.surah,
          ayah: appItem.ayah,
          before,
          after: sourceText,
          sourceUrl,
          reasons: appReasons,
        });
        pushCategory(categories, 'critical_auto_fixable', {
          ...appItem,
          currentText: before,
          sourceText,
          sourceUrl,
          reasons: appReasons,
          recommendation: 'Corregido automaticamente con coran.org.ar porque era texto cortado verificable.',
        });
      } else {
        pushCategory(categories, 'critical_manual_review', {
          ...appItem,
          currentText: appItem.text,
          sourceText,
          sourceUrl,
          reasons: appReasons,
          recommendation: 'Revisar manualmente; no se autocorrige porque puede requerir criterio editorial.',
        });
      }
      continue;
    }

    if (isSuspiciousLengthDiff(appItem.text, sourceText)) {
      pushCategory(categories, 'suspicious_length_diff', {
        ...appItem,
        currentText: appItem.text,
        sourceText,
        sourceUrl,
        reasons: ['diferencia de longitud muy grande'],
        recommendation: 'Comparar manualmente antes de tocar la traduccion.',
        length: getLengthDiff(appItem.text, sourceText),
      });
      continue;
    }

    if (normalizeForComparison(appItem.text) !== normalizeForComparison(sourceText)) {
      pushCategory(categories, 'normal_translation_difference', {
        ...appItem,
        currentText: appItem.text,
        sourceText,
        sourceUrl,
        reasons: ['traduccion distinta sin senales claras de corrupcion'],
        recommendation: 'No tocar automaticamente; diferencia normal entre fuentes.',
      });
    }
  }

  for (const [key, sourceText] of sourceMap.entries()) {
    if (appMap.has(key)) continue;
    const [surah, ayah] = key.split(':').map(Number);
    pushCategory(categories, 'app_missing', {
      surah,
      ayah,
      currentText: '',
      sourceText,
      sourceUrl: sourceUrls.get(key) || '',
      reasons: ['la app no tiene esta aleya'],
      recommendation: 'Verificar estructura del dataset offline.',
    });
  }

  return { categories, appliedCorrections };
}

function summarizeCategories(categories) {
  return Object.fromEntries(
    Object.entries(categories).map(([name, items]) => [name, items.length]),
  );
}

function firstItems(items, limit = 25) {
  return items.slice(0, limit);
}

function renderIssueItem(item, index) {
  return [
    `### ${index + 1}. ${item.surah}:${item.ayah}`,
    '',
    `- Reasons: ${item.reasons.join('; ') || '(none)'}`,
    `- Recommendation: ${item.recommendation || '(manual review)'}`,
    item.length ? `- Length: ${JSON.stringify(item.length)}` : '',
    `- Source: ${item.sourceUrl || '(not available)'}`,
    `- Current: ${item.currentText || '(missing)'}`,
    `- coran.org.ar: ${item.sourceText || '(missing)'}`,
    '',
  ]
    .filter(Boolean)
    .join('\n');
}

function buildMarkdownReport({ summary, categories, appliedCorrections, referenceStatus }) {
  const categorySections = Object.entries(categories).flatMap(([name, items]) => [
    `## ${name}`,
    '',
    `Count: ${items.length}`,
    '',
    ...(
      items.length > 0
        ? firstItems(items).map((item, index) => renderIssueItem(item, index))
        : ['No items.', '']
    ),
    items.length > 25 ? `_Showing first 25 of ${items.length}. Full list is in JSON report._` : '',
    '',
  ]);

  return [
    '# Quran Spanish Translation PRO Audit',
    '',
    `Input: \`${path.relative(repoRoot, inputPath).replace(/\\/g, '/')}\``,
    `Generated: ${new Date().toISOString()}`,
    `Reference: ${referenceStatus}`,
    '',
    '## Summary',
    '',
    `- App ayahs checked: ${summary.appAyahs}`,
    `- coran.org.ar ayahs parsed: ${summary.sourceAyahs}`,
    `- Applied corrections: ${appliedCorrections.length}`,
    `- Category counts: ${JSON.stringify(summary.categories)}`,
    '',
    '## Applied Corrections',
    '',
    ...(
      appliedCorrections.length > 0
        ? appliedCorrections.map((item, index) =>
            [
              `### ${index + 1}. ${item.surah}:${item.ayah}`,
              '',
              `- Source: ${item.sourceUrl}`,
              `- Reasons: ${item.reasons.join('; ')}`,
              `- Before: ${item.before}`,
              `- After: ${item.after}`,
              '',
            ].join('\n'),
          )
        : ['No automatic corrections were applied.', '']
    ),
    ...categorySections,
  ].join('\n');
}

async function main() {
  const appMap = buildAppAyahMap();
  const { reference, sourceUrls, suraCount } = await fetchCoranReference();
  const referenceStatus = `coran.org.ar loaded (${suraCount} suras, ${reference.size} translated ayahs)`;

  const { categories, appliedCorrections } = runProAudit({
    appMap,
    sourceMap: reference,
    sourceUrls,
  });

  if (appliedCorrections.length > 0) {
    fs.writeFileSync(inputPath, JSON.stringify(data), 'utf8');
  }

  const summary = {
    appAyahs: appMap.size,
    sourceAyahs: reference.size,
    categories: summarizeCategories(categories),
  };

  const markdown = buildMarkdownReport({
    summary,
    categories,
    appliedCorrections,
    referenceStatus,
  });

  fs.writeFileSync(markdownReportPath, markdown, 'utf8');
  fs.writeFileSync(
    jsonReportPath,
    JSON.stringify({ summary, referenceStatus, appliedCorrections, categories }, null, 2),
    'utf8',
  );

  console.log(`App ayahs checked: ${summary.appAyahs}`);
  console.log(`coran.org.ar ayahs parsed: ${summary.sourceAyahs}`);
  console.log(`Applied corrections: ${appliedCorrections.length}`);
  console.log(`Category counts: ${JSON.stringify(summary.categories)}`);
  console.log(`Markdown report: ${path.relative(repoRoot, markdownReportPath)}`);
  console.log(`JSON report: ${path.relative(repoRoot, jsonReportPath)}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
