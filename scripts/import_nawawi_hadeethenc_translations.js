const fs = require('fs');
const https = require('https');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const HADITH_PATH = path.join('assets', 'data', 'hadiths_multilang_v2.json');
const THIRD_PARTY_PATH = path.join('assets', 'data', 'third_party_sources.json');
const REPORT_JSON_PATH = path.join('scripts', 'nawawi_hadeethenc_import_report.json');
const REPORT_MD_PATH = path.join('scripts', 'nawawi_hadeethenc_import_report.md');
const CACHE_DIR = path.join(os.tmpdir(), 'qibla_hadeethenc_sources');

const IMPORTED_AT = new Date().toISOString();

const languages = {
  es: {
    name: 'Español',
    downloadUrl: 'https://hadeethenc.com/browse/download/es',
    homepage: 'https://hadeethenc.com/es',
    fileName: 'hadeethenc_es.xlsx',
  },
  fr: {
    name: 'Français',
    downloadUrl: 'https://hadeethenc.com/browse/download/fr',
    homepage: 'https://hadeethenc.com/fr',
    fileName: 'hadeethenc_fr.xlsx',
  },
  de: {
    name: 'Deutsch',
    downloadUrl: 'https://hadeethenc.com/browse/download/de',
    homepage: 'https://hadeethenc.com/de',
    fileName: 'hadeethenc_de.xlsx',
  },
  pt: {
    name: 'Português',
    downloadUrl: 'https://hadeethenc.com/browse/download/pt',
    homepage: 'https://hadeethenc.com/pt',
    fileName: 'hadeethenc_pt.xlsx',
  },
};

const nawawiTargets = [
  { appHadithId: 80202, nawawiRef: '40 Hadith Nawawi 2', hadeethEncId: 4563 },
  { appHadithId: 80204, nawawiRef: '40 Hadith Nawawi 4', hadeethEncId: 66513 },
  { appHadithId: 80206, nawawiRef: '40 Hadith Nawawi 6', hadeethEncId: 66515 },
  { appHadithId: 80208, nawawiRef: '40 Hadith Nawawi 8', hadeethEncId: 4211 },
  { appHadithId: 80210, nawawiRef: '40 Hadith Nawawi 10', hadeethEncId: 66518 },
  { appHadithId: 80219, nawawiRef: '40 Hadith Nawawi 19', hadeethEncId: 66522 },
  { appHadithId: 80222, nawawiRef: '40 Hadith Nawawi 22', hadeethEncId: 66525 },
  { appHadithId: 80223, nawawiRef: '40 Hadith Nawawi 23', hadeethEncId: 66526 },
  { appHadithId: 80224, nawawiRef: '40 Hadith Nawawi 24', hadeethEncId: 4810 },
  { appHadithId: 80225, nawawiRef: '40 Hadith Nawawi 25', hadeethEncId: 66527 },
  { appHadithId: 80226, nawawiRef: '40 Hadith Nawawi 26', hadeethEncId: 4568 },
  { appHadithId: 80227, nawawiRef: '40 Hadith Nawawi 27', hadeethEncId: 66540 },
  { appHadithId: 80228, nawawiRef: '40 Hadith Nawawi 28', hadeethEncId: 66529 },
  { appHadithId: 80229, nawawiRef: '40 Hadith Nawawi 29', hadeethEncId: 66530 },
  { appHadithId: 80230, nawawiRef: '40 Hadith Nawawi 30', hadeethEncId: 66510 },
  { appHadithId: 80231, nawawiRef: '40 Hadith Nawawi 31', hadeethEncId: 4307 },
  { appHadithId: 80232, nawawiRef: '40 Hadith Nawawi 32', hadeethEncId: 66531 },
  { appHadithId: 80235, nawawiRef: '40 Hadith Nawawi 35', hadeethEncId: 4706 },
  { appHadithId: 80236, nawawiRef: '40 Hadith Nawawi 36', hadeethEncId: 4801 },
  { appHadithId: 80237, nawawiRef: '40 Hadith Nawawi 37', hadeethEncId: 66533 },
  { appHadithId: 80238, nawawiRef: '40 Hadith Nawawi 38', hadeethEncId: 66534 },
  { appHadithId: 80240, nawawiRef: '40 Hadith Nawawi 40', hadeethEncId: 4704 },
  { appHadithId: 80242, nawawiRef: '40 Hadith Nawawi 42', hadeethEncId: 5456 },
];

