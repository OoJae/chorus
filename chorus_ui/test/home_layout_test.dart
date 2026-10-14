// Home's layout: full bleed on card, the chip at the top, the display title
// cropped by the hero's top edge, the hero leaning back as the page scrolls
// (its transform only), the actions in the thumb's reach, at every size,
// text scale and mode.
import 'package:chorus_ui/brand/board_object.dart';
import 'package:chorus_ui/brand/pressable_surface.dart';
import 'package:chorus_ui/brand/test_fonts.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/home/home.dart';
import 'package:chorus_ui/theme.dart';
import 'package:chorus_ui/widgets/sync_chip.dart';
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

bool _isPhone(Size size) => size.shortestSide < 600;

Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(360, 820),
  double textScale = 1,
  bool dark = false,
  bool reduced = false,
  bool partner = false,
  SyncStatus? sync,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final store = FakeBoardStore.seeded();
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? chorusDarkTheme() : chorusTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduced,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: HomeLayout(
        status: SyncChip(
          sync: sync ?? FakeSyncStatus(state: SyncState.offline),
        ),
        title: "Maya's board",
        hero: (context, lean) => HomeHero(
          store: store,
          childName: 'Maya',
          lean: lean,
          onOpen: () {},
        ),
        actions: HomeActions(
          openLabel: partner ? "View Maya's board" : "Open Maya's board",
          onOpen: () {},
          editLabel: partner ? null : 'Edit words',
          onEdit: () {},
        ),
        notes: const [
          HomeNote(
            icon: Icon(Icons.error_outline_rounded),
            alert: true,
            message:
                'This device could not check in with the others. The board '
                'saved here still works.',
            action: TextButton(onPressed: null, child: Text('Retry')),
          ),
        ],
        list: [
          SwitchListTile(
            secondary: const Icon(Icons.cloud_off_rounded),
            title: const Text('Work offline'),
            subtitle: const Text(
              'Pauses sync on this device. Changes are kept here and sent '
              'when you switch it back.',
            ),
            value: false,
            onChanged: (_) {},
          ),
          for (final label in [
            'Invite someone',
            'Share a view-only board',
            'Print a paper copy',
            'Word log and this week',
            'Credits',
            'Sign out',
          ])
            HomeEntry(icon: Icons.circle_outlined, label: label, onTap: () {}),
        ],
      ),
    ),
  );
  await tester.pump();
}

Matrix4 _tilt(WidgetTester tester) =>
    tester.widget<Transform>(find.byKey(BoardObject.tiltKey)).transform;

