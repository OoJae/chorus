// Photo ideas as small word tiles: a tap fills the form, and "Add all to
// Needs a home" puts them in the tray without taking a spot.
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/contracts_photo_ideas.dart';
import 'package:chorus_ui/contracts_suggest.dart';
import 'package:chorus_ui/editor/add_word_sheet.dart';
import 'package:chorus_ui/editor/photo_ideas_strip.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_media.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features_harness.dart';

/// Always online, and answers every photo with [ideas].
class _IdeasSuggester implements WordSuggester, PhotoIdeasSuggester {
  _IdeasSuggester(this.ideas);

  final List<WordIdea> ideas;

  @override
  final ValueListenable<bool> available = ValueNotifier(true);

  @override
  Future<WordIdea?> fromPhoto(Uint8List photo) async => null;

  @override
  Future<List<WordIdea>> ideasFromPhoto(Uint8List photo) async => ideas;
}

/// A store with no way to add straight to the tray, over [_inner].
class _AnchorOnlyStore extends BoardStore {
  _AnchorOnlyStore(this._inner);

  final FakeBoardStore _inner;

  @override
  String get childName => _inner.childName;
  @override
  String get myName => _inner.myName;
  @override
  CircleRole get role => _inner.role;
  @override
  List<BoardFacts> get boards => _inner.boards;
  @override
  List<TileFacts> get tiles => _inner.tiles;
  @override
  Future<bool> addTile({
    required String boardId,
    required int row,
    required int col,
    required String label,
    String? speech,
    String? colorKey,
  }) => _inner.addTile(
    boardId: boardId,
    row: row,
    col: col,
    label: label,
    speech: speech,
    colorKey: colorKey,
  );
  @override
  Future<bool> placeTile(String tileId, {required int row, required int col}) =>
      _inner.placeTile(tileId, row: row, col: col);
  @override
  Future<void> updateTile(
    String tileId, {
    String? label,
    String? speech,
    String? colorKey,
  }) => _inner.updateTile(
    tileId,
    label: label,
    speech: speech,
    colorKey: colorKey,
  );
  @override
  Future<void> archiveTile(String tileId) => _inner.archiveTile(tileId);
}

void main() {
  const ideas = [
    WordIdea(label: 'swing', colorKey: 'noun'),
    WordIdea(label: 'push', colorKey: 'verb'),
    WordIdea(label: 'high', colorKey: 'descriptor'),
  ];

  testWidgets('a tap uses the idea; Add all is offered', (tester) async {
    setScreen(tester, const Size(400, 800));
    WordIdea? used;
    var all = 0;
    await tester.pumpWidget(
      featureApp(
        Scaffold(
          body: PhotoIdeasStrip(
            ideas: ideas,
            onUse: (idea) => used = idea,
            onAddAll: () => all++,
          ),
        ),
      ),
    );
    expect(find.text(photoIdeasIntro), findsOneWidget);
    await tester.tap(find.text('push'));
    expect(used?.label, 'push');
    await tester.tap(find.text(addAllToTrayLabel));
    expect(all, 1);
  });

  test(
    'Add all puts every idea in the tray and moves no placed word',
    () async {
      final store = FakeBoardStore.seeded();
      final before = gridOf(store.homeBoardId, store.tiles, store.boards);
      final added = await addIdeasToTray(store, store.homeBoardId, ideas);
      expect(added, 3);
      final tray = trayOf(store.tiles, store.boards).map((e) => e.tile.label);
      expect(tray, containsAll(['swing', 'push', 'high']));
      expect(gridOf(store.homeBoardId, store.tiles, store.boards), before);
    },
  );

  test(
    'on a board with no words yet every idea still goes to the tray',
    () async {
      final store = FakeBoardStore.seeded();
      final boardId = await store.addBoard('Park');
      expect(gridOf(boardId, store.tiles, store.boards), isEmpty);
      final added = await addIdeasToTray(store, boardId, ideas);
      expect(added, 3);
      final waiting = trayOf(
        store.tiles,
        store.boards,
      ).where((e) => e.tile.boardId == boardId).map((e) => e.tile.label);
      expect(waiting, containsAll(['swing', 'push', 'high']));
      expect(gridOf(boardId, store.tiles, store.boards), isEmpty);
    },
  );

  test('a store that can only anchor adds nothing on an empty board', () async {
    final inner = FakeBoardStore.seeded();
    final boardId = await inner.addBoard('Park');
    final added = await addIdeasToTray(_AnchorOnlyStore(inner), boardId, ideas);
    expect(added, 0);
    expect(gridOf(boardId, inner.tiles, inner.boards), isEmpty);
  });

  testWidgets('Add all on a new board says the ideas wait in the tray', (
    tester,
  ) async {
    setScreen(tester, const Size(400, 900));
    final store = FakeMediaBoardStore.seeded();
    final boardId = await store.addBoard('Park');
    await tester.pumpWidget(
      featureApp(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAddWordSheet(
                context,
                store: store,
                boardId: boardId,
                row: 0,
                col: 0,
                media: FakeMediaStore(),
                capture: FakeMediaCapture(hasCamera: false),
                suggester: _IdeasSuggester(ideas),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Choose a photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose a photo'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(suggestFromPhotoLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(suggestFromPhotoLabel));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(addAllToTrayLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(addAllToTrayLabel));
    await tester.pumpAndSettle();

    expect(find.byType(WordForm), findsNothing);
    expect(find.text(ideasInTrayMessage(3)), findsOneWidget);
    final waiting = trayOf(
      store.tiles,
      store.boards,
    ).where((e) => e.tile.boardId == boardId).map((e) => e.tile.label);
    expect(waiting, containsAll(['swing', 'push', 'high']));
  });

  test('the tray line counts the words', () {
    expect(ideasInTrayMessage(1), contains('1 word waits'));
    expect(ideasInTrayMessage(3), contains('3 words wait'));
  });
}
