import 'package:chorus_shared/chorus_shared.dart';
import 'package:test/test.dart';

const board = 'b0000000-0000-0000-0000-000000000001';
const cup = 't0000000-0000-0000-0000-000000000001';
const cake = 't0000000-0000-0000-0000-000000000002';

TileFacts tile(
  String id,
  String label, {
  String? cellKey,
  bool archived = false,
  String? speech,
  DateTime? at,
}) => TileFacts(
  id: id,
  boardId: board,
  cellKey: cellKey ?? placedKey(board, 0, 0),
  label: label,
  speech: speech,
  archived: archived,
  createdBy: 'dad',
  createdByName: 'Dad',
  createdAt: at ?? DateTime.utc(2026, 10, 14, 9),
);

EditFacts edit(
  String id,
  String tileId,
  String prop,
  String? oldValue,
  String? newValue, {
  String reason = 'edit',
  DateTime? at,
}) => EditFacts(
  id: id,
  tileId: tileId,
  prop: prop,
  oldValue: oldValue,
  newValue: newValue,
  reason: reason,
  actorId: 'rivera',
  actorName: 'Ms Rivera',
  editedAt: at ?? DateTime.utc(2026, 10, 14, 10),
);

void main() {
  test('a new word is one line, its first edits folded in', () {
    final entries = activityOf(
      [tile(cup, 'cup')],
      [
        edit('e1', cup, 'label', null, 'cup', reason: 'add'),
        edit('e2', cup, 'cellKey', null, placedKey(board, 0, 0), reason: 'add'),
      ],
    );
    expect(entries, hasLength(1));
    expect(entries.single.kind, ActivityKind.added);
    expect(entries.single.actorName, 'Dad');
  });

  test('newest first, with renames and colours', () {
    final entries = activityOf(
      [tile(cup, 'mug')],
      [
        edit('e0', cup, 'label', null, 'cup', reason: 'add'),
        edit(
          'e1',
          cup,
          'label',
          'cup',
          'mug',
          at: DateTime.utc(2026, 10, 14, 10),
        ),
        edit(
          'e2',
          cup,
          'colorKey',
          null,
          'noun',
          at: DateTime.utc(2026, 10, 14, 11),
        ),
      ],
    );
    expect(
      [for (final e in entries) e.kind],
      [ActivityKind.colour, ActivityKind.renamed, ActivityKind.added],
    );
  });

  test('putting a word away keeps the cell it freed', () {
    final at = DateTime.utc(2026, 10, 14, 12);
    final old = placedKey(board, 1, 2);
    final entries = activityOf(
      [tile(cake, 'cake', cellKey: trayKey(cake), archived: true)],
      [
        edit(
          'e1',
          cake,
          'archivedAt',
          null,
          at.toIso8601String(),
          reason: 'archive',
          at: at,
        ),
        edit(
          'e2',
          cake,
          'cellKey',
          old,
          trayKey(cake),
          reason: 'archive',
          at: at,
        ),
      ],
    );
    expect(entries.first.kind, ActivityKind.putAway);
    expect(entries.first.oldCellKey, old);
    expect(entries, hasLength(1));
    expect(
      undoPlanOf(entries.first, [
        tile(cake, 'cake', cellKey: trayKey(cake), archived: true),
      ]),
      const UndoBringBack(PlacedCell(board, 1, 2)),
    );
  });

  test('undo of a rename writes the old label, only while it is current', () {
    final entries = activityOf(
      [tile(cup, 'mug')],
      [edit('e1', cup, 'label', 'cup', 'mug')],
    );
    final renamed = entries.firstWhere((e) => e.kind == ActivityKind.renamed);
    expect(
      undoPlanOf(renamed, [tile(cup, 'mug')]),
      const UndoSetValue('label', 'cup'),
    );
    expect(undoPlanOf(renamed, [tile(cup, 'beaker')]), isNull);
  });

  test('a seeded word, with no add edit, is not a line', () {
    expect(activityOf([tile(cup, 'cup')], const []), isEmpty);
  });

  test('undo of an added word puts it away; nothing for a gone word', () {
    final entries = activityOf(
      [tile(cup, 'cup')],
      [edit('e0', cup, 'label', null, 'cup', reason: 'add')],
    );
    expect(undoPlanOf(entries.single, [tile(cup, 'cup')]), const UndoPutAway());
    expect(
      undoPlanOf(entries.single, [tile(cup, 'cup', archived: true)]),
      isNull,
    );
    expect(undoPlanOf(entries.single, const []), isNull);
  });

  test('undo of a cleared speech clears it again', () {
    final entries = activityOf(
      [tile(cup, 'cup', speech: 'a cup')],
      [edit('e1', cup, 'speech', null, 'a cup')],
    );
    final spoken = entries.firstWhere((e) => e.kind == ActivityKind.spoken);
    expect(
      undoPlanOf(spoken, [tile(cup, 'cup', speech: 'a cup')]),
      const UndoSetValue('speech', ''),
    );
  });

  test('a word given a spot from the tray is a line with no undo', () {
    final entries = activityOf(
      [tile(cup, 'cup')],
      [
        edit(
          'e1',
          cup,
          'cellKey',
          trayKey(cup),
          placedKey(board, 0, 0),
          reason: 'resolve',
        ),
      ],
    );
    final placed = entries.firstWhere((e) => e.kind == ActivityKind.placed);
    expect(undoPlanOf(placed, [tile(cup, 'cup')]), isNull);
  });

  test('changesSince counts entries newer than the last look', () {
    final entries = activityOf(
      [tile(cup, 'mug')],
      [
        edit('e0', cup, 'label', null, 'cup', reason: 'add'),
        edit('e1', cup, 'label', 'cup', 'mug'),
      ],
    );
    expect(changesSince(entries, null), 2);
    expect(changesSince(entries, DateTime.utc(2026, 10, 14, 9, 30)), 1);
    expect(changesSince(entries, DateTime.utc(2026, 10, 15)), 0);
  });
}
