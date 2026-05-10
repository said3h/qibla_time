const fs = require('fs');
const https = require('https');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const HADITH_PATH = path.join('assets', 'data', 'hadiths_multilang_v2.json');
const REPORT_PATH = path.join('scripts', 'hadith_quality_warning_fix_report.json');
const CACHE_DIR = path.join(os.tmpdir(), 'qibla_hadeethenc_sources');
const IMPORTED_AT = new Date().toISOString();

const spanishFixes = [
  { appHadithId: 80220, nawawiRef: '40 Hadith Nawawi 20', hadeethEncId: 66523 },
  { appHadithId: 80221, nawawiRef: '40 Hadith Nawawi 21', hadeethEncId: 66524 },
  { appHadithId: 80233, nawawiRef: '40 Hadith Nawawi 33', hadeethEncId: 66532 },
  { appHadithId: 80234, nawawiRef: '40 Hadith Nawawi 34', hadeethEncId: 65001 },
  { appHadithId: 80239, nawawiRef: '40 Hadith Nawawi 39', hadeethEncId: 4216 },
  { appHadithId: 80241, nawawiRef: '40 Hadith Nawawi 41', hadeethEncId: 66535 },
];

const italianClears = [
  { appHadithId: 4820, collection: 'Sahih al-Bukhari' },
  { appHadithId: 6380, collection: 'Sahih Muslim' },
  { appHadithId: 6604, collection: 'Sahih al-Bukhari' },
  { appHadithId: 8301, collection: 'Sahih al-Bukhari' },
];

const spanishSource = {
  language: 'es',
  fileName: 'hadeethenc_es.xlsx',
  downloadUrl: 'https://hadeethenc.com/browse/download/es',
  homepage: 'https://hadeethenc.com/es',
};

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

async function ensureSpanishSource() {
  const filePath = path.join(CACHE_DIR, spanishSource.fileName);
  if (!fs.existsSync(filePath) || fs.statSync(filePath).size === 0) {
    await downloadFile(spanishSource.downloadUrl, filePath);
  }
  return filePath;
}

function parseSpanishSource(filePath) {
  const python = `
import json
import openpyxl
import re
import sys

file_path = sys.stdin.read().strip()
wb = openpyxl.load_workbook(file_path, read_only=True, data_only=True)
ws = wb.active
rows = list(ws.iter_rows(values_only=True))
meta = str(rows[0][0] or '') if rows else ''
version_match = re.search(r'\\((v[^)]+)\\)', meta)
update_match = re.search(r'Last update:\\s*([^\\n]+?)\\s*\\(', meta)
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
        'hadith_text': row[indexes['hadith_text']] or '',
        'grade': row[indexes['grade']] or '',
        'link': row[indexes['link']] or '',
    }
print(json.dumps({
    'version': version_match.group(1) if version_match else '',
    'last_update': update_match.group(1).strip() if update_match else '',
    'entries': entries,
}, ensure_ascii=False))
`;

  const parsed = spawnSync('python', ['-c', python], {
    input: filePath,
    encoding: 'utf8',
    env: { ...process.env, PYTHONIOENCODING: 'utf-8' },
    maxBuffer: 1024 * 1024 * 32,
  });

  if (parsed.status !== 0) {
    throw new Error(`Failed to parse HadeethEnc Spanish file:\n${parsed.stderr || parsed.stdout}`);
  }
  return JSON.parse(parsed.stdout);
}

function snapshotArabic(data) {
  return new Map(data.map((item) => [item.id, item.arabic]));
}

