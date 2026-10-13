#!/usr/bin/env python3
"""Regenerate docs/es-review-packet.md from Localizable.xcstrings (#12).
Run from the repo root:  python3 tools/generate_es_packet.py
Keys without letters are pure format-specifier artifacts — skipped."""
import json, re, subprocess

d = json.load(open('MenteViva/Localizable.xcstrings'))['strings']

# Signed off on #12 (2026-10-13, Card Table strings, #160/#161): pre-marked ✅.
SIGNED_OFF = {
    'game.celebration.added', 'game.celebration.next %@', 'game.celebration.today %lld %lld',
    'game.readaloud', 'game.readaloud.hint', 'home.allgames', 'home.greeting.afternoon',
    'home.greeting.evening', 'home.greeting.morning', 'home.today.continue %@',
    'home.today.done', 'home.today.label', 'home.today.play', 'home.today.played',
    'home.today.togo %lld', 'home.week.title',
}


def value(loc):
    """A plain string, or each plural form as 'one: … / other: …'."""
    if 'stringUnit' in loc:
        return loc['stringUnit']['value']
    forms = loc.get('variations', {}).get('plural', {})
    return ' / '.join('%s: %s' % (n, f['stringUnit']['value']) for n, f in forms.items())

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
    en = value(locs.get('en', {})) or k
    es = value(locs.get('es', {}))
    rows.append((k, en, es, where_used(k)))

header = f"""# ES review packet — for the native-speaker pass (#12)

Hand this whole file to the reviewer. Generated from `Localizable.xcstrings`
({len(rows)} user-facing strings; keys that are only format specifiers are omitted).
Rows already signed off on #12 are pre-marked ✅.
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
        mark = '✅' if k in SIGNED_OFF else ''
        f.write('| `%s` | %s | %s | %s | %s |\n' % (esc(k), esc(en), esc(es), used, mark))

print('packet written,', len(rows), 'rows')
