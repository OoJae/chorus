/// Yes-or-no facts this device keeps about itself, such as whether the first
/// screen has been shown.
///
/// They belong to the device, not to an account or a circle: never synced
/// and never sent. Each is kept beside the circle cache, in a small file on
/// phones and desktops and in the browser's local storage on the web.
library;

import '../screens/support/circle_cache_none.dart'
    if (dart.library.io) '../screens/support/circle_cache_io.dart'
    if (dart.library.js_interop) '../screens/support/circle_cache_web.dart'
    as platform;

/// A fact this device keeps.
enum LocalFlag {
  /// The onboarding screen has been shown, or someone has signed in here:
  /// from then on a signed-out start opens on sign-in.
  seenOnboarding('chorus_seen_onboarding.txt');

  const LocalFlag(this.fileName);

  /// Where it is kept: the file's name, or the local storage key.
  final String fileName;
}

/// Reads and writes [LocalFlag]s, remembering each one it has read or
/// written so a second look needs no wait.
///
/// A flag that was never saved, or that cannot be read, is false. Saving
/// never throws: a flag that could not be saved is simply false again at
/// the next start.
class LocalFlags {
  LocalFlags();

  final Map<LocalFlag, bool> _known = {};

  /// The flag as last read or written here; null when it is not known yet.
  bool? known(LocalFlag flag) => _known[flag];

  Future<bool> read(LocalFlag flag) async {
    final known = _known[flag];
    if (known != null) return known;
    var value = false;
    try {
      value = await platform.readText(flag.fileName) == _yes;
    } catch (_) {
      // Unreadable storage counts as never saved.
    }
    // A write while this read was waiting is newer.
    return _known[flag] ??= value;
  }

  Future<void> write(LocalFlag flag, bool value) async {
    _known[flag] = value;
    try {
      await platform.writeText(flag.fileName, value ? _yes : _no);
    } catch (_) {
      // Storage refused (a private window, blocked site data): it holds for
      // this run only.
    }
  }

  static const String _yes = 'yes';
  static const String _no = 'no';
}
