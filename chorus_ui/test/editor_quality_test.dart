// The editor, its sheets and the credits on the quality floor: light and
// dark, the largest text, and the five window sizes, with nothing
// overflowing; and a board that has not arrived yet holds its place.
import 'dart:math' as math;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/brand/haptics.dart';
import 'package:chorus_ui/brand/test_fonts.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/credits/credits_screen.dart';
import 'package:chorus_ui/editor/add_word_sheet.dart';
import 'package:chorus_ui/editor/editor_screen.dart';
import 'package:chorus_ui/editor/tray_panel.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_live.dart';
import 'package:chorus_ui/fakes_media.dart';
import 'package:chorus_ui/theme.dart';
import 'package:chorus_ui/widgets/board_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _sizes = [
  Size(360, 640),
  Size(360, 820),
  Size(820, 360),
  Size(1280, 800),
  Size(1440, 900),
];

String _name(Size size) => '${size.width.toInt()}x${size.height.toInt()}';

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  required Size size,
  bool dark = false,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: chorusTheme(),
      darkTheme: chorusDarkTheme(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: screen,
    ),
  );
  await tester.pump();
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// A store whose boards have not reached this device yet.
class _NoBoards extends FakeBoardStore {
  _NoBoards() : super.seeded();

  @override
  List<BoardFacts> get boards => const [];
}

