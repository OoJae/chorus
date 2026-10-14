import 'dart:typed_data';

import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/brand/haptics.dart';
import 'package:chorus_ui/brand/pressable_surface.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/contracts_media.dart';
import 'package:chorus_ui/editor/add_word_sheet.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_media.dart';
import 'package:chorus_ui/theme.dart';
import 'package:chorus_ui/widgets/tile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _empty = (4, 5);

Finder get _recordButton => find.byKey(const ValueKey('word-record-button'));

/// A page with one button that opens the add-word sheet for the empty cell.
Widget _host(
  FakeBoardStore store, {
  FakeMediaStore? media,
  FakeMediaCapture? capture,
}) => MaterialApp(
  theme: chorusTheme(),
  home: Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () => showAddWordSheet(
          context,
          store: store,
          boardId: store.homeBoardId,
          row: _empty.$1,
          col: _empty.$2,
          media: media,
          capture: capture,
        ),
        child: const Text('open'),
      ),
    ),
  ),
);

Widget _form({
  TileFacts? initial,
  FakeMediaStore? media,
  FakeMediaCapture? capture,
  TileSpeaker? speaker,
  required ValueChanged<WordDraft> onSubmit,
}) => MaterialApp(
  theme: chorusTheme(),
  home: Scaffold(
    body: WordForm(
      title: 'Change this word',
      submitLabel: 'Save',
      initial: initial,
      media: media,
      capture: capture,
      speaker: speaker,
      onSubmit: onSubmit,
    ),
  ),
);

TileFacts _tile({String? imageHash, String? audioHash}) => TileFacts(
  id: 'tile-1',
  boardId: 'board-1',
  cellKey: placedKey('board-1', 0, 0),
  label: 'Grandma',
  imageHash: imageHash,
  audioHash: audioHash,
);

/// Presses and holds the record button, lets the recording start, and
/// returns the gesture so the test decides when to let go.
Future<TestGesture> _hold(WidgetTester tester) async {
  await tester.ensureVisible(_recordButton);
  await tester.pump();
  final gesture = await tester.startGesture(tester.getCenter(_recordButton));
  await tester.pump();
  await tester.pump();
  return gesture;
}

