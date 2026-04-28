const fs = require('fs');
const https = require('https');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');
const inputPath = path.join(repoRoot, 'assets', 'data', 'quran_offline.json');
const markdownReportPath = path.join(
  repoRoot,
  'scripts',
  'quran_translation_audit_report.md',
);
const jsonReportPath = path.join(
  repoRoot,
  'scripts',
  'quran_translation_audit_report.json',
);

const data = JSON.parse(fs.readFileSync(inputPath, 'utf8'));

const coranIndexUrl =
  'https://coran.org.ar/wp-json/wp/v2/posts?per_page=100&page={page}&_fields=link,title';
const expectedCoranReplacement = {
  surah: 40,
  ayah: 4,
  source: 'https://coran.org.ar/40-ghafir-que-perdona/',
};

const pendingSourceVerification = new Map([
  [
    'es:40:4:La frase termina con articulo, preposicion o conjuncion; probable texto cortado.',
    {
      reason:
        'Pendiente de fuente fiable: alquran.cloud es.garcia y Quran.com resource 83 tambien terminan en "ya que". No se completa automaticamente.',
      suggestion:
        'Regenerar o corregir manualmente desde una fuente española fiable antes de publicar.',
    },
  ],
]);

const suspiciousEndings = {
  es: new Set([
    'al',
    'ante',
    'con',
    'contra',
    'de',
    'del',
    'desde',
    'durante',
    'e',
    'en',
    'entre',
    'hacia',
    'hasta',
    'le',
    'les',
    'para',
    'pero',
    'por',
    'que',
    'segun',
    'según',
    'sin',
    'sobre',
    'tras',
    'y',
  ]),
  en: new Set(['a', 'an', 'and', 'as', 'at', 'by', 'for', 'from', 'in', 'of', 'or', 'the', 'to', 'with']),
  fr: new Set(['a', 'au', 'aux', 'avec', 'chez', 'dans', 'de', 'des', 'du', 'en', 'et', 'la', 'le', 'les', 'ou', 'par', 'pour', 'que', 'qui', 'sur', 'un', 'une']),
};

const allowedSingleLetterWords = {
  es: new Set(['a', 'e', 'o', 'u', 'y']),
  en: new Set(['a', 'i']),
  fr: new Set(['a', 'à', 'y']),
};

function normalizeWord(word) {
  return word
    .toLowerCase()
    .normalize('NFD')
    .replace(/\p{Diacritic}/gu, '')
    .replace(/^[^\p{L}]+|[^\p{L}]+$/gu, '');
}

function cleanToken(token) {
  return token.replace(/^[^\p{L}]+|[^\p{L}]+$/gu, '');
}

function detectTranslationEntries(ayah) {
  if (ayah.translations && typeof ayah.translations === 'object') {
    return Object.entries(ayah.translations)
      .filter(([, value]) => typeof value === 'string' && value.trim())
      .map(([language, text]) => ({ language, text }));
  }

  if (typeof ayah.translation === 'string' && ayah.translation.trim()) {
    return [{ language: 'es', text: ayah.translation }];
  }

  return [];
}

