/// What a browser tab shows when another tab of the same browser has Chorus.
library;

import 'package:flutter/material.dart';

import 'status_views.dart';

/// Says that Chorus is open in another tab, how to try a second adult, and
/// offers to use Chorus in this tab instead.
class OtherTabScreen extends StatelessWidget {
  const OtherTabScreen({
    super.key,
    required this.onUseHere,
    this.moved = false,
  });

  /// Takes Chorus over from the other tab.
  final VoidCallback onUseHere;

  /// True when this tab had Chorus until another tab took it over.
  final bool moved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chorus'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  moved
                      ? 'Chorus moved to another tab'
                      : 'Chorus is open in another tab',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                // The same words whether Chorus is open elsewhere or was
                // just moved: the other tab may be closed by now, and the
                // button works either way.
                Text(
                  'Chorus runs in one tab of this browser at a time. Use it '
                  'here, and the other tab stops. Nothing saved is lost. To '
                  'try a second adult, sign in from a private window '
                  '(Incognito in Chrome, InPrivate in Edge) or another '
                  'browser.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                BigButton(
                  icon: Icons.tab,
                  label: 'Use Chorus in this tab',
                  onPressed: onUseHere,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
