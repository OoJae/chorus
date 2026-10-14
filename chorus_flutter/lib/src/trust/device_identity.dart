/// Who this device is, for "Who is up to date": a random id kept on the
/// device, and a plain description of it.
library;

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../screens/support/circle_cache_none.dart'
    if (dart.library.io) '../../screens/support/circle_cache_io.dart'
    if (dart.library.js_interop) '../../screens/support/circle_cache_web.dart'
    as platform;

/// Where the id is kept: a small file, or local storage on the web.
const String _deviceIdFile = 'chorus_device_id.txt';

String? _known;

/// This device's id: made once at random and kept. Never fails; where it
/// cannot be kept it lasts for this run.
Future<String> deviceId() async {
  final known = _known;
  if (known != null) return known;
  try {
    final saved = (await platform.readText(_deviceIdFile))?.trim();
    if (saved != null && saved.length >= 8 && saved.length <= 64) {
      return _known = saved;
    }
  } catch (_) {
    // Unreadable storage counts as never saved.
  }
  final random = Random.secure();
  final made = List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  _known = made;
  try {
    await platform.writeText(_deviceIdFile, made);
  } catch (_) {
    // Kept for this run only.
  }
  return made;
}

/// "Web browser", "Android phone", "iPhone", "Mac" and so on.
String deviceLabel() {
  if (kIsWeb) return 'Web browser';
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'Android phone',
    TargetPlatform.iOS => 'iPhone',
    TargetPlatform.macOS => 'Mac',
    TargetPlatform.windows => 'Windows computer',
    TargetPlatform.linux => 'Linux computer',
    TargetPlatform.fuchsia => 'Device',
  };
}
