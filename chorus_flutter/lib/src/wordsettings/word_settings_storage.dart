/// Where hidden words and the second language are kept on this device, so
/// the child's board shows them with no network.
///
/// Per device, never synced: a small file per adult and circle on phones and
/// desktops, the browser's local storage on the web, as the word log keeps
/// its words.
library;

import '../../screens/support/circle_cache_none.dart'
    if (dart.library.io) '../../screens/support/circle_cache_io.dart'
    if (dart.library.js_interop) '../../screens/support/circle_cache_web.dart'
    as platform;

/// Text kept under a few keys. Both calls may throw: a failed read is
/// taken as nothing kept and a failed write as a lost save.
abstract class WordSettingsStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String text);
}

/// The device's own storage for [userId]'s settings of [circleId].
class DeviceWordSettingsStorage implements WordSettingsStorage {
  DeviceWordSettingsStorage({required this.userId, required this.circleId});

  final String userId;
  final String circleId;

  String _name(String key) => 'chorus_word_settings_${userId}_${circleId}_$key';

  @override
  Future<String?> read(String key) => platform.readText(_name(key));

  @override
  Future<void> write(String key, String text) =>
      platform.writeText(_name(key), text);
}

/// Storage held in memory, for tests.
class MemoryWordSettingsStorage implements WordSettingsStorage {
  final Map<String, String> saved = {};

  @override
  Future<String?> read(String key) async => saved[key];

  @override
  Future<void> write(String key, String text) async => saved[key] = text;
}
