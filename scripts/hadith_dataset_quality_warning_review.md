# Hadith Dataset Quality Warning Review

Generated: 2026-05-10

Scope: review after correcting the 16 real warnings previously reported by `scripts/hadith_dataset_quality_report.md`.

## Result

- Warnings after correction: 0.
- Critical issues after correction: 0.
- Medium issues after correction: 0.

The previous 16 warnings represented 10 underlying translation problems:

- 6 Spanish Nawawi entries contained English text.
- 4 Italian entries duplicated English text.
- 6 duplicate warnings were secondary confirmations of the Spanish Nawawi issue.

## Corrected Spanish Nawawi Entries

These entries were replaced with verbatim HadeethEnc Spanish text.

| Collection | Hadith ID | Language | Source | HadeethEnc ID | Verdict | Action |
|---|---:|---|---|---:|---|---|
| 40 Hadith Nawawi | 80220 | es | HadeethEnc | 66523 | Incorrect translation fixed | Imported verified Spanish text. |
| 40 Hadith Nawawi | 80221 | es | HadeethEnc | 66524 | Incorrect translation fixed | Imported verified Spanish text. |
| 40 Hadith Nawawi | 80233 | es | HadeethEnc | 66532 | Incorrect translation fixed | Imported verified Spanish text. |
| 40 Hadith Nawawi | 80234 | es | HadeethEnc | 65001 | Incorrect translation fixed | Imported verified Spanish text. |
| 40 Hadith Nawawi | 80239 | es | HadeethEnc | 4216 | Incorrect translation fixed | Imported verified Spanish text. |
| 40 Hadith Nawawi | 80241 | es | HadeethEnc | 66535 | Incorrect translation fixed | Imported verified Spanish text. |

## Cleared Italian Entries

These entries duplicated English text. HadeethEnc Italian was checked, but no clear matching Italian source was found for these four hadiths, so the incorrect Italian text was cleared instead of leaving English under `it`.

| Collection | Hadith ID | Language | Previous issue | Verdict | Action |
|---|---:|---|---|---|---|
| Sahih al-Bukhari | 4820 | it | Exact duplicate of English | Incorrect translation fixed | Cleared Italian text and marked unavailable due to no legal source found. |
| Sahih Muslim | 6380 | it | Exact duplicate of English | Incorrect translation fixed | Cleared Italian text and marked unavailable due to no legal source found. |
| Sahih al-Bukhari | 6604 | it | Exact duplicate of English | Incorrect translation fixed | Cleared Italian text and marked unavailable due to no legal source found. |
| Sahih al-Bukhari | 8301 | it | Exact duplicate of English | Incorrect translation fixed | Cleared Italian text and marked unavailable due to no legal source found. |

## Validation

- `node scripts/audit_hadith_dataset_quality.js`: PASS.
- Final issues: 0.
- Arabic changed: 0.
- Non-target hadith changed: 0.

Detailed correction data is stored in `scripts/hadith_quality_warning_fix_report.json`.
