/// What a signed-out device shows: the onboarding screen the first time,
/// sign-in after that.
library;

import 'dart:async';

import 'package:chorus_ui/brand/motion.dart';
import 'package:chorus_ui/contracts.dart' show SpeechService;
import 'package:chorus_ui/onboarding/onboarding_view.dart';
import 'package:flutter/material.dart';

import '../src/local_flags.dart';
import 'sign_in_screen.dart';

/// Builds the sign-in screen: on the sign-up form when [signUp], with a way
/// back to the onboarding screen when [onBack] is given.
typedef SignInBuilder =
    Widget Function(
      BuildContext context, {
      required bool signUp,
      VoidCallback? onBack,
    });

/// The signed-out start.
///
/// On a device that has never shown it, the onboarding screen comes first,
/// and is marked as seen ([LocalFlag.seenOnboarding]) as it is shown. Its
/// two actions lead to sign-up and sign-in, and back (the system's, or the
/// screen's own) returns to it. Every later signed-out start, signing out
/// included, opens on sign-in.
class SignedOutStart extends StatefulWidget {
  const SignedOutStart({
    super.key,
    required this.speech,
    required this.flags,
    this.signIn = defaultSignIn,
  });

  /// The app's voice, for the onboarding board. It needs no account.
  final SpeechService speech;

  final LocalFlags flags;

  final SignInBuilder signIn;

  /// The real sign-in screen.
  static Widget defaultSignIn(
    BuildContext context, {
    required bool signUp,
    VoidCallback? onBack,
  }) => SignInScreen(startWithSignUp: signUp, onBack: onBack);

  @override
  State<SignedOutStart> createState() => _SignedOutStartState();
}

enum _Page { opening, onboarding, signIn, signUp }

class _SignedOutStartState extends State<SignedOutStart> {
  _Page _page = _Page.opening;

  /// Whether this start began on the onboarding screen, which sign-in can
  /// then go back to.
  bool _onboardingFirst = false;

  /// Whether the onboarding screen has already made its entrance.
  bool _entered = false;

  @override
  void initState() {
    super.initState();
    final known = widget.flags.known(LocalFlag.seenOnboarding);
    if (known != null) {
      _open(seen: known);
    } else {
      unawaited(_readFlag());
    }
  }

  Future<void> _readFlag() async {
    final seen = await widget.flags.read(LocalFlag.seenOnboarding);
    if (!mounted) return;
    setState(() => _open(seen: seen));
  }

  void _open({required bool seen}) {
    _onboardingFirst = !seen;
    _page = seen ? _Page.signIn : _Page.onboarding;
    if (!seen) {
      unawaited(widget.flags.write(LocalFlag.seenOnboarding, true));
    }
  }

  void _go(_Page page) {
    if (page == _page) return;
    setState(() {
      if (_page == _Page.onboarding) _entered = true;
      _page = page;
    });
  }

  bool get _canGoBack =>
      _onboardingFirst && (_page == _Page.signIn || _page == _Page.signUp);

  @override
  Widget build(BuildContext context) {
    final canGoBack = _canGoBack;
    final Widget screen = switch (_page) {
      // Read in a moment, and hidden under the launch reveal meanwhile.
      _Page.opening => const Scaffold(body: SizedBox.expand()),
      _Page.onboarding => OnboardingView(
        speech: widget.speech,
        animateIn: !_entered,
        onMakeBoard: () => _go(_Page.signUp),
        onHaveOne: () => _go(_Page.signIn),
      ),
      _Page.signIn || _Page.signUp => widget.signIn(
        context,
        signUp: _page == _Page.signUp,
        onBack: canGoBack ? () => _go(_Page.onboarding) : null,
      ),
    };
    return PopScope(
      canPop: !canGoBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _canGoBack) _go(_Page.onboarding);
      },
      child: AnimatedSwitcher(
        duration: ChorusMotion.duration(context, ChorusMotion.entranceShort),
        switchInCurve: ChorusMotion.entrance,
        switchOutCurve: ChorusMotion.entrance,
        child: KeyedSubtree(key: ValueKey(_page), child: screen),
      ),
    );
  }
}
