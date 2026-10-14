// The talker access features on the child's board and on "This device":
// touch settings, switch scanning, keyguard mode, share and recent
// sentences, and the settings page itself.
import 'package:chorus_ui/contracts_device.dart';
import 'package:chorus_ui/contracts_voice.dart';
import 'package:chorus_ui/device/device_settings_scope.dart';
import 'package:chorus_ui/device/device_settings_screen.dart';
import 'package:chorus_ui/device/keyguard_template_screen.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_device.dart';
import 'package:chorus_ui/fakes_live.dart';
import 'package:chorus_ui/talker/keyguard_geometry.dart';
import 'package:chorus_ui/talker/recent_sentences.dart';
import 'package:chorus_ui/talker/sentence_tools.dart';
import 'package:chorus_ui/talker/switch_scanner.dart';
import 'package:chorus_ui/talker/talker_screen.dart';
import 'package:chorus_ui/theme.dart';
import 'package:chorus_ui/widgets/tile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _tablet = Size(1000, 800);

Future<FakeSpeech> _pumpTalker(
  WidgetTester tester, {
  DeviceSettings settings = const DeviceSettings(),
  InMemoryDeviceSettings? store,
  FakeBoardStore? board,
  FakeLiveSession? live,
  Size size = _tablet,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final speech = FakeSpeech();
  await tester.pumpWidget(
    DeviceSettingsScope(
      store: store ?? InMemoryDeviceSettings(settings),
      child: MaterialApp(
        theme: chorusTheme(),
        home: TalkerScreen(
          store: board ?? FakeBoardStore.seeded(withWordsBoard: false),
          speech: speech,
          sync: FakeSyncStatus(),
          live: live,
        ),
      ),
    ),
  );
  await tester.pump();
  return speech;
}

/// Ends the board, so no timer outlives the test.
Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 3));
}

Finder _tile(String label) =>
    find.byWidgetPredicate((w) => w is TileView && w.tile.label == label);

Map<String, Rect> _tiles(WidgetTester tester) => {
  for (final element in find.byType(TileView).evaluate())
    (element.widget as TileView).tile.label: tester.getRect(
      find.byWidget(element.widget),
    ),
};

Future<void> _hold(WidgetTester tester, String label, Duration time) async {
  final gesture = await tester.startGesture(tester.getCenter(_tile(label)));
  await tester.pump(time);
  await gesture.up();
  await tester.pump();
}