const invalidPatterns = [
  /QUERY\s+LENGTH\s+LIMIT/i,
  /MAX\s+ALLOWED\s+QUERY|MAXIMUM\s+ALLOWED\s+QUERY/i,
  /TOO\s+MANY\s+REQUESTS|HTTP\s*429/i,
  /RATE\s+LIMIT|REQUEST\s+LIMIT/i,
  /TRANSLATION\s+FAILED|FAILED\s+TO\s+TRANSLATE/i,
  /REQUEST\s+ENTITY\s+TOO\s+LARGE|PAYLOAD\s+TOO\s+LARGE|500\s+CHARS/i,
  /LIMITE\s+DE\s+COMPRIMENTO|CONSULTA\s+M[ÁA]XIMA|M[ÁA]XIMA\s+PERMITIDA/i,
  /^\s*ERROR\s*:?\s*$/i,
  /^\s*ERROR\s*:/i,
];

function isInvalidTranslationText(text) {
  if (typeof text !== 'string' || text.trim().length === 0) return false;
  return invalidPatterns.some((pattern) => pattern.test(text));
}

function isEmptyOrInvalidTranslation(payload) {
  if (!payload || typeof payload !== 'object') return true;
  const text = typeof payload.text === 'string' ? payload.text : '';
  const translation =
    typeof payload.translation === 'string' ? payload.translation : '';
  const value = text.trim() || translation.trim();
  return value.length === 0 || isInvalidTranslationText(value);
}

function downloadFile(url, destination) {
  fs.mkdirSync(path.dirname(destination), { recursive: true });
  return new Promise((resolve, reject) => {
    const request = https.get(url, (response) => {
      if (
        response.statusCode >= 300 &&
        response.statusCode < 400 &&
        response.headers.location
      ) {
        response.resume();
        downloadFile(response.headers.location, destination)
          .then(resolve)
          .catch(reject);
        return;
      }

      if (response.statusCode !== 200) {
        response.resume();
        reject(new Error(`Download failed for ${url}: HTTP ${response.statusCode}`));
        return;
      }

      const file = fs.createWriteStream(destination);
      response.pipe(file);
      file.on('finish', () => file.close(resolve));
      file.on('error', reject);
    });
    request.on('error', reject);
  });
}

async function ensureSourceFiles() {
  for (const [language, config] of Object.entries(languages)) {
    const filePath = path.join(CACHE_DIR, config.fileName);
    if (!fs.existsSync(filePath) || fs.statSync(filePath).size === 0) {
      console.log(`Downloading HadeethEnc ${language}: ${config.downloadUrl}`);
      await downloadFile(config.downloadUrl, filePath);
    }
    config.filePath = filePath;
  }
}

