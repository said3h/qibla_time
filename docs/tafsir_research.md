# Tafsir Research

## Goal
Add reliable tafsir/context to Quran verses in Qibla Time to reduce misunderstandings caused by translations alone.

## Candidate Sources

### Quranic Universal Library - QUL
- Website: https://qul.tarteel.ai/resources/tafsir
- GitHub: https://github.com/TarteelAI/quranic-universal-library
- Notes:
  - Provides many tafsir resources.
  - Supports JSON and SQLite downloads.
  - Has Spanish Abridged Explanation of the Quran.
  - Has Tafsir As-Saadi in several languages.
  - The resources page currently lists tafsir downloads in multiple languages and exposes JSON/SQLite formats.
  - Repository license appears to be MIT, but individual text/resource rights must still be verified.
- Risk:
  - Do not assume every text resource is freely redistributable until verified.
  - The MIT license appears to apply to the QUL application/repository code, not automatically to every managed tafsir text.
  - Offline bundling in Qibla Time requires explicit redistribution permission for the selected tafsir resource.

### Quran Foundation / Quran.com API
- Docs: https://api-docs.quran.foundation/
- Tafsir endpoint docs: https://api-docs.quran.foundation/docs/content_apis_versioned/4.0.0/list-surah-tafsirs/
- Notes:
  - Provides tafsir endpoints.
  - Can fetch tafsir by resource, surah, ayah, page, juz, hizb, and related Quran divisions.
  - Useful for online loading and cache.
  - The documented tafsir response includes fields such as `resource_id`, `verse_key`, `text`, `resource_name`, and `language_name`.
  - The API requires access headers/authentication for content endpoints.
- Risk:
  - API terms are revocable and should not be treated as permission to redistribute full datasets inside the app.
  - Online API usage is not the same as offline bundling rights.
  - Cached content limits and attribution requirements must be verified before storing large offline caches.

## MVP Recommendation
Start with:
- Spanish Abridged Explanation of the Quran
- one tafsir source only
- one language first
- JSON format if legally usable
- clean architecture prepared for multiple tafsir later

Recommended first gate:
- Do not import any tafsir data until the exact Spanish resource has a verified source, author/translator/publisher, license, redistribution permission, offline bundling permission, and attribution requirements.
- If legal status is not clear, start with Quran Foundation online-only fetching and a small user cache, but only if API terms permit it.

## Legal Checklist
For every tafsir resource, verify:
- source name
- author
- translator
- publisher
- license
- redistribution permission
- commercial app permission
- attribution requirements
- whether offline bundling is allowed
- whether modified formatting is allowed
- whether caching API responses is allowed
- whether full-dataset redistribution inside APK/AAB is allowed
- whether attribution must be visible in-app or only in a sources/licenses screen

## Technical Checklist
Verify:
- all 6236 ayahs are covered or document missing entries
- verse keys match format surah:ayah
- UTF-8 is valid
- no HTML artifacts unless intentionally rendered
- no broken Arabic/Spanish characters
- no duplicated ayahs
- no shifted ayah alignment
- no grouped/multi-ayah entries unless the model supports ranges explicitly
- no API error payloads stored as tafsir text
- no empty text for required ayahs without a documented reason
- source metadata is stored with the dataset
- app fallback never shows a technical error as tafsir content

## Existing Quran Architecture Notes
Current Quran code already has patterns that tafsir should reuse:
- `lib/features/quran/models/quran_models.dart` contains simple immutable Quran models: `SurahSummary`, `SurahAyah`, `SurahDetail`, and load result/source enums.
- `lib/features/quran/services/quran_service.dart` exposes Riverpod providers near the service, including `quranServiceProvider`, `quranSurahsProvider`, `surahDetailProvider`, and `surahLoadResultProvider`.
- Quran data is offline-first/fallback-aware. The service loads `assets/data/quran_offline.json` with `rootBundle.loadString`.
- Large JSON parsing is moved off the UI isolate with `compute()`.
- The offline Quran cache is static in-memory cache: `static Map<int, SurahDetail>? _offlineCache`.
- Quran service logs recoverable failures through `AppLogger`.
- Spanish Quran currently prefers local translation data while using API Arabic/tajweed when available.
- Reader preferences use `SharedPreferences` through `SettingsService`, for example the Quran tajweed toggle.
- Reading history/bookmarks use a dedicated `QuranReadingService` with JSON encoded values in `SharedPreferences`.

## Architecture Draft
Create future feature folder:

```text
lib/features/tafsir/
```

Suggested structure:
- `models/`
- `services/`
- `providers/`
- `widgets/`
- `screens/`

Do not implement UI yet unless requested.

Suggested files:
- `lib/features/tafsir/models/tafsir_entry.dart`
- `lib/features/tafsir/models/tafsir_resource.dart`
- `lib/features/tafsir/services/tafsir_service.dart`
- `lib/features/tafsir/providers/tafsir_providers.dart`
- `lib/features/tafsir/widgets/tafsir_bottom_sheet.dart`
- `lib/features/tafsir/widgets/tafsir_button.dart`

## Open Decisions
- Whether first MVP is offline-bundled, online-only, or online with limited cache.
- Whether HTML from APIs/resources should be stripped to plain text or rendered as safe rich text.
- Whether grouped tafsir entries should be split, shown as ranges, or hidden until the UI supports ranges.
- Whether source attribution belongs in a dedicated About/Sources screen before shipping.
