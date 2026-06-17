#!/usr/bin/env python3
"""Generate Qibla Time Quran word-by-word JSON files.

The default source is Quran Foundation's public content API. Their developer
terms allow display of content inside beneficial Quranic applications, but do
not allow caching/storing QF Content longer than one week without permission.
Use this script for validation and pipeline preparation unless Qibla Time has
explicit permission to bundle the generated files.
"""

from __future__ import annotations

import argparse
import json
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any


API_BASE = "https://api.quran.com/api/v4"
DEFAULT_OUTPUT_DIR = Path("_quran_words_generated")
MAX_PER_PAGE = 50
QURAN_FOUNDATION_CACHE_WARNING = (
    "Quran Foundation API content must not be stored for more than one week "
    "without express permission. Do not commit generated output unless the "
    "project has a suitable content license."
)


class PipelineError(RuntimeError):
    pass


def parse_surah_list(raw: str) -> list[int]:
    if raw.strip().lower() == "all":
        return list(range(1, 115))

    surahs: list[int] = []
    for part in raw.split(","):
        value = int(part.strip())
        if value < 1 or value > 114:
            raise PipelineError(f"Invalid surah number: {value}")
        surahs.append(value)

    return sorted(set(surahs))


def get_json(url: str) -> dict[str, Any]:
    request = urllib.request.Request(
        url,
        headers={
            "Accept": "application/json",
            "User-Agent": "QiblaTimeWordPipeline/1.0",
        },
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.loads(response.read().decode("utf-8"))


def load_chapter_counts() -> dict[int, int]:
    data = get_json(f"{API_BASE}/chapters?language=en")
    chapters = data.get("chapters")
    if not isinstance(chapters, list) or len(chapters) != 114:
        raise PipelineError("Could not load 114 chapter metadata entries.")

    counts: dict[int, int] = {}
    for chapter in chapters:
        chapter_id = chapter.get("id")
        verses_count = chapter.get("verses_count")
        if not isinstance(chapter_id, int) or not isinstance(verses_count, int):
            raise PipelineError("Chapter metadata has an unexpected shape.")
        counts[chapter_id] = verses_count
    return counts


def fetch_surah_words(surah_number: int, ayah_count: int) -> list[dict[str, Any]]:
    verses: list[dict[str, Any]] = []
    page = 1
    while True:
        query = urllib.parse.urlencode(
            {
                "language": "en",
                "words": "true",
                "word_fields": "text_uthmani,transliteration,translation",
                "fields": "verse_key",
                "per_page": MAX_PER_PAGE,
                "page": page,
            }
        )
        data = get_json(f"{API_BASE}/verses/by_chapter/{surah_number}?{query}")
        page_verses = data.get("verses")
        if not isinstance(page_verses, list):
            raise PipelineError(f"Surah {surah_number}: missing verses list.")
        verses.extend(page_verses)

        pagination = data.get("pagination")
        next_page = pagination.get("next_page") if isinstance(pagination, dict) else None
        if next_page is None:
            break
        if not isinstance(next_page, int):
            raise PipelineError(f"Surah {surah_number}: invalid pagination.")
        page = next_page

    if len(verses) != ayah_count:
        raise PipelineError(
            f"Surah {surah_number}: expected {ayah_count} ayahs, got {len(verses)}."
        )

    output: list[dict[str, Any]] = []
    for verse in verses:
        ayah_number = verse.get("verse_number")
        if not isinstance(ayah_number, int):
            raise PipelineError(f"Surah {surah_number}: invalid ayah number.")

        words = verse.get("words")
        if not isinstance(words, list):
            raise PipelineError(
                f"Surah {surah_number}:{ayah_number}: missing words list."
            )

        next_position = 1
        for word in words:
            if word.get("char_type_name") != "word":
                continue

            arabic = str(word.get("text_uthmani") or word.get("text") or "").strip()
            transliteration = _nested_text(word.get("transliteration"))
            translation_en = _nested_text(word.get("translation"))

            output.append(
                {
                    "surahNumber": surah_number,
                    "ayahNumber": ayah_number,
                    "position": next_position,
                    "arabic": arabic,
                    "transliteration": transliteration,
                    "translations": {
                        "en": translation_en,
                    },
                }
            )
            next_position += 1

    return output


def _nested_text(value: Any) -> str:
    if isinstance(value, dict):
        raw = value.get("text")
        return "" if raw is None else str(raw).strip()
    return ""


def validate_surah_words(
    surah_number: int,
    ayah_count: int,
    words: list[dict[str, Any]],
) -> list[str]:
    errors: list[str] = []
    by_ayah: dict[int, list[dict[str, Any]]] = {}

    for index, word in enumerate(words):
        if word.get("surahNumber") != surah_number:
            errors.append(f"row {index}: wrong surahNumber")
        ayah_number = word.get("ayahNumber")
        if not isinstance(ayah_number, int) or ayah_number < 1 or ayah_number > ayah_count:
            errors.append(f"row {index}: invalid ayahNumber")
            continue
        by_ayah.setdefault(ayah_number, []).append(word)
        if not str(word.get("arabic") or "").strip():
            errors.append(f"{surah_number}:{ayah_number}: empty arabic")
        translations = word.get("translations")
        if not isinstance(translations, dict) or not str(translations.get("en") or "").strip():
            errors.append(f"{surah_number}:{ayah_number}: empty translations.en")
        transliteration = word.get("transliteration")
        if transliteration is not None and not isinstance(transliteration, str):
            errors.append(f"{surah_number}:{ayah_number}: invalid transliteration")

    missing_ayahs = [ayah for ayah in range(1, ayah_count + 1) if ayah not in by_ayah]
    if missing_ayahs:
        errors.append(f"missing ayahs: {missing_ayahs[:10]}")

    for ayah_number, ayah_words in by_ayah.items():
        positions = [word.get("position") for word in ayah_words]
        expected = list(range(1, len(ayah_words) + 1))
        if positions != expected:
            errors.append(
                f"{surah_number}:{ayah_number}: positions {positions} != {expected}"
            )

    return errors


def write_surah_file(output_dir: Path, surah_number: int, words: list[dict[str, Any]]) -> Path:
    output_dir.mkdir(parents=True, exist_ok=True)
    path = output_dir / f"surah_{surah_number:03d}.json"
    path.write_text(
        json.dumps({"words": words}, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    return path


def validate_output_directory(output_dir: Path, expected_surahs: list[int]) -> None:
    files = sorted(output_dir.glob("surah_*.json"))
    expected_names = {f"surah_{surah:03d}.json" for surah in expected_surahs}
    actual_names = {path.name for path in files}
    missing = expected_names - actual_names
    extra = actual_names - expected_names
    if missing or extra:
        raise PipelineError(
            f"Output file mismatch. Missing={sorted(missing)} extra={sorted(extra)}"
        )
    for path in files:
        json.loads(path.read_text(encoding="utf-8"))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--surahs",
        default="1,112,113,114",
        help='Comma-separated surah numbers, or "all". Default: 1,112,113,114.',
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help=f"Output directory. Default: {DEFAULT_OUTPUT_DIR}",
    )
    parser.add_argument(
        "--delay",
        type=float,
        default=0.2,
        help="Delay between API calls in seconds.",
    )
    args = parser.parse_args()

    print(f"WARNING: {QURAN_FOUNDATION_CACHE_WARNING}", file=sys.stderr)
    surahs = parse_surah_list(args.surahs)
    counts = load_chapter_counts()

    generated: list[Path] = []
    total_words = 0
    for surah_number in surahs:
        ayah_count = counts[surah_number]
        words = fetch_surah_words(surah_number, ayah_count)
        errors = validate_surah_words(surah_number, ayah_count, words)
        if errors:
            raise PipelineError(
                f"Validation failed for surah {surah_number}: " + "; ".join(errors[:8])
            )
        generated.append(write_surah_file(args.output_dir, surah_number, words))
        total_words += len(words)
        print(f"surah {surah_number:03d}: {len(words)} words")
        if args.delay:
            time.sleep(args.delay)

    validate_output_directory(args.output_dir, surahs)
    print(f"generated_files={len(generated)} total_words={total_words}")
    print(f"output_dir={args.output_dir}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except PipelineError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        raise SystemExit(1)
