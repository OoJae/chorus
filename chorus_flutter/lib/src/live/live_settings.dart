/// The per-device switch for sharing what the child's board says.
///
/// It is a setting of this device, not of the circle: it is never synced and
/// never sent. It is kept beside the circle cache, in a small file on phones
/// and desktops and in the browser's local storage on the web.
library;

import '../../screens/support/circle_cache_none.dart'
    if (dart.library.io) '../../screens/support/circle_cache_io.dart'
    if (dart.library.js_interop) '../../screens/support/circle_cache_web.dart'
    as platform;

/// Whether [userId] turned sharing on for [circleId] on this device. False
/// when nothing was saved or the store is unreadable: private by default.
Future<bool> readShareSaid(String userId, String circleId) async {
  try {
    return await platform.readText(_fileName(userId, circleId)) == 'on';
  } catch (_) {
    return false;
  }
}

/// Saves the switch. Throws if the store refuses, so a caller turning
/// sharing off can tell the adult it may come back on at the next start.
Future<void> writeShareSaid(String userId, String circleId, bool value) =>
    platform.writeText(_fileName(userId, circleId), value ? 'on' : 'off');

String _fileName(String userId, String circleId) =>
    'chorus_share_said_${userId}_$circleId.txt';
