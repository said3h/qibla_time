# Tafsir Implementation Plan

## Scope
Prepare a safe tafsir foundation without changing the main Quran screens yet and without bundling any tafsir dataset until legal rights are confirmed.

Initial MVP target:
- Spanish only.
- One verified tafsir resource.
- Ayah-level lookup from Quran reader.
- Offline-first if redistribution is verified; otherwise online fetch with conservative cache only if terms allow it.

## Proposed Feature Structure

```text
lib/features/tafsir/
  models/
    tafsir_entry.dart
    tafsir_resource.dart
  services/
    tafsir_service.dart
    tafsir_cache_service.dart
  providers/
    tafsir_providers.dart
  widgets/
    tafsir_button.dart
    tafsir_bottom_sheet.dart
  screens/
```

Keep tafsir separate from `lib/features/quran/` so Quran text/audio/tajweed stays stable.

## Model: TafsirEntry

Suggested fields:

```dart
class TafsirEntry {
  const TafsirEntry({
    required this.resourceId,
    required this.resourceName,
    required this.languageCode,
    required this.surahNumber,
    required this.ayahNumber,
    required this.verseKey,
    required this.text,
    required this.source,
    this.sourceUrl,
    this.author,
    this.translator,
    this.publisher,
    this.license,
    this.cachedAt,
  });

  final String resourceId;
  final String resourceName;
  final String languageCode;
  final int surahNumber;
  final int ayahNumber;
  final String verseKey;
  final String text;
  final String source;
  final String? sourceUrl;
  final String? author;
  final String? translator;
  final String? publisher;
  final String? license;
  final DateTime? cachedAt;
}
```

Rules:
- `verseKey` must be exactly `${surahNumber}:${ayahNumber}`.
- `text` must be validated before display.
- HTML should either be sanitized and rendered intentionally or stripped to plain text.
- Source/license metadata should travel with entries or be resolvable through `TafsirResource`.

## Model: TafsirResource

Suggested fields:

```dart
class TafsirResource {
  const TafsirResource({
    required this.id,
    required this.name,
    required this.languageCode,
    required this.source,
    required this.licenseStatus,
    required this.offlineBundlingAllowed,
    this.author,
    this.translator,
    this.publisher,
    this.sourceUrl,
    this.attributionText,
  });

  final String id;
  final String name;
  final String languageCode;
  final String source;
  final String licenseStatus;
  final bool offlineBundlingAllowed;
  final String? author;
  final String? translator;
  final String? publisher;
  final String? sourceUrl;
  final String? attributionText;
}
```

`licenseStatus` should be explicit, for example:
- `verified`
- `api_only`
- `pending_review`
- `blocked`

## Service: TafsirService

Responsibilities:
- Resolve tafsir for one ayah: `getTafsir({surahNumber, ayahNumber, languageCode})`.
- Validate verse alignment and text quality.
- Prefer local verified asset when legally allowed.
- Use online provider only when configured and legally safe.
- Return clean failure states, never technical API text as tafsir.
- Log recoverable failures with `AppLogger`.

Suggested API:

```dart
class TafsirService {
  Future<TafsirLoadResult> getTafsir({
    required int surahNumber,
    required int ayahNumber,
    required String languageCode,
  });
}
```

Suggested result:

```dart
enum TafsirLoadSource {
  offline,
  online,
  cache,
  unavailable,
}

class TafsirLoadResult {
  const TafsirLoadResult({
    required this.source,
    this.entry,
    this.errorCode,
  });

  final TafsirLoadSource source;
  final TafsirEntry? entry;
  final String? errorCode;
}
```

## Riverpod Providers

Mirror the current Quran style:

```dart
final tafsirServiceProvider = Provider<TafsirService>((ref) {
  return TafsirService();
});

final tafsirEntryProvider =
    FutureProvider.family<TafsirLoadResult, TafsirRequest>((ref, request) {
  return ref.watch(tafsirServiceProvider).getTafsir(
        surahNumber: request.surahNumber,
        ayahNumber: request.ayahNumber,
        languageCode: request.languageCode,
      );
});
```

`TafsirRequest` should be immutable and include:
- `surahNumber`
- `ayahNumber`
- `languageCode`
- optional `resourceId`

Use `currentLanguageCodeProvider` at the caller/provider level so tafsir refreshes when language changes.

## Local Cache

Two layers:

