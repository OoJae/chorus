// Inviting someone: the choices from the top, the action in reach of the
// thumb, the code on a card in the machine's face. Light and dark, the
// largest text and the five window sizes.
import 'dart:async';

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_flutter/screens/invite_screen.dart';
import 'package:chorus_ui/brand/test_fonts.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:chorus_ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

const _sizes = [
  Size(360, 640),
  Size(360, 820),
  Size(820, 360),
  Size(1280, 800),
  Size(1440, 900),
];

/// A gateway whose next invite waits for [gate].
class _SlowGateway extends FakeGateway {
  final Completer<void> gate = Completer<void>();

  @override
  Future<String> createInvite(CircleInfo circle, CircleRole role) async {
    await gate.future;
    return super.createInvite(circle, role);
  }
}

Future<void> _pump(
  WidgetTester tester,
  FakeGateway gateway, {
  Size size = const Size(360, 800),
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
      home: InviteScreen(gateway: gateway, circle: circle()),
    ),
  );
}

void main() {
  setUpAll(loadChorusFonts);

  testWidgets('a role is chosen, a code is made for it and shown in the '
      "machine's face", (tester) async {
    final gateway = FakeGateway();
    await _pump(tester, gateway);
    expect(find.text("Who are you inviting to Maya's board?"), findsOneWidget);

    await tester.tap(find.text('Teacher'));
    await tester.pump();
    await tester.tap(find.text('Make a code'));
    await tester.pumpAndSettle();

    expect(gateway.invited, [CircleRole.teacher]);
    final code = find.byKey(InviteScreen.codeKey);
    expect(find.text('ABC234'), findsOneWidget);
    expect(
      tester.widget<SelectableText>(code).style!.fontFamily,
      ChorusType.status.fontFamily,
    );
    expect(find.textContaining('They join as: Teacher.'), findsOneWidget);
    expect(find.text('Copy code'), findsOneWidget);

    await tester.tap(find.text('Invite someone else'));
    await tester.pumpAndSettle();
    expect(find.text('Make a code'), findsOneWidget);
  });

  testWidgets('the choices are radio buttons to a screen reader', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, FakeGateway());
    expect(
      tester.getSemantics(
        find.bySemanticsLabel(RegExp(r'^Therapist\. Can change the board')),
      ),
      isSemantics(
        isChecked: true,
        hasCheckedState: true,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
        isEnabled: true,
        hasEnabledState: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('while the code is made the choices stay put and the button '
      'says so', (tester) async {
    final gateway = _SlowGateway();
    await _pump(tester, gateway);
    final teacher = tester.getRect(find.text('Teacher'));
    await tester.tap(find.text('Make a code'));
    await tester.pump();

    expect(find.text('Making a code…'), findsOneWidget);
    expect(tester.getRect(find.text('Teacher')), teacher);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.ancestor(
              of: find.text('Making a code…'),
              matching: find.byWidgetPredicate((w) => w is FilledButton),
            ),
          )
          .onPressed,
      isNull,
    );

    gateway.gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('ABC234'), findsOneWidget);
  });

  testWidgets('a refusal is said in plain words and the button retries', (
    tester,
  ) async {
    final gateway = FakeGateway()
      ..failNext = CircleException(failure: CircleFailure.notAllowed);
    await _pump(tester, gateway);
    await tester.tap(find.text('Make a code'));
    await tester.pumpAndSettle();
    final error = find.text('Only a parent or guardian can do that.');
    expect(error, findsOneWidget);
    expect(
      tester.renderObject<RenderParagraph>(error).text.style!.color,
      ChorusColors.light.alert,
    );
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('ABC234'), findsOneWidget);
  });

  testWidgets('on a phone the action is in the bottom third', (tester) async {
    await _pump(tester, FakeGateway(), size: const Size(360, 800));
    expect(
      tester.getCenter(find.text('Make a code')).dy,
      greaterThan(800 * 2 / 3),
    );
  });

  for (final size in _sizes) {
    for (final dark in [false, true]) {
      testWidgets('fits ${size.width.toInt()}x${size.height.toInt()}, '
          '${dark ? 'dark' : 'light'}, at twice the text', (tester) async {
        await _pump(
          tester,
          FakeGateway(),
          size: size,
          dark: dark,
          textScale: 2,
        );
        expect(tester.takeException(), isNull);
        final scaffold = Theme.of(tester.element(find.byType(Scaffold)));
        expect(
          scaffold.scaffoldBackgroundColor,
          dark ? ChorusColors.dark.card : ChorusColors.light.card,
        );
        await tester.scrollUntilVisible(
          find.text('Make a code'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.text('Make a code'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Make a code'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('ABC234'), findsOneWidget);
      });
    }
  }
}