void main() {
  setUp(RecentSentences.session.clear);

  group('Touch settings', () {
    testWidgets('as always, a tap speaks the word', (tester) async {
      final speech = await _pumpTalker(tester);
      await tester.tap(_tile('want'));
      await tester.pump();
      expect(speech.spoken, ['want']);
      await _close(tester);
    });

    testWidgets('with a hold time, a quick tap is not a word; a hold is', (
      tester,
    ) async {
      final speech = await _pumpTalker(
        tester,
        settings: const DeviceSettings(holdTime: Duration(milliseconds: 600)),
      );
      await _hold(tester, 'want', const Duration(milliseconds: 100));
      expect(speech.spoken, isEmpty);
      await _hold(tester, 'want', const Duration(milliseconds: 700));
      expect(speech.spoken, ['want']);
      await _close(tester);
    });

    testWidgets('not on release, a word speaks once held, before the lift', (
      tester,
    ) async {
      final speech = await _pumpTalker(
        tester,
        settings: const DeviceSettings(
          holdTime: Duration(milliseconds: 300),
          selectOnRelease: false,
        ),
      );
      final gesture = await tester.startGesture(tester.getCenter(_tile('go')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(speech.spoken, isEmpty);
      await tester.pump(const Duration(milliseconds: 200));
      expect(speech.spoken, ['go']);
      await gesture.up();
      await tester.pump();
      // Lifting does not say it again.
      expect(speech.spoken, ['go']);
      await _close(tester);
    });

    testWidgets('not on release with no hold time, a touch speaks at once', (
      tester,
    ) async {
      final speech = await _pumpTalker(
        tester,
        settings: const DeviceSettings(selectOnRelease: false),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(_tile('more')),
      );
      await tester.pump();
      expect(speech.spoken, ['more']);
      await gesture.up();
      await tester.pump();
      expect(speech.spoken, ['more']);
      await _close(tester);
    });

    testWidgets('repeat taps inside the time are ignored, on any word', (
      tester,
    ) async {
      final speech = await _pumpTalker(
        tester,
        settings: const DeviceSettings(repeatGuard: Duration(seconds: 1)),
      );
      await tester.tap(_tile('want'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(_tile('want'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(_tile('more'));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(_tile('more'));
      await tester.pump();
      expect(speech.spoken, ['want', 'more']);
      await _close(tester);
    });

    testWidgets('a long press on a word never leaves the board', (
      tester,
    ) async {
      var left = 0;
      tester.view.physicalSize = _tablet;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        DeviceSettingsScope(
          store: InMemoryDeviceSettings(
            const DeviceSettings(holdTime: Duration(seconds: 1)),
          ),
          child: MaterialApp(
            theme: chorusTheme(),
            home: TalkerScreen(
              store: FakeBoardStore.seeded(withWordsBoard: false),
              speech: FakeSpeech(),
              sync: FakeSyncStatus(),
              onExit: () => left++,
            ),
          ),
        ),
      );
      await tester.pump();
      await _hold(tester, 'want', const Duration(seconds: 3));
      expect(left, 0);
      await _close(tester);
    });
  });

  group('Switch access', () {
    testWidgets('every tile is heard as the word it speaks, in reading order', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpTalker(tester);
      expect(find.bySemanticsLabel('want'), findsOneWidget);
      final like = tester.getRect(find.bySemanticsLabel('like'));
      final want = tester.getRect(find.bySemanticsLabel('want'));
      final not = tester.getRect(find.bySemanticsLabel('not'));
      expect(want.left, greaterThan(like.left));
      expect(not.top, greaterThan(like.top));
      handle.dispose();
      await _close(tester);
    });

    testWidgets('two switches: space moves, enter selects, nothing moves', (
      tester,
    ) async {
      final speech = await _pumpTalker(
        tester,
        settings: const DeviceSettings(scanMode: ScanMode.twoSwitches),
      );
      final before = _tiles(tester);
      expect(find.byKey(scanHighlightKey), findsOneWidget);
      // Row 0 is highlighted: enter opens it on "like"; space to "want".
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(speech.spoken, ['want']);
      // Space on the rows: row 1, then enter on "not".
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(speech.spoken, ['want', 'not']);
      expect(_tiles(tester), before);
      await _close(tester);
    });

    testWidgets('one switch: the highlight steps by itself; a press selects', (
      tester,
    ) async {
      final speech = await _pumpTalker(
        tester,
        settings: const DeviceSettings(
          scanMode: ScanMode.oneSwitch,
          scanStep: Duration(seconds: 1),
        ),
      );
      // Rests on row 0, then row 1.
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      // On "not" now; a step later on "go".
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(speech.spoken, ['go']);
      await _close(tester);
    });

    testWidgets('the spoken preview says the highlighted word', (tester) async {
      final speech = await _pumpTalker(
        tester,
        settings: const DeviceSettings(
          scanMode: ScanMode.twoSwitches,
          scanPreview: true,
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(speech.spoken, ['like', 'want']);
      await _close(tester);
    });

    testWidgets('scanning off leaves space and enter alone', (tester) async {
      final speech = await _pumpTalker(tester);
      expect(find.byKey(scanHighlightKey), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(speech.spoken, isEmpty);
      await _close(tester);
    });
  });

  group('Keyguard mode', () {
    for (final size in const [
      Size(1000, 800),
      Size(390, 844),
      Size(844, 390),
    ]) {
      testWidgets('the tiles are exactly where the geometry says, $size', (
        tester,
      ) async {
        await _pumpTalker(
          tester,
          settings: const DeviceSettings(keyguard: true),
          size: size,
        );
        final geometry = KeyguardGeometry.of(
          body: size,
          layout: keyguardLayoutFor(size),
          rows: 6,
          cols: 6,
        );
        final like = tester.getRect(_tile('like'));
        final expected = geometry.cell(0, 0);
        expect(like.left, closeTo(expected.left, 0.01));
        expect(like.top, closeTo(expected.top, 0.01));
        expect(like.width, closeTo(expected.width, 0.01));
        expect(like.height, closeTo(expected.height, 0.01));
        await _close(tester);
      });
    }

    testWidgets('sharing coming on moves nothing on the grid', (tester) async {
      final live = FakeLiveSession();
      addTearDown(live.dispose);
      await _pumpTalker(
        tester,
        settings: const DeviceSettings(keyguard: true),
        live: live,
      );
      final before = _tiles(tester);
      live.shareSaid = true;
      await tester.pump();
      expect(find.text(sharingSaidMessage), findsNothing);
      expect(_tiles(tester), before);
      await _close(tester);
    });

    testWidgets('without keyguard mode the sharing bar still shows', (
      tester,
    ) async {
      final live = FakeLiveSession();
      addTearDown(live.dispose);
      await _pumpTalker(tester, live: live);
      live.shareSaid = true;
      await tester.pump();
      expect(find.text(sharingSaidMessage), findsOneWidget);
      await _close(tester);
    });
  });

  group('Share a sentence', () {
    testWidgets('Speak notes the sentence for Recent; Recent says it again', (
      tester,
    ) async {
      final speech = await _pumpTalker(tester);
      await tester.tap(_tile('want'));
      await tester.tap(_tile('more'));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Speak'));
      await tester.pump();
      expect(RecentSentences.session.sentences, ['want more']);
      await tester.tap(find.byKey(SentenceTools.recentKey));
      await tester.pumpAndSettle();
      expect(find.text(recentSentencesTitle), findsOneWidget);
      expect(find.text('want more'), findsOneWidget);
      await tester.tap(find.byTooltip(sayAgainLabel));
      await tester.pump();
      expect(speech.spoken.last, 'want more');
      await _close(tester);
    });

    testWidgets('share sends the sentence to the share sheet', (tester) async {
      final shared = <String>[];
      tester.view.physicalSize = _tablet;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SentenceTools(
              sentence: 'I want juice',
              speech: FakeSpeech(),
              share: () => (text) async {
                shared.add(text);
                return true;
              },
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(SentenceTools.shareKey));
      await tester.pump();
      expect(shared, ['I want juice']);
      expect(find.text(sentenceCopiedMessage), findsNothing);
    });

    testWidgets('with no share sheet it copies and says so', (tester) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SentenceTools(
              sentence: 'go',
              speech: FakeSpeech(),
              share: () => null,
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(SentenceTools.shareKey));
      await tester.pump();
      expect(copied, ['go']);
      expect(find.text(sentenceCopiedMessage), findsOneWidget);
    });

    testWidgets('an empty strip asks for a sentence first', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SentenceTools(
              sentence: '',
              speech: FakeSpeech(),
              share: () => null,
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(SentenceTools.shareKey));
      await tester.pump();
      expect(find.text(nothingToShareMessage), findsOneWidget);
    });
  });

  group('This device', () {
    Future<InMemoryDeviceSettings> pumpSettings(
      WidgetTester tester, {
      VoiceChoice? voice,
    }) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final store = InMemoryDeviceSettings();
      await tester.pumpWidget(
        MaterialApp(
          theme: chorusTheme(),
          home: DeviceSettingsScreen(
            store: store,
            voice: voice,
            boardRows: 6,
            boardCols: 6,
          ),
        ),
      );
      await tester.pump();
      return store;
    }

    testWidgets('has its four sections, in plain words', (tester) async {
      await pumpSettings(tester, voice: FakeVoiceChoice());
      for (final heading in [
        touchHeading,
        switchAccessHeading,
        voiceHeading,
        keyguardHeading,
      ]) {
        expect(find.text(heading), findsOneWidget);
      }
      for (final words in [
        holdTimeLabel,
        repeatGuardLabel,
        selectOnReleaseLabel,
        scanModeLabel,
        keyguardModeLabel,
        keyguardTemplateLabel,
        tryVoiceLabel,
      ]) {
        expect(find.text(words), findsOneWidget);
      }
      for (final banned in ['conflict', 'error', 'replica', 'sync engine']) {
        expect(find.textContaining(banned), findsNothing);
      }
    });

    testWidgets('choices are kept on the device', (tester) async {
      final store = await pumpSettings(tester);
      await tester.tap(find.text('0.6 s'));
      await tester.pump();
      expect(store.settings.holdTime, const Duration(milliseconds: 600));
      await tester.tap(find.text(scanTwoLabel));
      await tester.pump();
      expect(store.settings.scanMode, ScanMode.twoSwitches);
      expect(find.text(scanPreviewLabel), findsOneWidget);
      await tester.tap(find.text(keyguardModeLabel));
      await tester.pump();
      expect(store.settings.keyguard, isTrue);
    });

    testWidgets('one switch offers its speed', (tester) async {
      final store = await pumpSettings(tester);
      expect(find.text(scanSpeedLabel), findsNothing);
      await tester.tap(find.text(scanOneLabel));
      await tester.pump();
      expect(find.text(scanSpeedLabel), findsOneWidget);
      await tester.tap(find.text('Quick').first);
      await tester.pump();
      expect(store.settings.scanStep, const Duration(seconds: 1));
    });

    testWidgets('the voice: speed and pitch change, Try it says juice', (
      tester,
    ) async {
      final voice = FakeVoiceChoice();
      await pumpSettings(tester, voice: voice);
      await tester.tap(find.text('Quick').last);
      await tester.pump();
      expect(voice.prefs.rate, 1.2);
      await tester.tap(find.text('Higher'));
      await tester.pump();
      expect(voice.prefs.pitch, 1.25);
      await tester.tap(find.text(tryVoiceLabel));
      await tester.pump();
      expect(voice.tried.single.$1, tryVoiceSentence);
      expect(voice.tried.single.$2.rate, 1.2);
    });

    testWidgets('a read-only partner hears the voice but cannot change it', (
      tester,
    ) async {
      final voice = FakeVoiceChoice(canChange: false);
      await pumpSettings(tester, voice: voice);
      expect(find.text(voiceReadOnlyHelp), findsOneWidget);
      await tester.tap(find.text('Quick').last);
      await tester.pump();
      expect(voice.prefs.rate, VoicePrefs.defaultRate);
      await tester.tap(find.text(tryVoiceLabel));
      await tester.pump();
      expect(voice.tried, hasLength(1));
    });

    testWidgets('the keyguard template shows the outlines and copies an SVG', (
      tester,
    ) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: chorusTheme(),
          home: KeyguardTemplateScreen(rows: 6, cols: 6, saveFile: () => null),
        ),
      );
      await tester.tap(find.text(copySvgLabel));
      await tester.pump();
      expect(find.text(typeScreenSizeMessage), findsOneWidget);
      await tester.enterText(find.byType(TextField), '10');
      await tester.pump();
      expect(find.textContaining('Each hole'), findsOneWidget);
      await tester.tap(find.text(copySvgLabel));
      await tester.pump();
      expect(copied.single, contains('<svg'));
      expect('<rect '.allMatches(copied.single), hasLength(37));
      await tester.tap(find.text(showOutlinesLabel));
      await tester.pumpAndSettle();
      expect(find.byKey(KeyguardTemplateScreen.outlinesKey), findsOneWidget);
      await tester.tapAt(const Offset(500, 400));
      await tester.pumpAndSettle();
      expect(find.byKey(KeyguardTemplateScreen.outlinesKey), findsNothing);
    });
  });
}
