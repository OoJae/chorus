import 'package:serverpod/serverpod.dart';

import 'focus_words.dart';

/// The Thursday nudge: for each circle with focus words, notes a word
/// nobody has modelled yet this week, so home can say so kindly.
///
/// Safe to run twice (one nudge per circle and week), and
/// `writeFocusNudges` is its twin for running on demand.
class FocusNudgeFutureCall extends FutureCall {
  Future<void> writeNudges(Session session) async {
    await writeFocusNudges(session);
  }
}
