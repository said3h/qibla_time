const fs = require('fs');
const { parse } = require('csv-parse/sync');

const INPUT_HADITHS_CSV = 'scripts/translation_export_hadiths.csv';
const INPUT_DUAS_CSV = 'scripts/translation_export_duas.csv';
const OUTPUT_HADITHS = 'assets/hadiths/hadiths_multilang_full.json';
const OUTPUT_DUAS = 'assets/data/duas_multilang_full.json';

const SUPPORTED_LANGS = ['es', 'en', 'ar'];

function parseCSV(content) {
  return parse(content, {
    columns: true,
    skip_empty_lines: true,
    trim: true,
    relax_column_count: true,
    quote: '"',
    escape: '"',
    relax: true,
  });
}

function parseBoolean(value) {
  if (value === undefined || value === null || value === '') {
    return null;
  }
  const normalized = value.toLowerCase().trim();
  if (normalized === 'true' || normalized === '1' || normalized === 'yes' || normalized === 'si') {
    return true;
  }
  if (normalized === 'false' || normalized === '0' || normalized === 'no') {
    return false;
  }
  return null;
}

function parseIntSafe(value) {
  if (value === undefined || value === null || value === '') {
    return null;
  }
  const parsed = parseInt(value, 10);
  return isNaN(parsed) ? null : parsed;
}

function validateRow(row, type, rowNum) {
  const errors = [];
  const warnings = [];

  if (!row.id) {
    errors.push(`falta 'id'`);
  }

  if (!row.lang) {
    errors.push(`falta 'lang'`);
  } else if (!SUPPORTED_LANGS.includes(row.lang)) {
    errors.push(`lang '${row.lang}' no soportado (soporta: ${SUPPORTED_LANGS.join(', ')})`);
  }

  if (type === 'hadith') {
    if (!row.translation) {
      warnings.push(`falta 'translation'`);
    }
  } else if (type === 'dua') {
    if (!row.title) {
      warnings.push(`falta 'title'`);
    }
  }

  return { errors, warnings };
}

function importHadiths() {
  console.log('📖 Importando Hadiths desde CSV...');

  if (!fs.existsSync(INPUT_HADITHS_CSV)) {
    console.log(`  ⚠️  Archivo no encontrado: ${INPUT_HADITHS_CSV}`);
    console.log('  └─ Ejecuta primero: node scripts/export_translation.js');
    return;
  }

  try {
    const raw = fs.readFileSync(INPUT_HADITHS_CSV, 'utf8');
    const rows = parseCSV(raw);

  console.log(`  └─ CSV parseado: ${rows.length} filas`);
  
  if (rows.length > 0) {
    console.log(`  └─ Columnas: ${Object.keys(rows[0]).join(', ')}`);
  }

  const hadithsMap = {};
    let importedCount = 0;
    let errorCount = 0;

    for (let i = 0; i < rows.length; i++) {
      const row = rows[i];
      const rowNum = i + 2;

      const { errors, warnings } = validateRow(row, 'hadith', rowNum);
      if (errors.length > 0) {
        console.log(`  ❌ Fila ${rowNum} [id=${row.id} lang=${row.lang}]: ${errors.join(', ')}`);
        errorCount++;
        continue;
      }
      if (warnings.length > 0) {
        console.log(`  ⚠️  Fila ${rowNum} [id=${row.id} lang=${row.lang}]: ${warnings.join(', ')} (omitida)`);
        errorCount++;
        continue;
      }

      const id = parseInt(row.id);
      if (isNaN(id)) {
        console.log(`  ❌ Fila ${rowNum}: id '${row.id}' no es un número válido`);
        errorCount++;
        continue;
      }

      const lang = row.lang;

      if (!hadithsMap[id]) {
        hadithsMap[id] = { id, translations: {} };
      }

      hadithsMap[id].translations[lang] = {
        arabic: row.arabic || '',
        translation: row.translation || '',
        category: row.category || '',
        reference: row.reference || '',
        grade: row.grade || ''
      };

      importedCount++;
    }

    const hadiths = Object.values(hadithsMap).sort((a, b) => a.id - b.id);

    fs.writeFileSync(OUTPUT_HADITHS, JSON.stringify(hadiths, null, 2), 'utf8');
    console.log(`  ✓ Importado: ${OUTPUT_HADITHS}`);
    console.log(`  └─ ${hadiths.length} hadiths únicos, ${importedCount} traducciones`);

    if (errorCount > 0) {
      console.log(`  ⚠️  ${errorCount} filas omitidas por errores`);
    }

    return { total: hadiths.length, imported: importedCount, errors: errorCount };
  } catch (e) {
    console.log(`  ❌ Error al procesar hadiths: ${e.message}`);
    return { total: 0, imported: 0, errors: 1 };
  }
}

