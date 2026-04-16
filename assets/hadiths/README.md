# Hadices en Español para Qibla Time

## 📚 Colecciones Disponibles

| Archivo | Colección | Cantidad |
|---------|-----------|----------|
| `bukhari.json` | Sahih Al-Bujari | 1,054 hadices |
| `muslim.json` | Sahih Muslim | 400 hadices |
| `tirmidhi.json` | Jami` at-Tirmidhi | 201 hadices |
| `abudawud.json` | Sunan Abu Dawud | 113 hadices |
| `ahmad.json` | Musnad Ahmad | 46 hadices |
| `malik.json` | Muwatta Malik | 5 hadices |
| `general.json` | Sin clasificar | 135 hadices |
| `hadiths_complete.json` | **Todas las colecciones** | **1,954 hadices** |

## 📥 Fuente de Datos

- **Origen:** [HadeethEnc.com](https://hadeethenc.com/es/)
- **Traducción:** Español con tildes correctas
- **Licencia:** Gratis con atribución
- **Actualización:** Ejecutar `python download_hadiths.py`

## 🔧 Cómo Usar en Flutter

### Opción 1: Cargar todos los hadices

```dart
import 'dart:convert';
import 'package:flutter/services.dart';

Future<List<Hadith>> loadAllHadiths() async {
  final jsonString = await rootBundle.loadString('assets/hadiths/hadiths_complete.json');
  final List<dynamic> jsonList = json.decode(jsonString);
  return jsonList.map((j) => Hadith.fromJson(j)).toList();
}
```

### Opción 2: Cargar por colección específica

```dart
Future<List<Hadith>> loadBukhariHadiths() async {
  final jsonString = await rootBundle.loadString('assets/hadiths/bukhari.json');
  final List<dynamic> jsonList = json.decode(jsonString);
  return jsonList.map((j) => Hadith.fromJson(j)).toList();
}
```

### Opción 3: Hadiz del día (aleatorio)

```dart
import 'dart:math';

Future<Hadith> getHadithOfDay() async {
  final allHadiths = await loadAllHadiths();
  final now = DateTime.now();
  final seed = now.year * 10000 + now.month * 100 + now.day;
  return allHadiths[seed % allHadiths.length];
}
```

## 📦 Estructura del JSON

Cada hadiz tiene el siguiente formato:

```json
{
  "id": 1751,
  "arabic": "عن أُمّ عَطِيَّةَ الأنصارية رضي الله عنها...",
  "translation": "Umm Atiya Al-Ansariya, que Al-lah esté complacido...",
  "reference": "Registrado por Al-Bujari y Muslim",
  "category": "el mensajero de al-lah, la paz y las bendiciones...",
  "grade": "Sahih"
}
```

### Campos:

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | int | Identificador único |
| `arabic` | string | Texto original en árabe |
| `translation` | string | Traducción al español con tildes |
| `reference` | string | Fuente/colección del hadiz |
| `category` | string | Tema/categoría del hadiz |
| `grade` | string | Grado de autenticidad (Sahih, Hasan, etc.) |

## 🔄 Actualizar Hadices

Para descargar la última versión de HadeethEnc:

```bash
# Instalar dependencias (primera vez)
pip install requests openpyxl

# Descargar hadices
python download_hadiths.py
```

## 📝 Modelo Dart Sugerido

```dart
class Hadith {
  final int id;
  final String arabic;
  final String translation;
  final String reference;
  final String category;
  final String grade;

  Hadith({
    required this.id,
    required this.arabic,
    required this.translation,
    required this.reference,
    required this.category,
    required this.grade,
  });

  factory Hadith.fromJson(Map<String, dynamic> json) {
    return Hadith(
      id: json['id'] ?? 0,
      arabic: json['arabic'] ?? '',
      translation: json['translation'] ?? '',
      reference: json['reference'] ?? '',
      category: json['category'] ?? 'general',
      grade: json['grade'] ?? 'Desconocido',
    );
  }
}
```

## ⚠️ Importante

- **No eliminar** los archivos JSON del repositorio
- **Mantener** el script `download_hadiths.py` para futuras actualizaciones
- **Verificar** que pubspec.yaml incluya:
  ```yaml
  assets:
    - assets/hadiths/
  ```

## 🙏 Agradecimientos

- **Fuente:** [HadeethEnc.com](https://hadeethenc.com/) - Enciclopedia de Hadices Proféticos Traducidos
- **Licencia:** MIT con atribución requerida
