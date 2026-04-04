const { loadScriptEnv } = require('./load_script_env');

loadScriptEnv();
const fs = require('fs');
const path = require('path');
const OpenAI = require('openai');

const SUPPORTED_LANGS = ['en', 'ar'];

const INPUT_DUAS = 'assets/data/duas_multilang_full.json';
const INPUT_HADITHS = 'assets/hadiths/hadiths_multilang_full.json';
const OUTPUT_DUAS = 'assets/data/duas_multilang_full.json';
const OUTPUT_HADITHS = 'assets/hadiths/hadiths_multilang_full.json';
const BACKUP_DIR = 'scripts/backups';

const args = process.argv.slice(2);
const options = {
  type: 'both',
  lang: 'both',
  dryRun: false,
  batchSize: 10,
  model: 'gpt-4o-mini'
};

for (const arg of args) {
  if (arg.startsWith('--type=')) options.type = arg.split('=')[1];
  if (arg.startsWith('--lang=')) options.lang = arg.split('=')[1];
  if (arg === '--dry-run') options.dryRun = true;
  if (arg.startsWith('--batch=')) options.batchSize = parseInt(arg.split('=')[1]);
  if (arg.startsWith('--model=')) options.model = arg.split('=')[1];
}

if (!process.env.OPENAI_API_KEY) {
  console.error('❌ Error: Falta OPENAI_API_KEY en .env');
  console.log('\n📋 Para configurar:');
  console.log('1. Crea archivo .env en la raíz del proyecto');
  console.log('2. Añade: OPENAI_API_KEY=tu_api_key_aqui');
  console.log('3. Obtén tu key de: https://platform.openai.com/api-keys');
  process.exit(1);
}

const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

function ensureBackupDir() {
  if (!fs.existsSync(BACKUP_DIR)) {
    fs.mkdirSync(BACKUP_DIR, { recursive: true });
  }
}

function createBackup(filePath, suffix) {
  ensureBackupDir();
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const filename = path.basename(filePath, '.json');
  const backupPath = `${BACKUP_DIR}/${filename}_${suffix}_${timestamp}.json`;
  fs.copyFileSync(filePath, backupPath);
  console.log(`  ✓ Backup creado: ${backupPath}`);
  return backupPath;
}

