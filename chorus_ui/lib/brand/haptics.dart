/// Haptics as punctuation: each one belongs to a named moment.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The moments that may be felt, and the feedback each one plays. There is
/// none on scroll, and none when a word arrives on the child's board.
enum ChorusHaptic {
  /// The child taps a word. On an AAC board the tap is the action, and
  /// feeling it helps children with motor difficulties.
  wordTapped(HapticFeedback.lightImpact),

  /// The sentence is spoken.
  sentenceSpoken(HapticFeedback.mediumImpact),

  /// "Hold to leave" completes.
  leftBoard(HapticFeedback.heavyImpact),

  /// An adult's word is added.
  wordAdded(HapticFeedback.mediumImpact),

  /// A waiting word is placed in a cell.
  wordPlaced(HapticFeedback.mediumImpact),

  /// A clash arrives in "Needs a home". Once.
  clashArrived(HapticFeedback.heavyImpact),

  /// The board tab changes.
  tabChanged(HapticFeedback.selectionClick),

  /// Something failed.
  failed(HapticFeedback.vibrate);

  const ChorusHaptic(this._feedback);

  final Future<void> Function() _feedback;
}

/// Plays [ChorusHaptic] moments on the device.
///
/// In the browser every moment does nothing: the web engine turns haptics
/// into `navigator.vibrate`, which most browsers ignore and Chrome refuses
/// (with a console warning) unless the page was just tapped, as it was not
/// when a clash arrives.
abstract final class ChorusHaptics {
  /// Where moments go instead of the device; for tests. Set it back to null
  /// afterwards.
  @visibleForTesting
  static void Function(ChorusHaptic moment)? sink;

  /// Plays [moment]; nothing when it is null.
  static void play(ChorusHaptic? moment) {
    if (moment == null) return;
    final sink = ChorusHaptics.sink;
    if (sink != null) {
      sink(moment);
      return;
    }
    if (kIsWeb) return;
    // A platform with no haptics may answer with an error: the moment is
    // simply not felt.
    unawaited(moment._feedback().catchError((Object _) {}));
  }

  static void wordTapped() => play(ChorusHaptic.wordTapped);
  static void sentenceSpoken() => play(ChorusHaptic.sentenceSpoken);
  static void leftBoard() => play(ChorusHaptic.leftBoard);
  static void wordAdded() => play(ChorusHaptic.wordAdded);
  static void wordPlaced() => play(ChorusHaptic.wordPlaced);
  static void clashArrived() => play(ChorusHaptic.clashArrived);
  static void tabChanged() => play(ChorusHaptic.tabChanged);
  static void failed() => play(ChorusHaptic.failed);
}
