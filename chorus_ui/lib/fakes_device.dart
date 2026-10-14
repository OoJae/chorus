/// In-memory stand-ins for this device's settings and the circle's voice.
library;

import 'contracts_device.dart';
import 'contracts_voice.dart';

/// Keeps [DeviceSettings] in memory.
class InMemoryDeviceSettings extends DeviceSettingsStore {
  InMemoryDeviceSettings([this._settings = const DeviceSettings()]);

  DeviceSettings _settings;

  /// Every value saved, oldest first.
  final List<DeviceSettings> saved = [];

  @override
  DeviceSettings get settings => _settings;

  @override
  Future<void> save(DeviceSettings value) async {
    saved.add(value);
    if (value == _settings) return;
    _settings = value;
    notifyListeners();
  }
}

/// A circle's voice in memory, with a fixed list of voices.
class FakeVoiceChoice extends VoiceChoice {
  FakeVoiceChoice({
    this.canChange = true,
    VoicePrefs prefs = const VoicePrefs(),
    this.names = const ['Samantha', 'Daniel'],
  }) : _prefs = prefs; // ignore: prefer_initializing_formals

  @override
  final bool canChange;

  final List<String> names;
  VoicePrefs _prefs;

  /// What "Try it" said, with the voice it said it in.
  final List<(String, VoicePrefs)> tried = [];

  @override
  VoicePrefs get prefs => _prefs;

  @override
  Future<List<String>> voiceNames() async => names;

  @override
  Future<void> choose(VoicePrefs prefs) async {
    if (!canChange) throw StateError('A read-only member cannot change it.');
    _prefs = prefs;
    notifyListeners();
  }

  @override
  Future<void> tryIt(String text) async => tried.add((text, _prefs));

  /// How many times [refresh] was asked for.
  int refreshes = 0;

  @override
  Future<void> refresh() async => refreshes++;
}
