/// Full-screen loading and failure states, and the large action button.
library;

import 'package:flutter/material.dart';

/// A spinner with a line saying what is happening. Never a blank screen.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// What went wrong, in plain words, with a way to try again.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.onSignOut,
  });

  final String message;
  final VoidCallback onRetry;

  /// Offered as a way out when retrying may never work for this account.
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
              if (onSignOut != null) ...[
                const SizedBox(height: 8),
                TextButton(onPressed: onSignOut, child: const Text('Sign out')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A full-width button tall enough to hit without aiming.
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  /// Filled when true, outlined when false.
  final bool primary;

  @override
  Widget build(BuildContext context) {
    const text = TextStyle(fontSize: 20, fontWeight: FontWeight.w600);
    const size = Size.fromHeight(64);
    final ink = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: primary
          ? FilledButton.icon(
              onPressed: onPressed,
              style: FilledButton.styleFrom(minimumSize: size, textStyle: text),
              icon: Icon(icon),
              label: Text(label),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                minimumSize: size,
                textStyle: text,
                foregroundColor: ink,
                side: BorderSide(color: ink, width: 1.5),
              ),
              icon: Icon(icon),
              label: Text(label),
            ),
    );
  }
}
