import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/contracts_live.dart';
import 'package:chorus_ui/contracts_media.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_live.dart';
import 'package:chorus_ui/talker/talker_controller.dart';
import 'package:chorus_ui/talker/talker_screen.dart';
import 'package:chorus_ui/widgets/tile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A speech service that can also play a tile's recorded clip.
class _ClipSpeech extends FakeSpeech implements TileSpeaker {
  final List<String> clips = [];

  @override
  Future<void> speakTile(TileFacts tile) async => clips.add(tile.id);
}

void main() {
  late FakeBoardStore store;
  late FakeSpeech speech;

  TileFacts byLabel(String label) =>
      store.tiles.firstWhere((tile) => tile.label == label);

  setUp(() {
    store = FakeBoardStore.seeded();
    speech = FakeSpeech();
  });

  group('FakeLiveSession', () {
    testWidgets('a pulse glows, then fades after livePulseFor', (tester) async {
      final live = FakeLiveSession();
      addTearDown(live.dispose);
      var notified = 0;
      live.addListener(() => notified++);

      live.receivePulse('a');
      expect(live.pulsing, {'a'});
      expect(notified, 1);

      await tester.pump(livePulseFor - const Duration(milliseconds: 100));
      expect(live.pulsing, {'a'});

      await tester.pump(const Duration(milliseconds: 100));
      expect(live.pulsing, isEmpty);
      expect(notified, 2);
    });

    testWidgets('a second pulse on the same tile starts the fade over', (
      tester,
    ) async {
      final live = FakeLiveSession();
      addTearDown(live.dispose);
      live.receivePulse('a');
      await tester.pump(const Duration(seconds: 2));
      live.receivePulse('a');
      await tester.pump(const Duration(seconds: 2));
      expect(live.pulsing, {'a'});
      await tester.pump(const Duration(milliseconds: 500));
      expect(live.pulsing, isEmpty);
    });

    test('sends nothing while disconnected', () {
      final live = FakeLiveSession(connected: false, shareSaid: true);
      addTearDown(live.dispose);
      live.sendPulse('a');
      live.sendSaid('I want more');
      expect(live.sentPulses, isEmpty);
      expect(live.sentSaid, isEmpty);
      expect(live.pulsing, isEmpty);
    });

    test('shares a sentence only while shareSaid is on', () {
      final live = FakeLiveSession();
      addTearDown(live.dispose);
      expect(live.shareSaid, isFalse);
      live.sendSaid('I want more');
      expect(live.sentSaid, isEmpty);

      live.shareSaid = true;
      live.sendSaid('I want more');
      expect(live.sentSaid, ['I want more']);
    });
  });

  group('TalkerController with a live session', () {
    late FakeLiveSession live;

    TalkerController start({SpeechService? withSpeech}) {
      final talker = TalkerController(
        store: store,
        speech: withSpeech ?? speech,
        live: live,
        quiet: Duration.zero,
      );
      addTearDown(talker.dispose);
      return talker;
    }

    setUp(() {
      live = FakeLiveSession();
      addTearDown(live.dispose);
    });

    test('with sharing off, speaking a sentence sends nothing', () async {
      final talker = start();
      talker.tapTile(byLabel('want'));
      talker.tapTile(byLabel('more'));
      await talker.speakStrip();
      expect(talker.sharingSaid, isFalse);
      expect(speech.spoken.last, 'want more');
      expect(live.sentSaid, isEmpty);
      expect(live.sentPulses, isEmpty);
    });

    test(
      'with sharing on, a spoken sentence is shared, single taps are not',
      () async {
        live.shareSaid = true;
        final talker = start();
        talker.tapTile(byLabel('want'));
        talker.tapTile(byLabel('more'));
        expect(live.sentSaid, isEmpty);
        await talker.speakStrip();
        expect(live.sentSaid, ['want more']);
      },
    );

    test('stopSharingSaid turns sharing off and tells listeners', () async {
      live.shareSaid = true;
      final talker = start();
      var notified = 0;
      talker.addListener(() => notified++);

      talker.stopSharingSaid();
      expect(live.shareSaid, isFalse);
      expect(talker.sharingSaid, isFalse);
      expect(notified, 1);

      talker.tapTile(byLabel('want'));
      await talker.speakStrip();
      expect(live.sentSaid, isEmpty);
    });

    testWidgets('a pulse reaches pulsing and leaves the snapshot alone', (
      tester,
    ) async {
      // Disposed by hand: its timer must be gone before the test ends.
      final talker = TalkerController(
        store: store,
        speech: speech,
        live: live,
        quiet: Duration.zero,
      );
      final before = talker.snapshot;
      final want = byLabel('want');
      var notified = 0;
      talker.addListener(() => notified++);

      live.receivePulse(want.id);
      expect(talker.pulsing, {want.id});
      expect(notified, 1);
      expect(talker.snapshot, same(before));
      expect(talker.waitingCount, 0);

      await tester.pump(livePulseFor);
      expect(talker.pulsing, isEmpty);
      expect(talker.snapshot, same(before));
      talker.dispose();
    });

    test('stops listening to the session after dispose', () {
      final talker = TalkerController(store: store, speech: speech, live: live);
      var notified = 0;
      talker.addListener(() => notified++);
      talker.dispose();
      live.setPresent(['Dad']);
      expect(notified, 0);
    });

    test(
      'a clip-capable speaker is asked for the tile, not the text',
      () async {
        final clips = _ClipSpeech();
        final talker = start(withSpeech: clips);
        final want = byLabel('want');
        final more = byLabel('more');

        talker.tapTile(want);
        expect(clips.clips, [want.id]);
        expect(clips.spoken, isEmpty);

        // One word keeps its recorded voice; a longer sentence is spoken.
        await talker.speakStrip();
        expect(clips.clips, [want.id, want.id]);
        talker.tapTile(more);
        await talker.speakStrip();
        expect(clips.spoken, ['want more']);
      },
    );

    test('never writes to the store', () async {
      live.shareSaid = true;
      final talker = start();
      final before = List.of(store.tiles);
      talker.tapTile(byLabel('want'));
      await talker.speakStrip();
      live.receivePulse(byLabel('want').id);
      talker.stopSharingSaid();
      expect(store.tiles, before);
    });
  });

  group('TalkerScreen with a live session', () {
    late FakeLiveSession live;

    Future<void> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: TalkerScreen(
            store: store,
            speech: speech,
            sync: FakeSyncStatus(),
            live: live,
          ),
        ),
      );
    }

    TileView view(WidgetTester tester, String label) => tester.widget<TileView>(
      find.byWidgetPredicate((w) => w is TileView && w.tile.label == label),
    );

    /// Colour of the ring drawn over the tile labelled [label].
    Color ringColour(WidgetTester tester, String label) {
      final box = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.text(label),
              matching: find.byWidgetPredicate(
                (w) =>
                    w is DecoratedBox &&
                    w.position == DecorationPosition.foreground,
              ),
            )
            .first,
      );
      return ((box.decoration as BoxDecoration).border! as Border).top.color;
    }

    /// Opacity of the ring drawn over the tile labelled [label].
    double ring(WidgetTester tester, String label) {
      final box = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.text(label),
              matching: find.byWidgetPredicate(
                (w) =>
                    w is DecoratedBox &&
                    w.position == DecorationPosition.foreground,
              ),
            )
            .first,
      );
      final border = (box.decoration as BoxDecoration).border! as Border;
      return border.top.color.a;
    }

    setUp(() {
      live = FakeLiveSession();
    });

    testWidgets('a pulsing tile is highlighted until the pulse fades', (
      tester,
    ) async {
      await open(tester);
      expect(view(tester, 'want').highlighted, isFalse);
      final cell = tester.getRect(find.text('want'));

      live.receivePulse(byLabel('want').id);
      await tester.pump();
      expect(view(tester, 'want').highlighted, isTrue);
      expect(view(tester, 'more').highlighted, isFalse);
      expect(ring(tester, 'more'), 0);
      // The glow breathes: the ring is never gone and its strength moves.
      final first = ring(tester, 'want');
      await tester.pump(const Duration(milliseconds: 450));
      final second = ring(tester, 'want');
      expect(first, greaterThan(0.4));
      expect(second, greaterThan(0.4));
      expect(second, isNot(first));
      // In tile ink, which reads on every family's fill: colour belongs to
      // words, so the ring has none of its own.
      expect(ringColour(tester, 'want').withValues(alpha: 1), tileLabelInk);
      // The tile has not moved.
      expect(tester.getRect(find.text('want')), cell);

      await tester.pump(livePulseFor);
      await tester.pump();
      expect(view(tester, 'want').highlighted, isFalse);
      expect(ring(tester, 'want'), 0);
      expect(tester.getRect(find.text('want')), cell);
    });

    testWidgets('a glowing tile can still be tapped and spoken', (
      tester,
    ) async {
      await open(tester);
      live.receivePulse(byLabel('want').id);
      await tester.pump();
      await tester.tap(find.text('want'));
      await tester.pump();
      expect(speech.spoken, ['want']);
      await tester.pump(livePulseFor);
    });

    testWidgets('with animations off the glow is steady', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(1200, 900),
              disableAnimations: true,
            ),
            child: TalkerScreen(
              store: store,
              speech: speech,
              sync: FakeSyncStatus(),
              live: live,
            ),
          ),
        ),
      );
      live.receivePulse(byLabel('want').id);
      await tester.pump();
      expect(view(tester, 'want').highlighted, isTrue);
      expect(ring(tester, 'want'), 1);
      await tester.pump(const Duration(milliseconds: 450));
      expect(ring(tester, 'want'), 1);
      await tester.pump(livePulseFor);
    });

    testWidgets('no sharing bar while sharing is off', (tester) async {
      await open(tester);
      expect(find.text(sharingSaidMessage), findsNothing);
    });

    testWidgets('the sharing bar shows while on and a tap turns it off', (
      tester,
    ) async {
      live.shareSaid = true;
      await open(tester);
      expect(find.text(sharingSaidMessage), findsOneWidget);

      await tester.tap(find.text('want'));
      await tester.tap(find.byIcon(Icons.volume_up_rounded));
      await tester.pump();
      expect(live.sentSaid, ['want']);

      await tester.tap(find.text(sharingSaidMessage));
      await tester.pump();
      expect(live.shareSaid, isFalse);
      expect(find.text(sharingSaidMessage), findsNothing);

      await tester.tap(find.byIcon(Icons.volume_up_rounded));
      await tester.pump();
      expect(live.sentSaid, ['want']);
    });

    testWidgets('the board works with no live session at all', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TalkerScreen(
            store: store,
            speech: speech,
            sync: FakeSyncStatus(),
          ),
        ),
      );
      await tester.tap(find.text('want'));
      await tester.pump();
      expect(speech.spoken, ['want']);
      expect(find.text(sharingSaidMessage), findsNothing);
    });
  });
}
