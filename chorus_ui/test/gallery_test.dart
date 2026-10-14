// The review gallery: every screen opens on the fakes, from the list and
// straight from its address, in light and dark, with the circle's clash
// and week of words already there.
import 'package:chorus_ui/editor/add_word_sheet.dart';
import 'package:chorus_ui/editor/editor_screen.dart';
import 'package:chorus_ui/features/features.dart';
import 'package:chorus_ui/main_fake.dart';
import 'package:chorus_ui/onboarding/onboarding_view.dart';
import 'package:chorus_ui/talker/talker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _open(
  WidgetTester tester,
  GalleryPage page, {
  ThemeMode mode = ThemeMode.light,
  Size size = const Size(360, 780),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ChorusGallery(initialRoute: page.route, themeMode: mode),
  );
  // Past the launch reveal and every entrance.
  await tester.pump(const Duration(seconds: 2));
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  test('the fakes hold a clash in the tray and a week of words', () async {
    final fakes = GalleryFakes();
    addTearDown(fakes.dispose);
    expect(
      fakes.store.tiles.where((tile) => tile.label == 'playground'),
      hasLength(1),
    );
    expect(fakes.wordLog.kept.length, 37);
    final week = await fakes.summary.thisWeek();
    expect(week, isNotNull);
    expect(week!.topWords.first.label, 'want');
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final page in GalleryPage.values) {
      testWidgets('${page.title} opens from its address, ${mode.name}', (
        tester,
      ) async {
        await _open(tester, page, mode: mode);
        expect(tester.takeException(), isNull);
        final expected = switch (page) {
          GalleryPage.onboarding => find.byType(OnboardingView),
          GalleryPage.talker => find.byType(TalkerScreen),
          GalleryPage.editor => find.byType(EditorScreen),
          GalleryPage.addWord => find.byType(WordForm),
          GalleryPage.wordLog => find.byType(WordLogScreen),
          GalleryPage.thisWeek => find.byType(ThisWeekScreen),
          GalleryPage.share => find.byType(ShareViewOnlyScreen),
          GalleryPage.export => find.byType(ExportObfScreen),
          GalleryPage.home => find.text("Open Maya's board"),
          GalleryPage.credits => find.text('Credits'),
        };
        expect(expected, findsWidgets);
      });
    }
  }

  testWidgets('the list opens each screen, and the theme switch turns the '
      'gallery dark', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ChorusGallery(themeMode: ThemeMode.light));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Gallery'))).brightness,
      Brightness.light,
    );
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Gallery'))).brightness,
      Brightness.dark,
    );

    await tester.tap(find.text(GalleryPage.thisWeek.title));
    await tester.pumpAndSettle();
    expect(find.byType(ThisWeekScreen), findsOneWidget);
  });

  testWidgets('home opens the child board from its primary action', (
    tester,
  ) async {
    await _open(tester, GalleryPage.home);
    await tester.tap(find.text("Open Maya's board"));
    await tester.pumpAndSettle();
    expect(find.byType(TalkerScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the editor shows the clash waiting in Needs a home', (
    tester,
  ) async {
    await _open(tester, GalleryPage.editor, size: const Size(1280, 800));
    expect(find.textContaining('Needs a home'), findsWidgets);
    expect(find.text('playground'), findsWidgets);
  });
}
