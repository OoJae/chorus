/// Where the word log keeps what it holds on this device: the words not
/// sent yet, and whether the log was on when the server last said.
///
/// Per device, never synced: a small file per adult and circle on phones and
/// desktops, the browser's local storage on the web, as the circle cache
/// and the "Share what is said" switch are kept.
library;

import '../../screens/support/circle_cache_none.dart'
    if (dart.library.io) '../../screens/support/circle_cache_io.dart'
    if (dart.library.js_interop) '../../screens/support/circle_cache_web.dart'
    as platform;

/// Text kept under a few keys. Both calls may throw; the word log treats a
/// failed read as nothing kept and a failed write as a lost save.
abstract class WordLogStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String text);
}

/// The device's own storage for [userId]'s log of [circleId].
class DeviceWordLogStorage implements WordLogStorage {
  DeviceWordLogStorage({required this.userId, required this.circleId});

  final String userId;
  final String circleId;

  String _name(String key) => 'chorus_word_log_${userId}_${circleId}_$key';

  @override
  Future<String?> read(String key) => platform.readText(_name(key));

  @override
  Future<void> write(String key, String text) =>
      platform.writeText(_name(key), text);
}

/// Storage held in memory, for tests. Survives a new log made on it, as the
/// device's storage survives a restart.
class MemoryWordLogStorage implements WordLogStorage {
  final Map<String, String> saved = {};

  /// When set, every call throws it, as a refused store does.
  Object? failWith;

  @override
  Future<String?> read(String key) async {
    final error = failWith;
    if (error != null) throw error;
    return saved[key];
  }

  @override
  Future<void> write(String key, String text) async {
    final error = failWith;
    if (error != null) throw error;
    saved[key] = text;
  }
}
