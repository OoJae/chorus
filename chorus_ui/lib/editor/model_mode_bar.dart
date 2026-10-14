/// The editor's switch for showing words on the child's board.
library;

import 'package:flutter/material.dart';

import '../brand/tokens.dart';
import '../contracts_live.dart';

/// Shown in the bar while the live session has no connection.
const String modelNeedsConnectionMessage =
    'Not connected. Showing words needs a connection.';

/// Shown in the bar when model mode is on and no other device is joined.
const String modelNobodyHereMessage = 'Nobody else is here right now.';

/// A bar that turns model mode on and off.
///
/// While [enabled], the editor must treat a tap on a word as "show this
/// word": call `live.sendPulse(tile.id)` and do not open the edit sheet. The
/// tile then glows on every other device in the circle for a moment, which
/// is how an adult shows the child which word to use. The bar changes
/// nothing on the board and writes nothing.
///
/// While on it also shows who else is present and, when the child's device
/// shares it, the sentence last spoken there. All of that is live only:
/// it is gone as soon as the connection is.
class ModelModeBar extends StatelessWidget {
  const ModelModeBar({
    super.key,
    required this.live,
    required this.enabled,
    required this.onChanged,
    this.labelFor,
    this.extra,
  });

  final LiveSession live;

  /// More tools shown under the live details while on: see
  /// `ModellingTools`.
  final Widget? extra;

  /// Whether model mode is on. The editor owns this.
  final bool enabled;
  final ValueChanged<bool> onChanged;

  /// The word on a tile, so the bar can name the one being shown. Without
  /// it the bar only says that a word is showing.
  final String? Function(String tileId)? labelFor;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    return ListenableBuilder(
      listenable: live,
      builder: (context, _) {
        final on = enabled;
        return Semantics(
          container: true,
          // A Material of its own, so the switch row's ink is drawn on the
          // bar's colour and not hidden behind it. On, it sinks to the page's
          // colour inside a heavier line; the switch row's text keeps its
          // theme colours, which read on both.
          child: Material(
            color: on ? colors.card : colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ChorusSpace.buttonRadius),
              side: BorderSide(
                color: on ? colors.ink : colors.line,
                width: on ? 2 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile(
                  value: on,
                  onChanged: onChanged,
                  secondary: Icon(Icons.touch_app_rounded, color: colors.ink),
                  title: Text(
                    'Show words on the board',
                    style: ChorusType.label.copyWith(color: colors.ink),
                  ),
                  subtitle: Text(
                    on
                        ? 'Tap a word and it glows on the other devices. '
                              'Nothing is changed.'
                        : 'Turn on to point at words instead of '
                              'changing them.',
                    style: ChorusType.body.copyWith(color: colors.inkMuted),
                  ),
                ),
                if (on)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _LiveDetails(live: live, labelFor: labelFor),
                  ),
                if (on && extra != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: extra,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Who is here, what is glowing and what was last said.
class _LiveDetails extends StatelessWidget {
  const _LiveDetails({required this.live, required this.labelFor});

  final LiveSession live;
  final String? Function(String tileId)? labelFor;

  @override
  Widget build(BuildContext context) {
    if (!live.connected) {
      return const _Line(
        icon: Icons.cloud_off_rounded,
        text: modelNeedsConnectionMessage,
      );
    }
    final present = live.present;
    final said = live.lastSaid;
    final showing = _showing();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Line(
          icon: Icons.people_rounded,
          text: present.isEmpty
              ? modelNobodyHereMessage
              : 'Here now: ${present.join(', ')}',
        ),
        if (showing != null) ...[
          const SizedBox(height: 6),
          Semantics(
            liveRegion: true,
            child: _Line(icon: Icons.flare_rounded, text: showing),
          ),
        ],
        if (said != null && said.isNotEmpty) ...[
          const SizedBox(height: 6),
          Semantics(
            liveRegion: true,
            child: _Line(
              icon: Icons.chat_bubble_outline_rounded,
              text: 'Just said: $said',
              strong: true,
            ),
          ),
        ],
      ],
    );
  }

  String? _showing() {
    final pulsing = live.pulsing;
    if (pulsing.isEmpty) return null;
    final names = [
      for (final id in pulsing)
        if (labelFor?.call(id) case final String label) label,
    ];
    return names.isEmpty ? 'Showing a word' : 'Showing: ${names.join(', ')}';
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text, this.strong = false});

  final IconData icon;
  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final ink = ChorusColors.of(context).ink;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: ink),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: ChorusType.body.copyWith(
              fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
              color: ink,
            ),
          ),
        ),
      ],
    );
  }
}