void main() {
  setUpAll(loadChorusFonts);

  for (final size in _sizes) {
    for (final textScale in [1.0, 2.0]) {
      for (final dark in [false, true]) {
        final name =
            '${size.width.toInt()}x${size.height.toInt()}, text '
            '${textScale}x, ${dark ? 'dark' : 'light'}';
        testWidgets('$name: lays out with nothing cut off', (tester) async {
          await _pump(tester, size: size, textScale: textScale, dark: dark);
          expect(tester.takeException(), isNull);

          final title = tester.renderObject<RenderParagraph>(
            find.text("Maya's board"),
          );
          expect(title.didExceedMaxLines, isFalse, reason: 'title is whole');

          // Every row of the list can be reached.
          await tester.scrollUntilVisible(
            find.text('Sign out'),
            100,
            scrollable: find.descendant(
              of: find.byKey(HomeLayout.scrollKey),
              matching: find.byType(Scrollable),
            ),
          );
          expect(tester.takeException(), isNull);

          final page = tester.widget<Scaffold>(find.byType(Scaffold));
          expect(
            page.backgroundColor,
            dark ? ChorusColors.dark.card : ChorusColors.light.card,
          );
        });
      }
    }

    if (_isPhone(size)) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}: the actions '
          'are in the bottom third, 48 dp and 8 dp apart', (tester) async {
        await _pump(tester, size: size);
        final open = tester.getRect(find.byKey(HomeActions.openKey));
        final edit = tester.getRect(
          find.widgetWithText(OutlinedButton, 'Edit words'),
        );
        expect(open.top, greaterThanOrEqualTo(size.height * 2 / 3));
        expect(edit.top, greaterThanOrEqualTo(size.height * 2 / 3));
        expect(open.height, greaterThanOrEqualTo(48));
        expect(edit.height, greaterThanOrEqualTo(48));
        final apart = open.right <= edit.left
            ? edit.left - open.right
            : edit.top - open.bottom;
        expect(apart, greaterThanOrEqualTo(8));
      });
    }
  }

  testWidgets('the chip is at the top, then the title, which the hero\'s '
      'top edge crops', (tester) async {
    await _pump(tester);
    final chip = tester.getRect(find.byType(SyncChip));
    final title = tester.getRect(find.text("Maya's board"));
    final hero = tester.getRect(find.byKey(HomeHero.boardKey));
    expect(chip.left, ChorusSpace.marginPhone);
    expect(chip.bottom, lessThanOrEqualTo(title.top));
    expect(title.left, ChorusSpace.marginPhone);
    // The hero starts inside the title's foot.
    expect(hero.top, lessThan(title.bottom));
    expect(hero.top, greaterThan(title.top + title.height / 2));
  });

  for (final size in const [Size(360, 640), Size(820, 360)]) {
    testWidgets('${size.width.toInt()}x${size.height.toInt()}: the title is '
        'drawn in front of the hero, so its descenders stay whole, and a tap '
        'there still opens the board', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var opened = 0;
      const heroKey = ValueKey('hero');
      await tester.pumpWidget(
        MaterialApp(
          theme: chorusTheme(),
          home: HomeLayout(
            status: const SizedBox(height: 36),
            title: "Maya's board",
            hero: (context, lean) => GestureDetector(
              key: heroKey,
              behavior: HitTestBehavior.opaque,
              onTap: () => opened++,
              child: ColoredBox(color: ChorusColors.of(context).surface),
            ),
            actions: HomeActions(
              openLabel: "Open Maya's board",
              onOpen: () {},
              editLabel: 'Edit words',
              onEdit: () {},
            ),
          ),
        ),
      );
      final title = find.text("Maya's board");
      expect(title, findsOneWidget);
      final titleRect = tester.getRect(title);
      final heroRect = tester.getRect(find.byKey(heroKey));
      expect(heroRect.top, lessThan(titleRect.bottom));

      // Painted after the hero: of the two, the hero is first in the
      // render tree's paint order and the title last.
      final order = tester
          .renderObjectList(
            find.descendant(
              of: find.byType(HomeLayout),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget.key == heroKey ||
                    (widget is Text && widget.data == "Maya's board"),
              ),
            ),
          )
          .toList();
      expect(order.last, isA<RenderParagraph>(), reason: 'title in front');

      // In the strip where they overlap, the finger reaches the board.
      await tester.tapAt(
        Offset(titleRect.left + 8, (heroRect.top + titleRect.bottom) / 2),
      );
      expect(opened, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('screen readers hear the title as the heading', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);
    expect(
      tester.getSemantics(find.text("Maya's board")),
      isSemantics(label: "Maya's board", isHeader: true),
    );
    semantics.dispose();
  });

  // Held sideways the list scrolls beside the hero, and leans it.
  for (final size in [const Size(360, 820), const Size(820, 360)]) {
    testWidgets('${size.width.toInt()}x${size.height.toInt()}: as the page '
        'scrolls the hero leans back, and only its transform changes', (
      tester,
    ) async {
      await _pump(tester, size: size);
      final board = tester.widget<BoardObject>(find.byKey(HomeHero.boardKey));
      final upright = _tilt(tester).clone();
      final box = tester.getSize(find.byKey(HomeHero.boardKey));

      await tester.drag(
        find.byKey(HomeLayout.scrollKey),
        const Offset(0, -120),
      );
      await tester.pump();
      final leaned = _tilt(tester);
      // Turned further about the horizontal axis: the card's height shrinks
      // on screen.
      expect(leaned.entry(1, 1).abs(), lessThan(upright.entry(1, 1).abs()));
      // Nothing was built or laid out again.
      expect(
        identical(
          tester.widget<BoardObject>(find.byKey(HomeHero.boardKey)),
          board,
        ),
        isTrue,
      );
      expect(tester.getSize(find.byKey(HomeHero.boardKey)), box);

      await tester.drag(find.byKey(HomeLayout.scrollKey), const Offset(0, 400));
      await tester.pumpAndSettle();
      for (var i = 0; i < 16; i++) {
        expect(_tilt(tester).storage[i], closeTo(upright.storage[i], 1e-6));
      }
    });
  }

  testWidgets('under reduced motion the hero stays flat while the page '
      'scrolls', (tester) async {
    await _pump(tester, reduced: true);
    expect(find.byKey(BoardObject.tiltKey), findsNothing);
    await tester.drag(find.byKey(HomeLayout.scrollKey), const Offset(0, -200));
    await tester.pump();
    expect(find.byKey(BoardObject.tiltKey), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('820x360: side by side, each action keeps its words on one '
      'line and the two are one height', (tester) async {
    await _pump(tester, size: const Size(820, 360));
    final open = tester.renderObject<RenderParagraph>(
      find.text("Open Maya's board"),
    );
    final edit = tester.renderObject<RenderParagraph>(find.text('Edit words'));
    // One line of the 17/22 label, and of the 15/20 one.
    expect(open.size.height, lessThan(2 * 22));
    expect(edit.size.height, lessThan(2 * 20));
    final openBox = tester.getRect(find.byKey(HomeActions.openKey));
    final editBox = tester.getRect(find.byType(OutlinedButton));
    expect(openBox.height, editBox.height);
    expect(openBox.top, editBox.top);
    expect(editBox.left - openBox.right, greaterThanOrEqualTo(8));
    expect(tester.takeException(), isNull);

    // At twice the text size they wrap, and still match.
    await _pump(tester, size: const Size(820, 360), textScale: 2);
    expect(
      tester.getRect(find.byKey(HomeActions.openKey)).height,
      tester.getRect(find.byType(OutlinedButton)).height,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a partner gets one action, to view the board', (tester) async {
    await _pump(tester, partner: true);
    expect(find.text("View Maya's board"), findsOneWidget);
    expect(find.text('Edit words'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a disabled open action looks it and does nothing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: chorusTheme(),
        home: const Scaffold(
          body: HomeActions(
            openLabel: "Open Maya's board",
            onOpen: null,
            editLabel: 'Edit words',
          ),
        ),
      ),
    );
    final surface = tester.widget<PressableSurface>(
      find.byKey(HomeActions.openKey),
    );
    expect(surface.onTap, isNull);
    expect(surface.color, ChorusColors.light.line);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );
  });
}