function decodeHtmlEntities(value) {
  const named = {
    Aacute: 'Á',
    Eacute: 'É',
    Iacute: 'Í',
    Ntilde: 'Ñ',
    Oacute: 'Ó',
    Uacute: 'Ú',
    amp: '&',
    apos: "'",
    aacute: 'á',
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
    .replace(/&([a-z]+);/gi, (match, name) => named[name.toLowerCase()] || match);
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

function fetchText(url) {
  return new Promise((resolve, reject) => {
    https
      .get(url, { headers: { 'User-Agent': 'qibla-time-quran-audit/1.0' } }, (response) => {
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
  const rowRegex = /<tr\b[^>]*>\s*<td\b[^>]*>\s*([^<]+?)\s*<\/td>\s*<td\b[^>]*>\s*([\s\S]*?)\s*<\/td>\s*<\/tr>/gi;
  let match;

  while ((match = rowRegex.exec(html)) !== null) {
    const verseRef = stripHtml(match[1]);
    const rawText = stripHtml(match[2]);
    const text = normalizeReferenceText(rawText);
    const refMatch = verseRef.match(/^(\d+)\.(\d+)$/u);
    if (!refMatch) continue;

    const surah = Number(refMatch[1]);
    const ayah = Number(refMatch[2]);
    if (surah !== surahNumber) continue;
    if (!rawText.match(new RegExp(`^${ayah}\\.`, 'u'))) continue;
    if (!text) continue;

    translations.set(ayah, normalizeReferenceText(text));
  }

  return translations;
}

async function fetchCoranReference() {
  const links = await fetchCoranSuraLinks();
  const reference = new Map();

  for (const [surahNumber, url] of [...links.entries()].sort((a, b) => a[0] - b[0])) {
    const html = await fetchText(url);
    reference.set(surahNumber, {
      url,
      translations: parseCoranTranslations(html, surahNumber),
    });
  }

  return reference;
}

function pushIssue(issues, issue) {
  const pendingKey = `${issue.language}:${Number(issue.surah)}:${Number(issue.ayah)}:${issue.reason}`;
  const pending = pendingSourceVerification.get(pendingKey);
  issues.push({
    severity: pending ? 'pending' : issue.severity || 'medium',
    language: issue.language,
    surah: Number(issue.surah),
    ayah: Number(issue.ayah),
    text: issue.text,
    suspicious: issue.suspicious || '',
    reason: pending ? pending.reason : issue.reason,
    suggestion: pending ? pending.suggestion : issue.suggestion || '',
  });
}

function auditText({ language, surah, ayah, text }) {
  const issues = [];
  const trimmed = text.trim();
  const normalizedLanguage = language.toLowerCase().split(/[-_]/)[0];

  if (text.includes('\uFFFD')) {
    pushIssue(issues, {
      severity: 'critical',
      language,
      surah,
      ayah,
      text,
      suspicious: '\uFFFD',
      reason: 'Caracter de reemplazo Unicode: indica corrupcion de encoding.',
    });
  }

  const htmlEntityMatch = text.match(/&(?:[a-z]+|#\d+|#x[0-9a-f]+);/iu);
  if (htmlEntityMatch) {
    pushIssue(issues, {
      severity: 'critical',
      language,
      surah,
      ayah,
      text,
      suspicious: htmlEntityMatch[0],
      reason: 'Entidad HTML visible dentro de la traduccion; indica texto importado sin decodificar.',
      suggestion: decodeHtmlEntities(text),
    });
  }

  const mojibakeMatch = text.match(/[ÃÂ�]|â[€™€œ€�]/u);
  if (mojibakeMatch) {
    pushIssue(issues, {
      severity: 'critical',
      language,
      surah,
      ayah,
      text,
      suspicious: mojibakeMatch[0],
      reason: 'Patron tipico de mojibake o texto mal decodificado.',
    });
  }

  if (/\s{2,}/u.test(text)) {
    pushIssue(issues, {
      severity: 'low',
      language,
      surah,
      ayah,
      text,
      suspicious: 'doble espacio',
      reason: 'Contiene espacios dobles o multiples.',
      suggestion: text.replace(/\s{2,}/gu, ' '),
    });
  }

  const lastRawWord = cleanToken(trimmed.split(/\s+/u).at(-1) || '').toLowerCase();
  const endings = suspiciousEndings[normalizedLanguage] || suspiciousEndings.es;
  const acceptedTerminalPronouns = new Set(['él', 'el', 'mí', 'mi', 'ti', 'sí', 'si']);
  if (
    lastRawWord &&
    endings.has(lastRawWord) &&
    !acceptedTerminalPronouns.has(lastRawWord)
  ) {
    pushIssue(issues, {
      severity: 'high',
      language,
      surah,
      ayah,
      text,
      suspicious: lastRawWord,
      reason: 'La frase termina con articulo, preposicion o conjuncion; probable texto cortado.',
    });
  }

  const tokens = trimmed.split(/\s+/u).map((token) => {
    const raw = cleanToken(token).toLowerCase();
    return { raw, normalized: normalizeWord(raw) };
  });

  const allowedSingles =
    allowedSingleLetterWords[normalizedLanguage] || allowedSingleLetterWords.es;
  for (const token of tokens) {
    if (
      token.raw.length === 1 &&
      !allowedSingles.has(token.raw) &&
      /[\p{L}]/u.test(token.raw)
    ) {
      pushIssue(issues, {
        severity: 'low',
        language,
        surah,
        ayah,
        text,
        suspicious: token.raw,
        reason: 'Palabra de una sola letra no esperada para este idioma.',
      });
    }
  }

  if (normalizedLanguage === 'es') {
    for (let i = 0; i < tokens.length - 1; i += 1) {
      const current = tokens[i];
      const previous = tokens[i - 1];
      const next = tokens[i + 1];
      if (current.normalized !== 'e') continue;
      if (!next?.normalized || next.normalized.startsWith('i') || next.normalized.startsWith('hi')) {
        continue;
      }

      const suspicious = `${current.raw} ${next.raw}`;
      const isLikelyMissingPronoun =
        previous?.normalized === 'y' &&
        ['temen', 'adora', 'adoran', 'invoca', 'invocan', 'siguen', 'obedecen'].includes(
          next.normalized,
        );

      pushIssue(issues, {
        severity: 'high',
        language,
        surah,
        ayah,
        text,
        suspicious: isLikelyMissingPronoun ? `y ${suspicious}` : suspicious,
        reason: isLikelyMissingPronoun
          ? 'Pronombre probablemente incompleto: aparece "y e ..." antes de verbo.'
          : 'Conjuncion "e" usada antes de palabra que no empieza por i/hi.',
        suggestion: isLikelyMissingPronoun
          ? `y le ${next.raw}`
          : next.normalized.startsWith('tem')
            ? `le ${next.raw}`
            : '',
      });
    }
  }

  return issues;
}

function auditDataset() {
  const issues = [];
  const surahs = data.surahs || {};

  for (const [surahNumber, surah] of Object.entries(surahs)) {
    for (const ayah of surah.ayahs || []) {
      for (const entry of detectTranslationEntries(ayah)) {
        issues.push(
          ...auditText({
            language: entry.language,
            surah: surahNumber,
            ayah: ayah.numberInSurah,
            text: entry.text,
          }),
        );
      }
    }
  }

  return issues;
}

function sortIssues(issues) {
  const severityRank = { critical: 0, high: 1, pending: 2, medium: 3, low: 4 };
  issues.sort((a, b) => {
    const severity = severityRank[a.severity] - severityRank[b.severity];
    if (severity !== 0) return severity;
    if (a.language !== b.language) return a.language.localeCompare(b.language);
    if (a.surah !== b.surah) return a.surah - b.surah;
    return a.ayah - b.ayah;
  });
}

function summarizeIssues(issues) {
  return issues.reduce(
    (acc, issue) => {
      acc.total += 1;
      acc.bySeverity[issue.severity] = (acc.bySeverity[issue.severity] || 0) + 1;
      acc.byLanguage[issue.language] = (acc.byLanguage[issue.language] || 0) + 1;
      return acc;
    },
    { total: 0, bySeverity: {}, byLanguage: {} },
  );
}

function getAyah(surah, ayah) {
  return data.surahs?.[String(surah)]?.ayahs?.find(
    (entry) => Number(entry.numberInSurah) === Number(ayah),
  );
}

function compareWithCoranReference(issues, reference) {
  const corrected = [];
  const differences = [];
  const pendingManual = [];

  for (const issue of issues.filter((entry) => entry.language === 'es')) {
    const referenceSura = reference.get(issue.surah);
    const referenceText = referenceSura?.translations.get(issue.ayah);

    if (!referenceText) {
      pendingManual.push({
        ...issue,
        referenceText: '',
        source: referenceSura?.url || '',
        recommendation: 'No se pudo confirmar esta aleya en coran.org.ar.',
      });
      continue;
    }

    const ayah = getAyah(issue.surah, issue.ayah);
    const currentText = ayah?.translation || '';
    const isExpectedSafeFix =
      issue.surah === expectedCoranReplacement.surah &&
      issue.ayah === expectedCoranReplacement.ayah &&
      (issue.suspicious === 'que' ||
        issue.reason ===
          'Entidad HTML visible dentro de la traduccion; indica texto importado sin decodificar.') &&
      (currentText.trim().endsWith('ya que') || /&(?:[a-z]+|#\d+|#x[0-9a-f]+);/iu.test(currentText)) &&
      referenceSura.url === expectedCoranReplacement.source;

    if (isExpectedSafeFix) {
      ayah.translation = referenceText;
      corrected.push({
        language: issue.language,
        surah: issue.surah,
        ayah: issue.ayah,
        before: currentText,
        after: referenceText,
        source: referenceSura.url,
        reason:
          'Texto cortado confirmado: la traduccion local termina en "ya que" y coran.org.ar contiene una aleya completa para la misma referencia.',
      });
      continue;
    }

    differences.push({
      language: issue.language,
      surah: issue.surah,
      ayah: issue.ayah,
      currentText,
      referenceText,
      source: referenceSura.url,
      reason: issue.reason,
      recommendation:
        'Diferencia detectada, no corregida automaticamente porque puede ser estilo o fuente de traduccion distinta.',
    });
  }

  return { corrected, differences, pendingManual };
}

function buildMarkdown({ summary, issues, coranComparison, referenceStatus }) {
  return [
    '# Quran Translation Audit Report',
    '',
    `Input: \`${path.relative(repoRoot, inputPath).replace(/\\/g, '/')}\``,
    `Generated: ${new Date().toISOString()}`,
    `Reference: ${referenceStatus}`,
    '',
    '## Summary',
    '',
    `- Total candidate issues: ${summary.total}`,
    `- By severity: ${JSON.stringify(summary.bySeverity)}`,
    `- By language: ${JSON.stringify(summary.byLanguage)}`,
    `- Corrected with coran.org.ar: ${coranComparison.corrected.length}`,
    `- Untouched suspicious differences: ${coranComparison.differences.length}`,
    `- Manual pending: ${coranComparison.pendingManual.length}`,
    '',
    '## Corrected Errors',
    '',
    ...(
      coranComparison.corrected.length
        ? coranComparison.corrected.map((item, index) =>
            [
              `### ${index + 1}. ${item.language} ${item.surah}:${item.ayah}`,
              '',
              `- Source: ${item.source}`,
              `- Reason: ${item.reason}`,
              `- Before: ${item.before}`,
              `- After: ${item.after}`,
              '',
            ].join('\n'),
          )
        : ['No automatic corrections were applied.', '']
    ),
    '## Untouched Differences',
    '',
    ...(
      coranComparison.differences.length
        ? coranComparison.differences.map((item, index) =>
            [
              `### ${index + 1}. ${item.language} ${item.surah}:${item.ayah}`,
              '',
              `- Source: ${item.source}`,
              `- Reason: ${item.reason}`,
              `- Recommendation: ${item.recommendation}`,
              `- Current: ${item.currentText}`,
              `- coran.org.ar: ${item.referenceText}`,
              '',
            ].join('\n'),
          )
        : ['No untouched suspicious differences.', '']
    ),
    '## Manual Pending',
    '',
    ...(
      coranComparison.pendingManual.length
        ? coranComparison.pendingManual.map((item, index) =>
            [
              `### ${index + 1}. ${item.language} ${item.surah}:${item.ayah}`,
              '',
              `- Source: ${item.source || '(not available)'}`,
              `- Reason: ${item.reason}`,
              `- Recommendation: ${item.recommendation}`,
              `- Current: ${item.text}`,
              '',
            ].join('\n'),
          )
        : ['No manual pending items.', '']
    ),
    '## Issues',
    '',
    ...issues.map((issue, index) => {
      return [
        `### ${index + 1}. [${issue.severity}] ${issue.language} ${issue.surah}:${issue.ayah}`,
        '',
        `- Suspicious: \`${issue.suspicious || '(general)'}\``,
        `- Reason: ${issue.reason}`,
        `- Suggestion: ${issue.suggestion || '(manual review)'}`,
        `- Text: ${issue.text}`,
        '',
      ].join('\n');
    }),
  ].join('\n');
}

async function main() {
  let issues = auditDataset();
  sortIssues(issues);

  let referenceStatus = 'coran.org.ar not loaded';
  let coranComparison = { corrected: [], differences: [], pendingManual: [] };

  try {
    const reference = await fetchCoranReference();
    const availableAyahs = [...reference.values()].reduce(
      (total, surah) => total + surah.translations.size,
      0,
    );
    referenceStatus = `coran.org.ar loaded (${reference.size} suras, ${availableAyahs} translated ayahs)`;
    coranComparison = compareWithCoranReference(issues, reference);

    if (coranComparison.corrected.length > 0) {
      fs.writeFileSync(inputPath, JSON.stringify(data), 'utf8');
      issues = auditDataset();
      sortIssues(issues);
    }
  } catch (error) {
    referenceStatus = `coran.org.ar unavailable: ${error.message}`;
  }

  const summary = summarizeIssues(issues);
  const markdown = buildMarkdown({
    summary,
    issues,
    coranComparison,
    referenceStatus,
  });

  fs.writeFileSync(markdownReportPath, markdown, 'utf8');
  fs.writeFileSync(
    jsonReportPath,
    JSON.stringify({ summary, issues, coranComparison, referenceStatus }, null, 2),
    'utf8',
  );

  console.log(`Total candidate issues: ${summary.total}`);
  console.log(`By severity: ${JSON.stringify(summary.bySeverity)}`);
  console.log(`By language: ${JSON.stringify(summary.byLanguage)}`);
  console.log(`Reference: ${referenceStatus}`);
  console.log(`Corrected with coran.org.ar: ${coranComparison.corrected.length}`);
  console.log(`Untouched suspicious differences: ${coranComparison.differences.length}`);
  console.log(`Manual pending: ${coranComparison.pendingManual.length}`);
  console.log(`Markdown report: ${path.relative(repoRoot, markdownReportPath)}`);
  console.log(`JSON report: ${path.relative(repoRoot, jsonReportPath)}`);
  console.log('');
  console.log('Top severe candidates:');
  for (const issue of issues.slice(0, 20)) {
    console.log(
      `[${issue.severity}] ${issue.language} ${issue.surah}:${issue.ayah} | ${issue.suspicious} | ${issue.reason}`,
    );
    console.log(`  ${issue.text}`);
    if (issue.suggestion) console.log(`  suggestion: ${issue.suggestion}`);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
