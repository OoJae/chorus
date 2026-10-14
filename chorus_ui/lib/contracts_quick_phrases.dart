/// Quick phrases and the device's own word counts, as the screens see them.
///
/// Kept apart from `contracts.dart` so every screen works exactly as before
/// without them: the talker then uses the default phrases and counts words
/// in memory only.
library;

import 'package:flutter/foundation.dart';

/// A circle's quick phrases on this device: the few whole sentences the
/// child's board says at once.
///
/// Notifies listeners whenever [phrases] or [canEdit] change.
abstract class QuickPhraseBook extends ChangeNotifier {
  /// The phrases in order. Never empty: the defaults until the circle's own
  /// reach this device, and kept on the device for use offline.
  List<String> get phrases;

  /// True when the signed-in adult may change them: every role but a
  /// read-only partner.
  bool get canEdit;

  /// Asks the server for the circle's phrases and keeps them on the device.
  /// Never throws: offline, what the device has stays.
  Future<void> refresh();

  /// Replaces the circle's phrases with [phrases], in order. An empty list
  /// puts the defaults back. Throws when it could not be saved (offline, or
  /// not allowed); nothing changes then.
  Future<void> save(List<String> phrases);
}

/// How often this device has spoken each word, counted on this device only
/// and never sent anywhere. The keyboard's predictions put these words
/// first.
abstract class SpokenWordCounts {
  /// Uses by lowercase word.
  Map<String, int> get counts;

  /// Counts each word of [text] once more. Never throws.
  void noteSaid(String text);
}
