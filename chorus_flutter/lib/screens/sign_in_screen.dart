import 'package:chorus_ui/brand/haptics.dart';
import 'package:chorus_ui/brand/mark.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:flutter/material.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import '../client.dart';

/// Email and password sign-in, with sign-up one tap away.
///
/// [startWithSignUp] opens it on the sign-up form instead, as "Make a board
/// for my child" on the onboarding screen does. [onBack] puts a back button
/// in the heading, for a screen reached from onboarding.
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key, this.startWithSignUp = false, this.onBack});

  final bool startWithSignUp;
  final VoidCallback? onBack;

  /// The largest text scale the package's email forms fit at on a phone:
  /// they are drawn in a box 330 dp high.
  static const double formMaxTextScale = 1.2;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // The same words on every form: sign-in asks for a password, sign-up
    // for a code, and any of them needs a connection.
    void showError(Object error) {
      ChorusHaptics.failed();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'That did not work. Check what you typed and the connection, '
              'then try again.',
              style: TextStyle(color: colors.onErrorContainer),
            ),
            backgroundColor: colors.errorContainer,
            duration: const Duration(seconds: 5),
          ),
        );
    }

    return Scaffold(
      // The heading names the app, so the bar has no title and no height.
      // It stays because it is what keeps the status bar icons dark, as on
      // every other screen.
      appBar: AppBar(toolbarHeight: 0),
      body: SafeArea(
        child: Center(
          // The form has a fixed height. On a phone held sideways, or with
          // the keyboard open, it is taller than the screen and must scroll
          // for its button to be reached.
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SignInHeading(signUp: startWithSignUp, onBack: onBack),
                // The package draws each form in a box of fixed height,
                // which larger text overflows: its text grows only as far
                // as the box allows. The heading above grows in full.
                MediaQuery.withClampedTextScaling(
                  maxScaleFactor: formMaxTextScale,
                  child: SignInWidget(
                    client: client,
                    onError: showError,
                    // Sign-in comes first. An address that already has an
                    // account, typed into the sign-up form, leads to a code
                    // screen and no code is ever sent. Only "Make a board
                    // for my child" starts on sign-up.
                    emailSignInWidget: EmailSignInWidget(
                      client: client,
                      startScreen: startWithSignUp
                          ? EmailFlowScreen.startRegistration
                          : EmailFlowScreen.login,
                      onError: showError,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The app's mark and name, what it is, and how someone new starts. As wide
/// as the form below it, and lined up with it.
class SignInHeading extends StatelessWidget {
  const SignInHeading({super.key, this.signUp = false, this.onBack});

  /// The form below starts on sign-up, so the last line says what happens
  /// there instead of pointing to it.
  final bool signUp;

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final back = onBack;
    return Padding(
      padding: EdgeInsets.fromLTRB(back == null ? 24 : 12, 8, 24, 0),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: back == null ? 400 : 412),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (back != null) ...[
                  IconButton(
                    onPressed: back,
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 4),
                ],
                const ChorusLockup(size: 28),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(left: back == null ? 0 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    "A talking picture board a child's whole circle keeps "
                    'in step',
                    style: ChorusType.headline,
                  ),
                  const SizedBox(height: 6),
                  // Points only to what always works. The demo password is
                  // handed out outside the app, and may not be there yet.
                  Text(
                    signUp
                        ? 'Use your own email address. A code is sent to it, '
                              'to check it is yours.'
                        : 'New here? Choose "Sign up" below and use your own '
                              'email address. A code is sent to it.',
                    style: ChorusType.body.copyWith(color: colors.inkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
