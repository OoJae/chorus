/// This device's settings for the child's board, kept on the device.
library;

import 'dart:convert';

import 'package:chorus_ui/contracts_device.dart';

import '../../screens/support/circle_cache_none.dart'
    if (dart.library.io) '../../screens/support/circle_cache_io.dart'
    if (dart.library.js_interop) '../../screens/support/circle_cache_web.dart'
    as platform;

/// Where the settings are kept: a small file on phones and desktops, the
/// browser's local storage on the web. Never synced and never sent.
const String deviceSettingsFile = 'chorus_device_settings.json';

/// [DeviceSettings] beside the app's other local facts (see `LocalFlags`).
///
/// Starts with the defaults and reads the saved settings once, notifying
/// when they arrive. Saving never throws: settings that could not be kept
/// hold for this run.
class LocalDeviceSettings extends DeviceSettingsStore {
  LocalDeviceSettings({
    Future<String?> Function(String name)? read,
    Future<void> Function(String name, String text)? write,
  }) : _read = read ?? platform.readText,
       _write = write ?? platform.writeText {
    _loaded = _load();
  }

  final Future<String?> Function(String name) _read;
  final Future<void> Function(String name, String text) _write;

  DeviceSettings _settings = const DeviceSettings();
  bool _changedHere = false;
  late final Future<void> _loaded;

  /// Completes once the saved settings have been read.
  Future<void> get loaded => _loaded;

  @override
  DeviceSettings get settings => _settings;

  Future<void> _load() async {
    try {
      final text = await _read(deviceSettingsFile);
      // A change made while this read was waiting is newer.
      if (text == null || _changedHere) return;
      final read = DeviceSettings.fromJson(jsonDecode(text));
      if (read == _settings) return;
      _settings = read;
      notifyListeners();
    } catch (_) {
      // Unreadable: the defaults.
    }
  }

  @override
  Future<void> save(DeviceSettings value) async {
    _changedHere = true;
    if (value != _settings) {
      _settings = value;
      notifyListeners();
    }
    try {
      await _write(deviceSettingsFile, jsonEncode(value.toJson()));
    } catch (_) {
      // Storage refused: it holds for this run only.
    }
  }
}