1. In-memory cache:
   - `Map<String, TafsirEntry>` keyed by `resourceId|language|surah:ayah`.
   - Useful during a Quran reading session.

2. Persistent cache:
   - Use `SharedPreferences` only for small metadata/preferences.
   - Use file cache or SQLite for larger tafsir content if online caching is permitted.
   - Avoid storing thousands of entries in `SharedPreferences`.

Cache rules:
- Store `cachedAt`, `resourceId`, `languageCode`, and `verseKey`.
- Do not cache error responses.
- Do not cache if API terms disallow it.
- Keep source attribution with cached entries.

## Online/Offline Strategy

### If QUL resource license is verified for offline bundling
- Add dataset under a dedicated path, for example:
  - `assets/data/tafsir/es_abridged_explanation.json`
- Register via existing `assets/data/` pubspec umbrella if still present.
- Parse with `rootBundle.loadString`.
- Use `compute()` for full dataset parsing, matching `QuranService`.
- Build a static in-memory cache keyed by verse key.
- Validate coverage before release with a script.

### If offline bundling is not legally verified
- Do not add the dataset to the repo.
- Use Quran Foundation API online only if credentials/terms are acceptable.
- Cache minimally only if terms permit.
- Show unavailable state when offline.

### Fallback order
Recommended:
1. Verified local tafsir asset.
2. Valid local cache, if allowed.
3. Online API, if configured and allowed.
4. Unavailable message.

Never show:
- raw API errors
- auth errors
- rate limit messages
- HTML error pages
- empty text as a tafsir card

## Safe API Configuration

Tafsir API access must be opt-in and configured with `--dart-define`. Do not
commit real tokens, client IDs, or `.env` files.

Supported defines:

```text
TAFSIR_API_ENABLED=true
TAFSIR_API_PROVIDER=quran_foundation
TAFSIR_API_BASE_URL=https://api.quran.com/api/v4
TAFSIR_API_AUTH_TOKEN=<content-api-token>
TAFSIR_API_CLIENT_ID=<client-id>
TAFSIR_DEFAULT_RESOURCE_ID=<numeric-resource-id>
```

Temporary QUL preview debug defines:

```text
TAFSIR_API_ENABLED=true
TAFSIR_API_PROVIDER=qul_preview
TAFSIR_DEFAULT_RESOURCE_ID=268
```

Notes:
- `qul_preview` is for internal debug only and is disabled in release builds by
  the provider layer.
- `268` is QUL's Spanish Abridged Explanation of the Quran resource ID.
- The QUL preview page is HTML, not JSON, so the debug client extracts only the
  visible `<div class="tafsir spanish">...</div>` text for one ayah.
- TODO: verify QUL/QuranEnc/Tafsir Center licensing, caching, attribution, and
  redistribution terms before any production or offline use.

Safety rules:
- If `TAFSIR_API_ENABLED` is not `true`, no `TafsirApiClient` is created.
- If token or client id is missing, no `TafsirApiClient` is created.
- Exception: `TAFSIR_API_PROVIDER=qul_preview` does not require Quran
  Foundation auth headers, but it only creates a client in debug builds.
- If `TAFSIR_DEFAULT_RESOURCE_ID` is missing, the debug screen can still accept
  a numeric tafsir ID manually.
- Resource IDs must be numeric; slugs or names are rejected before making a
  request.
- Release builds should not pass these defines until Quran Foundation API terms,
  caching policy, and source selection are approved.

Manual debug run example:

```bash
flutter run \
  --dart-define=TAFSIR_API_ENABLED=true \
  --dart-define=TAFSIR_API_PROVIDER=quran_foundation \
  --dart-define=TAFSIR_API_BASE_URL=https://api.quran.com/api/v4 \
  --dart-define=TAFSIR_API_AUTH_TOKEN=REDACTED \
  --dart-define=TAFSIR_API_CLIENT_ID=REDACTED \
  --dart-define=TAFSIR_DEFAULT_RESOURCE_ID=169
```

QUL Spanish preview debug run example:

```bash
flutter run \
  --dart-define=TAFSIR_API_ENABLED=true \
  --dart-define=TAFSIR_API_PROVIDER=qul_preview \
  --dart-define=TAFSIR_DEFAULT_RESOURCE_ID=268
```

GitHub Actions build behavior:
- The `qiblatime-android-debug` artifact enables the temporary Tafsir test
  flags automatically so internal APK testing can use the QuranScreen Tafsir
  button without running `flutter run` locally.
