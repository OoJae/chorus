import 'package:flutter/material.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import '../client.dart';

/// Email sign-in with an emailed code.
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Chorus')),
      body: SafeArea(
        child: Center(
          child: SignInWidget(
            client: client,
            onError: (error) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      'Sign-in did not work. Check the email and the code, '
                      'then try again.',
                      style: TextStyle(color: colors.onErrorContainer),
                    ),
                    backgroundColor: colors.errorContainer,
                    duration: const Duration(seconds: 5),
                  ),
                );
            },
          ),
        ),
      ),
    );
  }
}
