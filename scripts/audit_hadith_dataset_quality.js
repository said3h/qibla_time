const fs = require('fs');
const path = require('path');

const inputPath = path.join('assets', 'data', 'hadiths_multilang_v2.json');
const reportJsonPath = path.join('scripts', 'hadith_dataset_quality_report.json');
const reportMdPath = path.join('scripts', 'hadith_dataset_quality_report.md');

const technicalErrorPatterns = [
  { key: 'QUERY_LENGTH_LIMIT', regex: /QUERY\s+LENGTH\s+LIMIT/i },
  { key: 'MAX_ALLOWED_QUERY', regex: /MAX\s+ALLOWED\s+QUERY|MAXIMUM\s+ALLOWED\s+QUERY/i },
  { key: 'TOO_MANY_REQUESTS', regex: /TOO\s+MANY\s+REQUESTS|HTTP\s*429/i },
  { key: 'RATE_LIMIT', regex: /RATE\s+LIMIT|REQUEST\s+LIMIT/i },
  { key: 'TRANSLATION_FAILED', regex: /TRANSLATION\s+FAILED|FAILED\s+TO\s+TRANSLATE/i },
  { key: 'REQUEST_TOO_LARGE', regex: /REQUEST\s+TOO\s+LARGE|REQUEST\s+ENTITY\s+TOO\s+LARGE|PAYLOAD\s+TOO\s+LARGE|500\s+CHARS/i },
  { key: 'FORBIDDEN', regex: /(HTTP\s*403|403\s+FORBIDDEN|ERROR\s*:?\s*FORBIDDEN|ACCESS\s+FORBIDDEN)/i },
  { key: 'UNAUTHORIZED', regex: /(HTTP\s*401|401\s+UNAUTHORIZED|ERROR\s*:?\s*UNAUTHORIZED|ACCESS\s+UNAUTHORIZED)/i },
  { key: 'QUOTA', regex: /(QUOTA\s+EXCEEDED|ERROR\s*:?\s*QUOTA|API\s+QUOTA|TRANSLATION\s+QUOTA)/i },
  { key: 'TIMEOUT', regex: /(REQUEST\s+TIMEOUT|TRANSLATION\s+TIMEOUT|ERROR\s*:?\s*TIMEOUT|TIMED\s+OUT|ETIMEDOUT)/i },
  { key: 'EXCEPTION', regex: /(UnhandledPromiseRejection|Traceback|ERROR\s*:?\s*EXCEPTION|TRANSLATION\s+EXCEPTION|Exception:\s)/i },
  { key: 'STACK_TRACE', regex: /(Stack trace:|\bat\s+Object\.|\bat\s+[A-Za-z0-9_.<>]+\s*\([^)]*:\d+:\d+\))/i },
  { key: 'ERROR_VALUE', regex: /^\s*ERROR\s*:?\s*$/i },
  { key: 'ERROR_PREFIX', regex: /^\s*ERROR\s*:/i },
  { key: 'UNDEFINED_LITERAL', regex: /^\s*undefined\s*$/i },
  { key: 'NULL_LITERAL', regex: /^\s*null\s*$/i },
  { key: 'NAN_LITERAL', regex: /^\s*NaN\s*$/i },
];

const htmlGarbagePatterns = [
  { key: 'HTML_TAG', regex: /<\s*html[\s>]|<\s*body[\s>]|<!DOCTYPE/i },
  { key: 'SCRIPT_TAG', regex: /<\s*script[\s>]/i },
  { key: 'TRACEBACK', regex: /\bTraceback\s+\(most recent call last\)/i },
  { key: 'JS_STACK', regex: /\bat\s+Object\.|\bat\s+[A-Za-z0-9_$]+\.[A-Za-z0-9_$]+\s*\([^)]*:\d+:\d+\)/i },
  { key: 'SYNTAX_ERROR', regex: /\bSyntaxError\b/i },
  { key: 'TYPE_ERROR', regex: /\bTypeError\b/i },
];