async function main() {
  const sourceFile = await ensureSpanishSource();
  const source = parseSpanishSource(sourceFile);
  const raw = fs.readFileSync(HADITH_PATH, 'utf8');
  const data = JSON.parse(raw);
  const original = JSON.parse(raw);
  const arabicBefore = snapshotArabic(data);
  const importedSpanish = [];
  const clearedItalian = [];
  const skipped = [];

  for (const fix of spanishFixes) {
    const hadith = data.find((item) => item.id === fix.appHadithId);
    const sourceEntry = source.entries[String(fix.hadeethEncId)];
    if (!hadith || !hadith.translations?.es || !sourceEntry?.hadith_text?.trim()) {
      skipped.push({ ...fix, language: 'es', reason: 'NO_CLEAR_HADEETHENC_MATCH' });
      continue;
    }

    const before = hadith.translations.es.text || hadith.translations.es.translation || '';
    hadith.translations.es.text = sourceEntry.hadith_text;
    if (typeof hadith.translations.es.translation === 'string') {
      hadith.translations.es.translation = '';
    }
    hadith.translations.es.reference = fix.nawawiRef;
    hadith.translations.es.grade = hadith.translations.es.grade || sourceEntry.grade || '';
    hadith.translations.es.source = 'HadeethEnc';
    hadith.translations.es.source_url =
      sourceEntry.link || `${spanishSource.homepage}/browse/hadith/${fix.hadeethEncId}`;
    hadith.translations.es.source_language = 'es';
    hadith.translations.es.source_id = String(fix.hadeethEncId);
    hadith.translations.es.source_version = source.version || '';
    hadith.translations.es.imported_at = IMPORTED_AT;
    delete hadith.translations.es.translation_status;
    delete hadith.translations.es.unavailable_reason;

    importedSpanish.push({
      appHadithId: fix.appHadithId,
      nawawiRef: fix.nawawiRef,
      sourceId: fix.hadeethEncId,
      sourceUrl: hadith.translations.es.source_url,
      sourceVersion: hadith.translations.es.source_version,
      beforeExcerpt: before.slice(0, 180),
      afterExcerpt: sourceEntry.hadith_text.slice(0, 180),
    });
  }

  for (const fix of italianClears) {
    const hadith = data.find((item) => item.id === fix.appHadithId);
    const payload = hadith?.translations?.it;
    if (!payload) {
      skipped.push({ ...fix, language: 'it', reason: 'ITALIAN_PAYLOAD_MISSING' });
      continue;
    }

    const before = payload.text || payload.translation || '';
    payload.text = '';
    if (typeof payload.translation === 'string') payload.translation = '';
    payload.translation_status = 'unavailable_legal_source_not_found';
    payload.unavailable_reason =
      'Italian field previously duplicated English text; no clear HadeethEnc Italian match was found.';
    delete payload.source;
    delete payload.source_url;
    delete payload.source_language;
    delete payload.source_id;
    delete payload.source_version;
    delete payload.imported_at;

    clearedItalian.push({
      appHadithId: fix.appHadithId,
      collection: fix.collection,
      beforeExcerpt: before.slice(0, 180),
      action: 'cleared_it_translation',
    });
  }

  const targetIds = new Set([
    ...spanishFixes.map((item) => item.appHadithId),
    ...italianClears.map((item) => item.appHadithId),
  ]);
  const arabicChanged = [];
  const nonTargetChanged = [];

  for (let index = 0; index < data.length; index += 1) {
    if (data[index].id !== original[index].id) {
      throw new Error(`Dataset ordering changed at index ${index}`);
    }
    if (arabicBefore.get(data[index].id) !== data[index].arabic) {
      arabicChanged.push(data[index].id);
    }
    if (!targetIds.has(data[index].id) && JSON.stringify(data[index]) !== JSON.stringify(original[index])) {
      nonTargetChanged.push(data[index].id);
    }
  }

  if (arabicChanged.length > 0) {
    throw new Error(`Arabic changed unexpectedly: ${arabicChanged.join(', ')}`);
  }
  if (nonTargetChanged.length > 0) {
    throw new Error(`Non-target hadith changed unexpectedly: ${nonTargetChanged.join(', ')}`);
  }
  if (skipped.length > 0) {
    throw new Error(`Some warning fixes were skipped: ${JSON.stringify(skipped)}`);
  }

  fs.writeFileSync(HADITH_PATH, `${JSON.stringify(data, null, 2)}\n`, 'utf8');

  const report = {
    generatedAt: IMPORTED_AT,
    importedSpanishCount: importedSpanish.length,
    clearedItalianCount: clearedItalian.length,
    skippedCount: skipped.length,
    source: {
      name: 'HadeethEnc',
      language: 'es',
      downloadUrl: spanishSource.downloadUrl,
      version: source.version || '',
      lastUpdate: source.last_update || '',
    },
    validations: {
      arabicChanged: arabicChanged.length,
      nonTargetHadithChanged: nonTargetChanged.length,
    },
    importedSpanish,
    clearedItalian,
    skipped,
  };
  fs.writeFileSync(REPORT_PATH, `${JSON.stringify(report, null, 2)}\n`, 'utf8');

  console.log(JSON.stringify({
    importedSpanishCount: report.importedSpanishCount,
    clearedItalianCount: report.clearedItalianCount,
    skippedCount: report.skippedCount,
    arabicChanged: report.validations.arabicChanged,
    nonTargetHadithChanged: report.validations.nonTargetHadithChanged,
    reportPath: REPORT_PATH,
  }, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
