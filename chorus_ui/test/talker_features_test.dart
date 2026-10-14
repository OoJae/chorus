// The child's board with this wave's additions: the word log and the
// "Private" control, the haptic moments, the shared-element landing, dark
// mode, and every layout at the five sizes and at large text.
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/brand/haptics.dart';
import 'package:chorus_ui/brand/pressable_surface.dart';
import 'package:chorus_ui/brand/test_fonts.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/contracts_wordlog.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_features.dart';
import 'package:chorus_ui/fakes_live.dart';
import 'package:chorus_ui/fakes_media.dart';
import 'package:chorus_ui/features/flags/w7.dart';
import 'package:chorus_ui/talker/talker_controller.dart';
import 'package:chorus_ui/talker/talker_screen.dart';
import 'package:chorus_ui/talker/talker_tabs.dart';
import 'package:chorus_ui/theme.dart';
import 'package:chorus_ui/widgets/tile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A word log that counts what it is told, and can be made to throw.
class _SpyLog extends WordLog {
  final List<String> noted = [];
  bool fail = false;
  bool _private = false;

  @override
  bool get enabled => false;
  @override
  bool get private => _private;
  @override
  bool get canChange => false;
  @override
  int get pending => 0;

  @override
  void noteSpoken(TileFacts tile) {
    if (fail) throw StateError('broken log');
    noted.add(tile.label);
  }

  @override
  void setPrivate(bool value) {
    if (fail) throw StateError('broken log');
    _private = value;
    notifyListeners();
  }

  @override
  Future<void> setEnabled(bool value) async {}
  @override
  Future<void> deleteAll() async {}
}

/// A circle whose boards have not reached this device yet.
class _NoBoardsStore extends BoardStore {
  @override
  String get childName => 'Maya';
  @override
  String get myName => 'Mum';
  @override
  CircleRole get role => CircleRole.guardian;
  @override
  List<BoardFacts> get boards => const [];
  @override
  List<TileFacts> get tiles => const [];
  @override
  Future<bool> addTile({
    required String boardId,
    required int row,
    required int col,
    required String label,
    String? speech,
    String? colorKey,
  }) async => false;
  @override
  Future<bool> placeTile(
    String tileId, {
    required int row,
    required int col,
  }) async => false;
  @override
  Future<void> updateTile(
    String tileId, {
    String? label,
    String? speech,
    String? colorKey,
  }) async {}
  @override
  Future<void> archiveTile(String tileId) async {}
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(360, 800),
  bool dark = false,
  bool reduced = false,
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
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduced,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: screen,
    ),
  );
  await tester.pump();
}

Finder _tile(String label) =>
    find.byWidgetPredicate((w) => w is TileView && w.tile.label == label);

final Finder _speak = find.bySemanticsLabel('Speak');
final Finder _private = find.byKey(TalkerScreen.privateKey);

