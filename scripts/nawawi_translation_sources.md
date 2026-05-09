# Nawawi Translation Sources - Working Notes

Scope: identify legally usable offline translations for the 23 `40 Hadith Nawawi` entries cleaned in `assets/data/hadiths_multilang_v2.json`.

No translations were imported in this step.

## Target Hadiths

These app IDs currently need valid replacements for `es`, `fr`, `de`, and `pt`:

`80202`, `80204`, `80206`, `80208`, `80210`, `80219`, `80222`, `80223`, `80224`, `80225`, `80226`, `80227`, `80228`, `80229`, `80230`, `80231`, `80232`, `80235`, `80236`, `80237`, `80238`, `80240`, `80242`.

## Candidate Source: HadeethEnc

- URL: https://hadeethenc.com/es/home
- Downloads checked:
  - Spanish Excel: https://hadeethenc.com/browse/download/es
  - French Excel: https://hadeethenc.com/browse/download/fr
  - German Excel: https://hadeethenc.com/browse/download/de
  - Portuguese Excel: https://hadeethenc.com/browse/download/pt
- Publisher/editor: HadeethEnc.com project.
- Author/editor shown by project: Encyclopedia of Translated Prophetic Hadiths.
- License / permission found: the site states that translation contents can be downloaded and republished if its stated conditions are followed.
- Modification allowed: No. The terms require no modification, addition, or deletion of the content.
- Attribution required: Yes. Must clearly refer to HadeethEnc.com as publisher/source.
- Version required: Yes. Must mention the source version number when republishing.
- Transcript metadata required: Yes. Must keep the document transcript/source information.
- Other requirements:
  - Notify HadeethEnc.com of notes on the translation.
  - Keep translations updated according to newer source versions.
  - Avoid inappropriate advertisements when displaying hadith content.
- App use assessment: usable in a free app only if imported verbatim, with attribution/version metadata and no inappropriate ads around the content.

### Source Versions Observed

- `es`: v1.21.0, last update 2026-01-06 21:59:46
- `fr`: v1.16.0, last update 2026-01-08 11:29:15
- `de`: v1.47.0, last update 2026-04-22 18:38:45
- `pt`: v1.28.0, last update 2025-11-12 00:13:47

### Coverage Confirmed

HadeethEnc Excel rows contain matching hadith text for all 23 target Nawawi entries in `es`, `fr`, `de`, and `pt`.

| App hadith ID | Nawawi ref | HadeethEnc source ID |
|---:|---|---:|
| 80202 | 40 Hadith Nawawi 2 | 4563 |
| 80204 | 40 Hadith Nawawi 4 | 66513 |
| 80206 | 40 Hadith Nawawi 6 | 66515 |
| 80208 | 40 Hadith Nawawi 8 | 4211 |
| 80210 | 40 Hadith Nawawi 10 | 66518 |
| 80219 | 40 Hadith Nawawi 19 | 66522 |
| 80222 | 40 Hadith Nawawi 22 | 66525 |
| 80223 | 40 Hadith Nawawi 23 | 66526 |
| 80224 | 40 Hadith Nawawi 24 | 4810 |
| 80225 | 40 Hadith Nawawi 25 | 66527 |
| 80226 | 40 Hadith Nawawi 26 | 4568 |
| 80227 | 40 Hadith Nawawi 27 | 66540 |
| 80228 | 40 Hadith Nawawi 28 | 66529 |
| 80229 | 40 Hadith Nawawi 29 | 66530 |
| 80230 | 40 Hadith Nawawi 30 | 66510 |
| 80231 | 40 Hadith Nawawi 31 | 4307 |
| 80232 | 40 Hadith Nawawi 32 | 66531 |
| 80235 | 40 Hadith Nawawi 35 | 4706 |
| 80236 | 40 Hadith Nawawi 36 | 4801 |
| 80237 | 40 Hadith Nawawi 37 | 66533 |
| 80238 | 40 Hadith Nawawi 38 | 66534 |
| 80240 | 40 Hadith Nawawi 40 | 4704 |
| 80242 | 40 Hadith Nawawi 42 | 5456 |

## Candidate Source: 40hadith.com

- URL: https://www.40hadith.com/
- Languages observed: German, English, Spanish, French, Japanese, Italian, Indonesian, Dutch, Russian, Albanian, Finnish, Swedish, Turkish.
- Publisher/editor: not clearly identified on page.
- License / permission found: no clear reuse license found.
- Modification allowed: not stated.
- Attribution required: not stated.
- App use assessment: not safe for importing into app assets without explicit permission.

## Candidate Source: 40-hadith-nawawi.com

- URL: https://www.40-hadith-nawawi.com/
- Language observed: French with Arabic and phonetic text.
- Publisher/editor: site-branded "40 Hadith Nawawi".
- License / permission found: page shows copyright notice.
- Modification allowed: not stated.
- Attribution required: not enough for reuse without permission.
- App use assessment: discard for import unless explicit written permission is obtained.

## Candidate Source: Qalima

- URL: https://qalima.com/hadiths
- Language observed: French.
- Publisher/editor: Qalima.
- License / permission found: no reuse license found on the checked page.
- Modification allowed: not stated.
- Attribution required: not stated.
- App use assessment: not safe for import without explicit permission.

## Candidate Source: Sunnah.com

- URL: https://sunnah.com/nawawi40
- Language observed: English only for the relevant collection.
- License / permission found: no clear license for reuse into app assets found during this audit.
- App use assessment: not useful for `es/fr/de/pt`; do not use for this task.

## Candidate Source: Mumin API

- URL: https://docs.mumin.ink/
- Type: commercial/API product.
- Language coverage observed: primarily Arabic/English, with AI-assisted language support described for other languages.
- License / permission found: API product terms must be checked before redistribution; not an offline reusable text source by default.
- App use assessment: not suitable for this offline-assets task.
