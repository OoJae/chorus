import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/contracts_edits.dart';
import 'package:chorus_ui/editor/replaced_changes_panel.dart';
import 'package:chorus_ui/editor/tray_panel.dart' show notSavedMessage;
import 'package:chorus_ui/fakes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The fake store with an edit log bolted on. Local edits are logged the way
/// the replica does it; [remoteEdit] stands in for a merge.
class _LoggedStore extends FakeBoardStore implements EditLog {
  _LoggedStore() : super.seeded();

  final List<EditFacts> _edits = [];
  int _minutes = 0;

  /// Makes the next [restore] fail, as a refused write would.
  bool failRestore = false;

  @override
  List<EditFacts> get edits => List.unmodifiable(_edits);

  TileFacts named(String label) => tiles.singleWhere((t) => t.label == label);

  EditFacts _append(String tileId, String prop, String? from, String? to,
      {required String by, String? base, String reason = 'edit'}) {
    final edit = EditFacts(
      id: 'edit-${_edits.length}',
      tileId: tileId,
      prop: prop,
      oldValue: from,
      newValue: to,
      baseEditId: base,
      reason: reason,
      actorId: 'user-$by',
      actorName: by,
      editedAt: DateTime.utc(2026, 10, 13, 9, ++_minutes),
    );
    _edits.add(edit);
    return edit;
  }

  String? _newest(String tileId, String prop) => _edits.reversed
      .where((e) => e.tileId == tileId && e.prop == prop)
      .firstOrNull
      ?.id;

  /// A label change made on this device by [myName].
  Future<void> rename(String tileId, String label, {String? reason}) async {
    final before = tiles.singleWhere((t) => t.id == tileId).label;
    final base = _newest(tileId, 'label');
    await updateTile(tileId, label: label);
    _append(tileId, 'label', before, label,
        by: myName, base: base, reason: reason ?? 'edit');
    notifyListeners();
  }

  /// An edit that arrived by merge and did not win: the tile is untouched.
  void remoteEdit(String tileId, String prop, String? from, String? to,
      {required String by, String? base}) {
    _append(tileId, prop, from, to, by: by, base: base);
    notifyListeners();
  }

  @override
  Future<void> restore(Overwrite overwrite) async {
    if (failRestore) throw StateError('refused');
    final lost = overwrite.lost;
    if (lost.prop != 'label') throw UnsupportedError(lost.prop);
    await rename(lost.tileId, lost.newValue!, reason: restoreReason);
  }
}

