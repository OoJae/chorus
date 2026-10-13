/// The local, content-addressed home of photos and clips.
///
/// A file is named by the SHA-256 of its bytes, so it is stored once however
/// many tiles use it and never needs updating. Where it lives depends on the
/// platform: files in the app-support directory on phones and desktops, the
/// browser's IndexedDB on the web. Small text notes (the upload queue) are
/// kept beside the files so they share their lifetime.
library;

import 'dart:typed_data';

import 'media_files_none.dart'
    if (dart.library.io) 'media_files_io.dart'
    if (dart.library.js_interop) 'media_files_web.dart'
    as platform;

/// Where media bytes are kept on this device.
abstract class MediaFiles {
  /// True when the bytes for [hash] are on this device. Answered from
  /// memory, so it is safe to call while building a widget.
  bool has(String hash);

  /// The bytes for [hash], or null when they are not here.
  Future<Uint8List?> read(String hash);

  /// Keeps [bytes] under [hash]. The caller has already checked that the
  /// hash is the SHA-256 of the bytes. Writing a hash that is held does
  /// nothing.
  Future<void> write(String hash, Uint8List bytes);

  /// Path of the file for [hash] where files have paths (phones, desktops)
  /// and the file is here; null otherwise.
  String? pathOf(String hash);

  /// A small text kept under [name], or null.
  Future<String?> readNote(String name);

  Future<void> writeNote(String name, String text);
}

/// A [MediaFiles] that lasts as long as the process. Used in tests, and in a
/// browser that refuses storage (a private window): photos then show for the
/// visit and are gone after a reload.
class MemoryMediaFiles implements MediaFiles {
  final Map<String, Uint8List> _files = {};
  final Map<String, String> _notes = {};

  @override
  bool has(String hash) => _files.containsKey(hash);

  @override
  Future<Uint8List?> read(String hash) async => _files[hash];

  @override
  Future<void> write(String hash, Uint8List bytes) async {
    _files.putIfAbsent(hash, () => bytes);
  }

  @override
  String? pathOf(String hash) => null;

  @override
  Future<String?> readNote(String name) async => _notes[name];

  @override
  Future<void> writeNote(String name, String text) async {
    _notes[name] = text;
  }
}

Future<MediaFiles>? _shared;

/// The media files of this device, opened once and shared by every circle.
/// Never throws: where no storage can be opened the files are kept in
/// memory.
Future<MediaFiles> openMediaFiles() => _shared ??= _open();

Future<MediaFiles> _open() async {
  try {
    return await platform.openPlatformMediaFiles();
  } catch (_) {
    return MemoryMediaFiles();
  }
}