function loadJSON(filePath) {
  if (!fs.existsSync(filePath)) {
    console.error(`❌ Archivo no encontrado: ${filePath}`);
    process.exit(1);
  }
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function saveJSON(filePath, data) {
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf8');
}

function needsTranslation(translations, targetLang) {
  if (!translations.es) return false;
  const target = translations[targetLang];
  if (!target) return true;
  return !target.translation || !target.title || !target.category;
}

function getMissingTranslations(data, targetLang) {
  const missing = [];
  for (const item of data) {
    if (needsTranslation(item.translations, targetLang)) {
      missing.push(item);
    }
  }
  return missing;
}

const SYSTEM_PROMPT = `You are translating Islamic religious content from Spanish into {targetLanguage}.

CONTEXT:
* This content will be used in a Muslim app (Quran, Hadith, Dua)
* The tone must be respectful, natural, and spiritually appropriate
* Avoid robotic or literal translations

STRICT RULES:
* Do NOT translate or modify any Arabic text
* Do NOT change meaning, only improve clarity
* Do NOT add explanations
* Keep output clean for JSON

STYLE:
* Natural, fluent, human tone
* Avoid literal translation
* Clear and readable sentences

TERMINOLOGY:
* Allah (never God)
* Prophet Muhammad (ﷺ) or the Prophet (ﷺ)
* Hadith stays as Hadith
* dua → supplication

FIELD RULES:
Translate ONLY:
* translation
* title
* category
* reference

DO NOT TOUCH:
* id
* arabic / arabicText
* transliteration
* count
* isFeatured
* grade

QUALITY CHECK:
* Must sound natural when read aloud
* Avoid awkward phrasing
* Keep spiritual tone`;

function buildTranslationPrompt(item, targetLang, type) {
  const source = item.translations.es;
  const langName = targetLang === 'en' ? 'English' : 'Arabic';
  const targetLanguage = targetLang === 'en' ? 'English' : 'Classical Arabic';
  
  const systemPrompt = SYSTEM_PROMPT.replace('{targetLanguage}', targetLanguage);
  
  const prompt = `TYPE: ${type}

SOURCE TEXT:
ID: ${item.id}
Title: ${source.title || '(empty)'}
Translation: ${source.translation || '(empty)'}
Category: ${source.category || '(empty)'}
Reference: ${source.reference || '(empty)'}
Source: ${source.source || '(empty)'}

Translate to ${langName} following the style guidelines.`;

  return { role: 'user', content: prompt };
}

async function translateBatch(items, targetLang, type) {
  const targetLanguage = targetLang === 'en' ? 'English' : 'Classical Arabic';
  const systemPrompt = SYSTEM_PROMPT.replace('{targetLanguage}', targetLanguage);
  
  const messages = [
    { role: 'system', content: systemPrompt },
    ...items.map(item => buildTranslationPrompt(item, targetLang, type))
  ];

  try {
    const response = await client.chat.completions.create({
      model: options.model,
      messages: messages,
      temperature: 0.3,
      response_format: { type: 'json_object' }
    });

    const content = response.choices[0].message.content;
    const results = JSON.parse(content);
    
    if (Array.isArray(results)) {
      return results;
    } else if (results.translated) {
      return [results];
    } else {
      console.log('  ⚠️ Respuesta inesperada:', results);
      return [];
    }
  } catch (error) {
    console.error('  ❌ Error en batch:', error.message);
    return [];
  }
}

function applyTranslations(data, translations, targetLang) {
  const translatedMap = {};
  for (const t of translations) {
    translatedMap[t.id] = t.translated;
  }

  for (const item of data) {
    if (translatedMap[item.id]) {
      if (!item.translations[targetLang]) {
        item.translations[targetLang] = {};
      }
      const t = translatedMap[item.id];
      if (t.title) item.translations[targetLang].title = t.title;
      if (t.translation) item.translations[targetLang].translation = t.translation;
      if (t.category) item.translations[targetLang].category = t.category;
      if (t.reference) item.translations[targetLang].reference = t.reference;
      if (t.source !== undefined) item.translations[targetLang].source = t.source;
      
      if (item.translations.es && targetLang === 'ar') {
        item.translations[targetLang].arabicText = item.translations.es.arabicText;
        item.translations[targetLang].transliteration = item.translations.es.transliteration || '';
      }
    }
  }
  return data;
}

async function processType(type, targetLang) {
  const isDua = type === 'dua';
  const inputFile = isDua ? INPUT_DUAS : INPUT_HADITHS;
  const outputFile = isDua ? OUTPUT_DUAS : OUTPUT_HADITHS;
  const typeName = isDua ? 'Dua' : 'Hadith';
  const langName = targetLang === 'en' ? 'Inglés' : 'Árabe';

  console.log(`\n📖 Procesando ${typeName} → ${langName}...`);

  const data = loadJSON(inputFile);
  const missing = getMissingTranslations(data, targetLang);
  
  console.log(`  └─ Total: ${data.length} | Faltantes: ${missing.length}`);

  if (missing.length === 0) {
    console.log(`  ✓ No hay nada que traducir`);
    return;
  }

  if (options.dryRun) {
    console.log(`  ⚠️ Modo dry-run: mostrando primeros 3 ejemplos`);
    for (let i = 0; i < Math.min(3, missing.length); i++) {
      console.log(`\n  [${i + 1}] ${missing[i].id}`);
      console.log(`      Title: ${missing[i].translations.es.title}`);
      console.log(`      Category: ${missing[i].translations.es.category}`);
    }
    return;
  }

  createBackup(inputFile, `${type}_${targetLang}`);

  const batches = [];
  for (let i = 0; i < missing.length; i += options.batchSize) {
    batches.push(missing.slice(i, i + options.batchSize));
  }

  console.log(`  └─ Procesando ${batches.length} batches de ${options.batchSize}...`);

  let translatedCount = 0;
  for (let i = 0; i < batches.length; i++) {
    process.stdout.write(`  └─ Batch ${i + 1}/${batches.length}... `);
    const results = await translateBatch(batches[i], targetLang, type);
    applyTranslations(data, results, targetLang);
    translatedCount += results.length;
    console.log(`✓ (${translatedCount})`);
  }

  saveJSON(outputFile, data);
  console.log(`  ✓ Guardado: ${outputFile}`);
}

async function validateJSON() {
  console.log('\n🔍 Validando archivos JSON...');
  let valid = true;

  for (const [name, file] of [['Duas', OUTPUT_DUAS], ['Hadiths', OUTPUT_HADITHS]]) {
    try {
      const data = JSON.parse(fs.readFileSync(file, 'utf8'));
      console.log(`  ✓ ${name}: ${data.length} entradas`);
      
      for (const item of data.slice(0, 3)) {
        for (const lang of SUPPORTED_LANGS) {
          if (item.translations[lang] && !item.translations[lang].translation) {
            console.log(`  ⚠️ ${name} ${item.id}: falta translation en ${lang}`);
          }
        }
      }
    } catch (e) {
      console.log(`  ❌ ${name}: ${e.message}`);
      valid = false;
    }
  }

  return valid;
}

async function main() {
  console.log('\n========================================');
  console.log('🔄 TRADUCTOR AUTOMÁTICO DE CONTENIDO');
  console.log('========================================');
  console.log(`\n📋 Configuración:`);
  console.log(`   Tipo: ${options.type}`);
  console.log(`   Idioma: ${options.lang}`);
  console.log(`   Modelo: ${options.model}`);
  console.log(`   Batch size: ${options.batchSize}`);
  console.log(`   Modo: ${options.dryRun ? 'DRY-RUN (sin guardar)' : 'PRODUCCIÓN'}`);

  const targetLangs = options.lang === 'both' ? SUPPORTED_LANGS : [options.lang];
  const types = options.type === 'both' ? ['dua', 'hadith'] : [options.type];

  for (const type of types) {
    for (const lang of targetLangs) {
      await processType(type, lang);
    }
  }

  const isValid = await validateJSON();

  console.log('\n========================================');
  console.log(isValid ? '✅ TRADUCCIÓN COMPLETADA' : '⚠️ COMPLETADO CON ERRORES');
  console.log('========================================');

  if (options.dryRun) {
    console.log('\n⚠️ Era modo dry-run. Para aplicar cambios:');
    console.log('   node scripts/translate_content.js --type=dua --lang=en');
  }
}

main().catch(console.error);
