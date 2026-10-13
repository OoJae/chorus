import 'dart:math';

import 'package:chorus_shared/src/cell_key.dart';
import 'package:chorus_shared/src/facts.dart';
import 'package:chorus_shared/src/reconcile_snapshot.dart';
import 'package:test/test.dart';

const boardId = '11111111-1111-4111-8111-111111111111';
const board = BoardFacts(id: boardId, name: 'Home', rows: 6, cols: 6, isHome: true);

TileFacts tile(String id, int row, int col, {String? label}) => TileFacts(
      id: id,
      boardId: boardId,
      cellKey: placedKey(boardId, row, col),
      label: label ?? id,
    );

/// The same tile placed in another cell.
TileFacts movedTo(TileFacts t, int row, int col) =>
    t.copyWith(cellKey: placedKey(boardId, row, col));

(int, int) cellOf(TileFacts t) {
  final cell = CellKey.parse(t.cellKey) as PlacedCell;
  return (cell.row, cell.col);
}

BoardSnapshot snap(Iterable<TileFacts> tiles) =>
    BoardSnapshot(board, {for (final t in tiles) cellOf(t): t});

void main() {
  group('BoardSnapshot', () {
    test('of() keeps placed tiles of the board and drops the rest', () {
      final placed = tile('a', 0, 0);
      final archived = tile('b', 0, 1).copyWith(archived: true);
      final inTray = tile('c', 0, 2).copyWith(cellKey: trayKey('c'));
      final offGrid = tile('d', 9, 9);
      final snapshot =
          BoardSnapshot.of(board, [placed, archived, inTray, offGrid], [board]);
      expect(snapshot.board, board);
      expect(snapshot.cells, {(0, 0): placed});
    });

    test('has value equality', () {
      expect(snap([tile('a', 0, 0)]), snap([tile('a', 0, 0)]));
      expect(snap([tile('a', 0, 0)]).hashCode, snap([tile('a', 0, 0)]).hashCode);
      expect(snap([tile('a', 0, 0)]), isNot(snap([tile('a', 0, 1)])));
      expect(snap([tile('a', 0, 0)]), isNot(snap([])));
    });
  });

  group('reconcileSnapshot', () {
    test('two empty snapshots give an empty plan', () {
      final plan = reconcileSnapshot(snap([]), snap([]));
      expect(plan.isEmpty, isTrue);
      expect(plan.waitingCount, 0);
      expect(plan.next.cells, isEmpty);
    });

    test('identical snapshots give an empty plan', () {
      final tiles = [tile('a', 0, 0), tile('b', 3, 4)];
      final plan = reconcileSnapshot(snap(tiles), snap(tiles));
      expect(plan.isEmpty, isTrue);
      expect(plan.auto, isEmpty);
      expect(plan.needsAdult, isEmpty);
      expect(plan.next, snap(tiles));
    });

    test('added: a new tile fills an empty cell automatically', () {
      final a = tile('a', 0, 0);
      final b = tile('b', 2, 3);
      final plan = reconcileSnapshot(snap([a]), snap([a, b]));
      expect(plan.auto, [SnapshotChange(ChangeKind.added, 2, 3, after: b)]);
      expect(plan.needsAdult, isEmpty);
      expect(plan.next.cells, {(0, 0): a, (2, 3): b});
      expect(plan.waitingCount, 1);
      expect(plan.isEmpty, isFalse);
    });

    test('added: every tile is new when the current snapshot is empty', () {
      final fresh = snap([tile('b', 1, 1), tile('a', 0, 5), tile('c', 1, 0)]);
      final plan = reconcileSnapshot(snap([]), fresh);
      expect(plan.auto.map((c) => c.kind).toSet(), {ChangeKind.added});
      expect(plan.auto.map((c) => (c.row, c.col)), [(0, 5), (1, 0), (1, 1)],
          reason: 'row-major order');
      expect(plan.next, fresh);
    });

    test('updated: same tile, same cell, new content is automatic', () {
      final before = tile('a', 1, 1, label: 'go');
      final after = before.copyWith(label: 'stop', colorKey: 'verb');
      final plan = reconcileSnapshot(snap([before]), snap([after]));
      expect(plan.auto, [
        SnapshotChange(ChangeKind.updated, 1, 1, before: before, after: after),
      ]);
      expect(plan.needsAdult, isEmpty);
      expect(plan.next.cells, {(1, 1): after});
    });

    test('removed: a vanished tile leaves a gap automatically', () {
      final a = tile('a', 0, 0);
      final b = tile('b', 0, 1);
      final plan = reconcileSnapshot(snap([a, b]), snap([a]));
      expect(plan.auto, [SnapshotChange(ChangeKind.removed, 0, 1, before: b)]);
      expect(plan.needsAdult, isEmpty);
      expect(plan.next.cells, {(0, 0): a});
    });

    test('replaced: a different tile in an occupied cell needs an adult', () {
      final a = tile('a', 0, 0);
      final b = tile('b', 0, 0);
      final plan = reconcileSnapshot(snap([a]), snap([b]));
      expect(plan.auto, isEmpty);
      expect(plan.needsAdult, [
        SnapshotChange(ChangeKind.replaced, 0, 0, before: a, after: b),
      ]);
      expect(plan.next.cells, {(0, 0): a}, reason: 'the child keeps seeing a');
      expect(plan.waitingCount, 1);
      expect(plan.isEmpty, isFalse);
    });

    test('relocated: the tile stays put and its new cell is not filled', () {
      final a = tile('a', 0, 0);
      final moved = movedTo(a, 4, 4);
      final plan = reconcileSnapshot(snap([a]), snap([moved]));
      expect(plan.auto, isEmpty, reason: 'the old cell is not emptied');
      expect(plan.needsAdult, [
        SnapshotChange(ChangeKind.relocated, 4, 4, before: a, after: moved),
      ]);
      expect(plan.next.cells, {(0, 0): a});
      expect(plan.next.cells.containsKey((4, 4)), isFalse);
    });

    test('relocated: content changes do not sneak the tile into its new cell',
        () {
      final a = tile('a', 0, 0, label: 'go');
      final moved = movedTo(a, 0, 1).copyWith(label: 'went');
      final plan = reconcileSnapshot(snap([a]), snap([moved]));
      expect(plan.auto, isEmpty);
      expect(plan.needsAdult.single.kind, ChangeKind.relocated);
      expect(plan.next.cells, {(0, 0): a});
    });

    test('a swap of two visible tiles is two replacements, nothing automatic',
        () {
      final a = tile('a', 0, 0);
      final b = tile('b', 0, 1);
      final a2 = movedTo(a, 0, 1);
      final b2 = movedTo(b, 0, 0);
      final plan = reconcileSnapshot(snap([a, b]), snap([a2, b2]));
      expect(plan.auto, isEmpty);
      expect(plan.needsAdult, [
        SnapshotChange(ChangeKind.replaced, 0, 0, before: a, after: b2),
        SnapshotChange(ChangeKind.replaced, 0, 1, before: b, after: a2),
      ]);
      expect(plan.next, snap([a, b]));
    });

    test('a visible tile moving onto a removed tile is one replacement', () {
      final a = tile('a', 0, 0);
      final d = tile('d', 2, 2);
      final moved = movedTo(a, 2, 2);
      final plan = reconcileSnapshot(snap([a, d]), snap([moved]));
      expect(plan.auto, isEmpty);
      expect(plan.needsAdult, [
        SnapshotChange(ChangeKind.replaced, 2, 2, before: d, after: moved),
      ]);
      expect(plan.next, snap([a, d]));
    });

    test('auto and adult changes are separated in one plan', () {
      final a = tile('a', 0, 0);
      final b = tile('b', 0, 1, label: 'old');
      final c = tile('c', 0, 2);
      final d = tile('d', 0, 3);
      final b2 = b.copyWith(label: 'new');
      final e = tile('e', 0, 3);
      final f = tile('f', 5, 5);
      final a2 = movedTo(a, 3, 3);
      final plan = reconcileSnapshot(snap([a, b, c, d]), snap([a2, b2, e, f]));
      expect(plan.auto, [
        SnapshotChange(ChangeKind.updated, 0, 1, before: b, after: b2),
        SnapshotChange(ChangeKind.removed, 0, 2, before: c),
        SnapshotChange(ChangeKind.added, 5, 5, after: f),
      ]);
      expect(plan.needsAdult, [
        SnapshotChange(ChangeKind.replaced, 0, 3, before: d, after: e),
        SnapshotChange(ChangeKind.relocated, 3, 3, before: a, after: a2),
      ]);
      expect(plan.next, snap([a, b2, d, f]));
      expect(plan.waitingCount, 5);
    });

    test('a rename rides along with the plan', () {
      const renamed =
          BoardFacts(id: boardId, name: 'School', rows: 6, cols: 6, isHome: true);
      final a = tile('a', 0, 0);
      final plan = reconcileSnapshot(
        BoardSnapshot(board, {(0, 0): a}),
        BoardSnapshot(renamed, {(0, 0): a}),
      );
      expect(plan.next.board, renamed);
      expect(plan.next.cells, {(0, 0): a});
    });

    test('a resize stays out of next until an adult accepts it', () {
      const resized =
          BoardFacts(id: boardId, name: 'School', rows: 4, cols: 8, isHome: true);
      final a = tile('a', 0, 0);
      final current = BoardSnapshot(board, {(0, 0): a});
      final fresh = BoardSnapshot(resized, {(0, 0): a});
      final plan = reconcileSnapshot(current, fresh);
      expect(plan.next.board, current.board);
      expect(plan.next, current);
      expect(plan.isEmpty, isTrue);
      expect(plan.next.board, isNot(fresh.board));
    });
  });

  group('isSafePoint', () {
    TalkerActivity activity({
      bool stripEmpty = true,
      bool speaking = false,
      Duration sinceLastTouch = const Duration(seconds: 5),
    }) =>
        TalkerActivity(
          stripEmpty: stripEmpty,
          speaking: speaking,
          sinceLastTouch: sinceLastTouch,
        );

    test('true when the strip is empty, nothing speaks and the board is quiet',
        () {
      expect(isSafePoint(activity()), isTrue);
    });

    test('false while the strip holds tiles', () {
      expect(isSafePoint(activity(stripEmpty: false)), isFalse);
    });

    test('false while speaking', () {
      expect(isSafePoint(activity(speaking: true)), isFalse);
    });

    test('false just after a touch', () {
      expect(
        isSafePoint(activity(sinceLastTouch: const Duration(milliseconds: 500))),
        isFalse,
      );
    });

    test('the quiet boundary is inclusive', () {
      expect(
        isSafePoint(activity(sinceLastTouch: const Duration(milliseconds: 1999))),
        isFalse,
      );
      expect(
        isSafePoint(activity(sinceLastTouch: const Duration(seconds: 2))),
        isTrue,
      );
    });

    test('honours a custom quiet duration', () {
      const quiet = Duration(milliseconds: 300);
      expect(
        isSafePoint(
          activity(sinceLastTouch: const Duration(milliseconds: 299)),
          quiet: quiet,
        ),
        isFalse,
      );
      expect(
        isSafePoint(
          activity(sinceLastTouch: const Duration(milliseconds: 300)),
          quiet: quiet,
        ),
        isTrue,
      );
    });
  });

  test('property: a plan never changes what an occupied cell means', () {
    final random = Random(20261013);
    final seen = <ChangeKind, int>{};
    const rounds = 600;

    for (var round = 0; round < rounds; round++) {
      var serial = 0;
      final current = <(int, int), TileFacts>{};
      for (var row = 0; row < 6; row++) {
        for (var col = 0; col < 6; col++) {
          if (random.nextDouble() < 0.6) {
            current[(row, col)] = tile('t${serial++}', row, col);
          }
        }
      }

      // Fresh starts as current, then tiles appear, disappear, change
      // content and swap or move cells.
      final fresh = Map<(int, int), TileFacts>.of(current);
      final edits = random.nextInt(10);
      for (var i = 0; i < edits; i++) {
        final cell = (random.nextInt(6), random.nextInt(6));
        final other = (random.nextInt(6), random.nextInt(6));
        switch (random.nextInt(4)) {
          case 0:
            fresh.remove(cell);
          case 1:
            final t = fresh[cell];
            if (t != null) fresh[cell] = t.copyWith(label: '${t.label}!');
          case 2:
            fresh[cell] = tile('t${serial++}', cell.$1, cell.$2);
          default:
            final a = fresh.remove(cell);
            final b = fresh.remove(other);
            if (a != null) fresh[other] = movedTo(a, other.$1, other.$2);
            if (b != null) fresh[cell] = movedTo(b, cell.$1, cell.$2);
        }
      }

      final currentSnapshot = BoardSnapshot(board, current);
      final freshSnapshot = BoardSnapshot(board, fresh);
      final plan = reconcileSnapshot(currentSnapshot, freshSnapshot);
      final next = plan.next.cells;
      final why = 'round $round';

      for (final change in [...plan.auto, ...plan.needsAdult]) {
        seen[change.kind] = (seen[change.kind] ?? 0) + 1;
      }
      expect(plan.waitingCount, plan.auto.length + plan.needsAdult.length,
          reason: why);
      expect(plan.isEmpty, plan.waitingCount == 0, reason: why);

      // INVARIANT, part one: an occupied cell keeps its tile id or empties.
      final shownAt = <String, (int, int)>{};
      for (final entry in current.entries) {
        shownAt[entry.value.id] = entry.key;
        final after = next[entry.key];
        expect(after == null || after.id == entry.value.id, isTrue,
            reason: '$why: cell ${entry.key} changed tile');
      }
      // INVARIANT, part two: no visible tile id turns up in another cell.
      final nextIds = <String>{};
      for (final entry in next.entries) {
        expect(nextIds.add(entry.value.id), isTrue,
            reason: '$why: ${entry.value.id} shown twice');
        final shown = shownAt[entry.value.id];
        expect(shown == null || shown == entry.key, isTrue,
            reason: '$why: ${entry.value.id} moved to ${entry.key}');
        // Whatever next shares with fresh is fully up to date.
        if (fresh[entry.key]?.id == entry.value.id) {
          expect(entry.value, fresh[entry.key], reason: why);
        }
      }

      // With nothing held back, next is exactly fresh.
      if (plan.needsAdult.isEmpty) {
        expect(plan.next, freshSnapshot, reason: why);
      }

      // Reconciling again changes nothing and asks for the same decisions.
      final again = reconcileSnapshot(plan.next, freshSnapshot);
      expect(again.auto, isEmpty, reason: why);
      expect(again.needsAdult.toSet(), plan.needsAdult.toSet(), reason: why);
      expect(again.next, plan.next, reason: why);
    }

    expect(rounds, greaterThanOrEqualTo(500));
    for (final kind in ChangeKind.values) {
      expect(seen[kind] ?? 0, greaterThan(0),
          reason: 'the generator never produced ${kind.name}');
    }
  });
}