const targetLanguages = ['ar', 'es', 'en', 'fr', 'de', 'nl', 'id', 'ru', 'it', 'pt', 'tr'];
const languageHeuristics = {
  es: {
    expected: [' el ', ' la ', ' los ', ' las ', ' que ', ' de ', ' al ', ' con ', ' para ', ' por ', ' dijo '],
    english: [' the ', ' and ', ' messenger ', ' said ', ' who ', ' with ', ' from ', ' that '],
    french: [' le ', ' la ', ' les ', ' que ', ' des ', ' avec ', ' messager ', ' dit '],
    arabic: /[\u0600-\u06FF]/,
  },
  fr: {
    expected: [' le ', ' la ', ' les ', ' des ', ' que ', ' avec ', ' messager ', ' dit ', ' allah '],
    english: [' the ', ' and ', ' messenger ', ' said ', ' who ', ' with ', ' from ', ' that '],
    spanish: [' el ', ' los ', ' las ', ' mensajero ', ' dijo ', ' que al-lah '],
    arabic: /[\u0600-\u06FF]/,
  },
  de: {
    expected: [' der ', ' die ', ' das ', ' und ', ' sagte ', ' gesandte ', ' allahs ', ' von '],
    english: [' the ', ' and ', ' messenger ', ' said ', ' who ', ' with ', ' from ', ' that '],
    spanish: [' el ', ' los ', ' las ', ' mensajero ', ' dijo ', ' que al-lah '],
    arabic: /[\u0600-\u06FF]/,
  },
  pt: {
    expected: [' que ', ' de ', ' do ', ' da ', ' os ', ' as ', ' mensageiro ', ' disse ', ' allah '],
    english: [' the ', ' and ', ' messenger ', ' said ', ' who ', ' with ', ' from ', ' that '],
    spanish: [' el ', ' los ', ' las ', ' mensajero ', ' dijo ', ' al-lah esté '],
    arabic: /[\u0600-\u06FF]/,
  },
};

function readText(payload) {
  if (!payload || typeof payload !== 'object') return '';
  for (const key of ['text', 'translation', 'content', 'body']) {
    if (typeof payload[key] === 'string' && payload[key].trim()) {
      return payload[key].trim();
    }
  }
  return '';
}

function isIntentionallyUnavailable(payload) {
  if (!payload || typeof payload !== 'object') return false;
  return payload.translation_status === 'unavailable_legal_source_not_found';
}

function bestReference(hadith) {
  const translations = hadith.translations || {};
  for (const language of ['es', 'en', 'fr', 'de', 'pt', 'ar']) {
    const ref = translations[language]?.reference;
    if (typeof ref === 'string' && ref.trim()) return ref.trim();
  }
  for (const payload of Object.values(translations)) {
    if (payload && typeof payload === 'object') {
      const ref = payload.reference;
      if (typeof ref === 'string' && ref.trim()) return ref.trim();
    }
  }
  return '';
}

function collectionFromReference(reference) {
  const ref = String(reference || '').toLowerCase();
  if (ref.includes('nawawi') || ref.includes('40 hadith') || ref.includes('hadis nevev') || ref.includes('навави')) return '40 Hadith Nawawi';
  if (ref.includes('bujari') || ref.includes('bukhari') || ref.includes('bukhar') || ref.includes('boukhari')) return 'Sahih al-Bukhari';
  if (ref.includes('muslim') || ref.includes('mouslim')) return 'Sahih Muslim';
  if (ref.includes('riyad') || ref.includes('salihin')) return 'Riyad as-Salihin';
  if (ref.includes('tirmidhi') || ref.includes('tirmizi') || ref.includes('termed')) return "Jami' at-Tirmidhi";
  if (ref.includes('abu dawud') || ref.includes('abu daoud') || ref.includes('abu dawood') || ref.includes('abudawud')) return 'Sunan Abu Dawud';
  if (ref.includes("nasa'i") || ref.includes('nasai') || ref.includes('nasaai')) return "Sunan an-Nasa'i";
  if (ref.includes('ibn majah') || ref.includes('ibnmajah') || ref.includes('ibn mayah')) return 'Sunan Ibn Majah';
  if (ref.includes('malik') || ref.includes('muwatta')) return 'Muwatta Malik';
  return 'Other / Unclassified';
}

