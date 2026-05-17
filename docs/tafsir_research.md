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

### Debug Spanish Resource Candidate
- Resource: Spanish Abridged Explanation of the Quran
- QUL resource ID: `268`
- QUL URL: https://qul.tarteel.ai/resources/tafsir/268
- Source listed by QUL: https://quranenc.com/en/browse/spanish_mokhtasar
- Language: Spanish
- Publisher/source note from QUL: Spanish translation of "Abridged Explanation of the Quran" by Tafsir Center of Quranic Studies.
- Quran Foundation `/resources/tafsirs` status:
  - The public Quran.com/Quran Foundation tafsir resource list currently does not include a Spanish tafsir entry.
  - Resource `268` returns `404` from the Quran Foundation tafsir-by-ayah endpoint, so it is treated as a QUL resource ID, not a Quran Foundation API resource ID.
- QUL availability:
  - The public QUL resource page exposes a per-ayah preview, e.g. `https://qul.tarteel.ai/resources/tafsir/268?ayah=2%3A255`.
  - Full JSON/SQLite exports are shown by QUL, but download currently requires sign-in.
- Response/format observed:
  - QUL preview is HTML, not JSON.
  - The preview includes an HTML heading, Arabic ayah text, and a `<div class="tafsir spanish">...</div>` containing Spanish tafsir text.
  - QUL documentation says JSON exports may contain grouped tafsir entries where an ayah key points to another group key; this must be supported before offline bundling.
- Approximate length:
  - Short ayahs can be one sentence.
  - Longer ayahs such as 2:255 return a paragraph of several hundred Spanish characters.
- Current implementation decision:
  - Use QUL preview only for internal debug testing behind explicit `--dart-define` flags.
  - Do not bundle or redistribute the dataset yet.
  - TODO: verify QuranEnc/Tafsir Center redistribution, caching, modification, and attribution terms before any production feature or offline import.

### QUL Multi-language Resource Candidates

Discovery source:
- QUL tafsir list: https://qul.tarteel.ai/resources/tafsir?view=list
- Per-ayah preview checked with `?ayah=1%3A1`.
- These resources are for internal online preview only until legal/source terms
  are verified. They must not be bundled offline yet.

Confirmed initial mapping:

| App language | QUL resource ID | Name | Type | Preview status | Notes |
| --- | ---: | --- | --- | --- | --- |
| `es` | `268` | Spanish Abridged Explanation of the Quran | Al-Mukhtasar / abridged explanation | `1:1` returns HTML tafsir text | Current reference resource. |
| `en` | `266` | English Al-Mukhtasar | Al-Mukhtasar | `1:1` returns HTML tafsir text | Good first English candidate. |
| `ar` | `251` | Arabic Al-Mukhtasar in interpreting the Noble Quran | Al-Mukhtasar | `1:1` returns HTML tafsir text | Preferred Arabic candidate because it matches the Mukhtasar family. |
| `tr` | `258` | Turkish Al-Mukhtasar in Interpreting the Noble Quran | Al-Mukhtasar | `1:1` returns HTML tafsir text | Good first Turkish candidate. |
| `fr` | `259` | French Abridged Explanation of the Quran | Al-Mukhtasar / abridged explanation | `1:1` returns HTML tafsir text | Good first French candidate. |
| `ru` | `262` | Russian Al-Mukhtasar | Al-Mukhtasar | `1:1` returns HTML tafsir text | Good first Russian candidate. |
| `it` | `253` | Italian Al-Mukhtasar in interpreting the Noble Quran | Al-Mukhtasar | `1:1` returns HTML tafsir text | Good first Italian candidate. |

Not mapped yet:
- `de`: unsupported for now. A focused QUL tafsir search found no German or
  Deutsch tafsir resource by tag, title, or search text.
- `pt`: unsupported for now. A focused QUL tafsir search found no Portuguese,
  Portugues, Português, Brazil, or Brasil tafsir resource by tag, title, or
  search text.

Focused German/Portuguese check:
- Checked QUL tafsir list page: `https://qul.tarteel.ai/resources/tafsir?view=list`
- Checked QUL search pages:
  - `https://qul.tarteel.ai/resources/tafsir?q=german`
  - `https://qul.tarteel.ai/resources/tafsir?q=portuguese`
- Search terms checked in parsed resource cards:
  - German: `german`, `deutsch`, `alem`
  - Portuguese: `portuguese`, `portugues`, `português`, `brazil`, `brasil`
- Result: no reliable original tafsir resource found for `de` or `pt`.

Implementation decision:
- Use a central `languageCode -> QUL resourceId` map for confirmed resources.
- If the active language is not mapped, return the safe unavailable/fallback
  state.
- Do not use Spanish or English as automatic fallback for another language.
- Do not use machine translation.

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
