# Nawawi Translation Source Audit

Goal: find legally usable offline translations for the 23 cleaned `40 Hadith Nawawi` entries in Spanish, French, German, and Portuguese.

No changes were made to `assets/data/hadiths_multilang_v2.json` in this step.

## Summary

One source is usable with conditions: HadeethEnc.

HadeethEnc covers all 23 target Nawawi hadiths in all four requested languages:

- `es`: Nawawi 2, 4, 6, 8, 10, 19, 22-32, 35-38, 40, 42.
- `fr`: Nawawi 2, 4, 6, 8, 10, 19, 22-32, 35-38, 40, 42.
- `de`: Nawawi 2, 4, 6, 8, 10, 19, 22-32, 35-38, 40, 42.
- `pt`: Nawawi 2, 4, 6, 8, 10, 19, 22-32, 35-38, 40, 42.

## Fuentes Seguras

### HadeethEnc

- URL: https://hadeethenc.com/es/home
- Downloads:
  - `es`: https://hadeethenc.com/browse/download/es
  - `fr`: https://hadeethenc.com/browse/download/fr
  - `de`: https://hadeethenc.com/browse/download/de
  - `pt`: https://hadeethenc.com/browse/download/pt
- Publisher/editor: HadeethEnc.com.
- License / permission status: usable with stated republication conditions.
- Allows modification: No.
- Requires attribution: Yes.
- Requires version/source metadata: Yes.
- Suitable for a free app: Yes, if imported verbatim and attribution/version information is shown or otherwise included clearly.
- Important condition for Qibla Time: because modification is not allowed, do not edit, summarize, modernize spelling, or normalize punctuation in imported translations.

Observed source versions:

| Language | Version | Last update |
|---|---|---|
| es | v1.21.0 | 2026-01-06 21:59:46 |
| fr | v1.16.0 | 2026-01-08 11:29:15 |
| de | v1.47.0 | 2026-04-22 18:38:45 |
| pt | v1.28.0 | 2025-11-12 00:13:47 |

Coverage:

| App hadith ID | Nawawi ref | HadeethEnc ID | es | fr | de | pt |
|---:|---|---:|---|---|---|---|
| 80202 | 40 Hadith Nawawi 2 | 4563 | yes | yes | yes | yes |
| 80204 | 40 Hadith Nawawi 4 | 66513 | yes | yes | yes | yes |
| 80206 | 40 Hadith Nawawi 6 | 66515 | yes | yes | yes | yes |
| 80208 | 40 Hadith Nawawi 8 | 4211 | yes | yes | yes | yes |
| 80210 | 40 Hadith Nawawi 10 | 66518 | yes | yes | yes | yes |
| 80219 | 40 Hadith Nawawi 19 | 66522 | yes | yes | yes | yes |
| 80222 | 40 Hadith Nawawi 22 | 66525 | yes | yes | yes | yes |
| 80223 | 40 Hadith Nawawi 23 | 66526 | yes | yes | yes | yes |
| 80224 | 40 Hadith Nawawi 24 | 4810 | yes | yes | yes | yes |
| 80225 | 40 Hadith Nawawi 25 | 66527 | yes | yes | yes | yes |
| 80226 | 40 Hadith Nawawi 26 | 4568 | yes | yes | yes | yes |
| 80227 | 40 Hadith Nawawi 27 | 66540 | yes | yes | yes | yes |
| 80228 | 40 Hadith Nawawi 28 | 66529 | yes | yes | yes | yes |
| 80229 | 40 Hadith Nawawi 29 | 66530 | yes | yes | yes | yes |
| 80230 | 40 Hadith Nawawi 30 | 66510 | yes | yes | yes | yes |
| 80231 | 40 Hadith Nawawi 31 | 4307 | yes | yes | yes | yes |
| 80232 | 40 Hadith Nawawi 32 | 66531 | yes | yes | yes | yes |
| 80235 | 40 Hadith Nawawi 35 | 4706 | yes | yes | yes | yes |
| 80236 | 40 Hadith Nawawi 36 | 4801 | yes | yes | yes | yes |
| 80237 | 40 Hadith Nawawi 37 | 66533 | yes | yes | yes | yes |
| 80238 | 40 Hadith Nawawi 38 | 66534 | yes | yes | yes | yes |
| 80240 | 40 Hadith Nawawi 40 | 4704 | yes | yes | yes | yes |
| 80242 | 40 Hadith Nawawi 42 | 5456 | yes | yes | yes | yes |

## Fuentes Dudosas

### 40hadith.com

- URL: https://www.40hadith.com/
- Reason: has several target languages, but no clear reuse license was found.
- Risk: translations may be copyrighted even if publicly accessible.
- Recommendation: do not import unless written permission is obtained.

### Qalima

- URL: https://qalima.com/hadiths
- Reason: French Nawawi collection is visible, but no clear reuse license was found.
- Risk: public reading access does not equal redistribution permission.
- Recommendation: do not import without permission.

### Mumin API

- URL: https://docs.mumin.ink/
- Reason: API/commercial product, not an offline reusable source by default.
- Risk: API output and generated/AI translations may not be redistributable as static app assets.
- Recommendation: not suitable for this offline import.

## Fuentes Descartadas

### 40-hadith-nawawi.com

- URL: https://www.40-hadith-nawawi.com/
- Reason: page shows copyright notice and no explicit reuse permission.
- Coverage: French collection appears complete, but legal status is not suitable for import.
- Recommendation: discard unless written permission is granted.

### Sunnah.com

- URL: https://sunnah.com/nawawi40
- Reason: English only for this need and no clear license found for offline redistribution.
- Recommendation: discard for this `es/fr/de/pt` task.

### Commercial books, bookstores, Amazon, Google Books, PDFs without explicit license

- Reason: no redistribution rights.
- Recommendation: do not use.

## Recommended Next Step

Proceed with HadeethEnc only, but import carefully:

1. Add attribution/version metadata for HadeethEnc in the app or in bundled data.
2. Import the 23 target translations for `es`, `fr`, `de`, and `pt` verbatim from the Excel files.
3. Do not modify the imported text.
4. Keep a script that maps Qibla Time hadith IDs to HadeethEnc IDs.
5. Re-run the technical-error audit after import.
6. Keep the mapper-level invalid-translation filter as a safety net.

If attribution cannot be shown or the no-modification condition is unacceptable, leave these translations empty and rely on the mapper fallback instead.


## Import Status

Imported: 2026-05-09T21:18:08.289Z

- Source used: HadeethEnc only.
- Import policy: verbatim text only; no editing, summarizing, correcting, or adapting.
- App data file updated: `assets/data/hadiths_multilang_v2.json`.
- Attribution metadata file: `assets/data/third_party_sources.json`.
- Imported translations: 92.
- Pending translations after import: 0.

Imported source versions:

| Language | Version | Last update |
|---|---|---|
| es | v1.21.0 | 2026-01-06 21:59:46 |
| fr | v1.16.0 | 2026-01-08 11:29:15 |
| de | v1.47.0 | 2026-04-22 18:38:45 |
| pt | v1.28.0 | 2025-11-12 00:13:47 |