function normalizeForDuplicate(text) {
  return String(text || '')
    .trim()
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .replace(/[“”"'.،,;:!?()[\]{}]/g, '');
}

function normalizeWords(text) {
  return ` ${String(text || '').toLowerCase().replace(/\s+/g, ' ')} `;
}

function countHits(text, words) {
  return words.reduce((count, word) => count + (text.includes(word) ? 1 : 0), 0);
}

function detectWrongLanguage(language, text) {
  const heuristic = languageHeuristics[language];
  if (!heuristic || text.length < 80) return null;

  if (heuristic.arabic.test(text)) {
    const arabicChars = [...text].filter((char) => /[\u0600-\u06FF]/.test(char)).length;
    if (arabicChars > Math.max(20, text.length * 0.25)) {
      return 'TEXT_LOOKS_ARABIC';
    }
  }

  const normalized = normalizeWords(text);
  const expected = countHits(normalized, heuristic.expected);
  const foreignHits = [];
  for (const [name, words] of Object.entries(heuristic)) {
    if (name === 'expected' || name === 'arabic') continue;
    const hits = countHits(normalized, words);
    if (hits >= 4 && hits > expected + 2) {
      foreignHits.push(`${name.toUpperCase()}_LIKELY`);
    }
  }
  return foreignHits.length ? foreignHits.join(',') : null;
}

function addIssue(issues, severity, issue) {
  issues.push({ severity, ...issue });
}

function shortText(text) {
  return String(text || '').replace(/\s+/g, ' ').slice(0, 260);
}

function incrementMetric(map, key, language, field) {
  map[key] ??= {};
  map[key][language] ??= {
    total: 0,
    translated: 0,
    empty: 0,
    issues: 0,
    critical: 0,
    medium: 0,
    warning: 0,
  };
  map[key][language][field] += 1;
}

const data = JSON.parse(fs.readFileSync(inputPath, 'utf8'));
const issues = [];
const collectionStats = {};
const languageStats = {};
const collectionById = new Map();

for (const hadith of data) {
  const collection = collectionFromReference(bestReference(hadith));
  collectionById.set(hadith.id, collection);
  collectionStats[collection] ??= { totalHadiths: 0, languages: {} };
  collectionStats[collection].totalHadiths += 1;
}

for (const hadith of data) {
  const translations = hadith.translations || {};
  const collection = collectionById.get(hadith.id) || 'Other / Unclassified';
  const arabic = typeof hadith.arabic === 'string' ? hadith.arabic.trim() : '';
  const nonEmptyLanguages = Object.entries(translations)
    .filter(([language, payload]) => language !== 'ar' && readText(payload).length > 0)
    .map(([language]) => language);

  const duplicateMap = new Map();

  for (const language of targetLanguages) {
    const payload = translations[language];
    const declared = Object.prototype.hasOwnProperty.call(translations, language);
    const text = readText(payload);
    const isEmpty = text.length === 0;

    languageStats[language] ??= {
      totalDeclared: 0,
      translated: 0,
      empty: 0,
      issues: 0,
      critical: 0,
      medium: 0,
      warning: 0,
    };
    collectionStats[collection].languages[language] ??= {
      translated: 0,
      empty: 0,
      issues: 0,
      critical: 0,
      medium: 0,
      warning: 0,
    };

    if (!declared) continue;
    languageStats[language].totalDeclared += 1;

    if (isEmpty) {
      languageStats[language].empty += 1;
      collectionStats[collection].languages[language].empty += 1;
      if (
        nonEmptyLanguages.length > 0 &&
        language !== 'ar' &&
        !isIntentionallyUnavailable(payload)
      ) {
        addIssue(issues, 'medium', {
          reason: 'DECLARED_LANGUAGE_EMPTY',
          collection,
          hadithId: hadith.id,
          language,
          field: 'text/translation',
          detail: `Language declared but empty while other languages have content: ${nonEmptyLanguages.join(', ')}`,
          sample: '',
        });
      }
      continue;
    }

    languageStats[language].translated += 1;
    collectionStats[collection].languages[language].translated += 1;

    for (const pattern of technicalErrorPatterns) {
      if (pattern.regex.test(text)) {
        addIssue(issues, 'critical', {
          reason: pattern.key,
          collection,
          hadithId: hadith.id,
          language,
          field: 'text/translation',
          detail: 'Technical error text found inside translation content.',
          sample: shortText(text),
        });
      }
    }

    for (const pattern of htmlGarbagePatterns) {
      if (pattern.regex.test(text)) {
        addIssue(issues, 'critical', {
          reason: pattern.key,
          collection,
          hadithId: hadith.id,
          language,
          field: 'text/translation',
          detail: 'HTML, traceback, or code error content found inside translation content.',
          sample: shortText(text),
        });
      }
    }

    if (language !== 'ar') {
      const normalizedArabic = normalizeForDuplicate(arabic);
      const normalizedText = normalizeForDuplicate(text);
      if (normalizedArabic && normalizedText && normalizedArabic === normalizedText) {
        addIssue(issues, 'critical', {
          reason: 'TRANSLATION_EQUALS_ARABIC',
          collection,
          hadithId: hadith.id,
          language,
          field: 'text/translation',
          detail: 'Non-Arabic translation is identical to the Arabic source text.',
          sample: shortText(text),
        });
      }

      if (arabic.length > 450 && text.length < 60) {
        addIssue(issues, 'medium', {
          reason: 'TRANSLATION_TOO_SHORT_FOR_LONG_HADITH',
          collection,
          hadithId: hadith.id,
          language,
          field: 'text/translation',
          detail: `Arabic length ${arabic.length}; translation length ${text.length}.`,
          sample: shortText(text),
        });
      }

      const languageMismatch = detectWrongLanguage(language, text);
      if (languageMismatch) {
        addIssue(issues, 'warning', {
          reason: languageMismatch,
          collection,
          hadithId: hadith.id,
          language,
          field: 'text/translation',
          detail: 'Heuristic language check suggests the content may be in another language.',
          sample: shortText(text),
        });
      }

      if (normalizedText.length > 50) {
        const existing = duplicateMap.get(normalizedText) || [];
        existing.push(language);
        duplicateMap.set(normalizedText, existing);
      }
    }
  }

  for (const [normalized, languages] of duplicateMap.entries()) {
    if (languages.length > 1) {
      addIssue(issues, 'warning', {
        reason: 'DUPLICATE_TRANSLATION_ACROSS_LANGUAGES',
        collection,
        hadithId: hadith.id,
        language: languages.join(','),
        field: 'text/translation',
        detail: `Same normalized translation appears in multiple languages: ${languages.join(', ')}`,
        sample: shortText(normalized),
      });
    }
  }
}

for (const issue of issues) {
  const collection = issue.collection || 'Other / Unclassified';
  const language = issue.language || 'unknown';
  const languageKeys = language.includes(',') ? language.split(',') : [language];
  for (const key of languageKeys) {
    const lang = key.trim();
    languageStats[lang] ??= {
      totalDeclared: 0,
      translated: 0,
      empty: 0,
      issues: 0,
      critical: 0,
      medium: 0,
      warning: 0,
    };
    collectionStats[collection].languages[lang] ??= {
      translated: 0,
      empty: 0,
      issues: 0,
      critical: 0,
      medium: 0,
      warning: 0,
    };
    languageStats[lang].issues += 1;
    languageStats[lang][issue.severity] += 1;
    collectionStats[collection].languages[lang].issues += 1;
    collectionStats[collection].languages[lang][issue.severity] += 1;
  }
}

const severityCounts = issues.reduce(
  (acc, issue) => {
    acc[issue.severity] += 1;
    return acc;
  },
  { critical: 0, medium: 0, warning: 0 },
);

const byReason = {};
for (const issue of issues) {
  byReason[issue.reason] = (byReason[issue.reason] || 0) + 1;
}

const sortedIssues = {
  critical: issues.filter((issue) => issue.severity === 'critical'),
  medium: issues.filter((issue) => issue.severity === 'medium'),
  warning: issues.filter((issue) => issue.severity === 'warning'),
};

const status = severityCounts.critical > 0 ? 'FAIL' : 'PASS';

const report = {
  generatedAt: new Date().toISOString(),
  source: inputPath.replace(/\\/g, '/'),
  status,
  totalHadiths: data.length,
  totalIssues: issues.length,
  severityCounts,
  byReason: Object.fromEntries(Object.entries(byReason).sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]))),
  byLanguage: Object.fromEntries(Object.entries(languageStats).sort((a, b) => a[0].localeCompare(b[0]))),
  byCollection: Object.fromEntries(Object.entries(collectionStats).sort((a, b) => a[0].localeCompare(b[0]))),
  issues,
};

