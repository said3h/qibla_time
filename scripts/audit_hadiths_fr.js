const {
  DEFAULT_INPUT_PATH,
  detectEnglishLeakage,
  detectSpanishLeakage,
  loadJson,
  validateDatasetShape,
} = require('./hadith_fr_translation_common');

const args = process.argv.slice(2);

const options = {
  inputPath: DEFAULT_INPUT_PATH,
  sampleSize: 50,
  show: 20,
  auditAll: false,
};

for (const arg of args) {
  if (arg.startsWith('--input=')) options.inputPath = arg.split('=')[1];
  if (arg.startsWith('--sample=')) {
    options.sampleSize = Number.parseInt(arg.split('=')[1], 10);
  }
  if (arg.startsWith('--show=')) {
    options.show = Number.parseInt(arg.split('=')[1], 10);
  }
  if (arg === '--all') options.auditAll = true;
}

function pickSample(entries, sampleSize) {
  if (sampleSize >= entries.length) {
    return entries;
  }

  const step = Math.max(1, Math.floor(entries.length / sampleSize));
  const selected = [];

  for (
    let index = 0;
    index < entries.length && selected.length < sampleSize;
    index += step
  ) {
    selected.push(entries[index]);
  }

  return selected;
}

function auditEntry(entry) {
  const issues = [];
  const fr = entry?.translations?.fr;

  if (!fr) {
    issues.push('missing_fr');
    return issues;
  }

  for (const field of ['text', 'title', 'category']) {
    const frValue = String(fr[field] || '').trim();
    const esValue = String(entry?.translations?.es?.[field] || '').trim();
    const enValue = String(entry?.translations?.en?.[field] || '').trim();

    if (!frValue) {
      issues.push(`${field}_empty`);
      continue;
    }

    const spanishIssues = detectSpanishLeakage(frValue, esValue);
    const englishIssues = detectEnglishLeakage(frValue, enValue);

    issues.push(...spanishIssues.map((issue) => `${field}:${issue}`));
    issues.push(...englishIssues.map((issue) => `${field}:${issue}`));

    if (frValue === esValue) {
      issues.push(`${field}:identical_to_es`);
    }
    if (frValue === enValue) {
      issues.push(`${field}:identical_to_en`);
    }
  }

  return [...new Set(issues)];
}

function main() {
  const dataset = loadJson(options.inputPath);
  validateDatasetShape(dataset);

  const targetEntries = options.auditAll
    ? dataset
    : pickSample(dataset, options.sampleSize);

  const flagged = [];

  for (const entry of targetEntries) {
    const issues = auditEntry(entry);
    if (issues.length > 0) {
      flagged.push({
        id: entry.id,
        issues,
        esTitle: entry.translations.es.title,
        enTitle: entry.translations.en.title,
        frTitle: entry.translations.fr?.title || '',
      });
    }
  }

  console.log('\n=== Hadith FR audit ===');
  console.log(`Input: ${options.inputPath}`);
  console.log(`Entries checked: ${targetEntries.length}`);
  console.log(`Flagged entries: ${flagged.length}`);

  for (const row of flagged.slice(0, options.show)) {
    console.log(
      `- ${row.id}: ${row.issues.join(', ')} | ES="${row.esTitle}" | EN="${row.enTitle}" | FR="${row.frTitle}"`,
    );
  }

  if (flagged.length > 0) {
    process.exit(1);
  }
}

main();
