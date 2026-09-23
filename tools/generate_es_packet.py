#!/usr/bin/env python3
"""Regenerate docs/es-review-packet.md from Localizable.xcstrings (#12).
Run from the repo root:  python3 tools/generate_es_packet.py
Keys without letters are pure format-specifier artifacts — skipped."""
import json, re, subprocess

d = json.load(open('MenteViva/Localizable.xcstrings'))['strings']

def where_used(key):
    # Explicit calls reference the key verbatim (specifiers included);
    # implicit Text("key \(x)") lookups match the prefix before specifiers.
    prefix = re.split(r' %', key)[0]
    out = subprocess.run(['grep', '-rl', '--include=*.swift', prefix, 'MenteViva/'],
                         capture_output=True, text=True).stdout
    files = sorted({p.split('/')[-1].replace('.swift', '')
                    for p in out.strip().splitlines() if p})
    return ', '.join(files) or '—'

rows = []
for k in sorted(d):
    if not re.search(r'[A-Za-z]', re.sub(r'%(\d+\$)?(lld|@|f|d)', '', k)):
        continue  # pure format-specifier artifact, nothing to translate
    locs = d[k].get('localizations', {})
    en = locs.get('en', {}).get('stringUnit', {}).get('value', '') or k
    es = locs.get('es', {}).get('stringUnit', {}).get('value', '')
    rows.append((k, en, es, where_used(k)))

header = """# ES review packet — for the native-speaker pass (#12)

Hand this whole file to the reviewer. Generated from `Localizable.xcstrings`
(75 user-facing strings; 3 pure format-specifier keys omitted).
Regenerate after any string change: `python3 tools/generate_es_packet.py`.

## What to check, in order

1. **Tone.** Warm and kind, always. A missed answer must never read as
   failure — no «mal», «error», «fallaste». Ceiling is «inténtalo otra vez».
2. **Register.** Pick tú or usted and flag any mix — seniors often expect
   usted; consistency matters more than the choice.
3. **Claims.** Nothing medical. «Ejercicio mental divertido» is the ceiling;
   flag anything that sounds like treatment, prevention or improvement.
4. **Naturalness.** Would a Spanish-speaking abuelo say it this way?
   Mark anything that reads translated.
5. **Length.** ES runs ~20% longer than EN; flag strings that would crowd
   a big button (they show at very large text sizes).

Mark rows: ✅ fine / ✏️ suggestion (write the fix) / ❓ needs context (ask us).

## Strings

| Key | English | Español | Used in | ✓ |
|---|---|---|---|---|
"""

def esc(s):
    return s.replace('|', '\\|').replace('\n', ' ')

with open('docs/es-review-packet.md', 'w') as f:
    f.write(header)
    for k, en, es, used in rows:
        f.write('| `%s` | %s | %s | %s |  |\n' % (esc(k), esc(en), esc(es), used))

print('packet written,', len(rows), 'rows')
