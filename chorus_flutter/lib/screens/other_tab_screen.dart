/// What a browser tab shows when another tab of the same browser has Chorus.
library;

import 'package:chorus_ui/brand/mark.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:flutter/material.dart';

/// Says that Chorus is open in another tab, how to try a second adult, and
/// offers to use Chorus in this tab instead.
///
/// Ink on card: the brand at the top, the explanation, and the one action
/// at the bottom, in reach of the thumb.
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
    final colors = ChorusColors.of(context);
    final margin = ChorusSpace.marginOf(context);
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(margin, 24, margin, 24),
                  sliver: SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: ChorusLockup(size: 28),
                        ),
                        const SizedBox(height: 40),
                        Semantics(
                          header: true,
                          child: Text(
                            moved
                                ? 'Chorus moved to another tab'
                                : 'Chorus is open in another tab',
                            textScaler: ChorusType.displayScaler(context),
                            style: ChorusType.title.copyWith(
                              color: colors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // The same words whether Chorus is open elsewhere or
                        // was just moved: the other tab may be closed by
                        // now, and the button works either way.
                        Text(
                          'Chorus runs in one tab of this browser at a time. '
                          'Use it here, and the other tab stops. Nothing '
                          'saved is lost. To try a second adult, sign in '
                          'from a private window (Incognito in Chrome, '
                          'InPrivate in Edge) or another browser.',
                          style: ChorusType.body.copyWith(
                            color: colors.inkMuted,
                          ),
                        ),
                        // The action sits in the thumb zone; on a short
                        // window it follows the text.
                        const Spacer(),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: onUseHere,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                          ),
                          icon: const Icon(Icons.tab_rounded),
                          label: const Text('Use Chorus in this tab'),
                        ),
                      ],
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
