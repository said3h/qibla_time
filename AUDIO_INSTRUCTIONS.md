# 🎵 Instrucciones para Añadir Archivos de Adhan

## 📁 Ubicación de los Archivos

Debes colocar los archivos MP3 en **DOS** ubicaciones:

### 1️⃣ Para iOS y reproducción general (assets)
```
qibla_time/assets/audio/
├── adhan_makkah.mp3
├── adhan_madinah.mp3
├── adhan_cairo.mp3
├── adhan_istanbul.mp3
└── adhan_abdulmalik.mp3
```

### 2️⃣ Para notificaciones Android (raw)
```
qibla_time/android/app/src/main/res/raw/
├── adhan_makkah.mp3
├── adhan_madinah.mp3
├── adhan_cairo.mp3
├── adhan_istanbul.mp3
└── adhan_abdulmalik.mp3
```

---

## 📥 ¿Dónde conseguir los archivos de Adhan?

### Opciones gratuitas y legales:

1. **FreeSound.org**
   - https://freesound.org/search/?q=adhan+islamic+call+to+prayer
   - Filtra por licencias Creative Commons (CC0)

2. **Internet Archive**
   - https://archive.org/search.php?query=adhan

3. **GitHub - Open Source Adhan Files**
   - https://github.com/search?q=adhan+mp3
   - Busca repositorios con licencia MIT o Apache

4. **Muslim Central**
   - https://muslimcentral.com/
   - Algunos adhans son de dominio público

---

## ⚖️ Consideraciones de Licencia

### ✅ Licencias Permitidas:
- **CC0** (Dominio público)
- **CC BY** (Atribución requerida)
- **MIT** (Código abierto)
- **Apache 2.0** (Código abierto)

### ❌ NO usar:
- Archivos con copyright comercial
- Archivos de Spotify, Apple Music, etc.
- Grabaciones de artistas famosos sin permiso

---

## 🔧 Pasos para Añadir los Archivos

### Paso 1: Descargar los MP3
- Descarga 5 archivos de adhan con licencia permisiva
- Renómbralos exactamente como se muestra arriba

### Paso 2: Copiar a assets/audio/
```bash
# Crea la carpeta si no existe
mkdir assets\audio

# Copia los archivos allí
```

### Paso 3: Copiar a Android raw/
```bash
# Crea la carpeta si no existe
mkdir android\app\src\main\res\raw

# Copia los archivos allí
```

### Paso 4: Ejecutar flutter pub get
```bash
cd C:\Users\Said-\.gemini\antigravity\scratch\qibla_time
flutter pub get
```

### Paso 5: Probar la app
```bash
flutter run
```

---

## 🎨 Nombres Sugeridos para los Archivos

| Nombre para mostrar | Nombre del archivo |
|---------------------|-------------------|
| Makkah | `adhan_makkah.mp3` |
| Madinah | `adhan_madinah.mp3` |
| Cairo | `adhan_cairo.mp3` |
| Istanbul | `adhan_istanbul.mp3` |
| Abdulmalik Al-Nu'man | `adhan_abdulmalik.mp3` |

---

## ⚠️ Importante para Android

- Los nombres de archivo en `raw/` deben estar en **minúsculas**
- Sin espacios ni caracteres especiales
- Solo letras, números y guiones bajos

✅ Correcto: `adhan_makkah.mp3`
❌ Incorrecto: `Adhan Makkah.mp3`

---

## 📦 Tamaño Recomendado

- Cada archivo MP3: **2-4 MB** (calidad media)
- Total aproximado: **10-20 MB**
- Duración: **3-5 minutos** por adhan

---

## 🧪 Verificación

Después de añadir los archivos, verifica:

```bash
# Verificar que los archivos existen
dir assets\audio\*.mp3
dir android\app\src\main\res\raw\*.mp3
```

Deberías ver 5 archivos en cada carpeta.

---

## 🚀 Después de Añadir los Archivos

1. Ejecuta `flutter pub get`
2. Haz commit de los archivos:
   ```bash
   git add assets/audio/*.mp3
   git add android/app/src/main/res/raw/*.mp3
   git commit -m "Add Adhan audio files"
   git push
   ```

3. El build de GitHub Actions incluirá los archivos automáticamente

---

## 📝 Nota para el Build de GitHub

El workflow de Android **NO incluirá** los archivos MP3 en el artifact a menos que estén en el repositorio. Asegúrate de hacer commit y push de los archivos de audio.
