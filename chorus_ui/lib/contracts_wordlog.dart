/// The opt-in word log and "This week", as the screens see them.
///
/// Kept apart from `contracts.dart` so every screen works exactly as before
/// without them: no log, no private mark, no "This week".
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/foundation.dart';

export 'package:chorus_shared/chorus_shared.dart'
    show WeekSummary, WordCount, WordUse;

/// Which words the child spoke, and when: tile, board and time, never
/// sentences. Off until a guardian turns it on for the circle.
///
/// Notifies listeners whenever any getter changes.
abstract class WordLog extends ChangeNotifier {
  /// True once a guardian turned the log on for this circle.
  bool get enabled;

  /// True while the child's board is in private mode on this device: the
  /// log and "Share what is said" both pause, and a mark shows. Lasts for
  /// this session only.
  bool get private;

  /// True when the signed-in adult may turn the log on or off and delete
  /// it: a guardian.
  bool get canChange;

  /// Uses kept on this device that the server does not hold yet.
  int get pending;

  /// Records that [tile] was spoken, now. Does nothing unless [enabled] and
  /// not [private]. Never throws and never waits: the child's tap must not
  /// be slowed or broken by the log.
  void noteSpoken(TileFacts tile);

  /// Turns the log on or off for the whole circle. Throws [StateError]
  /// unless [canChange]. Turning it off keeps what was logged; use
  /// [deleteAll] for that.
  Future<void> setEnabled(bool value);

  /// Pauses or resumes the log and "Share what is said" on this device.
  /// Anyone at the child's board may; it is forgotten on restart.
  void setPrivate(bool value);

  /// Removes the circle's whole log for good, on the server and the uses
  /// waiting on this device. Throws [StateError] unless [canChange], or
  /// when the server could not be reached (then nothing was removed).
  Future<void> deleteAll();
}

/// The week so far, from the word log.
abstract class WeekSummarySource {
  /// This week (from Monday 00:00 UTC) for the circle. Null when it cannot
  /// be had: offline, the log is off, or the adult's role may not see it
  /// (guardians and therapists may). Never throws.
  Future<WeekSummary?> thisWeek();
}
