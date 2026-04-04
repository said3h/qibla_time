const fs = require('fs');
const path = require('path');

const DEFAULT_INPUT_PATH = 'assets/data/hadiths_multilang_v2.json';
const DEFAULT_STATE_PATH = 'scripts/.state/hadiths_fr_translation_state.json';
const DEFAULT_BACKUP_DIR = 'scripts/backups';

const REQUIRED_FR_FIELDS = ['text', 'title', 'category'];

const SPANISH_LEAK_PATTERNS = [
  /\bregistrado por\b/i,
  /\bse narro\b/i,
  /\bdijo\b/i,
  /\bque al lah este complacido\b/i,
  /\bla paz y las bendiciones de al lah sean con el\b/i,
  /\bel mensajero de al lah\b/i,
  /\bcuando llegue ramadan\b/i,
  /\bhizo la peregrinacion\b/i,
  /\bablucion\b/i,
  /\bmezquita\b/i,
  /\borina\b/i,
  /\bviertan\b/i,
  /\bdejenlo\b/i,
  /\bhumeda con el recuerdo de al lah\b/i,
];

const ENGLISH_LEAK_PATTERNS = [
  /\bnarrated by\b/i,
  /\breported by\b/i,
  /\bmay allah be pleased with (him|her|them)\b/i,
  /\bmay allahs peace and blessings be upon him\b/i,
  /\bthe messenger of allah\b/i,
  /\bthe prophet\b/i,
  /\bperformed hajj\b/i,
  /\bkeep your tongue moist\b/i,
  /\bone day i\b/i,
  /\bwhile facing\b/i,
];

function resolveProjectPath(relativePath) {
  return path.resolve(process.cwd(), relativePath);
}

function ensureDir(dirPath) {
  fs.mkdirSync(resolveProjectPath(dirPath), { recursive: true });
}

function loadJson(relativePath) {
  const absolutePath = resolveProjectPath(relativePath);
  return JSON.parse(fs.readFileSync(absolutePath, 'utf8'));
}

function saveJsonAtomic(relativePath, data) {
  const absolutePath = resolveProjectPath(relativePath);
  const tempPath = `${absolutePath}.tmp`;
  fs.writeFileSync(tempPath, `${JSON.stringify(data, null, 2)}\n`, 'utf8');
  fs.renameSync(tempPath, absolutePath);
}

function timestampForFilename() {
  return new Date().toISOString().replace(/[:.]/g, '-');
}

function createBackup(relativePath, backupDir = DEFAULT_BACKUP_DIR) {
  ensureDir(backupDir);
  const absolutePath = resolveProjectPath(relativePath);
  const baseName = path.basename(relativePath, '.json');
  const backupName = `${baseName}_fr_translation_${timestampForFilename()}.json`;
  const backupRelativePath = path.posix.join(
    backupDir.replace(/\\/g, '/'),
    backupName,
  );
  fs.copyFileSync(absolutePath, resolveProjectPath(backupRelativePath));
  return backupRelativePath;
}