void main() {
  setUpAll(loadChorusFonts);

  EditorScreen editor({CircleRole role = CircleRole.guardian}) {
    final store = FakeMediaBoardStore.seeded(leaveEmpty: const {(5, 5)})
      ..remoteConflict(row: 0, col: 0, label: 'playground');
    store.role = role;
    return EditorScreen(
      store: store,
      sync: FakeSyncStatus(state: SyncState.offline),
      live: FakeLiveSession(present: ['Dad']),
      media: FakeMediaStore(),
      capture: FakeMediaCapture(),
    );
  }

  group('the editor fits', () {
    for (final size in _sizes) {
      for (final dark in [false, true]) {
        for (final scale in [1.0, 2.0]) {
          testWidgets('${_name(size)}, ${dark ? 'dark' : 'light'}, text x'
              '$scale', (tester) async {
            await _pump(
              tester,
              editor(),
              size: size,
              dark: dark,
              textScale: scale,
            );
            expect(tester.takeException(), isNull);
            expect(find.text('Needs a home · 1'), findsOneWidget);
            // At twice the text a phone's page scrolls down to the board.
            await tester.scrollUntilVisible(
              find.byType(EditorGrid),
              200,
              scrollable: find.byType(Scrollable).first,
            );
            expect(tester.takeException(), isNull);
            // Every tile is a 48dp target at the normal text size.
            if (scale == 1) {
              final cell = tester
                  .state<EditorGridState>(find.byType(EditorGrid))
                  .cellRect(0, 0)!;
              expect(cell.width, greaterThanOrEqualTo(48));
            }
          });
        }
      }
      testWidgets('${_name(size)} for a partner, who reads and cannot '
          'change', (tester) async {
        await _pump(
          tester,
          editor(role: CircleRole.partner),
          size: size,
          textScale: 2,
        );
        expect(tester.takeException(), isNull);
        expect(find.text(readOnlyMessage), findsOneWidget);
        expect(find.byKey(BoardTabs.addKey), findsNothing);
      });
    }
  });

  group('the add-word sheet fits', () {
    for (final size in _sizes) {
      for (final dark in [false, true]) {
        testWidgets('${_name(size)}, ${dark ? 'dark' : 'light'}, text x2', (
          tester,
        ) async {
          final store = FakeMediaBoardStore.seeded(leaveEmpty: const {(4, 5)});
          await _pump(
            tester,
            Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showAddWordSheet(
                    context,
                    store: store,
                    boardId: store.homeBoardId,
                    row: 4,
                    col: 5,
                    media: FakeMediaStore(),
                    capture: FakeMediaCapture(),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
            size: size,
            dark: dark,
            textScale: 2,
          );
          await tester.tap(find.text('open'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          // Every row is kept: word, spoken text, colours, photo, record.
          expect(find.byType(TextField), findsNWidgets(2));
          expect(find.byType(ChoiceChip), findsNWidgets(wordColours.length));
          expect(find.text('Photo (optional)'), findsOneWidget);
          expect(find.text('Record how we say it (optional)'), findsOneWidget);
        });
      }
    }
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('360x640, text x$scale: the spoken-text help is whole, not '
        'cut short beside the counter', (tester) async {
      final store = FakeMediaBoardStore.seeded(leaveEmpty: const {(4, 5)});
      await _pump(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAddWordSheet(
                context,
                store: store,
                boardId: store.homeBoardId,
                row: 4,
                col: 5,
              ),
              child: const Text('open'),
            ),
          ),
        ),
        size: const Size(360, 640),
        textScale: scale,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final help = tester.renderObject<RenderParagraph>(
        find.text('Leave empty to say the word as written.'),
      );
      expect(help.didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('every colour family of the key can be picked, once', (
    tester,
  ) async {
    expect(
      TileFamily.values.map(
        (family) => wordColours
            .where((colour) => TileFamily.forKey(colour.key) == family)
            .length,
      ),
      everyElement(1),
    );
    // "not" is the key the starter board's own "not" has.
    expect(
      wordColours.map((colour) => colour.key),
      contains(
        universalCore36.singleWhere((word) => word.label == 'not').colorKey,
      ),
    );
  });

  group('the credits fit', () {
    for (final size in _sizes) {
      testWidgets('${_name(size)}, dark, text x2', (tester) async {
        await _pump(
          tester,
          const CreditsScreen(),
          size: size,
          dark: true,
          textScale: 2,
        );
        expect(tester.takeException(), isNull);
        expect(
          find.textContaining('Mulberry Symbols by Steve Lee'),
          findsOneWidget,
        );
      });
    }
  });

  testWidgets('in the dark the sheet is slate and its words are light ink', (
    tester,
  ) async {
    await _pump(tester, editor(), size: _sizes.first, dark: true);
    const dark = ChorusColors.dark;
    final sheet = tester.widget<Material>(
      find
          .descendant(
            of: find.byKey(EditorScreen.traySheetKey),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(sheet.color, dark.surface);
    final heading = tester
        .renderObject<RenderParagraph>(find.text('Needs a home · 1'))
        .text
        .style!
        .color!;
    expect(heading, dark.ink);
    expect(_contrast(heading, dark.surface), greaterThanOrEqualTo(7));
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor ??
          Theme.of(
            tester.element(find.byType(EditorGrid)),
          ).scaffoldBackgroundColor,
      dark.card,
    );
  });

  testWidgets('an added word is felt', (tester) async {
    final felt = <ChorusHaptic>[];
    ChorusHaptics.sink = felt.add;
    addTearDown(() => ChorusHaptics.sink = null);
    final store = FakeBoardStore.seeded(leaveEmpty: const {(5, 5)});
    await _pump(
      tester,
      EditorScreen(store: store, sync: FakeSyncStatus()),
      size: _sizes[3],
    );
    Future<void> add(String word) async {
      await tester.tap(
        find.bySemanticsLabel('Empty spot, row 6, column 6. Add a word here'),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, word);
      await tester.tap(find.text('Add to board'));
      await tester.pumpAndSettle();
    }

    await add('swing');
    expect(felt, [ChorusHaptic.wordAdded]);
    expect(find.text('swing'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('a board that has not arrived holds its place with grey tiles '
      'and says so', (tester) async {
    await _pump(
      tester,
      EditorScreen(store: _NoBoards(), sync: FakeSyncStatus()),
      size: _sizes.first,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('There is no board yet.'), findsOneWidget);
    final skeleton = find.byType(SkeletonBoard);
    expect(skeleton, findsOneWidget);
    expect(
      find.descendant(of: skeleton, matching: find.byType(DecoratedBox)),
      findsNWidgets(36),
    );
    expect(tester.getSize(skeleton).width, greaterThan(300));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a screen reader hears every control by name', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, editor(), size: _sizes.first);
    expect(find.bySemanticsLabel(BoardTabs.addLabel), findsOneWidget);
    expect(find.bySemanticsLabel('Board: Home'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Empty spot, row 6, column 6. Add a word here'),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(find.byKey(TrayPanel.headingKey)),
      isSemantics(
        label: 'Needs a home · 1',
        hint: 'Show the waiting words',
        isButton: true,
        isHeader: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });
}