- Release artifacts (`qiblatime-android-release` and
  `qiblatime-android-release-aab`) do not pass these Tafsir flags, so Tafsir
  remains hidden from public release builds while legal/source review is still
  pending.
- The Settings toggle remains an optional user preference in debug/internal
  builds. The QuranScreen button can still appear when the internal flag allows
  it, and tapping the button opens/enables Tafsir for that ayah.

The temporary debug screen is registered only in debug mode at:

```text
/debug/tafsir
```

It is not exposed in main navigation and is not available in production builds.

## Asset Loading Pattern

Reuse the existing Quran pattern:
- `rootBundle.loadString(...)`
- `json.decode(...)`
- `compute(...)` for large JSON
- static memory cache after first load
- `AppLogger.warning/error` on fallback failures

Suggested top-level parser:

```dart
Map<String, TafsirEntry> parseTafsirJson(String rawJson) {
  // Top-level function for compute().
}
```

## Validation

Before enabling a tafsir resource:
- count entries
- verify every `verseKey`
- verify `surahNumber` and `ayahNumber` match `verseKey`
- verify ayah range against `QuranService.allSurahs`
- detect duplicate verse keys
- detect empty text
- detect mojibake or replacement characters
- detect visible HTML if the UI expects plain text
- generate a report in `scripts/`

Suggested script later:

```text
scripts/audit_tafsir_dataset.js
scripts/tafsir_dataset_audit_report.md
scripts/tafsir_dataset_audit_report.json
```

## UI Minimum

Do not modify main Quran screens in this phase.

Future minimal UI:
- Add a small `Tafsir` button below each ayah, near existing ayah actions.
- Hide the button if no supported tafsir source exists for the current language.
- On tap, open a simple bottom sheet.

Bottom sheet:
- `SafeArea(top: false, bottom: true)`.
- Title: source name.
- Subtitle: `SurahName surah:ayah`.
- Body: tafsir text.
- Footer: source attribution.
- Loading state.
- Clean unavailable state.

Important:
- The button must not interfere with Quran selection mode, audio highlight, tajweed, or share actions.
- Do not auto-scroll when opening tafsir.

## Error Handling

User-facing states:
- Loading tafsir.
- Tafsir unavailable for this ayah.
- Tafsir unavailable offline.
- Unable to load tafsir. Try again.

Internal logging:
- resource id
- language
- verse key
- source attempted
- cache hit/miss
- validation failure
- HTTP status/API error type

Never display technical messages such as:
- `unauthorized`
- `rate_limit_exceeded`
- `gateway_timeout`
- stack traces
- HTML error bodies

## Localization ARB

Add keys when UI is implemented:
- `quranTafsirButton`
- `quranTafsirTitle`
- `quranTafsirLoading`
- `quranTafsirUnavailable`
- `quranTafsirUnavailableOffline`
- `quranTafsirRetry`
- `quranTafsirSource`
- `quranTafsirAttribution`

Add the keys to every ARB file and run `flutter gen-l10n`.

## Tests Minimum

Unit tests:
- parse valid tafsir JSON
- reject empty text
- reject invalid verse key
- reject duplicate verse key
- reject shifted ayah alignment
- strip or preserve HTML according to chosen rendering mode
- fallback order local/cache/API/unavailable

Provider tests:
- provider returns tafsir for supported language
- provider returns unavailable for unsupported language
- provider refreshes when language changes

Widget tests, later:
- `Tafsir` button appears for supported tafsir
- bottom sheet shows source and text
- unavailable state is clean

## Rollout Plan

1. Complete legal verification for one Spanish tafsir resource.
2. Add source metadata and attribution file only after verification.
3. Add models and service with no UI changes.
4. Add parser/audit script and tests.
5. Add local asset or online adapter depending on legal decision.
6. Add UI button behind a simple capability check.
7. Test with Al-Fatiha, 2:255, 18:1, 36:1-5, 112.
8. Only then consider additional languages/resources.

## Release Risks

- Legal risk is the main blocker, not technical implementation.
- Tafsir text can be longer than translations; UI must support long scrollable content.
- Some tafsir resources group multiple ayahs; the app must either model ranges or reject grouped resources for MVP.
- Online-only tafsir can disappoint offline-first users, so unavailable states must be honest and gentle.
- API auth/secrets should not be hardcoded in the Flutter client unless the provider explicitly supports public mobile usage.
