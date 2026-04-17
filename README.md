# Qibla Time — Islamic Companion App

> Prayer times, Qibla direction, Quran, Dhikr, and more — with no ads and no data collection.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-blue?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android-brightgreen?logo=android)](https://play.google.com/store/apps/details?id=com.qiblatime.app)

---

## Screenshots

| Home | Prayer Times | Qibla | Quran | Settings |
|:---:|:---:|:---:|:---:|:---:|
| *(coming soon)* | *(coming soon)* | *(coming soon)* | *(coming soon)* | *(coming soon)* |

---

## Features

- **Accurate Prayer Times** — Five daily prayers calculated on-device using the [Adhan](https://github.com/batoulapps/adhan-dart) library with support for multiple calculation methods (MWL, ISNA, Egypt, Makkah, Karachi, Tehran, Shia, etc.)
- **Qibla Compass** — Real-time compass pointing toward Mecca using GPS coordinates and magnetic sensor
- **Quran Reader & Audio** — Full Quran text with multiple recitations; gapless ayah-by-ayah playback with prefetch
- **Prayer Guide** — Step-by-step illustrated guide for each prayer (Fajr through Isha) with position images and rakaat breakdown
- **Dhikr & Duas** — Curated collections of morning/evening adhkar, post-prayer duas, and situational supplications
- **Islamic Books** — Hadith collections and educational booklets via the IslamHouse API
- **99 Names of Allah** — Full Asma ul-Husna with transliteration, meaning, and audio
- **Prayer Tracking** — Log completed prayers and view weekly/monthly statistics
- **Onboarding** — Clean 7-step intro flow covering permissions and key features
- **Period Mode** — Discreet banner and adapted prayer reminders during menstruation
- **Local Notifications** — Exact-time adhan alerts for each prayer (no server dependency)
- **No Ads, No Tracking** — Completely offline-first; no data ever leaves your device

---

## Supported Languages

The app is fully localized in **11 languages**:

| Code | Language |
|---|---|
| `ar` | Arabic (العربية) |
| `de` | German (Deutsch) |
| `en` | English |
| `es` | Spanish (Español) |
| `fr` | French (Français) |
| `id` | Indonesian (Bahasa Indonesia) |
| `it` | Italian (Italiano) |
| `nl` | Dutch (Nederlands) |
| `pt` | Portuguese (Português) |
| `ru` | Russian (Русский) |
| `tr` | Turkish (Türkçe) |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | [Flutter](https://flutter.dev) 3.x |
| Language | Dart 3.x |
| State Management | [Riverpod](https://riverpod.dev) 2.x (`AsyncNotifier`, `FutureProvider`) |
| Architecture | Feature-first Clean Architecture (domain / data / presentation) |
| Prayer Calculation | [Adhan Dart](https://pub.dev/packages/adhan) |
| Audio Playback | [audioplayers](https://pub.dev/packages/audioplayers) |
| Location | [geolocator](https://pub.dev/packages/geolocator) |
| Local Storage | [shared_preferences](https://pub.dev/packages/shared_preferences) |
| Fonts | [google_fonts](https://pub.dev/packages/google_fonts) (DM Serif Display, DM Sans, Amiri) |
| Navigation | [go_router](https://pub.dev/packages/go_router) |
| Deep Links | [url_launcher](https://pub.dev/packages/url_launcher) |
| Localization | Flutter `gen-l10n` with ARB files |

---

## Project Structure

```
lib/
├── core/
│   ├── design/          # QiblaTokens design system (colors, typography, spacing)
│   ├── navigation/      # App router and bottom nav
│   └── services/        # AudioService, NotificationService
├── features/
│   ├── prayer_times/    # Home screen, prayer time calculation
│   ├── qibla/           # Compass screen
│   ├── quran/           # Quran reader, mini player, audio service
│   ├── dhikr/           # Adhkar and duas
│   ├── hadith/          # IslamHouse book integration
│   ├── onboarding/      # 7-step onboarding flow
│   ├── tracking/        # Prayer log and analytics
│   ├── period/          # Period mode toggle and state
│   └── support/         # Settings, about, rate app
└── l10n/
    ├── app_*.arb        # Localization source files (template: app_es.arb)
    └── generated/       # Auto-generated AppLocalizations classes
assets/
├── images/
│   └── prayer_positions/   # Illustrated prayer position PNGs
└── audio/                  # Bundled short audio clips
```

---

## Building

### Prerequisites

- Flutter **3.19+** (project developed with Flutter 3.41.x)
- Android SDK with `compileSdkVersion 36`, `minSdkVersion 21`
- Java 17+

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/said3h/qibla_time.git
cd qibla_time

# 2. Get dependencies
flutter pub get

# 3. Regenerate localizations (if you modify any .arb file)
flutter gen-l10n

# 4. Run in debug mode
flutter run

# 5. Build release APK
flutter build apk --release

# 6. Build release App Bundle (for Play Store)
flutter build appbundle --release
```

### Android Signing

Create `android/key.properties` with your keystore credentials before a release build:

```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=<your-key-alias>
storeFile=<path-to-your.jks>
```

---

## Privacy

Qibla Time collects **no personal data**. Location is used only for on-device prayer time and Qibla calculation and is never transmitted anywhere.

Full details: [PRIVACY_POLICY.md](PRIVACY_POLICY.md)

---

## Contributing

This is a personal project maintained by a single developer. Bug reports and suggestions are welcome via GitHub Issues. Pull requests are reviewed on a best-effort basis.

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

## Contact

Developed by **Said** — individual developer based in Spain.
Google Play: [Qibla Time](https://play.google.com/store/apps/details?id=com.qiblatime.app)
