/// Modelling, as the screens see it: modelled taps, focus words of the week,
/// the Thursday nudge, the progress report and the browser's speech
/// recognition.
///
/// Kept apart from `contracts.dart` so every screen works exactly as before
/// without it.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/foundation.dart';

/// Most focus words a circle pins for one week.
const int maxFocusWords = 3;

/// Longest modelling tip, in characters.
const int maxFocusTipLength = 120;

/// A focus word of the week: the tile and a one-line modelling tip.
@immutable
class FocusPin {
  const FocusPin({required this.tileId, this.tip = ''});

  final String tileId;

  /// "At bath time: 'more bubbles?'". May be empty.
  final String tip;

  @override
  bool operator ==(Object other) =>
      other is FocusPin && other.tileId == tileId && other.tip == tip;

  @override
  int get hashCode => Object.hash(tileId, tip);
}

/// The Thursday nudge: a focus word nobody has modelled yet this week.
@immutable
class FocusNudgeNote {
  const FocusNudgeNote({
    required this.tileId,
    required this.label,
    required this.weekStart,
    this.tip = '',
  });

  final String tileId;
  final String label;
  final String tip;

  /// Monday 00:00 UTC of the week it is about.
  final DateTime weekStart;
}

/// The circle's modelling features for the signed-in adult. Notifies
/// listeners when [focusWords] change.
abstract class ModellingSource extends ChangeNotifier {
  /// This week's focus words, as last read. Empty until [refreshFocus]
  /// has read them, and when there are none.
  List<FocusPin> get focusWords;

  /// True when the adult may pin focus words and make a progress report:
  /// a guardian or a therapist.
  bool get canPinFocus;

  /// Reads this week's focus words again. Never throws; keeps the last
  /// ones on failure.
  Future<void> refreshFocus();

  /// Replaces this week's focus words. Throws [StateError] unless
  /// [canPinFocus], or when the server could not be reached or refused.
  Future<void> setFocusWords(List<FocusPin> pins);

  /// Notes that an adult showed [tile] on the board in model mode. Kept
  /// only when the circle's word log is on, this device is not in private
  /// mode and the tile may be logged. Never throws and never waits.
  void noteModelled(TileFacts tile);

  /// This week's nudge, unless it was dismissed on this device. Null when
  /// there is none or it cannot be had. Never throws.
  Future<FocusNudgeNote?> nudge();

  /// This week's nudge as last read, unless it was dismissed on this
  /// device; null otherwise. Reading it starts a read when there was none
  /// yet or the last one is old, and listeners hear when it arrives.
  FocusNudgeNote? get shownNudge;

  /// Hides [note] on this device; [shownNudge] is null from then on.
  Future<void> dismissNudge(FocusNudgeNote note);

  /// Makes a one-page progress report of this week and completes with its
  /// address. Throws when it could not be made (offline, or the role may
  /// not).
  Future<String> makeProgressReport();

  /// Opens [url] in a new browser tab where this device can. False where it
  /// cannot (the installed app), and the screen shows the link to copy.
  Future<bool> openLink(String url);
}

/// The browser's speech recognition, for "Listen" in model mode.
abstract class SpeechListener extends ChangeNotifier {
  /// True where speech can be recognised here. When false, "Listen" is not
  /// shown at all.
  bool get available;

  /// True while listening.
  bool get listening;

  /// Starts listening; [onHeard] gets each finished phrase. Does nothing
  /// when not [available].
  void start(ValueChanged<String> onHeard);

  /// Stops listening.
  void stop();
}

/// The nudge as home shows it.
String focusNudgeMessage(FocusNudgeNote note) {
  final tip = note.tip.trim();
  return "Nobody has modelled '${note.label}' yet this week. "
      '${tip.isEmpty ? 'Try it at snack time.' : tip}';
}
