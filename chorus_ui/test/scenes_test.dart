// Picture scenes: the child's "Scenes" button, picker and full-screen
// photo, and the adult's list and spot editor, all against the fakes.
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/contracts_scenes.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_features.dart';
import 'package:chorus_ui/fakes_media.dart';
import 'package:chorus_ui/fakes_scenes.dart';
import 'package:chorus_ui/features/flags/w8.dart';
import 'package:chorus_ui/scenes/scene_photo.dart';
import 'package:chorus_ui/scenes/scenes_screen.dart';
import 'package:chorus_ui/scenes/talker_scenes.dart';
import 'package:chorus_ui/talker/talker_screen.dart';
import 'package:chorus_ui/theme.dart';
import 'package:chorus_ui/widgets/tile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final String photoHash = 'b' * 64;

Scene park() => Scene(
  id: 'park',
  name: 'At the park',
  imageHash: photoHash,
  spots: const [
    SceneSpot(rect: SpotRect(0.1, 0.1, 0.4, 0.8), label: 'Grandma'),
    SceneSpot(
      rect: SpotRect(0.6, 0.5, 0.3, 0.4),
      label: 'dog',
      speech: 'our dog Biscuit',
    ),
  ],
);

Future<void> pumpApp(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(360, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: chorusTheme(), home: screen));
  await tester.pump();
}

/// The point at fractions ([x], [y]) of the photo on screen.
Offset onPhoto(WidgetTester tester, double x, double y) {
  final frame = tester.getRect(find.byKey(ScenePhoto.frameKey).last);
  return Offset(
    frame.left + x * frame.width,
    frame.top + y * frame.height,
  );
}

Finder tile(String label) =>
    find.byWidgetPredicate((w) => w is TileView && w.tile.label == label);