function normalizeForComparison(value) {
  return String(value || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/['"()]/g, ' ')
    .replace(/[^a-z0-9\s]/gi, ' ')
    .replace(/\s+/g, ' ')
    .trim()
    .toLowerCase();
}

function countMatches(value, patterns) {
  return patterns.reduce((count, pattern) => {
    return count + (pattern.test(value) ? 1 : 0);
  }, 0);
}

function detectSpanishLeakage(value, spanishSource = '') {
  const rawText = String(value || '').trim();
  if (!rawText) {
    return ['empty'];
  }

  const normalizedCandidate = normalizeForComparison(rawText);
  const normalizedSpanish = normalizeForComparison(spanishSource);
  const issues = [];

  if (normalizedCandidate && normalizedCandidate === normalizedSpanish) {
    issues.push('identical_to_spanish');
  }

  if (countMatches(normalizedCandidate, SPANISH_LEAK_PATTERNS) > 0) {
    issues.push('spanish_phrase_detected');
  }

  if (/[\u00BF\u00A1]/.test(rawText)) {
    issues.push('spanish_punctuation_detected');
  }

  return issues;
}

function detectEnglishLeakage(value, englishSource = '') {
  const rawText = String(value || '').trim();
  if (!rawText) {
    return ['empty'];
  }

  const normalizedCandidate = normalizeForComparison(rawText);
  const normalizedEnglish = normalizeForComparison(englishSource);
  const issues = [];

  if (normalizedCandidate && normalizedCandidate === normalizedEnglish) {
    issues.push('identical_to_english');
  }

  if (countMatches(normalizedCandidate, ENGLISH_LEAK_PATTERNS) > 0) {
    issues.push('english_phrase_detected');
  }

  return issues;
}

function looksCitationStyle(reference) {
  const value = String(reference || '').trim();
  if (!value) {
    return false;
  }

  return (
    /^\[.*\]$/.test(value) ||
    /narrated by/i.test(value) ||
    /reported by/i.test(value) ||
    /[\u0600-\u06FF]/.test(value)
  );
}

function chooseReference(entry) {
  const enReference = entry?.translations?.en?.reference || '';
  const esReference = entry?.translations?.es?.reference || '';
  const arReference = entry?.translations?.ar?.reference || '';

  if (looksCitationStyle(enReference)) {
    return enReference;
  }
  if (looksCitationStyle(esReference)) {
    return esReference;
  }
  if (looksCitationStyle(arReference)) {
    return arReference;
  }

  return enReference || esReference || arReference || '';
}

function chooseGrade(entry) {
  return (
    entry?.translations?.en?.grade ||
    entry?.translations?.es?.grade ||
    entry?.translations?.ar?.grade ||
    ''
  );
}

function buildFrenchTranslationObject(entry, translatedFields) {
  return {
    text: translatedFields.text,
    reference: chooseReference(entry),
    grade: chooseGrade(entry),
    title: translatedFields.title,
    category: translatedFields.category,
  };
}

function validateDatasetShape(dataset) {
  if (!Array.isArray(dataset)) {
    throw new Error('The hadith dataset must be a JSON array.');
  }

  let previousId = -Infinity;
  const seenIds = new Set();

  dataset.forEach((entry, index) => {
    if (typeof entry?.id !== 'number') {
      throw new Error(`Entry at index ${index} is missing a numeric id.`);
    }

    if (seenIds.has(entry.id)) {
      throw new Error(`Duplicate hadith id detected: ${entry.id}`);
    }
    seenIds.add(entry.id);

    if (entry.id < previousId) {
      throw new Error('Dataset ordering changed unexpectedly.');
    }
    previousId = entry.id;

    if (!entry.translations || typeof entry.translations !== 'object') {
      throw new Error(`Hadith ${entry.id} is missing translations.`);
    }

    for (const lang of ['es', 'en', 'ar']) {
      if (!entry.translations[lang]) {
        throw new Error(`Hadith ${entry.id} is missing translations.${lang}.`);
      }
    }
  });
}

function validateFrenchFields(entry, translatedFields) {
  const issues = [];

  for (const field of REQUIRED_FR_FIELDS) {
    const value = String(translatedFields?.[field] || '').trim();
    if (!value) {
      issues.push(`${field}_empty`);
      continue;
    }

    const spanishSource =
      entry?.translations?.es?.[field === 'text' ? 'text' : field] || '';
    const englishSource =
      entry?.translations?.en?.[field === 'text' ? 'text' : field] || '';

    const spanishIssues = detectSpanishLeakage(value, spanishSource);
    const englishIssues = detectEnglishLeakage(value, englishSource);

    issues.push(...spanishIssues.map((issue) => `${field}:${issue}`));
    issues.push(...englishIssues.map((issue) => `${field}:${issue}`));
  }

  return [...new Set(issues)];
}

function hasValidFrenchTranslation(entry) {
  const fr = entry?.translations?.fr;
  if (!fr || typeof fr !== 'object') {
    return false;
  }

  if (String(fr.text || '').trim() === '') {
    return false;
  }

  return validateFrenchFields(entry, fr).length === 0;
}

function loadState(relativePath = DEFAULT_STATE_PATH) {
  const absolutePath = resolveProjectPath(relativePath);
  if (!fs.existsSync(absolutePath)) {
    return null;
  }
  return JSON.parse(fs.readFileSync(absolutePath, 'utf8'));
}

function saveState(relativePath = DEFAULT_STATE_PATH, state) {
  ensureDir(path.dirname(relativePath));
  saveJsonAtomic(relativePath, state);
}

function createEmptyState(options) {
  return {
    version: 1,
    datasetPath: options.inputPath,
    model: options.model,
    batchSize: options.batchSize,
    startedAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    backupPath: null,
    completedIds: [],
    failedIds: [],
    lastCompletedId: null,
    processedCount: 0,
  };
}

function uniqueSortedIds(ids) {
  return [...new Set(ids)].sort((a, b) => a - b);
}

module.exports = {
  DEFAULT_BACKUP_DIR,
  DEFAULT_INPUT_PATH,
  DEFAULT_STATE_PATH,
  REQUIRED_FR_FIELDS,
  buildFrenchTranslationObject,
  chooseGrade,
  chooseReference,
  createBackup,
  createEmptyState,
  detectEnglishLeakage,
  detectSpanishLeakage,
  ensureDir,
  hasValidFrenchTranslation,
  loadJson,
  loadState,
  normalizeForComparison,
  resolveProjectPath,
  saveJsonAtomic,
  saveState,
  timestampForFilename,
  uniqueSortedIds,
  validateDatasetShape,
  validateFrenchFields,
};
