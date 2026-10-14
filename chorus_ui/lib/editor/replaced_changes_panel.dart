/// The "Replaced changes" list: edits a merge replaced without asking, each
/// with one tap to put it back.
library;

import 'package:flutter/material.dart';

import '../brand/haptics.dart';
import '../brand/tokens.dart';
import '../contracts.dart';
import '../contracts_edits.dart';
import 'tray_panel.dart' show notSavedMessage;

/// What happened in [overwrite], in words for a parent. With [ask] it ends
/// by offering the replaced value.
///
/// It says "without seeing", not "while offline": the log shows that
/// neither adult had the other's change, not why.
String replacedChangeText(Overwrite overwrite, {bool ask = true}) {
  final lost = overwrite.lost;
  final kept = overwrite.kept;
  final wanted = _valueText(overwrite, lost.newValue);
  final current = _valueText(overwrite, kept.newValue);
  final loser = _nameOf(lost);
  final winner = _nameOf(kept);
  final what = switch (lost.prop) {
    'speech' => 'what this word says',
    'colorKey' => "this word's colour",
    _ => 'this word',
  };
  final happened = lost.actorId == kept.actorId
      ? '$loser changed $what to $wanted on another device. '
            '${_sentenceStart(current)} was kept.'
      : "$loser changed $what to $wanted without seeing $winner's change. "
            "$winner's $current was kept.";
  return ask ? '$happened Use $wanted instead?' : happened;
}

String _nameOf(EditFacts edit) =>
    edit.actorName.isEmpty ? 'Someone' : edit.actorName;

String _sentenceStart(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// A value as it is shown in a sentence. A word with no speech of its own
/// says its label, and a word with no colour is plain.
String _valueText(Overwrite overwrite, String? value) {
  final empty = value == null || value.isEmpty;
  return switch (overwrite.prop) {
    'colorKey' => empty ? 'no colour' : 'the $value colour',
    'speech' => '"${empty ? overwrite.tile.label : value}"',
    _ => '"${value ?? ''}"',
  };
}

/// Says, under the heading, that a replaced change is not lost.
const String replacedChangesIntro =
    'Two people changed the same thing at once, so only one change could '
    'stay. The earlier version is kept here, so it can be put back.';

/// The panel's heading for [count] replaced changes, in the status face as
/// the tray's is: "Replaced changes · 1".
String replacedChangesTitle(int count) => 'Replaced changes · $count';

/// Lists every edit that was replaced by one made without sight of it, with
/// a one-tap Restore. Rebuilds whenever [store] changes.
///
/// Shows nothing at all unless [store] also implements [EditLog], and
/// nothing while there is no replaced change. A read-only partner sees the
/// list without the button.
class ReplacedChangesPanel extends StatelessWidget {
  const ReplacedChangesPanel({super.key, required this.store, this.boardId});

  final BoardStore store;

  /// Lists only the replaced changes to words of this board. Null lists
  /// those of every board.
  final String? boardId;

  @override
  Widget build(BuildContext context) {
    final store = this.store;
    if (store is! EditLog) return const SizedBox.shrink();
    final log = store as EditLog;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final boardId = this.boardId;
        final overwrites = detectOverwrites(
          log.edits,
          boardId == null
              ? store.tiles
              : store.tiles.where((tile) => tile.boardId == boardId),
        );
        if (overwrites.isEmpty) return const SizedBox.shrink();
        final colors = ChorusColors.of(context);
        final canEdit = store.role.canEdit;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: ChorusSpace.minTarget,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    replacedChangesTitle(overwrites.length),
                    style: ChorusType.status.copyWith(color: colors.ink),
                  ),
                ),
              ),
            ),
            Text(
              replacedChangesIntro,
              style: ChorusType.body.copyWith(color: colors.inkMuted),
            ),
            for (final overwrite in overwrites)
              _ReplacedCard(
                key: ValueKey(overwrite.lost.id),
                overwrite: overwrite,
                onRestore: canEdit
                    ? () => _restore(context, log, overwrite)
                    : null,
              ),
          ],
        );
      },
    );
  }

  Future<void> _restore(
    BuildContext context,
    EditLog log,
    Overwrite overwrite,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await log.restore(overwrite);
    } on Object {
      // The word was removed, or the role changed, meanwhile.
      ChorusHaptics.failed();
      messenger?.showSnackBar(const SnackBar(content: Text(notSavedMessage)));
      return;
    }
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          '${_sentenceStart(_valueText(overwrite, overwrite.lost.newValue))} '
          'is back.',
        ),
      ),
    );
  }
}

class _ReplacedCard extends StatelessWidget {
  const _ReplacedCard({super.key, required this.overwrite, this.onRestore});

  final Overwrite overwrite;

  /// Null hides the button.
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final onRestore = this.onRestore;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(ChorusSpace.buttonRadius),
          border: Border.all(color: colors.line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                overwrite.tile.label,
                style: ChorusType.headline.copyWith(color: colors.ink),
              ),
              const SizedBox(height: 4),
              Text(
                replacedChangeText(overwrite, ask: onRestore != null),
                style: ChorusType.body.copyWith(color: colors.ink),
              ),
              if (onRestore != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: onRestore,
                    child: const Text('Restore'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
