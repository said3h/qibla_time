const fs = require('fs');
const path = require('path');

const inputPath = path.join('assets', 'data', 'hadiths_multilang_v2.json');
const reportPath = path.join('scripts', 'hadith_translation_cleanup_report.json');

const patterns = [
  { key: 'QUERY_LENGTH_LIMIT', regex: /QUERY\s+LENGTH\s+LIMIT/i },
  { key: 'MAX_ALLOWED_QUERY', regex: /MAX\s+ALLOWED\s+QUERY|MAXIMUM\s+ALLOWED\s+QUERY/i },
  { key: 'TOO_MANY_REQUESTS', regex: /TOO\s+MANY\s+REQUESTS|HTTP\s*429/i },
  { key: 'RATE_LIMIT', regex: /RATE\s+LIMIT|REQUEST\s+LIMIT/i },
  { key: 'TRANSLATION_FAILED', regex: /TRANSLATION\s+FAILED|FAILED\s+TO\s+TRANSLATE/i },
  { key: 'REQUEST_TOO_LARGE', regex: /REQUEST\s+ENTITY\s+TOO\s+LARGE|PAYLOAD\s+TOO\s+LARGE|500\s+CHARS/i },
  { key: 'PORTUGUESE_QUERY_LIMIT', regex: /LIMITE\s+DE\s+COMPRIMENTO|CONSULTA\s+M[ÁA]XIMA|M[ÁA]XIMA\s+PERMITIDA/i },
  { key: 'GENERIC_ERROR', regex: /^\s*ERROR\s*:?\s*$/i },
  { key: 'ERROR_PREFIX', regex: /^\s*ERROR\s*:/i },
];

const targetLanguages = new Set(['es', 'fr', 'de', 'pt']);
const targetCollectionRegex = /40\s*Hadith\s*Nawawi|Hadith\s*Nawawi\s*\d+|Hadith\s*Nawawi\d+/i;

function findReasons(text) {
  const reasons = [];
  for (const pattern of patterns) {
    if (pattern.regex.test(text)) reasons.push(pattern.key);
  }
  return [...new Set(reasons)];
}

function isTargetNawawi(payload) {
  const reference = String(payload?.reference || '');
  return targetCollectionRegex.test(reference);
}

function findCorruptTranslationFields(data) {
  const issues = [];
  for (const hadith of data) {
    const translations = hadith.translations || {};
    for (const [language, payload] of Object.entries(translations)) {
      if (!targetLanguages.has(language) || !payload || typeof payload !== 'object') continue;
      if (!isTargetNawawi(payload)) continue;
      for (const field of ['translation', 'text']) {
        const value = payload[field];
        if (typeof value !== 'string' || !value.trim()) continue;
        const reasons = findReasons(value);
        if (reasons.length === 0) continue;
        issues.push({
          hadithId: hadith.id,
          language,
          field,
          reference: payload.reference || '',
          reasons,
          before: value,
        });
      }
    }
  }
  return issues;
}

const raw = fs.readFileSync(inputPath, 'utf8');
const data = JSON.parse(raw);
const before = findCorruptTranslationFields(data);

for (const issue of before) {
  const hadith = data.find(item => item.id === issue.hadithId);
  const payload = hadith?.translations?.[issue.language];
  if (!payload || typeof payload !== 'object') continue;
  if (payload[issue.field] !== issue.before) continue;
  payload[issue.field] = '';
}

const after = findCorruptTranslationFields(data);
fs.writeFileSync(inputPath, `${JSON.stringify(data, null, 2)}\n`, 'utf8');

const report = {
  generatedAt: new Date().toISOString(),
  source: inputPath.replace(/\\/g, '/'),
  backup: 'assets/data/hadiths_multilang_v2.backup_before_translation_cleanup.json',
  corruptTranslationFieldsBefore: before.length,
  corruptTranslationFieldsAfter: after.length,
  affectedHadithsBefore: [...new Set(before.map(issue => issue.hadithId))].length,
  affectedHadithsAfter: [...new Set(after.map(issue => issue.hadithId))].length,
  cleaned: before.map(issue => ({
    hadithId: issue.hadithId,
    language: issue.language,
    field: issue.field,
    reference: issue.reference,
    reasons: issue.reasons,
  })),
  remaining: after,
};

fs.writeFileSync(reportPath, `${JSON.stringify(report, null, 2)}\n`, 'utf8');
console.log(JSON.stringify({
  corruptTranslationFieldsBefore: report.corruptTranslationFieldsBefore,
  corruptTranslationFieldsAfter: report.corruptTranslationFieldsAfter,
  affectedHadithsBefore: report.affectedHadithsBefore,
  affectedHadithsAfter: report.affectedHadithsAfter,
  reportPath,
}, null, 2));