void main() {
  test('the flag is on', () {
    expect(pictureScenesEnabled, isTrue);
  });

  group("on the child's board", () {
    late FakeBoardStore store;
    late FakeSpeech speech;

    setUp(() {
      store = FakeBoardStore.seeded();
      speech = FakeSpeech();
    });

    Widget talker({SceneBook? scenes, FakeWordLog? log}) => TalkerScreen(
      store: store,
      speech: speech,
      sync: FakeSyncStatus(),
      wordLog: log,
      scenes: scenes,
    );

    for (final size in const [
      Size(360, 800),
      Size(600, 900),
      Size(800, 1280),
      Size(1280, 800),
    ]) {
      testWidgets('"Scenes" moves no button and not the grid at $size', (
        tester,
      ) async {
        await pumpApp(tester, talker(), size: size);
        Rect leave() => tester.getRect(find.text('Hold to leave').first);
        Rect speak() => tester.getRect(find.bySemanticsLabel('Speak'));
        Rect word() => tester.getRect(tile('want'));
        final before = (leave(), speak(), word());

        await pumpApp(
          tester,
          talker(scenes: FakeSceneBook(scenes: [park()])),
          size: size,
        );
        expect(find.byKey(TalkerScenesButton.buttonKey), findsOneWidget);
        expect((leave(), speak(), word()), before);
      });
    }

    for (final size in const [Size(820, 360), Size(320, 640)]) {
      testWidgets('there is no room for "Scenes" at $size, so it is left out', (
        tester,
      ) async {
        await pumpApp(
          tester,
          talker(scenes: FakeSceneBook(scenes: [park()])),
          size: size,
        );
        expect(find.byKey(TalkerScenesButton.buttonKey), findsNothing);
      });
    }

    testWidgets('there is no button without scenes', (tester) async {
      await pumpApp(tester, talker(scenes: FakeSceneBook()));
      expect(find.byKey(TalkerScenesButton.buttonKey), findsNothing);
      await pumpApp(tester, talker());
      expect(find.byKey(TalkerScenesButton.buttonKey), findsNothing);
    });

    testWidgets('a tapped spot speaks its word, is outlined for a moment and '
        'adds the word to the strip, and the word log never hears of it', (
      tester,
    ) async {
      final log = FakeWordLog(enabled: true);
      await pumpApp(
        tester,
        talker(scenes: FakeSceneBook(scenes: [park()]), log: log),
      );
      await tester.tap(find.byKey(TalkerScenesButton.buttonKey));
      await tester.pumpAndSettle();
      expect(find.text(chooseSceneTitle), findsOneWidget);
      await tester.tap(find.text('At the park'));
      await tester.pumpAndSettle();

      // Between the spots: nothing.
      await tester.tapAt(onPhoto(tester, 0.55, 0.05));
      await tester.pump();
      expect(speech.spoken, isEmpty);
      expect(find.byKey(SceneScreen.litKey), findsNothing);

      await tester.tapAt(onPhoto(tester, 0.75, 0.7));
      await tester.pump();
      expect(speech.spoken, ['our dog Biscuit']);
      expect(find.byKey(SceneScreen.litKey), findsOneWidget);
      await tester.pump(spotLitFor);
      expect(find.byKey(SceneScreen.litKey), findsNothing);

      await tester.tapAt(onPhoto(tester, 0.2, 0.5));
      await tester.pump();
      expect(speech.spoken.last, 'Grandma');

      // Back to the board: the strip holds both words.
      await tester.tap(find.bySemanticsLabel(backToBoardLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(backToBoardLabel));
      await tester.pumpAndSettle();
      expect(find.text('dog Grandma'), findsOneWidget);
      expect(log.kept, isEmpty);
      await tester.pump(spotLitFor);
    });

    testWidgets('a scene word is never sent as a tile', (tester) async {
      final word = sceneWord(park(), 1);
      expect(word.label, 'dog');
      expect(word.spokenText, 'our dog Biscuit');
      expect(word.boardId, isEmpty);
      expect(CellKey.parse(word.cellKey), isA<UnknownCell>());
    });
  });

  group('for adults', () {
    testWidgets('a scene is made from a photo, then a drag draws a spot and '
        'asks for its word, and the spot is saved', (tester) async {
      final book = FakeSceneBook();
      final media = FakeMediaStore();
      await pumpApp(
        tester,
        ScenesScreen(book: book, media: media, capture: FakeMediaCapture()),
      );
      expect(find.text(noScenesYetMessage), findsOneWidget);
      await tester.tap(find.text(makeSceneLabel));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Kitchen');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(book.scenes.single.name, 'Kitchen');
      expect(media.bytesOf(book.scenes.single.imageHash), isNotNull);
      expect(find.text(drawSpotsHint), findsOneWidget);

      await tester.dragFrom(
        onPhoto(tester, 0.2, 0.2),
        onPhoto(tester, 0.5, 0.6) - onPhoto(tester, 0.2, 0.2),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('spot-label')), 'cup');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final spot = book.scenes.single.spots.single;
      expect(spot.label, 'cup');
      expect(spot.rect.x, closeTo(0.2, 0.02));
      expect(spot.rect.y, closeTo(0.2, 0.02));
      expect(spot.rect.width, closeTo(0.3, 0.03));
      expect(spot.rect.height, closeTo(0.4, 0.03));
      expect(find.text(changeWordLabel), findsOneWidget);
    });

    testWidgets('a chosen spot can be moved, resized, renamed and removed', (
      tester,
    ) async {
      final book = FakeSceneBook(scenes: [park()]);
      await pumpApp(tester, SceneEditorScreen(book: book, sceneId: 'park'));
      // Choose the dog.
      await tester.tapAt(onPhoto(tester, 0.75, 0.7));
      await tester.pump();
      expect(find.byKey(SceneEditorScreen.resizeKey), findsOneWidget);

      // Move it up and left.
      await tester.dragFrom(
        onPhoto(tester, 0.75, 0.7),
        onPhoto(tester, 0.65, 0.6) - onPhoto(tester, 0.75, 0.7),
      );
      await tester.pumpAndSettle();
      var dog = book.scenes.single.spots[1];
      expect(dog.rect.x, closeTo(0.5, 0.02));
      expect(dog.rect.y, closeTo(0.4, 0.02));
      expect(dog.rect.width, closeTo(0.3, 1e-9));

      // Resize from its corner.
      final corner = tester.getCenter(find.byKey(SceneEditorScreen.resizeKey));
      await tester.dragFrom(corner, onPhoto(tester, 0.1, 0.1) - onPhoto(tester, 0, 0));
      await tester.pumpAndSettle();
      dog = book.scenes.single.spots[1];
      expect(dog.rect.x, closeTo(0.5, 0.02));
      expect(dog.rect.width, closeTo(0.4, 0.03));

      await tester.tap(find.text(changeWordLabel));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('spot-label')), 'puppy');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(book.scenes.single.spots[1].label, 'puppy');

      await tester.tap(find.text(removeSpotLabel));
      await tester.pumpAndSettle();
      expect(book.scenes.single.spots.map((s) => s.label), ['Grandma']);
    });

    testWidgets('a change that cannot be saved says so in plain words', (
      tester,
    ) async {
      final book = FakeSceneBook(scenes: [park()]);
      await pumpApp(tester, SceneEditorScreen(book: book, sceneId: 'park'));
      book.online = false;
      await tester.tapAt(onPhoto(tester, 0.75, 0.7));
      await tester.pump();
      await tester.tap(find.text(removeSpotLabel));
      await tester.pumpAndSettle();
      expect(find.text(sceneNotSavedMessage), findsOneWidget);
      expect(sceneNotSavedMessage.toLowerCase(), isNot(contains('error')));
      expect(book.scenes.single.spots, hasLength(2));
    });

    testWidgets('a read-only partner sees the scenes and cannot change them', (
      tester,
    ) async {
      final book = FakeSceneBook(
        scenes: [park()],
        role: CircleRole.partner,
      );
      await pumpApp(
        tester,
        ScenesScreen(
          book: book,
          media: FakeMediaStore(),
          capture: FakeMediaCapture(),
        ),
      );
      expect(find.text(makeSceneLabel), findsNothing);
      expect(find.text(scenesReadOnlyMessage), findsOneWidget);
      await tester.tap(find.text('At the park'));
      await tester.pumpAndSettle();
      await tester.dragFrom(
        onPhoto(tester, 0.6, 0.05),
        const Offset(40, 40),
      );
      await tester.pumpAndSettle();
      expect(find.text('What does this spot say?'), findsNothing);
      expect(book.scenes.single.spots, hasLength(2));
      expect(find.byTooltip('More for this scene'), findsNothing);
    });

    testWidgets('a scene can be renamed and removed from its menu', (
      tester,
    ) async {
      final book = FakeSceneBook(scenes: [park()]);
      await pumpApp(tester, ScenesScreen(book: book));
      await tester.tap(find.text('At the park'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('More for this scene'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(renameSceneLabel));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'The park');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(book.scenes.single.name, 'The park');

      await tester.tap(find.byTooltip('More for this scene'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(archiveSceneLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(book.scenes, isEmpty);
      expect(find.text(noScenesYetMessage), findsOneWidget);
    });
  });
}
