"""Writes chorus_shared/lib/src/symbol_svgs.dart from symbol SVG files.

Usage: python3 -I gen_symbol_svgs.py <out_dart> <svg_dir> [<svg_dir> ...]

Each <word>.svg becomes the entry for that word. The XML prolog, DOCTYPE and
comments are dropped, and ids and style classes are prefixed with the word,
so several symbols can sit inline in one HTML page.
"""
import os
import re
import sys

out_path, svg_dirs = sys.argv[1], sys.argv[2:]

files = {}
for svg_dir in svg_dirs:
    for name in os.listdir(svg_dir):
        if name.endswith('.svg'):
            word = name[:-4].lower()
            assert word not in files, f'{word} is in two folders'
            files[word] = os.path.join(svg_dir, name)

entries = []
for word in sorted(files):
    with open(files[word], encoding='utf-8') as f:
        svg = f.read()
    svg = re.sub(r'<\?xml[^>]*\?>', '', svg)
    svg = re.sub(r'<!DOCTYPE[^>]*(\[[^\]]*\])?\s*>', '', svg, flags=re.S)
    svg = re.sub(r'<!--.*?-->', '', svg, flags=re.S)
    svg = svg.replace('\r\n', '\n').strip()
    svg = re.sub(r'>\s+<', '><', svg)
    assert svg.startswith('<svg'), word
    assert "'''" not in svg, word

    ids = re.findall(r'\bid="([^"]+)"', svg)
    for old in ids:
        new = f'{word}-{old}'
        svg = svg.replace(f'id="{old}"', f'id="{new}"')
        svg = svg.replace(f'url(#{old})', f'url(#{new})')
        svg = svg.replace(f'href="#{old}"', f'href="#{new}"')
    styled = set()
    for css in re.findall(r'<style[^>]*>(.*?)</style>', svg, flags=re.S):
        styled.update(re.findall(r'\.([A-Za-z_][\w-]*)', css))

    def fix_css(m):
        return re.sub(r'\.([A-Za-z_][\w-]*)', lambda c: f'.{word}-{c.group(1)}',
                      m.group(0))

    svg = re.sub(r'<style[^>]*>.*?</style>', fix_css, svg, flags=re.S)

    def fix_class(m):
        parts = [f'{word}-{c}' if c in styled else c for c in m.group(1).split()]
        return 'class="' + ' '.join(parts) + '"'

    svg = re.sub(r'class="([^"]*)"', fix_class, svg)
    entries.append((word, svg))

lines = [
    '// Mulberry Symbols, Copyright 2018-2026 Steve Lee, CC BY-SA 4.0, and',
    '// symbols drawn for Chorus in the same style by the Chorus authors,',
    '// CC BY-SA 4.0 (see STARTER_BOARD_LICENSE.md),',
    '// https://creativecommons.org/licenses/by-sa/4.0/',
    '//',
    '// Generated from the SVG files by chorus_ui/symbols_src/gen_symbol_svgs.py:',
    '// the XML prolog, DOCTYPE and comments are removed, and ids and style',
    '// classes are prefixed with the word so several symbols can sit inline in',
    '// one HTML page. Do not edit by hand.',
    '',
    '/// Picture symbols for the starter words and the ready-made boards, by',
    '/// board word in lower case ("I" is "i"), as inline SVG markup.',
    
    'const Map<String, String> symbolSvgs = {',
]
for word, svg in entries:
    lines.append(f"  '{word}':")
    lines.append(f"      r'''{svg}''',")
lines += [
    '};',
    '',
    '/// The picture symbol for a tile [label], ignoring case and surrounding',
    '/// spaces, or null when there is none.',
    'String? symbolSvgFor(String label) => symbolSvgs[label.trim().toLowerCase()];',
    '',
]
with open(out_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))
print(len(entries), 'symbols')