function parseExcelSources() {
  const python = `
import json
import openpyxl
import re
import sys

files = json.loads(sys.stdin.read())
result = {}

for lang, file_path in files.items():
    wb = openpyxl.load_workbook(file_path, read_only=True, data_only=True)
    ws = wb.active
    rows = list(ws.iter_rows(values_only=True))
    meta = str(rows[0][0] or '') if rows else ''
    version_match = re.search(r'\\((v[^)]+)\\)', meta)
    update_match = re.search(r'Last update:\\s*([^\\n]+?)\\s*\\(', meta)
    source_match = re.search(r'Source:\\s*([^\\n]+)', meta)
    header = [str(value or '') for value in rows[1]]
    indexes = {name: index for index, name in enumerate(header)}
    entries = {}
    for row in rows[2:]:
        raw_id = row[indexes['id']]
        if raw_id is None:
            continue
        source_id = str(int(raw_id)) if isinstance(raw_id, (int, float)) else str(raw_id).strip()
        entries[source_id] = {
            'id': source_id,
            'title': row[indexes['title']] or '',
            'hadith_text': row[indexes['hadith_text']] or '',
            'grade': row[indexes['grade']] or '',
            'takhrij': row[indexes['takhrij']] or '',
            'lang': row[indexes['lang']] or lang,
            'link': row[indexes['link']] or '',
        }
    result[lang] = {
        'version': version_match.group(1) if version_match else '',
        'last_update': update_match.group(1).strip() if update_match else '',
        'source': source_match.group(1).strip() if source_match else '',
        'entries': entries,
    }

print(json.dumps(result, ensure_ascii=False))
`;

  const files = Object.fromEntries(
    Object.entries(languages).map(([language, config]) => [
      language,
      config.filePath,
    ]),
  );
  const parsed = spawnSync('python', ['-c', python], {
    input: JSON.stringify(files),
    encoding: 'utf8',
    env: { ...process.env, PYTHONIOENCODING: 'utf-8' },
    maxBuffer: 1024 * 1024 * 64,
  });

  if (parsed.status !== 0) {
    throw new Error(
      `Failed to parse HadeethEnc Excel files:\n${parsed.stderr || parsed.stdout}`,
    );
  }
  return JSON.parse(parsed.stdout);
}

function countPending(data) {
  let pending = 0;
  const pendingItems = [];
  for (const target of nawawiTargets) {
    const hadith = data.find((item) => item.id === target.appHadithId);
    for (const language of Object.keys(languages)) {
      const payload = hadith?.translations?.[language];
      if (isEmptyOrInvalidTranslation(payload)) {
        pending += 1;
        pendingItems.push({
          hadithId: target.appHadithId,
          nawawiRef: target.nawawiRef,
          language,
        });
      }
    }
  }
  return { pending, pendingItems };
}

function ensureThirdPartySource(sourceMeta) {
  let sources = {};
  if (fs.existsSync(THIRD_PARTY_PATH)) {
    sources = JSON.parse(fs.readFileSync(THIRD_PARTY_PATH, 'utf8'));
  }

  sources.hadeethenc = {
    name: 'HadeethEnc',
    url: 'https://hadeethenc.com/',
    license_or_permission:
      'Republication permitted under HadeethEnc stated conditions.',
    attribution_required: true,
    modification_allowed: false,
    attribution:
      'Translated hadith content sourced from HadeethEnc.com. Texts are imported verbatim and should not be modified.',
    imported_for:
      'Offline translations for selected 40 Hadith Nawawi entries in Qibla Time.',
    languages: Object.fromEntries(
      Object.entries(languages).map(([language, config]) => [
        language,
        {
          source_language: config.name,
          homepage: config.homepage,
          download_url: config.downloadUrl,
          version: sourceMeta[language]?.version || '',
          last_update: sourceMeta[language]?.last_update || '',
        },
      ]),
    ),
    imported_at: IMPORTED_AT,
  };

  fs.writeFileSync(THIRD_PARTY_PATH, `${JSON.stringify(sources, null, 2)}\n`, 'utf8');
}

