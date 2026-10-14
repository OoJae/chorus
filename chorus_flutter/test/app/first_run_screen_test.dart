import 'dart:async';

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_flutter/screens/first_run_screen.dart';
import 'package:chorus_flutter/screens/home_screen.dart';
import 'package:chorus_flutter/screens/signed_in_shell.dart';
import 'package:chorus_ui/brand/haptics.dart';
import 'package:chorus_ui/brand/pressable_surface.dart';
import 'package:chorus_ui/brand/test_fonts.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

const _choices = ['Make a board', 'Join with a code', 'Try a demo board'];

/// A gateway whose new circles wait for [gate].
class _SlowGateway extends FakeGateway {
  final Completer<void> gate = Completer<void>();

  @override
  Future<CircleInfo> createCircle({
    required String childName,
    required String displayName,
  }) async {
    await gate.future;
    return super.createCircle(childName: childName, displayName: displayName);
  }
}

Future<void> _pumpOnPhone(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(360, 640),
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
  await tester.pumpAndSettle();
}

Finder _choice(String title) => find.ancestor(
  of: find.text(title),
  matching: find.byType(PressableSurface),
);

void main() {
  setUpAll(loadChorusFonts);

  testWidgets('offers the three ways to get a board', (tester) async {
    await pumpScreen(
      tester,
      FirstRunScreen(gateway: FakeGateway(), onCircle: (_) {}),
    );

    expect(find.text('Make a board'), findsOneWidget);
    expect(find.text('Join with a code'), findsOneWidget);
    expect(find.text('Try a demo board'), findsOneWidget);
  });

  testWidgets('the demo makes a circle for Maya in one tap', (tester) async {
    final gateway = FakeGateway();
    CircleInfo? got;
    await pumpScreen(
      tester,
      FirstRunScreen(gateway: gateway, onCircle: (circle) => got = circle),
    );

    await tester.tap(find.text('Try a demo board'));
    await tester.pumpAndSettle();

    expect(gateway.created.single.$1, 'Maya');
    expect(got?.childName, 'Maya');
  });

  testWidgets('starting a board asks for both names', (tester) async {
    final gateway = FakeGateway();
    CircleInfo? got;
    await pumpScreen(
      tester,
      FirstRunScreen(gateway: gateway, onCircle: (circle) => got = circle),
    );

    await tester.tap(find.text('Make a board'));
    await tester.pumpAndSettle();

    // An empty form is refused and nothing is sent.
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.text('Please fill this in'), findsNWidgets(2));
    expect(gateway.created, isEmpty);

    await tester.enterText(find.byKey(const ValueKey('first-field')), ' Ada ');
    await tester.enterText(find.byKey(const ValueKey('second-field')), 'Dad');
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(gateway.created.single, ('Ada', 'Dad'));
    expect(got?.childName, 'Ada');
  });

  testWidgets('a refused code is explained in plain words, with Retry', (
    tester,
  ) async {
    final gateway = FakeGateway()
      ..failNext = CircleException(failure: CircleFailure.inviteUsed);
    CircleInfo? got;
    await pumpScreen(
      tester,
      FirstRunScreen(gateway: gateway, onCircle: (circle) => got = circle),
    );

    await tester.tap(find.text('Join with a code'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('first-field')), 'ABC234');
    await tester.enterText(
      find.byKey(const ValueKey('second-field')),
      'Ms Lee',
    );
    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(
      find.text('That code has already been used. Ask for a new one.'),
      findsOneWidget,
    );
    expect(got, isNull);

    // Retry repeats the same answers without asking again.
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(gateway.accepted.single, ('ABC234', 'Ms Lee'));
    expect(got?.childName, 'Sam');
  });

  testWidgets('a failure that is not about the circle still offers Retry', (
    tester,
  ) async {
    final gateway = FakeGateway()..failNext = Exception('socket closed');
    await pumpScreen(
      tester,
      FirstRunScreen(gateway: gateway, onCircle: (_) {}),
    );

    await tester.tap(find.text('Try a demo board'));
    await tester.pumpAndSettle();

    expect(find.textContaining('could not reach the server'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    // The raw error never reaches the screen.
    expect(find.textContaining('socket'), findsNothing);
  });

  testWidgets('an adult with no circle lands on the first screen, and the '
      'demo takes them home with the starter board seeded', (tester) async {
    final gateway = FakeGateway();
    final workspace = FakeWorkspace();
    await pumpScreen(
      tester,
      SignedInShell(
        gateway: gateway,
        openWorkspace: () async => workspace,
        speech: FakeSpeech(),
      ),
    );
    // The opening state is a message, not a blank screen.
    expect(find.text('Opening Chorus…'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Who is the board for?'), findsOneWidget);

    await tester.tap(find.text('Try a demo board'));
    await tester.pumpAndSettle();

    expect(find.text("Maya's board"), findsOneWidget);
    // Home, whatever it is redesigned to say.
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(workspace.readied, [('Maya', true)]);
  });

  testWidgets('the display line asks who the board is for, and on a phone '
      'the three choices wait in the thumb zone, large and apart', (
    tester,
  ) async {
    for (final size in const [Size(360, 640), Size(360, 820)]) {
      await _pumpOnPhone(
        tester,
        FirstRunScreen(gateway: FakeGateway(), onCircle: (_) {}),
        size: size,
      );
      final heading = tester.getRect(find.text('Who is the board for?'));
      final rects = [
        for (final title in _choices) tester.getRect(_choice(title)),
      ];
      // Pushed down: the spare room is above the choices, not below them.
      expect(rects.last.bottom, greaterThan(size.height * 2 / 3));
      expect(rects.first.top - heading.bottom, greaterThanOrEqualTo(24));
      final note = tester.getRect(
        find.text('Everyone you invite to a board can see all of it.'),
      );
      expect(size.height - note.bottom, lessThan(48), reason: '$size');
      for (final rect in rects) {
        expect(rect.height, greaterThanOrEqualTo(48));
      }
      for (var i = 1; i < rects.length; i++) {
        expect(rects[i].top - rects[i - 1].bottom, greaterThanOrEqualTo(8));
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('adding another board asks who the new board is for', (
    tester,
  ) async {
    await _pumpOnPhone(
      tester,
      FirstRunScreen(
        gateway: FakeGateway(),
        onCircle: (_) {},
        addingAnother: true,
      ),
    );
    expect(find.text('Who is the new board for?'), findsOneWidget);
  });

  testWidgets('while the board is being made the choices stay where they '
      'are, dimmed and asleep, under a line saying what is happening', (
    tester,
  ) async {
    final gateway = _SlowGateway();
    CircleInfo? got;
    await _pumpOnPhone(
      tester,
      FirstRunScreen(gateway: gateway, onCircle: (circle) => got = circle),
    );
    final before = tester.getRect(_choice('Try a demo board'));

    await tester.tap(find.text('Try a demo board'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Making a demo board…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.getRect(_choice('Try a demo board')), before);
    for (final title in _choices) {
      expect(
        tester.widget<PressableSurface>(_choice(title)).onTap,
        isNull,
        reason: title,
      );
    }
    await tester.tap(find.text('Join with a code'), warnIfMissed: false);
    await tester.pump();
    expect(find.text('Code'), findsNothing, reason: 'no dialog opens');

    gateway.gate.complete();
    await tester.pumpAndSettle();
    expect(got?.childName, 'Maya');
  });

  testWidgets('a failure is felt, once', (tester) async {
    final felt = <ChorusHaptic>[];
    ChorusHaptics.sink = felt.add;
    addTearDown(() => ChorusHaptics.sink = null);
    final gateway = FakeGateway()..failNext = Exception('socket closed');
    await _pumpOnPhone(
      tester,
      FirstRunScreen(gateway: gateway, onCircle: (_) {}),
    );
    await tester.tap(find.text('Try a demo board'));
    await tester.pumpAndSettle();
    expect(felt, [ChorusHaptic.failed]);
  });

  testWidgets('under reduced motion the dimming is a 150 ms crossfade', (
    tester,
  ) async {
    await _pumpOnPhone(
      tester,
      FirstRunScreen(gateway: FakeGateway(), onCircle: (_) {}),
      reduced: true,
    );
    for (final fade in tester.widgetList<AnimatedOpacity>(
      find.byType(AnimatedOpacity),
    )) {
      expect(fade.duration, const Duration(milliseconds: 150));
    }
  });

  for (final size in const [
    Size(360, 640),
    Size(360, 820),
    Size(820, 360),
    Size(1280, 800),
    Size(1440, 900),
  ]) {
    testWidgets('${size.width.toInt()}x${size.height.toInt()}: it builds '
        'without an error, light and dark, with sign-out and an error '
        'showing, and at twice the text size every choice can be reached', (
      tester,
    ) async {
      for (final (dark, scale) in [(false, 1.0), (true, 1.0), (false, 2.0)]) {
        final gateway = FakeGateway()..failNext = Exception('offline');
        await _pumpOnPhone(
          tester,
          FirstRunScreen(
            gateway: gateway,
            onCircle: (_) {},
            onSignOut: () {},
          ),
          size: size,
          dark: dark,
          textScale: scale,
        );
        await tester.ensureVisible(find.text('Try a demo board'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Try a demo board'));
        await tester.pumpAndSettle();
        expect(find.text('Retry'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$dark $scale');
        for (final title in _choices) {
          await tester.ensureVisible(find.text(title));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: title);
        }
      }
    });
  }
}