fs.writeFileSync(reportJsonPath, `${JSON.stringify(report, null, 2)}\n`, 'utf8');

function mdEscape(value) {
  return String(value ?? '').replace(/\|/g, '\\|').replace(/\n/g, '<br>');
}

function issueTable(items, limit = 80) {
  const lines = [];
  lines.push('| Collection | Hadith ID | Language | Field | Reason | Detail | Sample |');
  lines.push('|---|---:|---|---|---|---|---|');
  for (const issue of items.slice(0, limit)) {
    lines.push(
      `| ${mdEscape(issue.collection)} | ${issue.hadithId} | ${mdEscape(issue.language)} | ${mdEscape(issue.field)} | ${mdEscape(issue.reason)} | ${mdEscape(issue.detail)} | ${mdEscape(issue.sample)} |`,
    );
  }
  if (items.length > limit) {
    lines.push(`| ... | ... | ... | ... | ... | ${items.length - limit} more in JSON report | ... |`);
  }
  return lines;
}

const md = [];
md.push('# Hadith Dataset Quality Audit');
md.push('');
md.push(`Generated: ${report.generatedAt}`);
md.push(`Source: \`${report.source}\``);
md.push('');
md.push('## Summary');
md.push('');
md.push(`- Status: **${status}**`);
md.push(`- Total hadith entries scanned: ${report.totalHadiths}`);
md.push(`- Total issues: ${report.totalIssues}`);
md.push(`- Critical: ${severityCounts.critical}`);
md.push(`- Medium: ${severityCounts.medium}`);
md.push(`- Warnings: ${severityCounts.warning}`);
md.push('');
md.push('## By Collection');
md.push('');
md.push('| Collection | Hadith count | Translated by language | Empty by language | Issues | Critical | Medium | Warnings |');
md.push('|---|---:|---|---|---:|---:|---:|---:|');
for (const [collection, stats] of Object.entries(report.byCollection)) {
  const translated = Object.entries(stats.languages)
    .filter(([, value]) => value.translated > 0)
    .map(([language, value]) => `${language}:${value.translated}`)
    .join(', ');
  const empty = Object.entries(stats.languages)
    .filter(([, value]) => value.empty > 0)
    .map(([language, value]) => `${language}:${value.empty}`)
    .join(', ');
  const issueTotal = Object.values(stats.languages).reduce((sum, value) => sum + value.issues, 0);
  const critical = Object.values(stats.languages).reduce((sum, value) => sum + value.critical, 0);
  const medium = Object.values(stats.languages).reduce((sum, value) => sum + value.medium, 0);
  const warning = Object.values(stats.languages).reduce((sum, value) => sum + value.warning, 0);
  md.push(`| ${mdEscape(collection)} | ${stats.totalHadiths} | ${mdEscape(translated)} | ${mdEscape(empty)} | ${issueTotal} | ${critical} | ${medium} | ${warning} |`);
}
md.push('');
md.push('## By Language');
md.push('');
md.push('| Language | Declared | Translated | Empty | Issues | Critical | Medium | Warnings |');
md.push('|---|---:|---:|---:|---:|---:|---:|---:|');
for (const [language, stats] of Object.entries(report.byLanguage)) {
  md.push(`| ${language} | ${stats.totalDeclared} | ${stats.translated} | ${stats.empty} | ${stats.issues} | ${stats.critical} | ${stats.medium} | ${stats.warning} |`);
}
md.push('');
md.push('## By Reason');
md.push('');
md.push('| Reason | Count |');
md.push('|---|---:|');
for (const [reason, count] of Object.entries(report.byReason)) {
  md.push(`| ${reason} | ${count} |`);
}
md.push('');
md.push('## Critical Issues');
md.push('');
md.push(...issueTable(sortedIssues.critical));
md.push('');
md.push('## Medium Issues');
md.push('');
md.push(...issueTable(sortedIssues.medium));
md.push('');
md.push('## Warnings');
md.push('');
md.push(...issueTable(sortedIssues.warning));

fs.writeFileSync(reportMdPath, `${md.join('\n')}\n`, 'utf8');

console.log(JSON.stringify({
  status,
  totalHadiths: report.totalHadiths,
  totalIssues: report.totalIssues,
  severityCounts,
  reportJsonPath,
  reportMdPath,
}, null, 2));

if (status === 'FAIL') {
  process.exitCode = 1;
}
