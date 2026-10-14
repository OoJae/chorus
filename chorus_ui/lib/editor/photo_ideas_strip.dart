/// Ideas for a photo as small word tiles, coloured by part of speech. A tap
/// fills in the form; "Add all to Needs a home" puts them in the tray for
/// the adult to place. The ideas never speak for the child and never take a
/// spot by themselves.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';

import '../brand/tokens.dart';
import '../contracts.dart';
import '../contracts_copies.dart' show TrayWordAdder;
import '../contracts_photo_ideas.dart';
import '../widgets/tile_view.dart';

/// The line over the ideas.
const String photoIdeasIntro = 'Ideas for this photo. Tap one to use it:';

/// The button that puts every idea in the tray.
const String addAllToTrayLabel = 'Add all to Needs a home';

/// Shown when none of the ideas could be put in the tray.
const String ideasNotAddedMessage =
    'These ideas could not be put under "Needs a home". Nothing was '
    'changed. Put one word on this board first, then try again.';

/// Shown once the ideas are in the tray.
String ideasInTrayMessage(int count) =>
    '$count ${count == 1 ? 'word waits' : 'words wait'} under "Needs a home". '
    'Choose a spot for each.';

/// The ideas strip.
class PhotoIdeasStrip extends StatelessWidget {
  const PhotoIdeasStrip({
    super.key,
    required this.ideas,
    required this.onUse,
    this.onAddAll,
  });

  final List<WordIdea> ideas;
  final ValueChanged<WordIdea> onUse;

  /// Null leaves out "Add all to Needs a home".
  final VoidCallback? onAddAll;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final onAddAll = this.onAddAll;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              photoIdeasIntro,
              style: ChorusType.body.copyWith(color: colors.ink),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: ChorusSpace.targetGap,
            runSpacing: ChorusSpace.targetGap,
            children: [
              for (final (i, idea) in ideas.indexed)
                SizedBox(
                  key: ValueKey('photo-idea-$i'),
                  width: 76,
                  height: 64,
                  child: Semantics(
                    button: true,
                    label: 'Use ${idea.label}',
                    excludeSemantics: true,
                    onTap: () => onUse(idea),
                    child: TileView(
                      tile: TileFacts(
                        id: 'idea-$i',
                        boardId: '',
                        cellKey: '',
                        label: idea.label,
                        colorKey: idea.colorKey,
                      ),
                      onTap: () => onUse(idea),
                    ),
                  ),
                ),
            ],
          ),
          if (onAddAll != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onAddAll,
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
              icon: const Icon(Icons.inbox_outlined),
              label: const Text(addAllToTrayLabel),
            ),
          ],
        ],
      ),
    );
  }
}

/// Puts [ideas] in the tray of [boardId]. Completes with how many were
/// added. A store that is a [TrayWordAdder] adds each straight to the
/// tray, so this works on a board with no words yet and never takes a
/// spot. Any other store goes through the normal add path: each idea is
/// added at an occupied spot, which the store answers by keeping it under
/// "Needs a home"; that adds nothing when the board has no word yet to
/// anchor on, since then a spot would be taken.
Future<int> addIdeasToTray(
  BoardStore store,
  String boardId,
  List<WordIdea> ideas,
) async {
  final Object target = store;
  var added = 0;
  if (target is TrayWordAdder) {
    for (final idea in ideas) {
      await target.addToTray(
        boardId: boardId,
        label: idea.label,
        speech: idea.speech.isEmpty ? null : idea.speech,
        colorKey: colorForKey.containsKey(idea.colorKey) ? idea.colorKey : null,
      );
      added++;
    }
    return added;
  }
  final held = gridOf(boardId, store.tiles, store.boards);
  if (held.isEmpty) return 0;
  final (row, col) = held.keys.first;
  for (final idea in ideas) {
    await store.addTile(
      boardId: boardId,
      row: row,
      col: col,
      label: idea.label,
      speech: idea.speech.isEmpty ? null : idea.speech,
      colorKey: colorForKey.containsKey(idea.colorKey) ? idea.colorKey : null,
    );
    added++;
  }
  return added;
}