function importDuas() {
  console.log('🔤 Importando Duas desde CSV...');

  if (!fs.existsSync(INPUT_DUAS_CSV)) {
    console.log(`  ⚠️  Archivo no encontrado: ${INPUT_DUAS_CSV}`);
    console.log('  └─ Ejecuta primero: node scripts/export_translation.js');
    return;
  }

  try {
    const raw = fs.readFileSync(INPUT_DUAS_CSV, 'utf8');
    const rows = parseCSV(raw);

    console.log(`  └─ CSV parseado: ${rows.length} filas`);

    const duasMap = {};
    let importedCount = 0;
    let errorCount = 0;

    for (let i = 0; i < rows.length; i++) {
      const row = rows[i];
      const rowNum = i + 2;

      const { errors, warnings } = validateRow(row, 'dua', rowNum);
      if (errors.length > 0) {
        console.log(`  ❌ Fila ${rowNum} [id=${row.id} lang=${row.lang}]: ${errors.join(', ')}`);
        errorCount++;
        continue;
      }
      if (warnings.length > 0) {
        console.log(`  ⚠️  Fila ${rowNum} [id=${row.id} lang=${row.lang}]: ${warnings.join(', ')} (omitida)`);
        errorCount++;
        continue;
      }

      const id = row.id;
      const lang = row.lang;

      if (!duasMap[id]) {
        duasMap[id] = { id, translations: {} };
      }

      duasMap[id].translations[lang] = {
        title: row.title || '',
        arabicText: row.arabicText || '',
        transliteration: row.transliteration || '',
        translation: row.translation || '',
        category: row.category || '',
        reference: row.reference || '',
        source: row.source || '',
        count: parseIntSafe(row.count),
        isFeatured: parseBoolean(row.isFeatured)
      };

      importedCount++;
    }

    const duas = Object.values(duasMap);

    fs.writeFileSync(OUTPUT_DUAS, JSON.stringify(duas, null, 2), 'utf8');
    console.log(`  ✓ Importado: ${OUTPUT_DUAS}`);
    console.log(`  └─ ${duas.length} duas únicas, ${importedCount} traducciones`);

    if (errorCount > 0) {
      console.log(`  ⚠️  ${errorCount} filas omitidas por errores`);
    }

    return { total: duas.length, imported: importedCount, errors: errorCount };
  } catch (e) {
    console.log(`  ❌ Error al procesar duas: ${e.message}`);
    return { total: 0, imported: 0, errors: 1 };
  }
}

function validateJSON() {
  console.log('\n🔍 Validando archivos JSON...');

  let valid = true;

  try {
    const hadithsRaw = fs.readFileSync(OUTPUT_HADITHS, 'utf8');
    const hadiths = JSON.parse(hadithsRaw);
    console.log(`  ✓ hadiths_multilang_full.json: ${hadiths.length} entradas`);

    for (const h of hadiths) {
      if (!h.id || !h.translations) {
        console.log(`  ❌ Hadith ${h.id}: estructura inválida`);
        valid = false;
        continue;
      }

      for (const lang of SUPPORTED_LANGS) {
        if (!h.translations[lang]) {
          console.log(`  ⚠️ Hadith ${h.id}: falta traducción '${lang}'`);
        }
      }
    }
  } catch (e) {
    console.log(`  ❌ Error en hadiths: ${e.message}`);
    valid = false;
  }

  try {
    const duasRaw = fs.readFileSync(OUTPUT_DUAS, 'utf8');
    const duas = JSON.parse(duasRaw);
    console.log(`  ✓ duas_multilang_full.json: ${duas.length} entradas`);

    for (const d of duas) {
      if (!d.id || !d.translations) {
        console.log(`  ❌ Dua ${d.id}: estructura inválida`);
        valid = false;
        continue;
      }

      for (const lang of SUPPORTED_LANGS) {
        if (!d.translations[lang]) {
          console.log(`  ⚠️ Dua ${d.id}: falta traducción '${lang}'`);
        }
      }
    }
  } catch (e) {
    console.log(`  ❌ Error en duas: ${e.message}`);
    valid = false;
  }

  return valid;
}

(async () => {
  console.log('\n========================================');
  console.log('📥 IMPORTADOR DE TRADUCCIONES (ROBUSTO)');
  console.log('========================================\n');

  let totalErrors = 0;

  const hadithsResult = importHadiths();
  console.log('');
  const duasResult = importDuas();

  if (hadithsResult) totalErrors += hadithsResult.errors;
  if (duasResult) totalErrors += duasResult.errors;

  console.log('');
  const isValid = validateJSON();

  console.log('\n========================================');
  const hasErrors = totalErrors > 0 || !isValid;
  console.log(hasErrors ? '⚠️ IMPORTACIÓN COMPLETADA CON ERRORES' : '✅ IMPORTACIÓN COMPLETADA Y VALIDADA');
  console.log('========================================');

  if (hasErrors) {
    console.log('\n📋 Revisa los errores arriba antes de continuar.');
  }

  console.log('\n📋 Para activar las traducciones en la app:');
  console.log('1. Copia: assets/hadiths/hadiths_multilang_full.json → assets/hadiths/hadiths_multilang.json');
  console.log('2. Copia: assets/data/duas_multilang_full.json → assets/data/duas_multilang.json');
  console.log('3. Reinicia la app\n');
})();