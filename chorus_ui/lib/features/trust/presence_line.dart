/// One quiet line naming who else has the board open right now.
library;

import 'package:flutter/material.dart';

import '../../brand/tokens.dart';
import '../../contracts_live.dart';
import '../flags/w1.dart';

/// "Ms Rivera is looking at the board", "Ms Rivera and Dad are looking at
/// the board", "Ms Rivera, Dad and Grandma are looking at the board"; null
/// with nobody else here.
String? presenceText(List<String> names) {
  final named = [
    for (final name in names)
      if (name.trim().isNotEmpty) name.trim(),
  ];
  if (named.isEmpty) return null;
  if (named.length == 1) return '${named.single} is looking at the board';
  final last = named.last;
  final rest = named.sublist(0, named.length - 1).join(', ');
  return '$rest and $last are looking at the board';
}

/// The line, from [live]'s presence; nothing at all when nobody else is
/// here or the session is not connected.
class PresenceLine extends StatelessWidget {
  const PresenceLine({super.key, required this.live});

  final LiveSession live;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: live,
      builder: (context, _) {
        final text = live.connected ? presenceText(live.present) : null;
        if (text == null) return const SizedBox.shrink();
        final colors = ChorusColors.of(context);
        return Semantics(
          container: true,
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.visibility_rounded,
                    size: 18,
                    color: colors.inkMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: ChorusType.status.copyWith(color: colors.inkMuted),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// [header] with the presence line under it, when there is a [live]
/// session and the flag is on.
Widget withPresenceLine(Widget header, {required LiveSession? live}) {
  if (live == null || !presenceLineEnabled) return header;
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [header, PresenceLine(live: live)],
  );
}
