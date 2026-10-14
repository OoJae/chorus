import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_flutter/client.dart';
import 'package:chorus_flutter/screens/sign_in_screen.dart';
import 'package:chorus_ui/brand/haptics.dart';
import 'package:chorus_ui/brand/mark.dart';
import 'package:chorus_ui/brand/test_fonts.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:chorus_ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import 'fakes.dart';

const _whatItIs =
    "A talking picture board a child's whole circle keeps in step";
const _howToStart =
    'New here? Choose "Sign up" below and use your own email address. A code '
    'is sent to it.';
const _tryAgain =
    'That did not work. Check what you typed and the connection, then try '
    'again.';

/// Pumps the screen on a phone of [size], with a status bar of [top] and a
/// navigation bar of [bottom].
Future<void> _pumpOnPhone(
  WidgetTester tester,
  Size size, {
  double top = 0,
  double bottom = 0,
  Widget screen = const SignInScreen(),
  bool dark = false,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(top: top, bottom: bottom);
  tester.view.viewPadding = FakeViewPadding(top: top, bottom: bottom);
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
  await tester.pumpAndSettle();
}

/// How far the screen can be scrolled; zero when everything fits.
double _scrollRoom(WidgetTester tester) => Scrollable.of(
  tester.element(find.byType(SignInHeading)),
).position.maxScrollExtent;

void main() {
  setUpAll(() async {
    // The screen only draws the form here; nothing is sent to this address.
    client = Client('http://chorus.invalid/')
      ..authSessionManager = FlutterAuthSessionManager();
    // The fonts the app bundles. The test font draws every letter as a full
    // square: the sign-in package's own rows are then wider than a phone,
    // and nothing can be said about what fits.
    await loadChorusFonts();
  });

  testWidgets('the first form is sign-in, with sign-up one tap away', (
    tester,
  ) async {
    await pumpScreen(tester, const SignInScreen());
    await tester.pumpAndSettle();

    expect(find.text('Sign In with email'), findsOneWidget);
    expect(find.text('Sign Up with email'), findsNothing);
    expect(find.text("Don't have an account?"), findsOneWidget);

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    expect(find.text('Sign Up with email'), findsOneWidget);
    expect(find.text('Sign In with email'), findsNothing);
  });

  testWidgets('a failed sign-in asks to check what was typed and the '
      'connection, not a code', (tester) async {
    await pumpScreen(tester, const SignInScreen());
    await tester.pumpAndSettle();

    // The email form reports through its own onError, not SignInWidget's.
    tester.widget<EmailSignInWidget>(find.byType(EmailSignInWidget)).onError!(
      Exception('Invalid email or password.'),
    );
    await tester.pump();

    expect(find.text(_tryAgain), findsOneWidget);
  });

  testWidgets('a failed sign-up gets the same words, and they do not say '
      'sign-in', (tester) async {
    await pumpScreen(tester, const SignInScreen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    expect(find.text('Sign Up with email'), findsOneWidget);

    // The package reports a lost connection through the same onError.
    tester.widget<EmailSignInWidget>(find.byType(EmailSignInWidget)).onError!(
      Exception('A connection error occurred.'),
    );
    await tester.pump();

    expect(find.text(_tryAgain), findsOneWidget);
    expect(find.textContaining('Sign-in'), findsNothing);
  });

  testWidgets('the heading says what Chorus is and how to start, and shows '
      'no address', (tester) async {
    await pumpScreen(tester, const SignInScreen());
    await tester.pumpAndSettle();

    // Once, as the wordmark: the heading is the only place the name is
    // written.
    expect(find.text('chorus'), findsOneWidget);
    expect(find.byType(ChorusLockup), findsOneWidget);
    expect(find.text(_whatItIs), findsOneWidget);
    expect(find.text(_howToStart), findsOneWidget);
    // The heading sits above the form.
    expect(
      tester.getBottomLeft(find.text(_howToStart)).dy,
      lessThan(tester.getTopLeft(find.text('Sign In with email')).dy),
    );
    // No account is named on the screen, and no demo account is promised:
    // its password is handed out outside the app.
    expect(find.textContaining('@'), findsNothing);
    expect(find.textContaining('demo'), findsNothing);
  });

  testWidgets('on a tall screen the heading and form sit in the middle', (
    tester,
  ) async {
    await pumpScreen(tester, const SignInScreen());
    await tester.pumpAndSettle();

    final content = tester.getRect(find.byType(SingleChildScrollView));
    expect(content.height, lessThan(1600));
    expect(content.center.dy, 800);
    expect(_scrollRoom(tester), 0);
  });

  testWidgets('an upright 360 by 640 phone shows the whole form without '
      'scrolling', (tester) async {
    await _pumpOnPhone(tester, const Size(360, 640), top: 24, bottom: 48);

    expect(tester.takeException(), isNull);
    expect(_scrollRoom(tester), 0);
    // The last line of the form is above the navigation bar.
    expect(
      tester.getBottomLeft(find.text('Sign up')).dy,
      lessThan(640 - 48),
    );
  });

  testWidgets('on a phone held sideways the form scrolls, so sign-up can '
      'still be reached', (tester) async {
    await _pumpOnPhone(tester, const Size(640, 360), top: 24);

    expect(tester.takeException(), isNull);
    expect(_scrollRoom(tester), greaterThan(0));

    await tester.ensureVisible(find.text('Sign up'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    expect(find.text('Sign Up with email'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opened from "Make a board for my child" it starts on the '
      'sign-up form, and says what happens there', (tester) async {
    await pumpScreen(tester, const SignInScreen(startWithSignUp: true));
    await tester.pumpAndSettle();

    expect(find.text('Sign Up with email'), findsOneWidget);
    expect(find.text('Sign In with email'), findsNothing);
    expect(find.text(_howToStart), findsNothing);
    expect(
      find.text(
        'Use your own email address. A code is sent to it, to check it is '
        'yours.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('demo'), findsNothing);
  });

  testWidgets('reached from onboarding it has a Back button; on its own it '
      'has none', (tester) async {
    var back = 0;
    await pumpScreen(tester, SignInScreen(onBack: () => back++));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    expect(back, 1);
    expect(
      tester
          .getSize(
            find.ancestor(
              of: find.byTooltip('Back'),
              matching: find.byType(IconButton),
            ),
          )
          .shortestSide,
      greaterThanOrEqualTo(48),
    );

    await pumpScreen(tester, const SignInScreen());
    await tester.pumpAndSettle();
    expect(find.byTooltip('Back'), findsNothing);
  });

  testWidgets('a failure is felt as well as read', (tester) async {
    final felt = <ChorusHaptic>[];
    ChorusHaptics.sink = felt.add;
    addTearDown(() => ChorusHaptics.sink = null);
    await pumpScreen(tester, const SignInScreen());
    await tester.pumpAndSettle();

    tester.widget<EmailSignInWidget>(find.byType(EmailSignInWidget)).onError!(
      Exception('Invalid email or password.'),
    );
    await tester.pump();
    expect(felt, [ChorusHaptic.failed]);
  });

  testWidgets('in the dark the heading reads on slate', (tester) async {
    await _pumpOnPhone(tester, const Size(360, 640), dark: true);
    expect(tester.takeException(), isNull);
    final whatItIs = tester
        .renderObject<RenderParagraph>(find.text(_whatItIs))
        .text
        .style!
        .color!;
    expect(whatItIs, ChorusColors.dark.ink);
    final howToStart = tester
        .renderObject<RenderParagraph>(find.text(_howToStart))
        .text
        .style!
        .color!;
    expect(howToStart, ChorusColors.dark.inkMuted);
  });

  for (final size in const [
    Size(360, 640),
    Size(360, 820),
    Size(820, 360),
    Size(1280, 800),
    Size(1440, 900),
  ]) {
    testWidgets('${size.width.toInt()}x${size.height.toInt()}: it builds '
        'without an error, light and dark, and at twice the text size', (
      tester,
    ) async {
      for (final (dark, scale) in [(false, 1.0), (true, 1.0), (false, 2.0)]) {
        await _pumpOnPhone(tester, size, dark: dark, textScale: scale);
        expect(tester.takeException(), isNull, reason: '$dark $scale');
        await tester.ensureVisible(find.text('Sign up'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$dark $scale');
      }
    });
  }
}
