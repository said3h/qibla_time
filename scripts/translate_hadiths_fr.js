const { loadScriptEnv } = require('./load_script_env');

loadScriptEnv();

const OpenAI = require('openai');
const {
  DEFAULT_INPUT_PATH,
  DEFAULT_STATE_PATH,
  buildFrenchTranslationObject,
  createBackup,
  createEmptyState,
  hasValidFrenchTranslation,
  loadJson,
  loadState,
  saveJsonAtomic,
  saveState,
  uniqueSortedIds,
  validateDatasetShape,
  validateFrenchFields,
} = require('./hadith_fr_translation_common');

const args = process.argv.slice(2);

const options = {
  inputPath: DEFAULT_INPUT_PATH,
  statePath: DEFAULT_STATE_PATH,
  batchSize: 4,
  model: process.env.HADITH_FR_TRANSLATION_MODEL || 'gpt-4o',
  temperature: 0.1,
  maxRetries: 2,
  limit: null,
  startAfterId: null,
  dryRun: false,
};

for (const arg of args) {
  if (arg.startsWith('--input=')) options.inputPath = arg.split('=')[1];
  if (arg.startsWith('--state=')) options.statePath = arg.split('=')[1];
  if (arg.startsWith('--batch-size=')) {
    options.batchSize = Number.parseInt(arg.split('=')[1], 10);
  }
  if (arg.startsWith('--model=')) options.model = arg.split('=')[1];
  if (arg.startsWith('--temperature=')) {
    options.temperature = Number.parseFloat(arg.split('=')[1]);
  }
  if (arg.startsWith('--max-retries=')) {
    options.maxRetries = Number.parseInt(arg.split('=')[1], 10);
  }
  if (arg.startsWith('--limit=')) {
    options.limit = Number.parseInt(arg.split('=')[1], 10);
  }
  if (arg.startsWith('--start-after-id=')) {
    options.startAfterId = Number.parseInt(arg.split('=')[1], 10);
  }
  if (arg === '--dry-run') options.dryRun = true;
}

if (!Number.isInteger(options.batchSize) || options.batchSize < 1) {
  console.error('Invalid --batch-size. Use an integer >= 1.');
  process.exit(1);
}

if (!Number.isInteger(options.maxRetries) || options.maxRetries < 0) {
  console.error('Invalid --max-retries. Use an integer >= 0.');
  process.exit(1);
}

if (!options.dryRun && !process.env.OPENAI_API_KEY) {
  console.error('Missing OPENAI_API_KEY in the environment.');
  console.error('Set OPENAI_API_KEY in .env before running the translator.');
  process.exit(1);
}

const client = options.dryRun
  ? null
  : new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

const SYSTEM_PROMPT = `You are a senior translator specializing in Islamic religious texts.

Task:
Translate Hadith dataset entries into natural, respectful, production-ready French.

Rules:
- Translate only into French.
- Preserve the meaning fully. Do not summarize, shorten, or paraphrase away meaning.
- Keep the tone reverent, fluent, and readable for a Muslim audience in French.
- Produce real French wording from start to finish. Do not leave Spanish or English phrasing in the result.
- Never output a partial translation, placeholder, mixed-language sentence, or transliterated source sentence pretending to be French.
- Use Islamic terminology carefully and consistently:
  - Allah, never Dieu as a replacement for Allah.
  - Messager d'Allah when the source refers to the Messenger of Allah.
  - Hadith remains Hadith.
  - Keep well-known Arabic religious terms when appropriate, but make the sentence natural in French.
- Do not copy Spanish into French.
- Do not copy English into French.
- Do not insert explanations, footnotes, or extra commentary.
- Do not translate the reference field.
- Do not translate the grade field.
- Keep citation-style wording out of text, title, and category.
- Titles must be natural French titles, not copied English headlines and not raw Spanish openings.
- Categories must be valid French labels or French preview snippets, never Spanish or English leftovers.
- If the category is a truncated preview/snippet, return a natural French snippet of the same idea. Keep an ellipsis only if the source clearly behaves like a truncated preview.

Return strict JSON only using this shape:
{
  "items": [
    {
      "id": 123,
      "text": "French translation",
      "title": "French title",
      "category": "French category"
    }
  ]
}`;

