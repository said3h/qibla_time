const fs = require('fs');
const path = require('path');

const inputHadithsPath = 'assets/hadiths/hadiths_complete.json';
const inputDuasPath = 'assets/data/duas_hisnul.json';
const outputHadithsPath = 'assets/hadiths/hadiths_multilang_full.json';
const outputDuasPath = 'assets/data/duas_multilang_full.json';

function convertHadiths() {
  console.log('📖 Convirtiendo hadiths...');
  
  const raw = fs.readFileSync(inputHadithsPath, 'utf8');
  const hadiths = JSON.parse(raw);
  
  console.log(`  - Total hadiths a convertir: ${hadiths.length}`);
  
  const multilang = hadiths.map(h => ({
    id: h.id,
    translations: {
      es: {
        arabic: h.arabic,
        translation: h.translation,
        reference: h.reference,
        category: h.category,
        grade: h.grade
      },
      en: {
        arabic: h.arabic,
        translation: '', // TODO: Añadir traducción inglés
        reference: h.reference,
        category: '', // TODO: Traducir categoría al inglés
        grade: h.grade
      }
    }
  }));
  
  fs.writeFileSync(outputHadithsPath, JSON.stringify(multilang, null, 2), 'utf8');
  console.log(`  ✓ Guardado en: ${outputHadithsPath}`);
  console.log(`  ⚠️  IMPORTANTE: Hay ${hadiths.length} entradas vacías en inglés que necesitas traducir`);
  
  return multilang.length;
}

function convertDuas() {
  console.log('🔤 Convirtiendo duas...');
  
  const raw = fs.readFileSync(inputDuasPath, 'utf8');
  const duas = JSON.parse(raw);
  
  console.log(`  - Total duas a convertir: ${duas.length}`);
  
  const multilang = duas.map(d => ({
    id: d.id,
    translations: {
      es: {
        title: d.title,
        arabicText: d.arabicText,
        transliteration: d.transliteration || '',
        translation: d.translation,
        category: d.category,
        reference: d.reference || '',
        source: d.source || '',
        count: d.count || null,
        tags: d.tags || [],
        times: d.times || [],
        isFeatured: d.isFeatured || false
      },
      en: {
        title: '', // TODO: Traducir título al inglés
        arabicText: d.arabicText,
        transliteration: d.transliteration || '', // Puede mantenerse o traducirse
        translation: '', // TODO: Traducir traducción al inglés
        category: d.category, // TODO: Traducir categoría al inglés
        reference: d.reference || '',
        source: d.source || '',
        count: d.count || null,
        tags: d.tags || [], // TODO: Traducir tags al inglés
        times: d.times || [],
        isFeatured: d.isFeatured || false
      },
      ar: {
        title: d.arabicText, // Para árabe, usamos el texto árabe como título
        arabicText: d.arabicText,
        transliteration: '', // No aplica para árabe
        translation: '', // El texto árabe es la traducción
        category: d.category, // TODO: Traducir categoría al árabe
        reference: d.reference || '',
        source: d.source || '',
        count: d.count || null,
        tags: d.tags || [],
        times: d.times || [],
        isFeatured: d.isFeatured || false
      }
    }
  }));
  
  fs.writeFileSync(outputDuasPath, JSON.stringify(multilang, null, 2), 'utf8');
  console.log(`  ✓ Guardado en: ${outputDuasPath}`);
  console.log(`  ⚠️  IMPORTANTE: Hay ${duas.length} entradas vacías en inglés que necesitas traducir`);
  
  return duas.length;
}

console.log('\n========================================');
console.log('🚀 CONVERTIDOR DE CONTENIDO MULTIIDIOMA');
console.log('========================================\n');

const hadithsCount = convertHadiths();
console.log('');
const duasCount = convertDuas();

console.log('\n========================================');
console.log('✅ CONVERSIÓN COMPLETADA');
console.log('========================================');
console.log(`📖 Hadiths convertidos: ${hadithsCount}`);
console.log(`🔤 Duas convertidos: ${duasCount}`);
console.log('\n📋 Archivos generados:');
console.log(`  - ${outputHadithsPath}`);
console.log(`  - ${outputDuasPath}`);
console.log('\n⚠️  SIGUIENTES PASOS:');
console.log('1. Revisa los archivos generados');
console.log('2. Rellena las traducciones al inglés (campo "en")');
console.log('3. Para árabe, el texto árabe ya está incluido en "arabicText"');
console.log('4. Cuando estés listo, renombra los archivos a:');
console.log('   - hadiths_multilang.json');
console.log('   - duas_multilang.json');
console.log('5. La app usará automáticamente las traducciones disponibles');
console.log('   con fallback a español si falta algún idioma\n');