/// Scrolls to the form's Save button and presses it. The text field
/// scrolls itself into view for a moment after typing, so this settles
/// first.
Future<void> _save(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Save'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

void main() {
  group('TileView', () {
    testWidgets('draws the label only until the picture is on this device', (
      tester,
    ) async {
      final media = FakeMediaStore();
      final hash = fakeHashOf(tinyPng);
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 120,
            height: 120,
            child: TileView(
              tile: _tile(imageHash: hash),
              media: media,
            ),
          ),
        ),
      );

      expect(find.text('Grandma'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(media.requested, [hash]);

      media.arrive(tinyPng);
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Grandma'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('without a store, or without a picture, nothing changes', (
      tester,
    ) async {
      final media = FakeMediaStore();
      final hash = media.arrive(tinyPng);
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              Expanded(
                child: TileView(tile: _tile(imageHash: hash)),
              ),
              Expanded(
                child: TileView(tile: _tile(), media: media),
              ),
            ],
          ),
        ),
      );

      expect(find.byType(Image), findsNothing);
      expect(find.text('Grandma'), findsNWidgets(2));
    });

    testWidgets('keeps its label for screen readers and stays tappable', (
      tester,
    ) async {
      final media = FakeMediaStore();
      final hash = media.arrive(tinyPng);
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 60,
            height: 60,
            child: TileView(
              tile: _tile(imageHash: hash),
              media: media,
              onTap: () => taps++,
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Grandma'), findsOneWidget);
      await tester.tap(find.byType(TileView));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('TileView, laminated', () {
    late List<ChorusHaptic> felt;
    setUp(() {
      felt = [];
      ChorusHaptics.sink = felt.add;
    });
    tearDown(() => ChorusHaptics.sink = null);

    Widget host(Widget tile, {TextStyle? around}) => MaterialApp(
      theme: chorusTheme(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 120,
            height: 120,
            child: around == null
                ? tile
                : DefaultTextStyle.merge(style: around, child: tile),
          ),
        ),
      ),
    );

    testWidgets('with onTap it sinks on the press spring and is felt with '
        'its haptic moment', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          TileView(
            tile: _tile(),
            haptic: ChorusHaptic.wordTapped,
            onTap: () => taps++,
          ),
        ),
      );
      final face = find.byKey(PressableSurface.faceKey);
      final rest = tester.getRect(face);
      final finger = await tester.startGesture(tester.getCenter(face));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(face).top - rest.top,
        closeTo(ChorusSpace.pressSink, 0.05),
      );
      await finger.up();
      await tester.pumpAndSettle();
      expect(tester.getRect(face).top, closeTo(rest.top, 0.01));
      expect(taps, 1);
      expect(felt, [ChorusHaptic.wordTapped]);
    });

    testWidgets('with no haptic given a tap is not felt', (tester) async {
      await tester.pumpWidget(host(TileView(tile: _tile(), onTap: () {})));
      await tester.tap(find.byType(TileView));
      await tester.pumpAndSettle();
      expect(felt, isEmpty);
    });

    testWidgets('without onTap it is a picture of the word, not a button', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(host(TileView(tile: _tile())));
      expect(find.byType(PressableSurface), findsNothing);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Grandma')),
        isSemantics(label: 'Grandma', isButton: false),
      );
      semantics.dispose();
    });

    testWidgets('highlighted lays a tile-ink outline over the face, and a '
        'press under way survives it coming', (tester) async {
      var taps = 0;
      Widget tile(bool on) =>
          host(TileView(tile: _tile(), highlighted: on, onTap: () => taps++));
      await tester.pumpWidget(tile(false));
      expect(find.byKey(TileView.highlightKey), findsNothing);
      final finger = await tester.startGesture(
        tester.getCenter(find.byType(TileView)),
      );
      await tester.pump();
      await tester.pumpWidget(tile(true));
      final outline = tester.widget<DecoratedBox>(
        find.byKey(TileView.highlightKey),
      );
      final border = (outline.decoration as BoxDecoration).border! as Border;
      expect(border.top.color, tileLabelInk);
      await finger.up();
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('the label is drawn in the tile-label style at the size '
        'given, whatever text style is around the tile', (tester) async {
      await tester.pumpWidget(
        host(
          TileView(tile: _tile(), labelSize: 20, onTap: () {}),
          around: const TextStyle(height: 3, letterSpacing: 6),
        ),
      );
      final drawn = tester
          .renderObject<RenderParagraph>(find.text('Grandma'))
          .text
          .style!;
      expect(drawn.fontFamily, ChorusType.tileLabel(20).fontFamily);
      expect(drawn.fontWeight, FontWeight.w700);
      expect(drawn.fontSize, 20);
      expect(drawn.height, isNull, reason: 'what TileLabelSizer measures');
      expect(drawn.letterSpacing, isNull);
      expect(drawn.color, tileLabelInk);
    });

    testWidgets('a tile with a symbol puts it above the label, or beside it '
        'on a wide tile', (tester) async {
      final want = TileFacts(
        id: 'tile-2',
        boardId: 'board-1',
        cellKey: placedKey('board-1', 0, 1),
        label: 'want',
        colorKey: 'verb',
      );
      Future<(Rect, Rect)> at(Size size) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox.fromSize(
                size: size,
                child: TileView(tile: want, onTap: () {}),
              ),
            ),
          ),
        );
        return (
          tester.getRect(find.byKey(TileView.symbolKey)),
          tester.getRect(find.text('want')),
        );
      }

      final (upPicture, upLabel) = await at(const Size(90, 110));
      expect(upPicture.bottom, lessThanOrEqualTo(upLabel.top));
      final (widePicture, wideLabel) = await at(const Size(220, 80));
      expect(widePicture.right, lessThanOrEqualTo(wideLabel.left));
      expect(tester.takeException(), isNull);
    });

    testWidgets('in the dark a tile keeps its label in tile ink on the dark '
        'family fill', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: chorusDarkTheme(),
          home: SizedBox(
            width: 120,
            height: 120,
            child: TileView(
              tile: TileFacts(
                id: 'tile-3',
                boardId: 'board-1',
                cellKey: placedKey('board-1', 0, 2),
                label: 'what',
                colorKey: 'question',
              ),
              onTap: () {},
            ),
          ),
        ),
      );
      final face = tester.widget<DecoratedBox>(
        find.byKey(PressableSurface.faceKey),
      );
      expect(
        (face.decoration as BoxDecoration).color,
        TileFamily.question.dark.fill,
      );
      final edge = tester.widget<DecoratedBox>(
        find.byKey(PressableSurface.edgeKey),
      );
      expect(
        (edge.decoration as BoxDecoration).color,
        TileFamily.question.dark.edge,
      );
    });
  });

  group('Add a word with a photo and a recording', () {
    testWidgets('the sheet has no media rows unless it is given them', (
      tester,
    ) async {
      final store = FakeMediaBoardStore.seeded(leaveEmpty: const {_empty});
      await tester.pumpWidget(_host(store));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Photo (optional)'), findsNothing);
      expect(_recordButton, findsNothing);
    });

    testWidgets('a store that cannot hold media hashes is not offered them', (
      tester,
    ) async {
      final store = FakeBoardStore.seeded(leaveEmpty: const {_empty});
      await tester.pumpWidget(
        _host(store, media: FakeMediaStore(), capture: FakeMediaCapture()),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Photo (optional)'), findsNothing);
      expect(_recordButton, findsNothing);
    });

    testWidgets('photo and recording end up on the new tile', (tester) async {
      final store = FakeMediaBoardStore.seeded(leaveEmpty: const {_empty});
      final media = FakeMediaStore();
      final capture = FakeMediaCapture();
      await tester.pumpWidget(_host(store, media: media, capture: capture));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Grandma');
      await tester.ensureVisible(find.text('Take or choose a photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take or choose a photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose a photo'));
      await tester.pumpAndSettle();

      expect(capture.picks, [false]);
      expect(find.byKey(const ValueKey('word-photo-preview')), findsOneWidget);
      // Picked, but not kept anywhere until the word is saved.
      expect(media.pendingUploads, 0);

      final gesture = await _hold(tester);
      expect(capture.recording, isTrue);
      expect(find.text('Recording. Let go to stop'), findsOneWidget);
      await gesture.up();
      await tester.pumpAndSettle();

      expect(capture.stops, 1);
      expect(find.text('Hold to record again'), findsOneWidget);
      expect(media.pendingUploads, 0);

      await tester.ensureVisible(find.text('Play it back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Play it back'));
      await tester.pump();
      expect(capture.played, [capture.clip]);

      await tester.ensureVisible(find.text('Add to board'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to board'));
      await tester.pumpAndSettle();

      final added = store.tiles.singleWhere((t) => t.label == 'Grandma');
      expect(added.imageHash, fakeHashOf(tinyPng));
      expect(added.audioHash, fakeHashOf(capture.clip!));
      expect(
        CellKey.parse(added.cellKey),
        PlacedCell(store.homeBoardId, _empty.$1, _empty.$2),
      );
      expect(media.pendingUploads, 2);
      expect(media.imageFor(added.imageHash), isNotNull);
      expect(media.hasAudio(added.audioHash), isTrue);
    });

    testWidgets('a word with neither is added as before', (tester) async {
      final store = FakeMediaBoardStore.seeded(leaveEmpty: const {_empty});
      final media = FakeMediaStore();
      await tester.pumpWidget(
        _host(store, media: media, capture: FakeMediaCapture()),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'park');
      // Let the field finish scrolling its caret into view first, or it
      // scrolls the button back out after ensureVisible.
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Add to board'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to board'));
      await tester.pumpAndSettle();

      final added = store.tiles.singleWhere((t) => t.label == 'park');
      expect(added.imageHash, isNull);
      expect(added.audioHash, isNull);
      expect(media.pendingUploads, 0);
    });

    testWidgets('closing the sheet keeps and sends nothing', (tester) async {
      final store = FakeMediaBoardStore.seeded(leaveEmpty: const {_empty});
      final media = FakeMediaStore();
      final capture = FakeMediaCapture(hasCamera: false);
      final tilesBefore = store.tiles.length;
      await tester.pumpWidget(_host(store, media: media, capture: capture));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // No camera: one tap goes straight to the photo library.
      await tester.ensureVisible(find.text('Choose a photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose a photo'));
      await tester.pumpAndSettle();
      final gesture = await _hold(tester);
      await gesture.up();
      await tester.pumpAndSettle();

      Navigator.of(tester.element(find.byType(WordForm))).pop();
      await tester.pumpAndSettle();

      expect(store.tiles.length, tilesBefore);
      expect(media.pendingUploads, 0);
      expect(media.bytesOf(fakeHashOf(tinyPng)), isNull);
    });

    testWidgets('closing the sheet mid-recording throws the recording away', (
      tester,
    ) async {
      final store = FakeMediaBoardStore.seeded(leaveEmpty: const {_empty});
      final capture = FakeMediaCapture();
      final media = FakeMediaStore();
      await tester.pumpWidget(_host(store, media: media, capture: capture));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final gesture = await _hold(tester);
      expect(capture.recording, isTrue);

      Navigator.of(tester.element(find.byType(WordForm))).pop();
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pump(maxClipLength);

      // Leaving the sheet cancels the touch, which ends the recording; the
      // clip dies with the sheet.
      expect(capture.stops + capture.cancels, 1);
      expect(capture.recording, isFalse);
      expect(capture.starts, 1);
      expect(media.pendingUploads, 0);
      expect(tester.takeException(), isNull);
    });
  });

  group('Recording', () {
    testWidgets('stops by itself after five seconds', (tester) async {
      final capture = FakeMediaCapture();
      WordDraft? draft;
      await tester.pumpWidget(
        _form(
          media: FakeMediaStore(),
          capture: capture,
          onSubmit: (d) => draft = d,
        ),
      );

      final gesture = await _hold(tester);
      await tester.pump(maxClipLength - const Duration(milliseconds: 100));
      expect(capture.stops, 0);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      expect(capture.stops, 1);
      expect(find.text('Hold to record again'), findsOneWidget);

      // Letting go afterwards does not stop twice or start again.
      await gesture.up();
      await tester.pump();
      expect(capture.stops, 1);
      expect(capture.starts, 1);
      expect(draft, isNull);
    });

    testWidgets('says so when the microphone is refused', (tester) async {
      final capture = FakeMediaCapture(microphoneAllowed: false);
      await tester.pumpWidget(
        _form(media: FakeMediaStore(), capture: capture, onSubmit: (_) {}),
      );

      final gesture = await _hold(tester);
      await gesture.up();
      await tester.pump();

      expect(find.text(microphoneUnavailableMessage), findsOneWidget);
      expect(find.text('Play it back'), findsNothing);
      expect(capture.stops, 0);
    });

    testWidgets('a slip of the finger records nothing and says how', (
      tester,
    ) async {
      final capture = FakeMediaCapture()..clip = null;
      WordDraft? draft;
      await tester.pumpWidget(
        _form(
          media: FakeMediaStore(),
          capture: capture,
          onSubmit: (d) => draft = d,
        ),
      );

      final gesture = await _hold(tester);
      await gesture.up();
      await tester.pump();
      await tester.pump();

      expect(find.text(holdLongerMessage), findsOneWidget);
      expect(find.text('Play it back'), findsNothing);

      await tester.enterText(find.byType(TextField).first, 'more');
      await _save(tester);
      expect(draft!.audioHash, isNull);
    });

    testWidgets('recording again replaces the clip', (tester) async {
      final media = FakeMediaStore();
      final capture = FakeMediaCapture();
      WordDraft? draft;
      await tester.pumpWidget(
        _form(media: media, capture: capture, onSubmit: (d) => draft = d),
      );

      var gesture = await _hold(tester);
      await gesture.up();
      await tester.pump();
      await tester.pump();
      final second = Uint8List.fromList(const [9, 9, 9]);
      capture.clip = second;
      gesture = await _hold(tester);
      await gesture.up();
      await tester.pump();
      await tester.pump();

      await tester.enterText(find.byType(TextField).first, 'more');
      await _save(tester);

      expect(draft!.audioHash, fakeHashOf(second));
      // Only the clip that was saved is kept.
      expect(media.pendingUploads, 1);
    });

    testWidgets('a screen reader starts and stops with two activations', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final capture = FakeMediaCapture();
      await tester.pumpWidget(
        _form(media: FakeMediaStore(), capture: capture, onSubmit: (_) {}),
      );

      tester.semantics.tap(find.semantics.byLabel(RegExp('Activate to start')));
      await tester.pump();
      await tester.pump();
      expect(capture.recording, isTrue);

      tester.semantics.tap(find.semantics.byLabel(RegExp('Activate to stop')));
      await tester.pump();
      await tester.pump();
      expect(capture.stops, 1);
      expect(find.text('Play it back'), findsOneWidget);
      handle.dispose();
    });
  });

  group('Changing a word that has media', () {
    testWidgets('untouched media is left alone', (tester) async {
      final media = FakeMediaStore();
      final hash = media.arrive(tinyPng);
      WordDraft? draft;
      await tester.pumpWidget(
        _form(
          initial: _tile(imageHash: hash, audioHash: 'a' * 64),
          media: media,
          capture: FakeMediaCapture(),
          onSubmit: (d) => draft = d,
        ),
      );

      expect(find.text('Remove photo'), findsOneWidget);
      expect(find.text('This word has a recording.'), findsOneWidget);
      await _save(tester);

      expect(draft!.imageHash, isNull);
      expect(draft!.audioHash, isNull);
    });

    testWidgets('removing asks for both to be cleared', (tester) async {
      final media = FakeMediaStore();
      final hash = media.arrive(tinyPng);
      WordDraft? draft;
      await tester.pumpWidget(
        _form(
          initial: _tile(imageHash: hash, audioHash: 'a' * 64),
          media: media,
          capture: FakeMediaCapture(),
          onSubmit: (d) => draft = d,
        ),
      );

      await tester.tap(find.text('Remove photo'));
      await tester.pump();
      await tester.ensureVisible(find.text('Remove recording'));
      await tester.pump();
      await tester.tap(find.text('Remove recording'));
      await tester.pump();
      expect(find.text('Remove photo'), findsNothing);
      expect(find.text('Remove recording'), findsNothing);

      await _save(tester);

      expect(draft!.imageHash, '');
      expect(draft!.audioHash, '');
    });

    testWidgets('a saved recording plays through the tile speaker', (
      tester,
    ) async {
      final media = FakeMediaStore();
      final clipHash = media.arrive(Uint8List.fromList(const [7, 7]));
      final speaker = FakeTileSpeaker(media: media);
      final tile = _tile(audioHash: clipHash);
      await tester.pumpWidget(
        _form(
          initial: tile,
          media: media,
          capture: FakeMediaCapture(),
          speaker: speaker,
          onSubmit: (_) {},
        ),
      );

      await tester.ensureVisible(find.text('Play it back'));
      await tester.pump();
      await tester.tap(find.text('Play it back'));
      await tester.pump();

      expect(speaker.playedClips, [tile.id]);
    });

    testWidgets('a file that is not a picture is refused with a message', (
      tester,
    ) async {
      final media = FakeMediaStore()..refuseImages = true;
      WordDraft? draft;
      await tester.pumpWidget(
        _form(
          media: media,
          capture: FakeMediaCapture(hasCamera: false),
          onSubmit: (d) => draft = d,
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'cat');
      await tester.ensureVisible(find.text('Choose a photo'));
      await tester.pump();
      await tester.tap(find.text('Choose a photo'));
      await tester.pump();
      await tester.pump();
      await _save(tester);

      expect(draft, isNull);
      expect(find.text(photoUnusableMessage), findsOneWidget);

      // Saving again goes through without the photo.
      await _save(tester);
      expect(draft!.label, 'cat');
      expect(draft!.imageHash, isNull);
    });
  });

  group('saveDraftMedia', () {
    test('writes only what changed, and clears with an empty hash', () async {
      final store = FakeMediaBoardStore.seeded();
      final id = store.tiles.first.id;
      TileFacts tile() => store.tiles.firstWhere((t) => t.id == id);

      await saveDraftMedia(
        store,
        tile(),
        WordDraft(
          label: tile().label,
          speech: '',
          imageHash: 'i1',
          audioHash: 'a1',
        ),
      );
      expect((tile().imageHash, tile().audioHash), ('i1', 'a1'));

      var notified = 0;
      store.addListener(() => notified++);
      await saveDraftMedia(
        store,
        tile(),
        WordDraft(
          label: tile().label,
          speech: '',
          imageHash: 'i1',
          audioHash: null,
        ),
      );
      expect(notified, 0, reason: 'nothing changed, nothing written');

      await saveDraftMedia(
        store,
        tile(),
        WordDraft(label: tile().label, speech: '', imageHash: ''),
      );
      expect((tile().imageHash, tile().audioHash), (null, 'a1'));
    });

    test('a partner cannot set media', () async {
      final store = FakeMediaBoardStore.seeded()..role = CircleRole.partner;
      final tile = store.tiles.first;
      expect(
        () => saveDraftMedia(
          store,
          tile,
          WordDraft(label: tile.label, speech: '', imageHash: 'i1'),
        ),
        throwsStateError,
      );
    });
  });

  group('FakeTileSpeaker', () {
    test('plays the clip when cached and speaks the text otherwise', () async {
      final media = FakeMediaStore();
      final speech = FakeSpeech();
      final speaker = FakeTileSpeaker(media: media, speech: speech);
      final clip = Uint8List.fromList(const [4, 2]);
      final tile = _tile(audioHash: fakeHashOf(clip));

      await speaker.speakTile(tile);
      expect(speech.spoken, ['Grandma']);
      expect(speaker.playedClips, isEmpty);

      media.arrive(clip);
      await speaker.speakTile(tile);
      expect(speech.spoken, ['Grandma']);
      expect(speaker.playedClips, [tile.id]);
    });
  });
}
