// Ready-made boards: the six bundled .obf files, each read by the same
// parser as "Import a board (.obf)" and added as a new board of 24 words,
// and the editor's "Add a ready-made board" that offers them.
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/brand/symbols.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/editor/board_actions.dart';
import 'package:chorus_ui/editor/editor_screen.dart';
import 'package:chorus_ui/editor/ready_boards.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/features/flags/w7.dart';
import 'package:chorus_ui/theme.dart';
import 'package:chorus_ui/widgets/board_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: chorusTheme(), home: screen));
}

Finder _tab(String name) =>
    find.descendant(of: find.byType(BoardTabs), matching: find.text(name));

/// The colour key every word of a board should come in with, where the
/// whole board is one family.
const Map<String, String> _oneFamily = {
  'People': 'pronoun',
  'Actions': 'verb',
  'Describing words': 'descriptor',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  if (!readyMadeBoardsEnabled) {
    test('with the feature off, the board menu does not offer it', () {
      expect(offerReadyBoards(canAddBoards: true), isFalse);
    });
    return;
  }

  test('the feature is on, and there are six boards with distinct names', () {
    expect(readyMadeBoardsEnabled, isTrue);
    expect(readyBoards.map((b) => b.name), [
      'Food',
      'People',
      'Places',
      'Feelings',
      'Actions',
      'Describing words',
    ]);
    expect(readyBoards.map((b) => b.asset).toSet(), hasLength(6));
    expect(offerReadyBoards(canAddBoards: true), isTrue);
    expect(offerReadyBoards(canAddBoards: false), isFalse);
  });

  for (final ready in readyBoards) {
    group('${ready.name}:', () {
      late String text;
      setUpAll(() async => text = await loadReadyBoard(ready));

      test('the bundled file parses as a 4 by 6 board of 24 words that all '
          'fit, in the colours of the key', () {
        final board = parseObf(text);
        expect(board.name, ready.name);
        expect(board.rows, 4);
        expect(board.columns, 6);
        final (:fitted, :leftOver) = obfPlacements(board);
        expect(fitted, hasLength(24));
        expect(leftOver, isEmpty);
        final labels = fitted.map((w) => w.label).toList();
        expect(labels.toSet(), hasLength(24), reason: 'no word twice');
        for (final word in fitted) {
          expect(word.speech, isNull, reason: word.label);
          expect(
            word.label.length,
            lessThanOrEqualTo(maxTileLabelLength),
            reason: word.label,
          );
          // Every key is one the tiles have a colour for; nouns are plain.
          if (word.colorKey != null) {
            expect(colorForKey, contains(word.colorKey), reason: word.label);
          }
        }
        final family = _oneFamily[ready.name];
        if (family != null) {
          expect(fitted.map((w) => w.colorKey).toSet(), {family});
        }
        // The words shown under the name are on the board.
        for (final word in ready.sample.split(', ')) {
          expect(labels, contains(word), reason: word);
        }
      });

      test('it imports into a new board of its name with 24 words', () async {
        final store = FakeBoardStore.seeded();
        final before = store.boards.length;
        final result = await store.importBoard(parseObf(text));
        expect(result.leftOut, isEmpty);
        expect(store.boards, hasLength(before + 1));
        final board = store.boards.singleWhere((b) => b.id == result.boardId);
        expect(board.name, ready.name);
        expect(board.rows, starterRows);
        expect(board.cols, starterCols);
        expect(gridOf(board.id, store.tiles, store.boards), hasLength(24));
      });
    });
  }

  test('Food keeps its verbs green, its describing words blue, and its '
      'foods plain', () async {
    final food = parseObf(await loadReadyBoard(readyBoards.first));
    final keys = {
      for (final word in obfPlacements(food).fitted) word.label: word.colorKey,
    };
    expect(keys['eat'], 'verb');
    expect(keys['hungry'], 'descriptor');
    expect(keys['apple'], isNull);
    expect(keys['ice cream'], isNull);
  });

  test('Feelings keeps the starter words in their own colours, and they '
      'show their pictures', () async {
    final feelings = parseObf(await loadReadyBoard(readyBoards[3]));
    final keys = {
      for (final word in obfPlacements(feelings).fitted)
        word.label: word.colorKey,
    };
    expect(keys['I'], 'pronoun');
    expect(keys['not'], 'negation');
    expect(keys['help'], 'verb');
    for (final word in ['I', 'not', 'help']) {
      expect(symbolImageFor(word), isNotNull, reason: word);
    }
  });

  test('the boards show Mulberry pictures where they fit, and every such '
      'picture is for a word on them', () async {
    final all = <String>{};
    for (final ready in readyBoards) {
      final board = parseObf(await loadReadyBoard(ready));
      final words = [
        for (final word in obfPlacements(board).fitted)
          word.label.toLowerCase(),
      ];
      all.addAll(words);
      final pictured = words.where((w) => symbolAssetFor(w) != null);
      expect(pictured.length, greaterThanOrEqualTo(10), reason: ready.name);
    }
    expect(all, containsAll(readyBoardSymbolWords));
  });

  test(
    'a file the app bundles is found under the package path first',
    () async {
      final bundle = _Bundle({
        'packages/chorus_ui/assets/boards/food.obf': 'x',
      });
      expect(await loadReadyBoard(readyBoards.first, bundle: bundle), 'x');
      final own = _Bundle({'assets/boards/food.obf': 'y'});
      expect(await loadReadyBoard(readyBoards.first, bundle: own), 'y');
    },
  );

  group('Add a ready-made board', () {
    // Read ahead: an asset read does not finish inside a widget test.
    final files = <ReadyBoard, String>{};
    setUpAll(() async {
      for (final board in readyBoards) {
        files[board] = await loadReadyBoard(board);
      }
      readyBoardLoader = (board) async => files[board]!;
    });
    tearDownAll(() => readyBoardLoader = loadReadyBoard);

    Future<void> openPicker(WidgetTester tester) async {
      await tester.tap(find.byTooltip(boardMenuLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(readyBoardsLabel));
      await tester.pumpAndSettle();
    }

    testWidgets('lists the six boards, and the one chosen comes in through '
        'the import as a new board, on show', (tester) async {
      final store = FakeBoardStore.seeded();
      await _pump(tester, EditorScreen(store: store, sync: FakeSyncStatus()));
      await openPicker(tester);

      expect(find.text(readyBoardsIntro), findsOneWidget);
      for (final board in readyBoards) {
        expect(find.text(board.name), findsOneWidget, reason: board.name);
        expect(find.text('${board.sample} and more'), findsOneWidget);
      }
      await tester.tap(find.text('Feelings'));
      await tester.pumpAndSettle();

      expect(find.text('Imported "Feelings"'), findsOneWidget);
      expect(find.text('24 words are on the new board.'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      final board = store.boards.singleWhere((b) => b.name == 'Feelings');
      expect(gridOf(board.id, store.tiles, store.boards), hasLength(24));
      expect(_tab('Feelings'), findsOneWidget);
      // It is the board on show.
      expect(find.text('excited'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the same board twice gets a name of its own', (tester) async {
      final store = FakeBoardStore.seeded();
      await _pump(tester, EditorScreen(store: store, sync: FakeSyncStatus()));
      for (var i = 0; i < 2; i++) {
        await openPicker(tester);
        // By its row: the first one's tab is called "Food" too.
        await tester.tap(
          find.byKey(const ValueKey('ready-board-assets/boards/food.obf')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
      }
      expect(
        store.boards.where((b) => !b.archived).map((b) => b.name),
        containsAll(['Food', 'Food 2']),
      );
    });

    testWidgets('closing the list adds nothing', (tester) async {
      final store = FakeBoardStore.seeded();
      final before = store.boards.length;
      await _pump(tester, EditorScreen(store: store, sync: FakeSyncStatus()));
      await openPicker(tester);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text(readyBoardsIntro), findsNothing);
      expect(store.boards, hasLength(before));
    });

    testWidgets('a partner, who cannot add boards, is not offered it', (
      tester,
    ) async {
      final store = FakeBoardStore.seeded(role: CircleRole.partner);
      await _pump(
        tester,
        EditorScreen(store: store, sync: FakeSyncStatus(), onExport: (_) {}),
      );
      await tester.tap(find.byTooltip(boardMenuLabel));
      await tester.pumpAndSettle();
      expect(find.text(exportBoardLabel), findsOneWidget);
      expect(find.text(readyBoardsLabel), findsNothing);
      expect(find.text(renameBoardLabel), findsNothing);
    });
  });
}

/// An asset bundle holding only [files].
class _Bundle extends CachingAssetBundle {
  _Bundle(this.files);

  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    final text = files[key];
    if (text == null) throw FlutterError('No asset $key');
    return ByteData.sublistView(Uint8List.fromList(text.codeUnits));
  }
}