void main() {
  Future<void> pump(WidgetTester tester, BoardStore store,
          {String? boardId}) =>
      tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReplacedChangesPanel(store: store, boardId: boardId),
          ),
        ),
      ));

  /// Mum renamed "like" to "biscuit"; Teacher, not having seen that, had
  /// renamed it to "snack" and lost.
  Future<_LoggedStore> overwritten({
    CircleRole role = CircleRole.guardian,
  }) async {
    final store = _LoggedStore();
    final id = store.named('like').id;
    await store.rename(id, 'biscuit');
    store.remoteEdit(id, 'label', 'like', 'snack', by: 'Teacher');
    store.role = role;
    return store;
  }

  const sentence = 'Teacher changed this word to "snack" without seeing '
      'Mum\'s change. Mum\'s "biscuit" was kept.';

  testWidgets('shows nothing for a store without an edit log', (tester) async {
    final store = FakeBoardStore.seeded();
    await pump(tester, store);
    expect(find.byType(Text), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('shows nothing while no change was replaced', (tester) async {
    final store = _LoggedStore();
    await store.rename(store.named('like').id, 'love');
    await store.rename(store.named('love').id, 'adore');
    await pump(tester, store);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('lists a replaced change in plain words with one Restore',
      (tester) async {
    final store = await overwritten();
    await pump(tester, store);

    expect(find.text('Replaced changes (1)'), findsOneWidget);
    expect(find.text('$sentence Use "snack" instead?'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Restore'), findsOneWidget);
  });

  testWidgets('given a board, lists only the replaced changes to its words',
      (tester) async {
    final store = await overwritten();
    await pump(tester, store, boardId: store.wordsBoardId);
    expect(find.byType(Text), findsNothing);

    await pump(tester, store, boardId: store.homeBoardId);
    expect(find.text('Replaced changes (1)'), findsOneWidget);
  });

  testWidgets('Restore puts the replaced word back and the entry goes',
      (tester) async {
    final store = await overwritten();
    await pump(tester, store);

    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    expect(store.tiles.where((t) => t.label == 'snack'), hasLength(1));
    expect(store.tiles.where((t) => t.label == 'biscuit'), isEmpty);
    expect(store.edits.last.reason, restoreReason);
    expect(find.text('Replaced changes (1)'), findsNothing);
    expect(find.text('Restore'), findsNothing);
    expect(find.text('"snack" is back.'), findsOneWidget);
  });

  testWidgets('appears when a merge brings a replaced change in',
      (tester) async {
    final store = _LoggedStore();
    final id = store.named('like').id;
    await store.rename(id, 'biscuit');
    await pump(tester, store);
    expect(find.text('Restore'), findsNothing);

    store.remoteEdit(id, 'label', 'like', 'snack', by: 'Teacher');
    await tester.pump();
    expect(find.text('Restore'), findsOneWidget);
  });

  testWidgets('a three-way overwrite lists both replaced words',
      (tester) async {
    final store = await overwritten();
    store.remoteEdit(store.named('biscuit').id, 'label', 'like', 'treat',
        by: 'Gran');
    await pump(tester, store);

    expect(find.text('Replaced changes (2)'), findsOneWidget);
    expect(find.text('Restore'), findsNWidgets(2));
    expect(find.textContaining('Gran changed this word to "treat"'),
        findsOneWidget);
    expect(find.textContaining('Teacher changed this word to "snack"'),
        findsOneWidget);
  });

  testWidgets('a partner sees what happened but cannot restore',
      (tester) async {
    final store = await overwritten(role: CircleRole.partner);
    await pump(tester, store);

    expect(find.text(sentence), findsOneWidget);
    expect(find.text('Restore'), findsNothing);
  });

  testWidgets('a refused restore says so and keeps the entry', (tester) async {
    final store = await overwritten()..failRestore = true;
    await pump(tester, store);

    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    expect(find.text(notSavedMessage), findsOneWidget);
    expect(find.text('Restore'), findsOneWidget);
    expect(store.named('biscuit').label, 'biscuit');
  });

  group('replacedChangeText', () {
    final tile = TileFacts(
      id: 't',
      boardId: 'b',
      cellKey: placedKey('b', 0, 0),
      label: 'biscuit',
    );

    EditFacts edit(String id, String by, String prop, String? to) => EditFacts(
          id: id,
          tileId: 't',
          prop: prop,
          newValue: to,
          reason: 'edit',
          actorId: 'user-$by',
          actorName: by,
          editedAt: DateTime.utc(2026),
        );

    test('speech: a cleared value reads as the word itself', () {
      final text = replacedChangeText(Overwrite(
        lost: edit('a', 'Teacher', 'speech', 'a biscuit please'),
        kept: edit('b', 'Mum', 'speech', null),
        tile: tile,
      ));
      expect(
        text,
        'Teacher changed what this word says to "a biscuit please" without '
        'seeing Mum\'s change. Mum\'s "biscuit" was kept. '
        'Use "a biscuit please" instead?',
      );
    });

    test('colour', () {
      final text = replacedChangeText(Overwrite(
        lost: edit('a', 'Teacher', 'colorKey', 'verb'),
        kept: edit('b', 'Mum', 'colorKey', null),
        tile: tile,
      ));
      expect(
        text,
        'Teacher changed this word\'s colour to the verb colour without '
        'seeing Mum\'s change. Mum\'s no colour was kept. '
        'Use the verb colour instead?',
      );
    });

    test('one adult on two devices is not told about "their own change"', () {
      final text = replacedChangeText(Overwrite(
        lost: edit('a', 'Mum', 'label', 'snack'),
        kept: edit('b', 'Mum', 'label', 'biscuit'),
        tile: tile,
      ));
      expect(
        text,
        'Mum changed this word to "snack" on another device. '
        '"biscuit" was kept. Use "snack" instead?',
      );
    });

    test('an edit with no name is by "Someone"', () {
      final text = replacedChangeText(
        Overwrite(
          lost: edit('a', '', 'label', 'snack'),
          kept: edit('b', 'Mum', 'label', 'biscuit'),
          tile: tile,
        ),
        ask: false,
      );
      expect(
        text,
        'Someone changed this word to "snack" without seeing Mum\'s change. '
        'Mum\'s "biscuit" was kept.',
      );
    });
  });
}
