const fs = require('fs');
const path = require('path');

const INPUT_HADITHS = 'assets/hadiths/hadiths_multilang_full.json';
const INPUT_DUAS = 'assets/data/duas_multilang_full.json';
const OUTPUT_HADITHS_CSV = 'scripts/translation_export_hadiths.csv';
const OUTPUT_DUAS_CSV = 'scripts/translation_export_duas.csv';

function escapeCSV(str) {
  if (str === null || str === undefined) return '';
  const s = String(str);
  if (s.includes(',') || s.includes('"') || s.includes('\n') || s.includes('\r')) {
    return '"' + s.replace(/"/g, '""') + '"';
  }
  return s;
}

function unescapeCSV(str) {
  if (!str) return '';
  return str.replace(/""/g, '"').replace(/^"|"$/g, '');
}

function exportHadiths() {
  console.log('📖 Exportando Hadiths a CSV...');
  
  const raw = fs.readFileSync(INPUT_HADITHS, 'utf8');
  const hadiths = JSON.parse(raw);
  
  const headers = ['id', 'lang', 'arabic', 'translation', 'category', 'reference', 'grade'];
  const rows = [headers.join(',')];
  
  for (const hadith of hadiths) {
    for (const lang of ['es', 'en', 'ar']) {
      const t = hadith.translations[lang] || {};
      const row = [
        hadith.id,
        lang,
        escapeCSV(t.arabic || ''),
        escapeCSV(t.translation || ''),
        escapeCSV(t.category || ''),
        escapeCSV(t.reference || ''),
        escapeCSV(t.grade || '')
      ];
      rows.push(row.join(','));
    }
  }
  
  fs.writeFileSync(OUTPUT_HADITHS_CSV, rows.join('\n'), 'utf8');
  console.log(`  ✓ Exportado: ${OUTPUT_HADITHS_CSV}`);
  console.log(`  └─ ${hadiths.length} hadiths × 3 idiomas = ${hadiths.length * 3} filas`);
  
  return hadiths.length;
}

function exportDuas() {
  console.log('🔤 Exportando Duas a CSV...');
  
  const raw = fs.readFileSync(INPUT_DUAS, 'utf8');
  const duas = JSON.parse(raw);
  
  const headers = ['id', 'lang', 'title', 'arabicText', 'transliteration', 'translation', 'category', 'reference', 'source', 'count', 'isFeatured'];
  const rows = [headers.join(',')];
  
  for (const dua of duas) {
    for (const lang of ['es', 'en', 'ar']) {
      const t = dua.translations[lang] || {};
      const row = [
        escapeCSV(dua.id),
        lang,
        escapeCSV(t.title || ''),
        escapeCSV(t.arabicText || ''),
        escapeCSV(t.transliteration || ''),
        escapeCSV(t.translation || ''),
        escapeCSV(t.category || ''),
        escapeCSV(t.reference || ''),
        escapeCSV(t.source || ''),
        t.count || '',
        t.isFeatured ? 'true' : 'false'
      ];
      rows.push(row.join(','));
    }
  }
  
  fs.writeFileSync(OUTPUT_DUAS_CSV, rows.join('\n'), 'utf8');
  console.log(`  ✓ Exportado: ${OUTPUT_DUAS_CSV}`);
  console.log(`  └─ ${duas.length} duas × 3 idiomas = ${duas.length * 3} filas`);
  
  return duas.length;
}

console.log('\n========================================');
console.log('📤 EXPORTADOR DE CONTENIDO PARA TRADUCCIÓN');
console.log('========================================\n');

const hadithsCount = exportHadiths();
console.log('');
const duasCount = exportDuas();

console.log('\n========================================');
console.log('✅ EXPORTACIÓN COMPLETADA');
console.log('========================================');
console.log(`📖 Hadiths: ${hadithsCount}`);
console.log(`🔤 Duas: ${duasCount}`);
console.log('\n📁 Archivos CSV generados:');
console.log(`  - ${OUTPUT_HADITHS_CSV}`);
console.log(`  - ${OUTPUT_DUAS_CSV}`);
console.log('\n📋 SIGUIENTES PASOS:');
console.log('1. Abre los CSV en Google Sheets o Excel');
console.log('2. Traduce las columnas "translation" y "category" (para "en")');
console.log('3. Guarda los CSV');
console.log('4. Ejecuta el importador: node scripts/import_translation.js');
console.log('\n⚠️  IMPORTANTE:');
console.log('- NO toques las columnas "id", "arabic", "arabicText"');
console.log('- Solo traduce los campos de texto: translation, category, title, reference');
console.log('- El campo "count" debe ser número o vacío');
console.log('- El campo "isFeatured" debe ser "true" o "false"\n');