import 'package:chorus_shared/chorus_shared.dart';
import 'package:test/test.dart';

const _board = '11111111-1111-4111-8111-111111111111';
const _tileId = '22222222-2222-4222-8222-222222222222';
const _otherTileId = '33333333-3333-4333-8333-333333333333';

final _t0 = DateTime.utc(2026, 10, 13, 9);

TileFacts _tile({
  String id = _tileId,
  String label = 'biscuit',
  String? speech,
  String? colorKey,
  bool archived = false,
}) =>
    TileFacts(
      id: id,
      boardId: _board,
      cellKey: archived ? trayKey(id) : placedKey(_board, 0, 0),
      label: label,
      speech: speech,
      colorKey: colorKey,
      archived: archived,
    );

/// An edit by [by], [minute] minutes after the start, built on [base].
EditFacts _edit(
  String id,
  String by, {
  required String? from,
  required String? to,
  String? base,
  int minute = 0,
  String prop = 'label',
  String reason = 'edit',
  String tileId = _tileId,
}) =>
    EditFacts(
      id: id,
      tileId: tileId,
      prop: prop,
      oldValue: from,
      newValue: to,
      baseEditId: base,
      reason: reason,
      actorId: 'user-$by',
      actorName: by,
      editedAt: _t0.add(Duration(minutes: minute)),
    );

/// The word was added as "cookie"; every scenario builds on this edit.
final _added = _edit('add', 'Mum', from: null, to: 'cookie', reason: 'add');

