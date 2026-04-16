# Traductor Automático de Contenido Islámico

Script para traducir automáticamente contenido religioso (Hadiths y Duas) desde español hacia inglés y árabe.

## Archivos del proyecto

- `scripts/translate_content.js` - Script principal de traducción
- `.env.example` - Plantilla de variables de entorno
- `.env` - Tu archivo de configuración (NO commitear)

## Dependencias

```bash
npm install dotenv openai
```

## Configuración

1. Copia el archivo de ejemplo:
   ```bash
   cp .env.example .env
   ```

2. Edita `.env` y añade tu API key de OpenAI:
   ```
   OPENAI_API_KEY=sk-tu-api-key-aqui
   ```

3. Obtén tu API key en: https://platform.openai.com/api-keys

## Uso

### Modo de prueba (dry-run)

```bash
# Ver qué se traduciría sin guardar cambios
node scripts/translate_content.js --type=dua --lang=en --dry-run
node scripts/translate_content.js --type=hadith --lang=en --dry-run
node scripts/translate_content.js --type=dua --lang=ar --dry-run
node scripts/translate_content.js --type=hadith --lang=ar --dry-run
```

### Traducir Duas a Inglés

```bash
node scripts/translate_content.js --type=dua --lang=en
```

### Traducir Hadiths a Inglés

```bash
node scripts/translate_content.js --type=hadith --lang=en
```

### Traducir Duas a Árabe

```bash
node scripts/translate_content.js --type=dua --lang=ar
```

### Traducir todo a todos los idiomas

```bash
node scripts/translate_content.js
```

### Opciones disponibles

```bash
# Tipo de contenido: dua, hadith, both (default: both)
--type=dua

# Idioma destino: en, ar, both (default: both)
--lang=en

# Tamaño del batch (default: 10)
--batch=5

# Modelo de OpenAI (default: gpt-4o-mini)
--model=gpt-4o

# Modo dry-run (no guarda cambios)
--dry-run
```

## Estrategia recomendada

1. **Primera fase - Duas a Inglés:**
   ```bash
   node scripts/translate_content.js --type=dua --lang=en --batch=5
   ```

2. **Segunda fase - Duas a Árabe:**
   ```bash
   node scripts/translate_content.js --type=dua --lang=ar --batch=5
   ```

3. **Tercera fase - Hadiths a Inglés:**
   ```bash
   node scripts/translate_content.js --type=hadith --lang=en --batch=10
   ```

4. **Cuarta fase - Hadiths a Árabe:**
   ```bash
   node scripts/translate_content.js --type=hadith --lang=ar --batch=10
   ```

## Cómo revisar la calidad

### Verificar estructura JSON
```bash
node scripts/translate_content.js --type=dua --dry-run
```

### Verificar traducciones específicas
```bash
# Ver las primeras traducciones de Duas
node -e "
const d = require('./assets/data/duas_multilang_full.json');
console.log('Duas con inglés:', d.filter(x => x.translations.en).length);
console.log('Ejemplo:', d[0].translations.en);
"
```

### Verificar Hadiths
```bash
node -e "
const h = require('./assets/hadiths/hadiths_multilang_full.json');
console.log('Hadiths con inglés:', h.filter(x => x.translations.en).length);
console.log('Ejemplo:', h[0].translations.en);
"
```

## Notas importantes

- El script hace **backup automático** en `scripts/backups/` antes de modificar archivos
- Solo traduce campos que faltan (no sobreescribe traducciones existentes)
- El modelo `gpt-4o-mini` es económico y rápido; `gpt-4o` da mejores resultados
- Para contenido religioso, se usa un prompt especializado que mantiene el tono apropiado
- El proceso puede tomar tiempo dependiendo de la cantidad de contenido

## Solución de problemas

### Error: Falta OPENAI_API_KEY
Asegúrate de tener el archivo `.env` con tu API key.

### Rate limiting
Reduce el batch size:
```bash
node scripts/translate_content.js --batch=3
```

### Timeout
El modelo por defecto es `gpt-4o-mini` que es rápido. Si tienes problemas, usa:
```bash
node scripts/translate_content.js --batch=1
```