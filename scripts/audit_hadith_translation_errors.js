const fs = require('fs');
const path = require('path');

const inputPath = path.join('assets', 'data', 'hadiths_multilang_v2.json');
const reportJsonPath = path.join('scripts', 'hadith_translation_error_audit_report.json');
const reportMdPath = path.join('scripts', 'hadith_translation_error_audit_report.md');

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

function readTranslationText(value) {
  if (!value || typeof value !== 'object') return '';
  for (const key of ['translation', 'text', 'content', 'body']) {
    if (typeof value[key] === 'string' && value[key].trim()) return value[key].trim();
  }
  return '';
}

function collectionFromReference(reference) {
  const ref = String(reference || '').toLowerCase();
  if (ref.includes('nawawi') || ref.includes('hadith nawawi') || ref.includes('hadis nevev') || ref.includes('навави')) return '40 Hadith Nawawi';
  if (ref.includes('bukhari') || ref.includes('bujari') || ref.includes('bukhar')) return 'Sahih al-Bukhari';
  if (ref.includes('muslim')) return 'Sahih Muslim';
  if (ref.includes('riyad') || ref.includes('salihin')) return 'Riyad as-Salihin';
  if (ref.includes('tirmidhi') || ref.includes('tirmizi') || ref.includes('tirmidhi')) return "Jami' at-Tirmidhi";
  if (ref.includes('abu dawud') || ref.includes('abu dawood') || ref.includes('abudawud')) return 'Sunan Abu Dawud';
  if (ref.includes("nasa'i") || ref.includes('nasai')) return "Sunan an-Nasa'i";
  if (ref.includes('ibn majah')) return 'Sunan Ibn Majah';
  if (ref.includes('malik') || ref.includes('muwatta')) return 'Muwatta Malik';
  return reference ? 'Other / inferred from reference' : 'Unknown';
}

function findReasons(text) {
  const reasons = [];
  for (const pattern of patterns) {
    if (pattern.regex.test(text)) reasons.push(pattern.key);
  }
  return [...new Set(reasons)];
}

const data = JSON.parse(fs.readFileSync(inputPath, 'utf8'));
const issues = [];

for (const hadith of data) {
  const translations = hadith.translations || {};
  for (const [language, payload] of Object.entries(translations)) {
    const text = readTranslationText(payload);
    if (!text) continue;
    const reasons = findReasons(text);
    if (reasons.length === 0) continue;
    const reference = payload.reference || '';
    issues.push({
      hadithId: hadith.id,
      language,
      collection: collectionFromReference(reference),
      reference,
      reasons,
      text,
    });
  }
}

function countBy(key) {
  const result = {};
  for (const issue of issues) {
    const value = issue[key] || 'Unknown';
    result[value] = (result[value] || 0) + 1;
  }
  return Object.fromEntries(Object.entries(result).sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0])));
}

const byReason = {};
for (const issue of issues) {
  for (const reason of issue.reasons) byReason[reason] = (byReason[reason] || 0) + 1;
}
const byCollection = countBy('collection');
const byLanguage = countBy('language');
const affectedHadithIds = [...new Set(issues.map(i => i.hadithId))].sort((a, b) => a - b);

const report = {
  generatedAt: new Date().toISOString(),
  source: inputPath.replace(/\\/g, '/'),
  totalHadiths: data.length,
  corruptTranslations: issues.length,
  affectedHadithCount: affectedHadithIds.length,
  affectedHadithIds,
  byCollection,
  byLanguage,
  byReason: Object.fromEntries(Object.entries(byReason).sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]))),
  issues,
};

fs.mkdirSync('scripts', { recursive: true });
fs.writeFileSync(reportJsonPath, JSON.stringify(report, null, 2), 'utf8');

const lines = [];
lines.push('# Hadith Translation Technical Error Audit');
lines.push('');
lines.push(`Generated: ${report.generatedAt}`);
lines.push(`Source: \`${report.source}\``);
lines.push('');
lines.push('## Summary');
lines.push('');
lines.push(`- Total hadith entries scanned: ${report.totalHadiths}`);
lines.push(`- Corrupt translations found: ${report.corruptTranslations}`);
lines.push(`- Affected hadith IDs: ${report.affectedHadithCount}`);
lines.push('');
lines.push('## By Collection');
lines.push('');
lines.push('| Collection | Count |');
lines.push('|---|---:|');
for (const [collection, count] of Object.entries(byCollection)) lines.push(`| ${collection} | ${count} |`);
lines.push('');
lines.push('## By Language');
lines.push('');
lines.push('| Language | Count |');
lines.push('|---|---:|');
for (const [language, count] of Object.entries(byLanguage)) lines.push(`| ${language} | ${count} |`);
lines.push('');
lines.push('## By Error Pattern');
lines.push('');
lines.push('| Pattern | Count |');
lines.push('|---|---:|');
for (const [reason, count] of Object.entries(report.byReason)) lines.push(`| ${reason} | ${count} |`);
lines.push('');
lines.push('## Issues');
lines.push('');
lines.push('| Hadith ID | Language | Collection | Reference | Reasons | Text |');
lines.push('|---:|---|---|---|---|---|');
for (const issue of issues) {
  const text = issue.text.replace(/\s+/g, ' ').replace(/\|/g, '\\|');
  const ref = String(issue.reference || '').replace(/\|/g, '\\|');
  lines.push(`| ${issue.hadithId} | ${issue.language} | ${issue.collection} | ${ref} | ${issue.reasons.join(', ')} | ${text} |`);
}
fs.writeFileSync(reportMdPath, lines.join('\n'), 'utf8');

console.log(JSON.stringify({
  corruptTranslations: report.corruptTranslations,
  affectedHadithCount: report.affectedHadithCount,
  byCollection,
  byLanguage,
  byReason: report.byReason,
  reportJsonPath,
  reportMdPath,
}, null, 2));