function cloneForPrompt(entry) {
  return {
    id: entry.id,
    arabic: entry.arabic,
    es: {
      text: entry.translations.es.text,
      title: entry.translations.es.title,
      category: entry.translations.es.category,
      reference: entry.translations.es.reference,
      grade: entry.translations.es.grade,
    },
    en: {
      text: entry.translations.en.text,
      title: entry.translations.en.title,
      category: entry.translations.en.category,
      reference: entry.translations.en.reference,
      grade: entry.translations.en.grade,
    },
    ar: {
      text: entry.translations.ar.text,
      title: entry.translations.ar.title,
      category: entry.translations.ar.category,
      reference: entry.translations.ar.reference,
      grade: entry.translations.ar.grade,
    },
  };
}

function buildUserPrompt(entries, retryIssues = new Map()) {
  const payload = entries.map((entry) => {
    const retryKey = retryIssues.get(entry.id);
    return {
      ...cloneForPrompt(entry),
      translator_notes: retryKey || undefined,
    };
  });

  return [
    'Translate these hadith entries into French.',
    'Translate only the fields text, title, and category.',
    'Use the Arabic plus the English translation as the primary meaning reference, and use the Spanish as a secondary cross-check.',
    'The final output must be fully natural French with no Spanish leakage and no English leakage.',
    'Keep Islamic terminology respectful and consistent for a Muslim audience.',
    'Return JSON only.',
    '',
    JSON.stringify({ items: payload }, null, 2),
  ].join('\n');
}

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function requestBatch(entries, retryIssues = new Map()) {
  const response = await client.chat.completions.create({
    model: options.model,
    temperature: options.temperature,
    response_format: { type: 'json_object' },
    messages: [
      { role: 'system', content: SYSTEM_PROMPT },
      { role: 'user', content: buildUserPrompt(entries, retryIssues) },
    ],
  });

  const content = response.choices?.[0]?.message?.content;
  if (!content) {
    throw new Error('The model returned an empty response.');
  }

  const parsed = JSON.parse(content);
  if (!Array.isArray(parsed.items)) {
    throw new Error('The model response is missing an items array.');
  }

  return parsed.items;
}

function parseValidatedBatch(entries, items) {
  const expectedIds = new Set(entries.map((entry) => entry.id));
  const outputById = new Map();

  for (const item of items) {
    if (!expectedIds.has(item.id)) {
      throw new Error(`Unexpected id in model output: ${item.id}`);
    }

    outputById.set(item.id, {
      text: String(item.text || '').trim(),
      title: String(item.title || '').trim(),
      category: String(item.category || '').trim(),
    });
  }

  if (outputById.size !== entries.length) {
    throw new Error(
      `Expected ${entries.length} translated items but received ${outputById.size}.`,
    );
  }

  return outputById;
}

async function translateBatch(entries) {
  let retryIssues = new Map();

  for (let attempt = 0; attempt <= options.maxRetries; attempt += 1) {
    const rawItems = await requestBatch(entries, retryIssues);
    const outputById = parseValidatedBatch(entries, rawItems);

    const invalidEntries = [];
    retryIssues = new Map();

    for (const entry of entries) {
      const translatedFields = outputById.get(entry.id);
      const issues = validateFrenchFields(entry, translatedFields);
      if (issues.length > 0) {
        invalidEntries.push(entry);
        retryIssues.set(
          entry.id,
          `The previous French output was rejected for: ${issues.join(', ')}. Rewrite it in real French with no Spanish leakage, no English leakage, and no empty fields.`,
        );
      }
    }

    if (invalidEntries.length === 0) {
      return outputById;
    }

    if (attempt === options.maxRetries) {
      throw new Error(
        `Validation failed after retries for hadith ids: ${invalidEntries
          .map((entry) => entry.id)
          .join(', ')}`,
      );
    }

    console.log(
      `  Validation rejected ${invalidEntries.length} item(s). Retrying invalid subset...`,
    );
    entries = invalidEntries;
    await delay(1000 * (attempt + 1));
  }

  throw new Error('Unexpected translation loop failure.');
}