void main() {
  late FakeBoardStore store;
  late FakeSpeech speech;
  late List<ChorusHaptic> felt;

  setUp(() {
    store = FakeBoardStore.seeded();
    speech = FakeSpeech();
    felt = [];
    ChorusHaptics.sink = felt.add;
  });
  tearDown(() => ChorusHaptics.sink = null);

  TileFacts byLabel(String label) =>
      store.tiles.firstWhere((tile) => tile.label == label);

  group('the word log', () {
    testWidgets('is offered every tapped word, and keeps them while a '
        'guardian has it on', (tester) async {
      final log = FakeWordLog(enabled: true);
      await _pump(
        tester,
        TalkerScreen(
          store: store,
          speech: speech,
          sync: FakeSyncStatus(),
          wordLog: log,
        ),
      );
      await tester.tap(_tile('want'));
      await tester.tap(_tile('more'));
      await tester.pump();
      expect(
        [for (final use in log.kept) use.tileId],
        [byLabel('want').id, byLabel('more').id],
      );
      expect(log.kept.map((use) => use.boardId).toSet(), {store.homeBoardId});
      // Speaking the sentence logs nothing more: words, never sentences.
      await tester.tap(_speak);
      await tester.pump();
      expect(log.kept, hasLength(2));
      expect(speech.spoken.last, 'want more');
    });

    testWidgets('keeps nothing while it is off', (tester) async {
      final log = FakeWordLog();
      await _pump(
        tester,
        TalkerScreen(
          store: store,
          speech: speech,
          sync: FakeSyncStatus(),
          wordLog: log,
        ),
      );
      await tester.tap(_tile('want'));
      await tester.pump();
      expect(log.kept, isEmpty);
      expect(log.pending, 0);
      expect(speech.spoken, ['want']);
    });

    test('the controller tells the log about each tap, and a log that '
        'throws never breaks the board', () {
      final log = _SpyLog();
      final talker = TalkerController(
        store: store,
        speech: speech,
        wordLog: log,
      );
      addTearDown(talker.dispose);
      talker.tapTile(byLabel('want'));
      talker.tapTile(byLabel('go'));
      expect(log.noted, ['want', 'go']);

      log.fail = true;
      talker.tapTile(byLabel('more'));
      expect(talker.strip.map((t) => t.label), ['want', 'go', 'more']);
      expect(speech.spoken, ['want', 'go', 'more']);
      talker.setPrivate(true);
      expect(talker.private, isFalse, reason: 'the log refused');
    });

    test('the controller stops listening to the log when disposed', () {
      final log = _SpyLog();
      final talker = TalkerController(
        store: store,
        speech: speech,
        wordLog: log,
      );
      var notified = 0;
      talker.addListener(() => notified++);
      talker.setPrivate(true);
      expect(notified, 1);
      talker.dispose();
      log.setPrivate(false);
      expect(notified, 1);
    });
  });

  group('"Private"', () {
    testWidgets('is offered only with a word log or a live session', (
      tester,
    ) async {
      await _pump(
        tester,
        TalkerScreen(store: store, speech: speech, sync: FakeSyncStatus()),
      );
      expect(_private, findsNothing);

      await _pump(
        tester,
        TalkerScreen(
          key: const ValueKey('log'),
          store: store,
          speech: speech,
          sync: FakeSyncStatus(),
          wordLog: FakeWordLog(),
        ),
      );
      expect(_private, findsOneWidget);

      final live = FakeLiveSession();
      addTearDown(live.dispose);
      await _pump(
        tester,
        TalkerScreen(
          key: const ValueKey('live'),
          store: store,
          speech: speech,
          sync: FakeSyncStatus(),
          live: live,
        ),
      );
      expect(_private, findsOneWidget);
    });

    testWidgets('pauses the log and the sharing of sentences, shows while '
        'it is on, and leaves the guardian\'s setting alone', (tester) async {
      final semantics = tester.ensureSemantics();
      final log = FakeWordLog(enabled: true);
      final live = FakeLiveSession(shareSaid: true);
      addTearDown(live.dispose);
      await _pump(
        tester,
        TalkerScreen(
          store: store,
          speech: speech,
          sync: FakeSyncStatus(),
          live: live,
          wordLog: log,
        ),
        size: const Size(1200, 900),
      );
      final control = find.bySemanticsLabel(privateLabel);
      expect(
        tester.getSemantics(control),
        isSemantics(
          isButton: true,
          hasToggledState: true,
          isToggled: false,
          hint: privateOffMessage,
        ),
      );
      Color face() =>
          (tester.widget<Container>(_private).decoration! as BoxDecoration)
              .color!;
      expect(face(), ChorusColors.light.surface);
      expect(find.text(sharingSaidMessage), findsOneWidget);

      await tester.tap(_private);
      await tester.pump();
      expect(log.private, isTrue);
      expect(
        tester.getSemantics(control),
        isSemantics(isToggled: true, hint: privateOnMessage),
      );
      // The mark: filled ink, and the bar says nothing is sent.
      expect(face(), ChorusColors.light.ink);
      expect(find.text(sharingSaidMessage), findsNothing);
      expect(find.text(sharingPausedMessage), findsOneWidget);

      await tester.tap(_tile('want'));
      await tester.tap(_speak);
      await tester.pump();
      expect(log.kept, isEmpty);
      expect(live.sentSaid, isEmpty);
      expect(speech.spoken, ['want', 'want'], reason: 'the board still talks');
      expect(live.shareSaid, isTrue, reason: 'a guardian\'s choice, kept');

      await tester.tap(_private);
      await tester.pump();
      expect(log.private, isFalse);
      await tester.tap(_speak);
      await tester.pump();
      expect(live.sentSaid, ['want']);
      await tester.tap(_tile('more'));
      await tester.pump();
      expect(log.kept.map((use) => use.tileId), [byLabel('more').id]);
      semantics.dispose();
    });

    testWidgets('the board under the sharing bar does not move when private '
        'goes on and off', (tester) async {
      final live = FakeLiveSession(shareSaid: true);
      addTearDown(live.dispose);
      await _pump(
        tester,
        TalkerScreen(
          store: store,
          speech: speech,
          sync: FakeSyncStatus(),
          live: live,
        ),
      );
      final before = tester.getRect(_tile('like'));
      await tester.tap(_private);
      await tester.pump();
      expect(tester.getRect(_tile('like')), before);
      await tester.tap(_private);
      await tester.pump();
      expect(tester.getRect(_tile('like')), before);
    });

    for (final withLive in [false, true]) {
      testWidgets('on a phone on its side, Speak, Delete last word and Clear '
          'stay where they are when "Private" turns on and a word waits'
          '${withLive ? ', with the live mark and sharing' : ''}', (
        tester,
      ) async {
        final log = FakeWordLog(enabled: true);
        final live = withLive ? FakeLiveSession() : null;
        if (live != null) addTearDown(live.dispose);
        await _pump(
          tester,
          TalkerScreen(
            store: store,
            speech: speech,
            sync: FakeSyncStatus(),
            live: live,
            wordLog: log,
          ),
          size: const Size(820, 360),
        );
        List<Rect> row() => [
          find.bySemanticsLabel(RegExp('^Sentence')),
          _speak,
          find.bySemanticsLabel('Delete last word'),
          find.bySemanticsLabel('Clear'),
        ].map(tester.getRect).toList();
        final before = row();

        log.setPrivate(true);
        await tester.pump();
        expect(find.text(privateLabel), findsOneWidget, reason: 'named');
        expect(row(), before);

        // A word in the strip holds a merge back, so a pill comes.
        await tester.tap(_tile('want'));
        await store.archiveTile(byLabel('more').id);
        await tester.pump();
        expect(find.textContaining('waiting'), findsOneWidget);
        expect(row(), before);

        if (live != null) {
          live.shareSaid = true;
          await tester.pump();
          expect(row(), before);
          live.shareSaid = false;
        }
        log.setPrivate(false);
        await tester.pump();
        expect(row(), before);
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
      });
    }

    test('without a word log the controller keeps private mode itself, '
        'and it pauses sharing', () async {
      final live = FakeLiveSession(shareSaid: true);
      addTearDown(live.dispose);
      final talker = TalkerController(store: store, speech: speech, live: live);
      addTearDown(talker.dispose);
      expect(talker.offersPrivate, isTrue);
      talker.setPrivate(true);
      expect(talker.private, isTrue);
      expect(talker.sharingSaid, isFalse);
      expect(talker.sharingOn, isTrue);
      talker.tapTile(byLabel('want'));
      await talker.speakStrip();
      expect(live.sentSaid, isEmpty);
      talker.setPrivate(false);
      await talker.speakStrip();
      expect(live.sentSaid, ['want']);
    });
  });

  group('haptic moments', () {
    testWidgets('a word is felt as tapped, Speak as spoken only when there is '
        'a sentence, and "Hold to leave" as left when the hold completes', (
      tester,
    ) async {
      var left = 0;
      await _pump(
        tester,
        TalkerScreen(
          store: store,
          speech: speech,
          sync: FakeSyncStatus(),
          onExit: () => left++,
        ),
      );
      await tester.tap(_speak);
      await tester.pump();
      expect(felt, isEmpty, reason: 'nothing was said');

      await tester.tap(_tile('want'));
      await tester.tap(_speak);
      await tester.pump();
      expect(felt, [ChorusHaptic.wordTapped, ChorusHaptic.sentenceSpoken]);
      // The strip itself speaks too.
      await tester.tap(find.bySemanticsLabel(RegExp('^Sentence')));
      await tester.pump();
      expect(felt.last, ChorusHaptic.sentenceSpoken);
      felt.clear();

      // Delete and Clear are not moments.
      await tester.tap(find.bySemanticsLabel('Delete last word'));
      await tester.tap(find.bySemanticsLabel('Clear'));
      await tester.pump();
      expect(felt, isEmpty);

      final hold = await tester.startGesture(
        tester.getCenter(find.text(leaveLabel)),
      );
      await tester.pump(const Duration(milliseconds: 1900));
      expect(felt, isEmpty);
      await tester.pump(const Duration(milliseconds: 200));
      expect(left, 1);
      expect(felt, [ChorusHaptic.leftBoard]);
      await hold.up();
      await tester.pumpAndSettle();
    });
  });

  group('the shared-element landing', () {
    testWidgets('with a heroTag the board grid is the Hero, and without one '
        'there is none', (tester) async {
      await _pump(
        tester,
        TalkerScreen(
          store: store,
          speech: speech,
          sync: FakeSyncStatus(),
          heroTag: 'board-${store.homeBoardId}',
        ),
      );
      final hero = tester.widget<Hero>(find.byType(Hero));
      expect(hero.tag, 'board-${store.homeBoardId}');
      expect(
        find.descendant(of: find.byType(Hero), matching: _tile('want')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(Hero),
          matching: find.bySemanticsLabel('Speak'),
        ),
        findsNothing,
        reason: 'only the board flies',
      );

      await _pump(
        tester,
        TalkerScreen(
          key: const ValueKey('plain'),
          store: store,
          speech: speech,
          sync: FakeSyncStatus(),
        ),
      );
      expect(find.byType(Hero), findsNothing);
    });

    testWidgets('under reduced motion there is no flight to land', (
      tester,
    ) async {
      await _pump(
        tester,
        TalkerScreen(
          store: store,
          speech: speech,
          sync: FakeSyncStatus(),
          heroTag: 'board-${store.homeBoardId}',
        ),
        reduced: true,
      );
      expect(find.byType(Hero), findsNothing);
      expect(_tile('want'), findsOneWidget);
    });
  });

  group('laminated tiles', () {
    Color fill(WidgetTester tester, String label) =>
        (tester
                    .widget<DecoratedBox>(
                      find.descendant(
                        of: _tile(label),
                        matching: find.byKey(PressableSurface.faceKey),
                      ),
                    )
                    .decoration
                as BoxDecoration)
            .color!;

    for (final dark in [false, true]) {
      testWidgets(
        'take their family colours ${dark ? 'for slate' : 'for '
                  'card'}, with the label in tile ink',
        (tester) async {
          await _pump(
            tester,
            TalkerScreen(store: store, speech: speech, sync: FakeSyncStatus()),
            dark: dark,
          );
          final mode = dark ? Brightness.dark : Brightness.light;
          expect(fill(tester, 'want'), TileFamily.action.colorsFor(mode).fill);
          expect(fill(tester, 'I'), TileFamily.person.colorsFor(mode).fill);
          expect(
            fill(tester, 'more'),
            TileFamily.describe.colorsFor(mode).fill,
          );
          expect(
            fill(tester, 'what'),
            TileFamily.question.colorsFor(mode).fill,
          );
          expect(fill(tester, 'not'), TileFamily.not.colorsFor(mode).fill);
          expect(fill(tester, 'all'), TileFamily.other.colorsFor(mode).fill);
          final label = tester.widget<Text>(
            find.descendant(of: _tile('want'), matching: find.byType(Text)),
          );
          expect(label.style!.color, tileLabelInk);
          final page = tester.widget<Scaffold>(find.byType(Scaffold));
          expect(
            page.backgroundColor,
            dark ? ChorusColors.dark.surface : ChorusColors.light.surface,
          );
        },
      );
    }

    testWidgets('a starter word shows its symbol, a photo wins over it, and '
        'a word with neither is its label alone', (tester) async {
      final store = FakeMediaBoardStore.seeded();
      final media = FakeMediaStore();
      await store.setTileMedia(
        store.tiles.firstWhere((t) => t.label == 'want').id,
        imageHash: media.arrive(tinyPng),
      );
      // Every starter word has a symbol, so one is renamed to a word that
      // has none.
      await store.updateTile(
        store.tiles.firstWhere((t) => t.label == 'like').id,
        label: 'crackers',
      );
      await _pump(
        tester,
        TalkerScreen(
          store: store,
          speech: speech,
          sync: FakeSyncStatus(),
          media: media,
        ),
      );
      Finder on(String label, Key key) =>
          find.descendant(of: _tile(label), matching: find.byKey(key));
      expect(on('help', TileView.symbolKey), findsOneWidget);
      expect(on('want', TileView.photoKey), findsOneWidget);
      expect(on('want', TileView.symbolKey), findsNothing);
      expect(
        on('stop', TileView.symbolKey),
        coreSymbolsEnabled ? findsOneWidget : findsNothing,
      );
      expect(on('crackers', TileView.symbolKey), findsNothing);
      expect(on('crackers', TileView.photoKey), findsNothing);
      // The pictures are decoration: a screen reader hears the word.
      expect(find.bySemanticsLabel('help'), findsOneWidget);
    });
  });

  group('the talker tabs', () {
    testWidgets('the board on show is a flat ink tab; another is a raised '
        'card that changes board', (tester) async {
      await _pump(
        tester,
        TalkerScreen(store: store, speech: speech, sync: FakeSyncStatus()),
      );
      final tabs = find.byType(TalkerBoardTabs);
      // The one on show has no press of its own.
      expect(
        find.descendant(
          of: tabs,
          matching: find.ancestor(
            of: find.text('Home'),
            matching: find.byType(PressableSurface),
          ),
        ),
        findsNothing,
      );
      expect(
        find.ancestor(
          of: find.text('My words'),
          matching: find.byType(PressableSurface),
        ),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Board: Home')),
        isSemantics(isSelected: true, isButton: true),
      );
      await tester.tap(find.text('My words'));
      await tester.pump();
      expect(_tile('want'), findsNothing);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Board: My words')),
        isSemantics(isSelected: true),
      );
    });
  });

  group('before the board is here', () {
    for (final size in const [Size(360, 640), Size(820, 360)]) {
      testWidgets('grey laminated tiles hold its place and a line says why '
          '(${size.width.toInt()}x${size.height.toInt()})', (tester) async {
        final semantics = tester.ensureSemantics();
        await _pump(
          tester,
          TalkerScreen(
            store: _NoBoardsStore(),
            speech: speech,
            sync: FakeSyncStatus(state: SyncState.connecting),
            onExit: () {},
          ),
          size: size,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('No board yet'), findsOneWidget);
        expect(find.byType(TileView), findsNothing);
        // The skeleton is decoration; the reason is read out.
        expect(find.bySemanticsLabel(RegExp('^No board yet')), findsOneWidget);
        // Everything else still works: the way out and the strip.
        expect(find.text(leaveLabel), findsOneWidget);
        expect(find.bySemanticsLabel('Sentence, empty'), findsOneWidget);
        expect(tester.binding.hasScheduledFrame, isFalse, reason: 'still');
        semantics.dispose();
      });
    }
  });

  group('no overflow, nothing cut', () {
    const sizes = [
      Size(360, 640),
      Size(360, 820),
      Size(820, 360),
      Size(1280, 800),
      Size(1440, 900),
    ];
    setUpAll(loadChorusFonts);

    for (final size in sizes) {
      for (final (dark, scale) in [(false, 1.0), (true, 1.0), (false, 2.0)]) {
        testWidgets('${size.width.toInt()}x${size.height.toInt()}, '
            '${dark ? 'dark' : 'light'}, text x$scale, everything on', (
          tester,
        ) async {
          final live = FakeLiveSession(shareSaid: true);
          addTearDown(live.dispose);
          final sync = FakeSyncStatus(state: SyncState.offline);
          await _pump(
            tester,
            TalkerScreen(
              store: store,
              speech: FakeSpeech(offlineVoice: false),
              sync: sync,
              live: live,
              wordLog: FakeWordLog(enabled: true),
              onExit: () {},
            ),
            size: size,
            dark: dark,
            textScale: scale,
          );
          // A long sentence, a word waiting for an adult, an adult
          // pointing: the fullest the screen gets.
          for (final word in ['I', 'want', 'different', 'finished', 'more']) {
            await tester.tap(_tile(word));
          }
          await store.archiveTile(byLabel('go').id);
          await store.addTile(
            boardId: store.homeBoardId,
            row: 1,
            col: 1,
            label: 'swing',
          );
          live.receivePulse(byLabel('help').id);
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(find.textContaining('waiting'), findsOneWidget);
          expect(find.text(leaveLabel), findsOneWidget);

          await tester.tap(_private);
          await tester.pump();
          expect(tester.takeException(), isNull);

          // Every control is still a 48 dp target where it is laid out.
          for (final control in [
            _speak,
            find.bySemanticsLabel('Delete last word'),
            find.bySemanticsLabel('Clear'),
          ]) {
            final box = tester.getSize(control);
            expect(box.width, greaterThanOrEqualTo(48));
            expect(box.height, greaterThanOrEqualTo(48));
          }
          await tester.pump(const Duration(seconds: 3));
        });
      }
    }
  });
}
