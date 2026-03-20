#!/usr/bin/env python3
"""
generate_quran_offline.py
─────────────────────────
Descarga el Corán completo (114 suras) desde api.alquran.cloud
y genera assets/data/quran_offline.json con árabe + español + transliteración.

USO:
    pip install requests
    python generate_quran_offline.py

El archivo resultante va en:
    assets/data/quran_offline.json

Tiempo estimado: 3-6 minutos (342 peticiones en paralelo).
Tamaño esperado: ~9-11 MB.
"""

import json
import time
import requests
from concurrent.futures import ThreadPoolExecutor, as_completed

BASE_URL = "https://api.alquran.cloud/v1"

# Ediciones que usamos
ARABIC_EDITION      = "ar.alafasy"       # árabe con recitación
SPANISH_EDITION     = "es.asad"          # traducción española
TRANSLIT_EDITION    = "en.transliteration"  # transliteración

OUTPUT_FILE = "assets/data/quran_offline.json"


def fetch_surah(number: int) -> dict | None:
    """Descarga una sura con los 3 textos. Reintenta hasta 3 veces."""
    url = f"{BASE_URL}/surah/{number}/editions/{ARABIC_EDITION},{SPANISH_EDITION},{TRANSLIT_EDITION}"

    for attempt in range(3):
        try:
            resp = requests.get(url, timeout=15)
            if resp.status_code == 200:
                return resp.json()
            time.sleep(1)
        except Exception as e:
            if attempt == 2:
                print(f"  ✗ Sura {number} falló después de 3 intentos: {e}")
            time.sleep(2)

    return None


def parse_surah(raw: dict, number: int) -> dict | None:
    """Extrae árabe, español y transliteración de la respuesta de la API."""
    try:
        editions = raw["data"]  # lista de 3 ediciones

        arabic_data  = next(e for e in editions if e["edition"]["identifier"] == ARABIC_EDITION)
        spanish_data = next(e for e in editions if e["edition"]["identifier"] == SPANISH_EDITION)
        translit_data= next(e for e in editions if e["edition"]["identifier"] == TRANSLIT_EDITION)

        arabic_ayahs  = arabic_data["ayahs"]
        spanish_ayahs = spanish_data["ayahs"]
        translit_ayahs= translit_data["ayahs"]

        ayahs = []
        for i, ayah in enumerate(arabic_ayahs):
            ayahs.append({
                "number":          ayah["number"],
                "numberInSurah":   ayah["numberInSurah"],
                "arabic":          ayah["text"],
                "transliteration": translit_ayahs[i]["text"] if i < len(translit_ayahs) else "",
                "translation":     spanish_ayahs[i]["text"]  if i < len(spanish_ayahs)  else "",
                "audioUrl": f"https://cdn.islamic.network/quran/audio/128/ar.alafasy/{ayah['number']}.mp3",
            })

        return {"ayahs": ayahs}

    except Exception as e:
        print(f"  ✗ Error parseando sura {number}: {e}")
        return None


def main():
    print("QiblaTime — Generando quran_offline.json")
    print("=" * 50)
    print(f"Descargando 114 suras con árabe + español + transliteración...")
    print()

    result = {"surahs": {}}
    failed = []

    # Descarga en paralelo con máximo 5 conexiones simultáneas
    # (la API tiene rate limiting, no subas de 5)
    with ThreadPoolExecutor(max_workers=5) as executor:
        futures = {
            executor.submit(fetch_surah, n): n
            for n in range(1, 115)
        }

        completed = 0
        for future in as_completed(futures):
            number = futures[future]
            raw = future.result()

            if raw:
                parsed = parse_surah(raw, number)
                if parsed:
                    result["surahs"][str(number)] = parsed
                    completed += 1
                    print(f"  ✓ Sura {number:3d}/114", end="\r")
                else:
                    failed.append(number)
            else:
                failed.append(number)

    print(f"\n  ✓ Completadas: {completed}/114")

    if failed:
        print(f"  ✗ Fallidas:    {failed}")
        print("    Vuelve a ejecutar el script para reintentar las fallidas.")

    # Guardar
    import os
    os.makedirs("assets/data", exist_ok=True)

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, separators=(",", ":"))

    size_mb = os.path.getsize(OUTPUT_FILE) / (1024 * 1024)
    print(f"\n  ✅ Guardado en: {OUTPUT_FILE}")
    print(f"  📦 Tamaño:      {size_mb:.1f} MB")
    print()
    print("Siguiente paso:")
    print("  Añade a pubspec.yaml:")
    print("    assets:")
    print("      - assets/data/quran_offline.json")
    print()
    print("  Luego: flutter clean && flutter pub get && flutter run")


if __name__ == "__main__":
    main()
