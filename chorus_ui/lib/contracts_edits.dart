/// The edit log as the screens see it.
///
/// Kept apart from `contracts.dart` so a store can offer it or not: the
/// "Replaced changes" panel appears only for a `BoardStore` that also
/// implements [EditLog].
library;

import 'package:chorus_shared/chorus_shared.dart';

export 'package:chorus_shared/chorus_shared.dart'
    show EditFacts, Overwrite, detectOverwrites, restoreReason;

/// Every recorded change to the circle's tiles, and the way to put a
/// replaced one back.
///
/// Implemented by the same object as the `BoardStore`, which notifies its
/// listeners when [edits] changes as it does for tiles.
abstract class EditLog {
  /// Every edit in the circle, oldest first.
  List<EditFacts> get edits;

  /// Writes the value of `overwrite.lost` back to the tile, as a new edit
  /// with reason `restore`. The replaced value stays in the log, so this can
  /// itself be undone. Throws if the store refuses the write.
  Future<void> restore(Overwrite overwrite);
}
