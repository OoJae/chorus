// The signed-out start: onboarding on the first start, sign-in after it,
// with the onboarding's two ways on leading to sign-up and sign-in and back
// returning to it.
import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_flutter/client.dart';
import 'package:chorus_flutter/screens/onboarding_screen.dart';
import 'package:chorus_flutter/screens/sign_in_screen.dart';
import 'package:chorus_flutter/src/local_flags.dart';
import 'package:chorus_ui/brand/test_fonts.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/onboarding/onboarding_view.dart';
import 'package:chorus_ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

/// Flags kept in memory, as this device's storage would keep them.
class _Flags extends LocalFlags {
  _Flags({this.saved = false});

  bool saved;
  final List<bool> writes = [];
  int reads = 0;

  @override
  Future<bool> read(LocalFlag flag) async {
    reads++;
    return saved;
  }

  @override
  Future<void> write(LocalFlag flag, bool value) async {
    writes.add(value);
    saved = value;
  }
}

/// What the sign-in builder was last asked for.
class _Asked {
  bool? signUp;
  VoidCallback? onBack;
  int times = 0;
}

Future<_Asked> _pump(
  WidgetTester tester, {
  required LocalFlags flags,
  FakeSpeech? speech,
  bool realSignIn = false,
  bool reduced = false,
  bool dark = false,
}) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final asked = _Asked();
  Widget stub(
    BuildContext context, {
    required bool signUp,
    VoidCallback? onBack,
  }) {
    asked
      ..signUp = signUp
      ..onBack = onBack
      ..times += 1;
    return Scaffold(body: Text(signUp ? 'stub sign-up' : 'stub sign-in'));
  }

  await tester.pumpWidget(
    MaterialApp(
      theme: chorusTheme(),
      darkTheme: chorusDarkTheme(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: child!,
      ),
      home: SignedOutStart(
        speech: speech ?? FakeSpeech(),
        flags: flags,
        signIn: realSignIn ? SignedOutStart.defaultSignIn : stub,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return asked;
}

void main() {
  setUpAll(() async {
    // The real sign-in screen only draws its form here; nothing is sent.
    client = Client('http://chorus.invalid/')
      ..authSessionManager = FlutterAuthSessionManager();
    await loadChorusFonts();
  });

  testWidgets('a first start shows the onboarding screen and marks it seen '
      'as it is shown', (tester) async {
    final flags = _Flags();
    final asked = await _pump(tester, flags: flags);

    expect(find.byType(OnboardingView), findsOneWidget);
    expect(asked.times, 0);
    expect(flags.writes, [true]);
  });

  testWidgets('a start after that opens on sign-in, with nothing to go back '
      'to', (tester) async {
    final flags = _Flags(saved: true);
    final asked = await _pump(tester, flags: flags);

    expect(find.byType(OnboardingView), findsNothing);
    expect(find.text('stub sign-in'), findsOneWidget);
    expect(asked.signUp, isFalse);
    expect(asked.onBack, isNull);
    expect(flags.writes, isEmpty);

    // System back leaves the app as usual: nothing is caught.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('stub sign-in'), findsOneWidget);
    expect(find.byType(OnboardingView), findsNothing);
  });

  testWidgets('"Make a board for my child" opens sign-up, and system back '
      'returns to the onboarding screen', (tester) async {
    final asked = await _pump(tester, flags: _Flags());

    await tester.tap(find.text(OnboardingCopy.makeBoard));
    await tester.pumpAndSettle();
    expect(find.text('stub sign-up'), findsOneWidget);
    expect(find.byType(OnboardingView), findsNothing);
    expect(asked.signUp, isTrue);
    expect(asked.onBack, isNotNull);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingView), findsOneWidget);
    // Back again, it does not make its entrance a second time.
    expect(
      tester.widget<OnboardingView>(find.byType(OnboardingView)).animateIn,
      isFalse,
    );
  });

  testWidgets('"I already have one" opens sign-in, whose own back button '
      'returns to the onboarding screen', (tester) async {
    final asked = await _pump(tester, flags: _Flags());

    await tester.tap(find.text(OnboardingCopy.haveOne));
    await tester.pumpAndSettle();
    expect(find.text('stub sign-in'), findsOneWidget);
    expect(asked.signUp, isFalse);

    asked.onBack!();
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingView), findsOneWidget);
  });

  testWidgets('the onboarding board speaks with no account and no network', (
    tester,
  ) async {
    final speech = FakeSpeech();
    await _pump(tester, flags: _Flags(), speech: speech);

    await tester.tap(find.text('help'));
    await tester.pumpAndSettle();
    expect(speech.spoken, ['help']);
  });

  testWidgets('after signing out, a flag this run already knows opens '
      'sign-in from the first frame', (tester) async {
    // Written as someone signed in; this device's storage is not there in a
    // test, so only the run remembers it.
    final flags = LocalFlags();
    await tester.runAsync(() => flags.write(LocalFlag.seenOnboarding, true));

    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: chorusTheme(),
        home: SignedOutStart(
          speech: FakeSpeech(),
          flags: flags,
          signIn: (context, {required signUp, onBack}) =>
              const Scaffold(body: Text('stub sign-in')),
        ),
      ),
    );
    expect(find.text('stub sign-in'), findsOneWidget);
  });

  testWidgets('with the real sign-in screen: sign-up first from "Make a '
      'board for my child", with a Back button to the onboarding screen', (
    tester,
  ) async {
    await _pump(tester, flags: _Flags(), realSignIn: true);

    await tester.tap(find.text(OnboardingCopy.makeBoard));
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.text('Sign Up with email'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingView), findsOneWidget);

    await tester.tap(find.text(OnboardingCopy.haveOne));
    await tester.pumpAndSettle();
    expect(find.text('Sign In with email'), findsOneWidget);
  });

  testWidgets('under reduced motion the change of screen is a 150 ms '
      'crossfade', (tester) async {
    await _pump(tester, flags: _Flags(), reduced: true);
    await tester.tap(find.text(OnboardingCopy.haveOne));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.byType(OnboardingView), findsNothing);
    expect(find.text('stub sign-in'), findsOneWidget);
  });

  testWidgets('it builds in the dark', (tester) async {
    await _pump(tester, flags: _Flags(), dark: true);
    expect(find.byType(OnboardingView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
