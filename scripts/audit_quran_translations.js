const fs = require('fs');
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

const severityRank = { critical: 0, high: 1, pending: 2, medium: 3, low: 4 };
issues.sort((a, b) => {
  const severity = severityRank[a.severity] - severityRank[b.severity];
  if (severity !== 0) return severity;
  if (a.language !== b.language) return a.language.localeCompare(b.language);
  if (a.surah !== b.surah) return a.surah - b.surah;
  return a.ayah - b.ayah;
});

const summary = issues.reduce(
  (acc, issue) => {
    acc.total += 1;
    acc.bySeverity[issue.severity] = (acc.bySeverity[issue.severity] || 0) + 1;
    acc.byLanguage[issue.language] = (acc.byLanguage[issue.language] || 0) + 1;
    return acc;
  },
  { total: 0, bySeverity: {}, byLanguage: {} },
);

const markdown = [
  '# Quran Translation Audit Report',
  '',
  `Input: \`${path.relative(repoRoot, inputPath).replace(/\\/g, '/')}\``,
  `Generated: ${new Date().toISOString()}`,
  '',
  '## Summary',
  '',
  `- Total candidate issues: ${summary.total}`,
  `- By severity: ${JSON.stringify(summary.bySeverity)}`,
  `- By language: ${JSON.stringify(summary.byLanguage)}`,
  '',
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

fs.writeFileSync(markdownReportPath, markdown, 'utf8');
fs.writeFileSync(
  jsonReportPath,
  JSON.stringify({ summary, issues }, null, 2),
  'utf8',
);

console.log(`Total candidate issues: ${summary.total}`);
console.log(`By severity: ${JSON.stringify(summary.bySeverity)}`);
console.log(`By language: ${JSON.stringify(summary.byLanguage)}`);
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
