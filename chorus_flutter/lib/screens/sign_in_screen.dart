import 'package:flutter/material.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import '../client.dart';

/// Email and password sign-in, with sign-up one tap away.
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // The same words on every form: sign-in asks for a password, sign-up
    // for a code, and any of them needs a connection.
    void showError(Object error) {
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
                const SignInHeading(),
                SignInWidget(
                  client: client,
                  onError: showError,
                  // Sign-in comes first. An address that already has an
                  // account, typed into the sign-up form, leads to a code
                  // screen and no code is ever sent.
                  emailSignInWidget: EmailSignInWidget(
                    client: client,
                    startScreen: EmailFlowScreen.login,
                    onError: showError,
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

/// The app's name, what it is, and how someone new starts. As wide as the
/// form below it, and lined up with it.
class SignInHeading extends StatelessWidget {
  const SignInHeading({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Chorus',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "A talking picture board a child's whole circle keeps in step",
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            // Points only to what always works. The demo password is handed
            // out outside the app, and may not be there yet.
            Text(
              'New here? Choose "Sign up" below and use your own email '
              'address. A code is sent to it.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