function applyFrenchTranslations(dataset, translatedById) {
  for (const entry of dataset) {
    const translatedFields = translatedById.get(entry.id);
    if (!translatedFields) {
      continue;
    }

    entry.translations.fr = buildFrenchTranslationObject(entry, translatedFields);
  }
}

function getPendingEntries(dataset) {
  const allPending = dataset.filter((entry) => !hasValidFrenchTranslation(entry));
  let selectedPending = allPending;

  if (options.startAfterId !== null) {
    selectedPending = selectedPending.filter(
      (entry) => entry.id > options.startAfterId,
    );
  }

  if (options.limit !== null) {
    selectedPending = selectedPending.slice(0, options.limit);
  }

  return { allPending, selectedPending };
}

async function main() {
  const dataset = loadJson(options.inputPath);
  validateDatasetShape(dataset);

  const { allPending, selectedPending } = getPendingEntries(dataset);
  const pendingEntries = selectedPending;
  const alreadyTranslated = dataset.length - allPending.length;

  console.log('\n=== Hadith FR translation pipeline ===');
  console.log(`Input: ${options.inputPath}`);
  console.log(`Model: ${options.model}`);
  console.log(`Batch size: ${options.batchSize}`);
  console.log(`Already valid in fr: ${alreadyTranslated}`);
  console.log(`Pending translation: ${allPending.length}`);
  if (options.startAfterId !== null || options.limit !== null) {
    console.log(`Selected for this run: ${pendingEntries.length}`);
  }

  if (pendingEntries.length === 0) {
    console.log('Nothing to translate. The dataset already looks complete for fr.');
    return;
  }

  if (options.dryRun) {
    console.log('\nDry-run sample:');
    for (const entry of pendingEntries.slice(0, 3)) {
      console.log(`- ${entry.id}: ${entry.translations.en.title}`);
    }
    console.log('\nNo changes were written.');
    return;
  }

  const batches = [];
  for (
    let index = 0;
    index < pendingEntries.length;
    index += options.batchSize
  ) {
    batches.push(pendingEntries.slice(index, index + options.batchSize));
  }

  const existingState = loadState(options.statePath);
  const state = existingState || createEmptyState(options);

  if (!state.backupPath) {
    state.backupPath = createBackup(options.inputPath);
    saveState(options.statePath, state);
    console.log(`Backup created: ${state.backupPath}`);
  } else {
    console.log(`Reusing backup: ${state.backupPath}`);
  }

  let translatedCount = 0;

  for (let batchIndex = 0; batchIndex < batches.length; batchIndex += 1) {
    const batch = batches[batchIndex];
    const batchIds = batch.map((entry) => entry.id);

    console.log(
      `\nBatch ${batchIndex + 1}/${batches.length} | ids ${batchIds.join(', ')}`,
    );

    const translatedSubset = await translateBatch(batch);
    applyFrenchTranslations(dataset, translatedSubset);
    saveJsonAtomic(options.inputPath, dataset);

    translatedCount += batch.length;
    state.completedIds = uniqueSortedIds([...state.completedIds, ...batchIds]);
    state.failedIds = [];
    state.lastCompletedId = batchIds[batchIds.length - 1];
    state.processedCount = state.completedIds.length;
    state.updatedAt = new Date().toISOString();
    saveState(options.statePath, state);

    console.log(
      `Saved ${translatedCount}/${pendingEntries.length} pending entries to translations.fr`,
    );
  }

  console.log('\nFrench hadith translation completed successfully.');
  console.log(`State file: ${options.statePath}`);
  console.log(`Updated file: ${options.inputPath}`);
}

main().catch((error) => {
  console.error('\nTranslation pipeline failed.');
  console.error(error?.stack || error?.message || error);
  process.exit(1);
});