function updateAuditDocument(sourceMeta, report) {
  const auditPath = path.join('scripts', 'nawawi_translation_source_audit.md');
  if (!fs.existsSync(auditPath)) return;

  let content = fs.readFileSync(auditPath, 'utf8');
  const marker = '## Import Status';
  const section = [
    marker,
    '',
    `Imported: ${IMPORTED_AT}`,
    '',
    '- Source used: HadeethEnc only.',
    '- Import policy: verbatim text only; no editing, summarizing, correcting, or adapting.',
    '- App data file updated: `assets/data/hadiths_multilang_v2.json`.',
    '- Attribution metadata file: `assets/data/third_party_sources.json`.',
    `- Imported translations: ${report.imported.length}.`,
    `- Pending translations after import: ${report.pendingAfter}.`,
    '',
    'Imported source versions:',
    '',
    '| Language | Version | Last update |',
    '|---|---|---|',
    ...Object.keys(languages).map((language) => {
      const meta = sourceMeta[language] || {};
      return `| ${language} | ${meta.version || ''} | ${meta.last_update || ''} |`;
    }),
    '',
  ].join('\n');

  if (content.includes(marker)) {
    content = content.slice(0, content.indexOf(marker)).trimEnd();
  }
  fs.writeFileSync(auditPath, `${content}\n\n${section}`, 'utf8');
}

