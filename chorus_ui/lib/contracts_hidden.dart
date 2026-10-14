/// Words hidden from the child's board for now, as the screens see them.
///
/// Kept apart from `contracts.dart` so every screen works exactly as before
/// without it.
library;

import 'package:flutter/foundation.dart';

/// Which of the circle's words an adult has hidden from the child's board.
///
/// A hidden word keeps its cell: on the child's board the cell is blank and
/// silent, and no other word may take it. Nothing moves when a word is
/// hidden or shown again.
///
/// Kept on this device, so the child's board shows it with no network.
/// Notifies listeners whenever [hiddenIds] or [canChange] changes.
abstract class HiddenWords extends ChangeNotifier {
  /// Ids of the tiles hidden now, as this device knows it.
  Set<String> get hiddenIds;

  /// True when the signed-in adult may hide and show words: every role but
  /// a read-only partner.
  bool get canChange;

  /// Hides ([hidden] true) or shows again the tile [tileId]. Takes effect on
  /// this device at once and reaches the others when there is a network.
  /// Throws [StateError] unless [canChange].
  Future<void> setHidden(String tileId, bool hidden);
}
