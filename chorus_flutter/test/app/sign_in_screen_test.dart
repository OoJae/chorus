import 'dart:io';

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_flutter/client.dart';
import 'package:chorus_flutter/screens/sign_in_screen.dart';
import 'package:chorus_ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Loads the Roboto that comes with the Flutter SDK, the font the app has on
/// Android and in the browser. The test font draws every letter as a full
/// square: the sign-in package's own rows are then wider than a phone, and
/// nothing can be said about what fits.
Future<void> _loadRoboto() async {
  final fonts = Directory(
    '${Platform.environment['FLUTTER_ROOT']}'
    '/bin/cache/artifacts/material_fonts',
  );
  final loader = FontLoader('Roboto');
  for (final weight in ['Regular', 'Medium', 'Bold']) {
    final file = File('${fonts.path}/Roboto-$weight.ttf');
    if (!file.existsSync()) {
      fail('These tests measure real text and need ${file.path}.');
    }
    loader.addFont(
      file.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
    );
  }
  await loader.load();
}

/// Pumps the screen on a phone of [size], with a status bar of [top] and a
/// navigation bar of [bottom].
Future<void> _pumpOnPhone(
  WidgetTester tester,
  Size size, {
  double top = 0,
  double bottom = 0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(top: top, bottom: bottom);
  tester.view.viewPadding = FakeViewPadding(top: top, bottom: bottom);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(theme: chorusTheme(), home: const SignInScreen()),
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
    await _loadRoboto();
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

    // Once: the heading is the only place the name is written.
    expect(find.text('Chorus'), findsOneWidget);
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
}
