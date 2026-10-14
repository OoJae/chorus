"""Writes the ready-made boards in chorus_ui/assets/boards/ as Open Board
Format 0.1 files: 24 words each, 4 rows of 6, with the Fitzgerald-style
colour of each word as the app's colour key (`colorForKey` in chorus_shared)
writes it. Nouns are plain (white).

Usage: python3 -I make_ready_boards.py <out_dir>
"""
import json
import os
import sys

# The light fills of `colorForKey`, as the app writes them in an export.
COLOURS = {
    'verb': 'rgb(199, 239, 178)',
    'pronoun': 'rgb(255, 239, 160)',
    'question': 'rgb(221, 203, 255)',
    'descriptor': 'rgb(192, 219, 255)',
    'determiner': 'rgb(229, 228, 224)',
    'negation': 'rgb(255, 210, 174)',
    None: 'rgb(255, 255, 255)',
}
V, P, Q, D, N, X = 'verb', 'pronoun', 'question', 'descriptor', None, 'negation'

BOARDS = [
    ('food', 'Food', [
        ('eat', V), ('drink', V), ('hungry', D), ('thirsty', D), ('yummy', D), ('yucky', D),
        ('water', N), ('milk', N), ('juice', N), ('apple', N), ('banana', N), ('grapes', N),
        ('bread', N), ('toast', N), ('cereal', N), ('yogurt', N), ('cheese', N), ('egg', N),
        ('pasta', N), ('rice', N), ('chicken', N), ('pizza', N), ('biscuit', N), ('ice cream', N),
    ]),
    ('people', 'People', [
        ('mum', P), ('dad', P), ('baby', P), ('brother', P), ('sister', P), ('family', P),
        ('grandma', P), ('grandpa', P), ('aunt', P), ('uncle', P), ('cousin', P), ('friend', P),
        ('teacher', P), ('helper', P), ('doctor', P), ('nurse', P), ('dentist', P), ('driver', P),
        ('me', P), ('my', P), ('we', P), ('they', P), ('your', P), ('mine', P),
    ]),
    ('places', 'Places', [
        ('go', V), ('come', V), ('where', Q), ('home', N), ('school', N), ('outside', D),
        ('park', N), ('playground', N), ('shop', N), ('library', N), ('swimming pool', N), ('beach', N),
        ('garden', N), ('zoo', N), ('farm', N), ('cafe', N), ('car', N), ('bus', N),
        ('bedroom', N), ('bathroom', N), ('kitchen', N), ('toilet', N), ('bed', N), ('upstairs', D),
    ]),
    ('feelings', 'Feelings', [
        ('happy', D), ('sad', D), ('angry', D), ('scared', D), ('tired', D), ('excited', D),
        ('calm', D), ('silly', D), ('worried', D), ('cross', D), ('proud', D), ('bored', D),
        ('hurt', D), ('sick', D), ('hot', D), ('cold', D), ('okay', D), ('quiet', D),
        ('I', P), ('feel', V), ('not', X), ('help', V), ('hug', V), ('break', N),
    ]),
    ('actions', 'Actions', [
        ('play', V), ('eat', V), ('drink', V), ('sleep', V), ('wash', V), ('read', V),
        ('run', V), ('walk', V), ('jump', V), ('climb', V), ('swim', V), ('sit', V),
        ('open', V), ('close', V), ('give', V), ('take', V), ('push', V), ('pull', V),
        ('watch', V), ('listen', V), ('sing', V), ('dance', V), ('draw', V), ('build', V),
    ]),
    ('describing', 'Describing words', [
        ('big', D), ('little', D), ('hot', D), ('cold', D), ('wet', D), ('dry', D),
        ('fast', D), ('slow', D), ('loud', D), ('quiet', D), ('soft', D), ('hard', D),
        ('clean', D), ('dirty', D), ('full', D), ('empty', D), ('new', D), ('old', D),
        ('red', D), ('blue', D), ('green', D), ('yellow', D), ('funny', D), ('broken', D),
    ]),
]

out = sys.argv[1]
os.makedirs(out, exist_ok=True)
for slug, name, words in BOARDS:
    assert len(words) == 24, slug
    assert len({w for w, _ in words}) == 24, slug
    buttons = []
    order = [[None] * 6 for _ in range(4)]
    for i, (label, key) in enumerate(words):
        bid = f'{slug}-{i + 1}'
        buttons.append({
            'id': bid,
            'label': label,
            'background_color': COLOURS[key],
            'border_color': 'rgb(169, 168, 163)',
        })
        order[i // 6][i % 6] = bid
    board = {
        'format': 'open-board-0.1',
        'id': f'chorus-ready-{slug}',
        'locale': 'en',
        'name': name,
        'description_html': f'A ready-made {name.lower()} board from Chorus: '
                            f'24 words for a young child.',
        'buttons': buttons,
        'grid': {'rows': 4, 'columns': 6, 'order': order},
        'images': [],
        'sounds': [],
        'license': {
            'type': 'CC By-SA',
            'copyright_notice_url': 'https://creativecommons.org/licenses/by-sa/4.0/',
            'author_name': 'The Chorus authors',
        },
    }
    with open(os.path.join(out, f'{slug}.obf'), 'w', encoding='utf-8') as fh:
        json.dump(board, fh, indent=1, ensure_ascii=False)
        fh.write('\n')
print('wrote', len(BOARDS), 'boards')
