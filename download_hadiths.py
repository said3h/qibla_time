import urllib.request, json, time

def fetch(url, retries=3):
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers={
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                'Accept': 'application/json',
                'Referer': 'https://github.com/'
            })
            with urllib.request.urlopen(req, timeout=20) as r:
                return json.loads(r.read().decode('utf-8'))
        except Exception as e:
            print(f'  Error (attempt {attempt+1}/{retries}): {e}')
            if attempt < retries - 1:
                time.sleep(2)
    return None

base = 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions'

print('Descargando 40 Hadith Nawawi...')
nawawi_en = fetch(f'{base}/eng-nawawi.json')
if nawawi_en:
    print(f'  OK: {len(nawawi_en.get("hadiths", []))} hadiths')
    time.sleep(1.5)
else:
    print('  FAILED to download Nawawi English')

nawawi_ar = fetch(f'{base}/ara-nawawi.json')
if nawawi_ar:
    print(f'  OK: {len(nawawi_ar.get("hadiths", []))} hadiths')
    time.sleep(1.5)
else:
    print('  FAILED to download Nawawi Arabic')

print('\nDescargando Riyad as-Salihin...')
riyad_en = fetch(f'{base}/eng-riyadussalihin.json')
if riyad_en:
    print(f'  OK: {len(riyad_en.get("hadiths", []))} hadiths')
    time.sleep(1.5)
else:
    print('  FAILED to download Riyad English')

riyad_ar = fetch(f'{base}/ara-riyadussalihin.json')
if riyad_ar:
    print(f'  OK: {len(riyad_ar.get("hadiths", []))} hadiths')
    time.sleep(1.5)
else:
    print('  FAILED to download Riyad Arabic')

def build_entries(en_data, ar_data, collection_name, ref_prefix):
    if not en_data or not ar_data:
        print(f'  Skipping {collection_name} - missing data')
        return []
    
    hadiths = []
    en_list = en_data.get('hadiths', [])
    ar_list = ar_data.get('hadiths', [])
    ar_map = {h['hadithnumber']: h for h in ar_list}
    
    for i, en_h in enumerate(en_list):
        num = en_h.get('hadithnumber', i+1)
        ar_h = ar_map.get(num, {})
        arabic_text = ar_h.get('text', ar_h.get('arab', ''))
        english_text = en_h.get('text', '')
        reference = f'{ref_prefix} {num}'
        
        entry = {
            'id': 90000 + (10000 if 'nawawi' in ref_prefix.lower() else 0) + num,
            'arabic': arabic_text,
            'translations': {
                'es': {
                    'text': english_text,
                    'reference': reference,
                    'grade': 'Sahih',
                    'title': '',
                    'category': ''
                },
                'en': {
                    'text': english_text,
                    'reference': reference,
                    'grade': 'Sahih',
                    'title': '',
                    'category': ''
                },
                'ar': {
                    'text': arabic_text,
                    'reference': reference,
                    'grade': 'Sahih',
                    'title': '',
                    'category': ''
                },
                'fr': {
                    'arabic': arabic_text,
                    'translation': english_text,
                    'reference': reference,
                    'grade': 'Sahih',
                    'category': ''
                }
            }
        }
        hadiths.append(entry)
    return hadiths

nawawi_entries = build_entries(nawawi_en, nawawi_ar, '40 Hadith Nawawi', '40 Hadith Nawawi')
riyad_entries = build_entries(riyad_en, riyad_ar, 'Riyad as-Salihin', 'Riyad as-Salihin')

all_new = nawawi_entries + riyad_entries
print(f'\nNawawi: {len(nawawi_entries)} hadiths')
print(f'Riyad: {len(riyad_entries)} hadiths')
print(f'Total: {len(all_new)} hadiths')

if all_new:
    with open('new_hadiths.json', 'w', encoding='utf-8') as f:
        json.dump(all_new, f, ensure_ascii=False, indent=2)
    print('Guardado en new_hadiths.json')
else:
    print('No data to save')