void main() {
  group('no overwrite', () {
    test('an empty log, or a tile with one edit', () {
      expect(detectOverwrites(const [], [_tile()]), isEmpty);
      expect(detectOverwrites([_added], [_tile(label: 'cookie')]), isEmpty);
    });

    test('one author changing their mind, edit after edit', () {
      final edits = [
        _added,
        _edit('m1', 'Mum', from: 'cookie', to: 'snack', base: 'add', minute: 1),
        _edit('m2', 'Mum', from: 'snack', to: 'treat', base: 'm1', minute: 2),
        _edit('m3', 'Mum', from: 'treat', to: 'biscuit', base: 'm2', minute: 3),
      ];
      expect(detectOverwrites(edits, [_tile()]), isEmpty);
    });

    test('one author going back to an earlier value', () {
      final edits = [
        _added,
        _edit('m1', 'Mum', from: 'cookie', to: 'snack', base: 'add', minute: 1),
        _edit('m2', 'Mum', from: 'snack', to: 'cookie', base: 'm1', minute: 2),
      ];
      expect(detectOverwrites(edits, [_tile(label: 'cookie')]), isEmpty);
    });

    test('two adults taking turns, each seeing the other', () {
      final edits = [
        _added,
        _edit('m1', 'Mum', from: 'cookie', to: 'snack', base: 'add', minute: 1),
        _edit('t1', 'Teacher',
            from: 'snack', to: 'biscuit', base: 'm1', minute: 2),
      ];
      expect(detectOverwrites(edits, [_tile()]), isEmpty);
    });

    test('sequential edits whose clocks run backwards', () {
      final edits = [
        _added,
        _edit('m1', 'Mum', from: 'cookie', to: 'snack', base: 'add', minute: 9),
        _edit('t1', 'Teacher',
            from: 'snack', to: 'biscuit', base: 'm1', minute: 1),
      ];
      expect(detectOverwrites(edits, [_tile()]), isEmpty);
    });

    test('two adults who chose the same word side by side', () {
      final edits = [
        _added,
        _edit('m1', 'Mum',
            from: 'cookie', to: 'biscuit', base: 'add', minute: 1),
        _edit('t1', 'Teacher',
            from: 'cookie', to: 'biscuit', base: 'add', minute: 2),
      ];
      expect(detectOverwrites(edits, [_tile()]), isEmpty);
    });

    test('a value the kept line already held and moved on from', () {
      // Mum tried "snack" herself before settling on "biscuit".
      final edits = [
        _added,
        _edit('m1', 'Mum', from: 'cookie', to: 'snack', base: 'add', minute: 1),
        _edit('m2', 'Mum', from: 'snack', to: 'biscuit', base: 'm1', minute: 2),
        _edit('t1', 'Teacher',
            from: 'cookie', to: 'snack', base: 'add', minute: 3),
      ];
      expect(detectOverwrites(edits, [_tile()]), isEmpty);
    });

    test('a tile whose value no edit in the log explains', () {
      final edits = [
        _added,
        _edit('m1', 'Mum', from: 'cookie', to: 'snack', base: 'add', minute: 1),
        _edit('t1', 'Teacher',
            from: 'cookie', to: 'treat', base: 'add', minute: 2),
      ];
      expect(detectOverwrites(edits, [_tile(label: 'elsewhere')]), isEmpty);
    });
  });

  group('concurrent edits', () {
    final mum = _edit('m1', 'Mum',
        from: 'cookie', to: 'biscuit', base: 'add', minute: 1);
    final teacher = _edit('t1', 'Teacher',
        from: 'cookie', to: 'snack', base: 'add', minute: 2);

    test('two label edits on one base give exactly one overwrite', () {
      final tile = _tile();
      final found = detectOverwrites([_added, mum, teacher], [tile]);
      expect(found, [Overwrite(lost: teacher, kept: mum, tile: tile)]);
      expect(found.single.prop, 'label');
    });

    test('the winner is read from the tile, not from the clocks', () {
      // The later clock lost here, and the earlier one in the test above.
      final tile = _tile(label: 'snack');
      expect(
        detectOverwrites([_added, mum, teacher], [tile]),
        [Overwrite(lost: mum, kept: teacher, tile: tile)],
      );
    });

    test('the order of the log does not matter', () {
      final tile = _tile();
      final expected = [Overwrite(lost: teacher, kept: mum, tile: tile)];
      expect(detectOverwrites([teacher, mum, _added], [tile]), expected);
      expect(detectOverwrites([mum, _added, teacher], [tile]), expected);
    });

    test('the same edit listed twice is counted once', () {
      final found =
          detectOverwrites([_added, mum, teacher, teacher, mum], [_tile()]);
      expect(found, hasLength(1));
    });

    test('two first edits of a starter word, neither with a base', () {
      // Starter tiles are seeded without edit rows, so the first edit on
      // each device has no base.
      final a = _edit('m1', 'Mum', from: 'like', to: 'love', minute: 1);
      final b = _edit('t1', 'Teacher', from: 'like', to: 'enjoy', minute: 2);
      final tile = _tile(label: 'enjoy');
      expect(
        detectOverwrites([a, b], [tile]),
        [Overwrite(lost: a, kept: b, tile: tile)],
      );
    });

    test('only the last word of the losing side is reported', () {
      // Teacher changed their mind twice while offline.
      final t2 = _edit('t2', 'Teacher',
          from: 'snack', to: 'treat', base: 't1', minute: 3);
      final tile = _tile();
      expect(
        detectOverwrites([_added, mum, teacher, t2], [tile]),
        [Overwrite(lost: t2, kept: mum, tile: tile)],
      );
    });

    test('the kept edit is the tip of the winning side', () {
      final m2 = _edit('m2', 'Mum',
          from: 'biscuit', to: 'cracker', base: 'm1', minute: 3);
      final tile = _tile(label: 'cracker');
      expect(
        detectOverwrites([_added, mum, m2, teacher], [tile]),
        [Overwrite(lost: teacher, kept: m2, tile: tile)],
      );
    });

    test('a losing side that went back to the original word still lost', () {
      // Teacher: cookie -> snack -> cookie. Mum never saw either.
      final t2 = _edit('t2', 'Teacher',
          from: 'snack', to: 'cookie', base: 't1', minute: 3);
      final tile = _tile();
      expect(
        detectOverwrites([_added, mum, teacher, t2], [tile]),
        [Overwrite(lost: t2, kept: mum, tile: tile)],
      );
    });

    test('one adult on two devices overwrites themselves', () {
      final phone = _edit('p1', 'Mum',
          from: 'cookie', to: 'snack', base: 'add', minute: 2);
      final tile = _tile();
      expect(
        detectOverwrites([_added, mum, phone], [tile]),
        [Overwrite(lost: phone, kept: mum, tile: tile)],
      );
    });

    test('a base that has not arrived yet still marks a separate line', () {
      final orphan = _edit('t9', 'Teacher',
          from: 'crumb', to: 'snack', base: 'not-here', minute: 2);
      final tile = _tile();
      expect(
        detectOverwrites([_added, mum, orphan], [tile]),
        [Overwrite(lost: orphan, kept: mum, tile: tile)],
      );
    });

    test('a later edit by someone who saw the merge leaves the unseen one '
        'reported', () {
      // Gran saw "biscuit" and made it "cracker". Nobody chose against
      // "snack".
      final gran = _edit('g1', 'Gran',
          from: 'biscuit', to: 'cracker', base: 'm1', minute: 5);
      final tile = _tile(label: 'cracker');
      expect(
        detectOverwrites([_added, mum, teacher, gran], [tile]),
        [Overwrite(lost: teacher, kept: gran, tile: tile)],
      );
    });

    test('an edit made on top of the merged tile settles the value it '
        'replaced', () {
      // The device picked Teacher's edit as the base (its clock was ahead)
      // although the tile showed Mum's "biscuit". Gran replaced "biscuit"
      // knowingly, so Mum's edit is not an overwrite.
      final gran = _edit('g1', 'Gran',
          from: 'biscuit', to: 'cracker', base: 't1', minute: 5);
      final tile = _tile(label: 'cracker');
      expect(detectOverwrites([_added, mum, teacher, gran], [tile]), isEmpty);
    });
  });

  group('three-way', () {
    final mum = _edit('m1', 'Mum',
        from: 'cookie', to: 'biscuit', base: 'add', minute: 1);
    final teacher = _edit('t1', 'Teacher',
        from: 'cookie', to: 'snack', base: 'add', minute: 2);
    final gran = _edit('g1', 'Gran',
        from: 'cookie', to: 'treat', base: 'add', minute: 3);

    test('three different words give two overwrites, newest first', () {
      final tile = _tile();
      expect(detectOverwrites([_added, mum, teacher, gran], [tile]), [
        Overwrite(lost: gran, kept: mum, tile: tile),
        Overwrite(lost: teacher, kept: mum, tile: tile),
      ]);
    });

    test('two losers asking for the same word are reported once', () {
      final gran2 = _edit('g1', 'Gran',
          from: 'cookie', to: 'snack', base: 'add', minute: 3);
      final tile = _tile();
      expect(
        detectOverwrites([_added, mum, teacher, gran2], [tile]),
        [Overwrite(lost: gran2, kept: mum, tile: tile)],
      );
    });

    test('a loser that agrees with the winner is not reported', () {
      final gran2 = _edit('g1', 'Gran',
          from: 'cookie', to: 'biscuit', base: 'add', minute: 3);
      final tile = _tile();
      final found = detectOverwrites([_added, mum, teacher, gran2], [tile]);
      expect(found.map((o) => o.lost), [teacher]);
      expect(found.single.kept, gran2, reason: 'the newest of the two kept');
    });

    test('restoring one loser leaves the other reported', () {
      final restore = _edit('r1', 'Mum',
          from: 'biscuit',
          to: 'snack',
          base: 'm1',
          minute: 9,
          reason: restoreReason);
      final tile = _tile(label: 'snack');
      expect(
        detectOverwrites([_added, mum, teacher, gran, restore], [tile]),
        [Overwrite(lost: gran, kept: restore, tile: tile)],
      );
    });
  });

  group('restore', () {
    final mum = _edit('m1', 'Mum',
        from: 'cookie', to: 'biscuit', base: 'add', minute: 1);
    final teacher = _edit('t1', 'Teacher',
        from: 'cookie', to: 'snack', base: 'add', minute: 2);

    test('built on the kept edit, resolves the overwrite', () {
      final restore = _edit('r1', 'Mum',
          from: 'biscuit',
          to: 'snack',
          base: 'm1',
          minute: 9,
          reason: restoreReason);
      expect(
        detectOverwrites(
            [_added, mum, teacher, restore], [_tile(label: 'snack')]),
        isEmpty,
      );
    });

    test('built on the lost edit, resolves it too and does not report the '
        'edit it overruled', () {
      // Which of the two the restoring device names as its base depends on
      // their clocks; the result must not.
      final restore = _edit('r1', 'Mum',
          from: 'biscuit',
          to: 'snack',
          base: 't1',
          minute: 9,
          reason: restoreReason);
      expect(
        detectOverwrites(
            [_added, mum, teacher, restore], [_tile(label: 'snack')]),
        isEmpty,
      );
    });

    test('a later ordinary edit does not bring the restored pair back', () {
      final restore = _edit('r1', 'Mum',
          from: 'biscuit',
          to: 'snack',
          base: 'm1',
          minute: 9,
          reason: restoreReason);
      final later = _edit('m3', 'Mum',
          from: 'snack', to: 'cracker', base: 'r1', minute: 10);
      expect(
        detectOverwrites([_added, mum, teacher, restore, later],
            [_tile(label: 'cracker')]),
        isEmpty,
      );
    });

    test('a restore that itself loses to an unseen edit is an overwrite', () {
      final restore = _edit('r1', 'Mum',
          from: 'biscuit',
          to: 'snack',
          base: 'm1',
          minute: 9,
          reason: restoreReason);
      // Gran, offline since "biscuit", makes it "cracker" and wins.
      final gran = _edit('g1', 'Gran',
          from: 'biscuit', to: 'cracker', base: 'm1', minute: 10);
      final tile = _tile(label: 'cracker');
      final found =
          detectOverwrites([_added, mum, teacher, restore, gran], [tile]);
      expect(found, hasLength(1));
      expect(found.single.kept, gran);
      expect(found.single.lost.newValue, 'snack');
    });
  });

  group('properties', () {
    test('edits to different properties never conflict', () {
      final edits = [
        _added,
        _edit('m1', 'Mum',
            from: 'cookie', to: 'biscuit', base: 'add', minute: 1),
        _edit('t1', 'Teacher',
            from: null, to: 'a biscuit please', prop: 'speech', minute: 2),
        _edit('g1', 'Gran', from: null, to: 'noun', prop: 'colorKey', minute: 3),
      ];
      expect(
        detectOverwrites(edits,
            [_tile(speech: 'a biscuit please', colorKey: 'noun')]),
        isEmpty,
      );
    });

    test('a lost speech edit is found beside a kept label edit', () {
      final speechA = _edit('s1', 'Mum',
          from: null, to: 'biscuit please', prop: 'speech', minute: 1);
      final speechB = _edit('s2', 'Teacher',
          from: null, to: 'snack time', prop: 'speech', minute: 2);
      final label = _edit('m1', 'Mum',
          from: 'cookie', to: 'biscuit', base: 'add', minute: 1);
      final tile = _tile(speech: 'biscuit please');
      expect(
        detectOverwrites([_added, label, speechA, speechB], [tile]),
        [Overwrite(lost: speechB, kept: speechA, tile: tile)],
      );
    });

    test('clearing a property counts as a value: empty and null are equal',
        () {
      final set = _edit('s1', 'Mum',
          from: null, to: 'biscuit please', prop: 'speech', minute: 1);
      final cleared =
          _edit('s2', 'Teacher', from: null, to: '', prop: 'speech', minute: 2);
      final tile = _tile();
      expect(
        detectOverwrites([set, cleared], [tile]),
        [Overwrite(lost: set, kept: cleared, tile: tile)],
      );
    });

    test('colour edits are compared like any other', () {
      final a = _edit('c1', 'Mum',
          from: null, to: 'noun', prop: 'colorKey', minute: 1);
      final b = _edit('c2', 'Teacher',
          from: null, to: 'verb', prop: 'colorKey', minute: 2);
      final tile = _tile(colorKey: 'verb');
      expect(
        detectOverwrites([a, b], [tile]),
        [Overwrite(lost: a, kept: b, tile: tile)],
      );
    });

    test('cell, archive and media edits are never reported', () {
      final edits = [
        for (final prop in ['cellKey', 'archivedAt', 'imageHash', 'audioHash'])
          ...[
            _edit('$prop-a', 'Mum', from: null, to: 'one', prop: prop),
            _edit('$prop-b', 'Teacher', from: null, to: 'two', prop: prop),
          ],
      ];
      expect(detectOverwrites(edits, [_tile()]), isEmpty);
    });

    test('currentValueOf reads the three restorable properties', () {
      final tile = _tile(speech: '', colorKey: 'noun');
      expect(currentValueOf(tile, 'label'), 'biscuit');
      expect(currentValueOf(tile, 'speech'), isNull);
      expect(currentValueOf(tile, 'colorKey'), 'noun');
      expect(currentValueOf(tile, 'cellKey'), isNull);
    });
  });

  group('tiles', () {
    final mum = _edit('m1', 'Mum',
        from: 'cookie', to: 'biscuit', base: 'add', minute: 1);
    final teacher = _edit('t1', 'Teacher',
        from: 'cookie', to: 'snack', base: 'add', minute: 2);

    test('archived tiles are ignored', () {
      expect(
        detectOverwrites([_added, mum, teacher], [_tile(archived: true)]),
        isEmpty,
      );
    });

    test('edits of a tile that is not listed are ignored', () {
      expect(
        detectOverwrites(
            [_added, mum, teacher], [_tile(id: _otherTileId)]),
        isEmpty,
      );
      expect(detectOverwrites([_added, mum, teacher], const []), isEmpty);
    });

    test('each tile is judged on its own edits', () {
      final otherA = _edit('o1', 'Mum',
          from: 'like', to: 'love', tileId: _otherTileId, minute: 4);
      final otherB = _edit('o2', 'Teacher',
          from: 'like', to: 'enjoy', tileId: _otherTileId, minute: 5);
      final first = _tile();
      final second = _tile(id: _otherTileId, label: 'love');
      expect(
        detectOverwrites(
            [_added, mum, teacher, otherA, otherB], [first, second]),
        [
          Overwrite(lost: otherB, kept: otherA, tile: second),
          Overwrite(lost: teacher, kept: mum, tile: first),
        ],
      );
    });

    test('a loop of bases reports nothing and returns', () {
      final a = _edit('a', 'Mum', from: 'x', to: 'y', base: 'b');
      final b = _edit('b', 'Teacher', from: 'y', to: 'x', base: 'a');
      expect(detectOverwrites([a, b], [_tile(label: 'y')]), isEmpty);
    });
  });
}
