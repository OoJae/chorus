/// In-memory modelling for the gallery and the tests.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/foundation.dart';

import 'contracts_modelling.dart';

/// Modelling held in memory. Records what it is asked to do.
class FakeModelling extends ModellingSource {
  FakeModelling({
    List<FocusPin> focusWords = const [],
    this.canPinFocus = true,
    this.nudgeNote,
    this.reportUrl = 'https://example.org/report/token',
    this.failReport = false,
  }) : _focus = List.of(focusWords);

  List<FocusPin> _focus;

  @override
  final bool canPinFocus;

  /// The nudge [nudge] gives until dismissed.
  FocusNudgeNote? nudgeNote;

  final String reportUrl;
  final bool failReport;

  /// Tiles passed to [noteModelled], in order.
  final List<TileFacts> modelled = [];

  /// How many reports were made.
  int reportsMade = 0;

  /// Links passed to [openLink]; it opens them when [opensLinks].
  final List<String> opened = [];
  bool opensLinks = false;

  @override
  List<FocusPin> get focusWords => List.unmodifiable(_focus);

  @override
  Future<void> refreshFocus() async {}

  @override
  Future<void> setFocusWords(List<FocusPin> pins) async {
    if (!canPinFocus) throw StateError('Only guardians and therapists.');
    _focus = List.of(pins.take(maxFocusWords));
    notifyListeners();
  }

  @override
  void noteModelled(TileFacts tile) => modelled.add(tile);

  @override
  Future<FocusNudgeNote?> nudge() async => nudgeNote;

  @override
  Future<void> dismissNudge(FocusNudgeNote note) async {
    nudgeNote = null;
  }

  @override
  Future<String> makeProgressReport() async {
    if (failReport) throw StateError('offline');
    reportsMade++;
    return reportUrl;
  }

  @override
  Future<bool> openLink(String url) async {
    if (!opensLinks) return false;
    opened.add(url);
    return true;
  }
}

/// Speech recognition that hears what [hear] says.
class FakeSpeechListener extends SpeechListener {
  FakeSpeechListener({this.available = true});

  @override
  final bool available;

  bool _listening = false;
  ValueChanged<String>? _onHeard;

  @override
  bool get listening => _listening;

  @override
  void start(ValueChanged<String> onHeard) {
    if (!available) return;
    _onHeard = onHeard;
    _listening = true;
    notifyListeners();
  }

  @override
  void stop() {
    _listening = false;
    _onHeard = null;
    notifyListeners();
  }

  /// Delivers [phrase] as if it had been heard.
  void hear(String phrase) => _onHeard?.call(phrase);
}