async function main() {
  await ensureSourceFiles();
  const sourceData = parseExcelSources();
  const originalRaw = fs.readFileSync(HADITH_PATH, 'utf8');
  const data = JSON.parse(originalRaw);
  const originalData = JSON.parse(originalRaw);
  const originalArabicById = new Map(data.map((item) => [item.id, item.arabic]));
  const before = countPending(data);
  const imported = [];
  const skipped = [];

  for (const target of nawawiTargets) {
    const hadith = data.find((item) => item.id === target.appHadithId);
    if (!hadith) {
      skipped.push({ ...target, reason: 'APP_HADITH_NOT_FOUND' });
      continue;
    }
    if (!hadith.translations || typeof hadith.translations !== 'object') {
      skipped.push({ ...target, reason: 'APP_TRANSLATIONS_MISSING' });
      continue;
    }

    for (const [language, config] of Object.entries(languages)) {
      const payload = hadith.translations[language];
      if (!isEmptyOrInvalidTranslation(payload)) {
        skipped.push({
          ...target,
          language,
          reason: 'TRANSLATION_ALREADY_VALID',
        });
        continue;
      }

      const sourceEntry =
        sourceData[language]?.entries?.[String(target.hadeethEncId)];
      if (!sourceEntry || !String(sourceEntry.hadith_text || '').trim()) {
        skipped.push({
          ...target,
          language,
          reason: 'HADEETHENC_ENTRY_NOT_FOUND',
        });
        continue;
      }

      const nextPayload =
        payload && typeof payload === 'object' ? payload : {};
      nextPayload.text = sourceEntry.hadith_text;
      if (typeof nextPayload.translation === 'string') {
        nextPayload.translation = '';
      }
      nextPayload.reference = target.nawawiRef;
      nextPayload.grade = nextPayload.grade || sourceEntry.grade || '';
      nextPayload.source = 'HadeethEnc';
      nextPayload.source_url =
        sourceEntry.link || `${config.homepage}/browse/hadith/${target.hadeethEncId}`;
      nextPayload.source_language = language;
      nextPayload.source_id = String(target.hadeethEncId);
      nextPayload.source_version = sourceData[language]?.version || '';
      nextPayload.imported_at = IMPORTED_AT;
      hadith.translations[language] = nextPayload;

      imported.push({
        appHadithId: target.appHadithId,
        nawawiRef: target.nawawiRef,
        language,
        sourceId: target.hadeethEncId,
        sourceUrl: nextPayload.source_url,
        sourceVersion: nextPayload.source_version,
      });
    }
  }

  const after = countPending(data);
  const changedNonNawawi = [];
  const changedArabic = [];
  const targetIds = new Set(nawawiTargets.map((item) => item.appHadithId));

  for (let index = 0; index < data.length; index += 1) {
    const beforeItem = originalData[index];
    const afterItem = data[index];
    if (beforeItem.id !== afterItem.id) {
      throw new Error(`Dataset ordering changed at index ${index}`);
    }
    if (originalArabicById.get(afterItem.id) !== afterItem.arabic) {
      changedArabic.push(afterItem.id);
    }
    if (!targetIds.has(afterItem.id)) {
      const beforeJson = JSON.stringify(beforeItem);
      const afterJson = JSON.stringify(afterItem);
      if (beforeJson !== afterJson) changedNonNawawi.push(afterItem.id);
    }
  }

  if (changedArabic.length > 0) {
    throw new Error(`Arabic text changed unexpectedly: ${changedArabic.join(', ')}`);
  }
  if (changedNonNawawi.length > 0) {
    throw new Error(
      `Non-Nawawi entries changed unexpectedly: ${changedNonNawawi.join(', ')}`,
    );
  }
  if (after.pending > 0) {
    throw new Error(
      `Import left ${after.pending} pending translations. See report details.`,
    );
  }

  fs.writeFileSync(HADITH_PATH, `${JSON.stringify(data, null, 2)}\n`, 'utf8');

  const report = {
    generatedAt: IMPORTED_AT,
    source: 'HadeethEnc',
    sourcePolicy: 'verbatim-import-only',
    targetHadithCount: nawawiTargets.length,
    targetLanguages: Object.keys(languages),
    pendingBefore: before.pending,
    pendingAfter: after.pending,
    importedCount: imported.length,
    skippedCount: skipped.length,
    imported,
    skipped,
    sourceVersions: Object.fromEntries(
      Object.keys(languages).map((language) => [
        language,
        {
          version: sourceData[language]?.version || '',
          last_update: sourceData[language]?.last_update || '',
          download_url: languages[language].downloadUrl,
        },
      ]),
    ),
    validations: {
      corruptTranslationsAfterImport: null,
      targetHadithsWithAllTranslationsAfterImport:
        nawawiTargets.length - new Set(after.pendingItems.map((item) => item.hadithId)).size,
      nonNawawiChanged: changedNonNawawi.length,
      arabicChanged: changedArabic.length,
    },
  };

  fs.writeFileSync(REPORT_JSON_PATH, `${JSON.stringify(report, null, 2)}\n`, 'utf8');

  const md = [];
  md.push('# Nawawi HadeethEnc Import Report');
  md.push('');
  md.push(`Generated: ${report.generatedAt}`);
  md.push('');
  md.push('## Summary');
  md.push('');
  md.push(`- Source: ${report.source}`);
  md.push('- Import policy: verbatim only; no text modifications.');
  md.push(`- Pending translations before: ${report.pendingBefore}`);
  md.push(`- Pending translations after: ${report.pendingAfter}`);
  md.push(`- Imported translations: ${report.importedCount}`);
  md.push(`- Non-Nawawi entries changed: ${report.validations.nonNawawiChanged}`);
  md.push(`- Arabic entries changed: ${report.validations.arabicChanged}`);
  md.push('');
  md.push('## Imported Translations');
  md.push('');
  md.push('| App hadith ID | Nawawi ref | Language | HadeethEnc ID | Version |');
  md.push('|---:|---|---|---:|---|');
  for (const item of imported) {
    md.push(
      `| ${item.appHadithId} | ${item.nawawiRef} | ${item.language} | ${item.sourceId} | ${item.sourceVersion} |`,
    );
  }
  md.push('');
  md.push('## Skipped');
  md.push('');
  md.push('| App hadith ID | Nawawi ref | Language | Reason |');
  md.push('|---:|---|---|---|');
  for (const item of skipped) {
    md.push(
      `| ${item.appHadithId} | ${item.nawawiRef} | ${item.language || ''} | ${item.reason} |`,
    );
  }
  fs.writeFileSync(REPORT_MD_PATH, `${md.join('\n')}\n`, 'utf8');

  ensureThirdPartySource(sourceData);
  updateAuditDocument(sourceData, report);

  console.log(JSON.stringify({
    pendingBefore: report.pendingBefore,
    pendingAfter: report.pendingAfter,
    importedCount: report.importedCount,
    skippedCount: report.skippedCount,
    reportJsonPath: REPORT_JSON_PATH,
    reportMdPath: REPORT_MD_PATH,
    thirdPartySourcesPath: THIRD_PARTY_PATH,
  }, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
