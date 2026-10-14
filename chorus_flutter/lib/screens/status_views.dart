/// Full-screen loading and failure states, and the large action button.
library;

import 'package:chorus_ui/brand/mark.dart';
import 'package:chorus_ui/brand/motion.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:flutter/material.dart';

/// The mark, a line saying what is happening, and a thin moving rule under
/// it. Never a blank screen, and never a spinner filling it.
///
/// Under reduced motion there is no rule: the words say it.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ChorusMark(size: 56),
            const SizedBox(height: 24),
            Semantics(
              liveRegion: true,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: ChorusType.headline.copyWith(color: colors.ink),
              ),
            ),
            if (!ChorusMotion.reduced(context)) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 120,
                child: ExcludeSemantics(
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
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
    final colors = ChorusColors.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: colors.alert),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: ChorusType.body.copyWith(color: colors.ink),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
              if (onSignOut != null) ...[
                const SizedBox(height: ChorusSpace.targetGap),
                TextButton(onPressed: onSignOut, child: const Text('Sign out')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A full-width button tall enough to hit without aiming: ink on a
/// laminated edge when [primary], an ink outline otherwise.
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
    final text = ChorusType.label.copyWith(fontSize: 17, height: 22 / 17);
    const size = Size.fromHeight(60);
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
              ),
              icon: Icon(icon),
              label: Text(label),
            ),
    );
  }
}
