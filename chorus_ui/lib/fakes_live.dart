/// An in-memory [LiveSession] for running the screens with no server.
library;

import 'dart:async';

import 'contracts_live.dart';

/// A [LiveSession] driven by hand.
///
/// The `receive*` and `set*` methods stand in for the other devices; the
/// `sent*` lists record what this device would have sent. It keeps the
/// contract's rules: nothing is sent while disconnected, a sentence is sent
/// only while [shareSaid] is on, and a pulse fades after [pulseFor].
class FakeLiveSession extends LiveSession {
  FakeLiveSession({
    this._connected = true,
    this._shareSaid = false,
    List<String> present = const [],
    this.pulseFor = livePulseFor,
  }) : _present = List.of(present);

  final Duration pulseFor;

  /// Every tile id passed to [sendPulse] while connected, oldest first.
  final List<String> sentPulses = [];

  /// Every sentence that [sendSaid] really sent, oldest first.
  final List<String> sentSaid = [];

  bool _connected;
  bool _shareSaid;
  List<String> _present;
  String? _lastSaid;
  final Map<String, Timer> _pulses = {};
  bool _disposed = false;

  @override
  bool get connected => _connected;

  @override
  Set<String> get pulsing => Set.unmodifiable(_pulses.keys);

  @override
  List<String> get present => List.unmodifiable(_present);

  @override
  bool get shareSaid => _shareSaid;

  @override
  set shareSaid(bool value) {
    if (_shareSaid == value) return;
    _shareSaid = value;
    notifyListeners();
  }

  @override
  String? get lastSaid => _lastSaid;

  @override
  void sendPulse(String tileId) {
    if (!_connected) return;
    sentPulses.add(tileId);
    _glow(tileId);
  }

  @override
  void sendSaid(String text) {
    if (!_connected || !_shareSaid || text.trim().isEmpty) return;
    sentSaid.add(text);
  }

  /// The connection opened or dropped. Dropping empties everything live.
  void setConnected(bool value) {
    if (_connected == value) return;
    _connected = value;
    if (!value) {
      _present = [];
      for (final timer in _pulses.values) {
        timer.cancel();
      }
      _pulses.clear();
    }
    notifyListeners();
  }

  /// The members present changed.
  void setPresent(List<String> names) {
    _present = List.of(names);
    notifyListeners();
  }

  /// Another member tapped [tileId] in model mode.
  void receivePulse(String tileId) {
    if (!_connected) return;
    _glow(tileId);
  }

  /// Another device shared a sentence.
  void receiveSaid(String text) {
    if (!_connected) return;
    _lastSaid = text;
    notifyListeners();
  }

  void _glow(String tileId) {
    _pulses[tileId]?.cancel();
    _pulses[tileId] = Timer(pulseFor, () {
      _pulses.remove(tileId);
      if (!_disposed) notifyListeners();
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final timer in _pulses.values) {
      timer.cancel();
    }
    _pulses.clear();
    super.dispose();
  }
}
