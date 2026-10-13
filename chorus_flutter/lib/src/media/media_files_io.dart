/// Media storage on phones and desktops: one file per hash in the
/// app-support directory, which the system does not clear behind the app's
/// back the way it may clear a cache directory.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'media_files.dart';
import 'media_hash.dart';

Future<MediaFiles> openPlatformMediaFiles() async {
  final support = await getApplicationSupportDirectory();
  return IoMediaFiles.open(Directory(p.join(support.path, 'media')));
}

/// Files named `<hash>.<extension>` in one directory.
///
/// The extension is read from the bytes when the file is written. It is
/// there for the audio player, which on some platforms goes by the file
/// name; the hash alone identifies the file.
class IoMediaFiles implements MediaFiles {
  IoMediaFiles._(this._dir, this._names);

  final Directory _dir;

  /// File name by hash, for every media file in [_dir].
  final Map<String, String> _names;

  /// Opens [dir], creating it if needed, and lists what it holds.
  static Future<IoMediaFiles> open(Directory dir) async {
    await dir.create(recursive: true);
    final names = <String, String>{};
    await for (final entry in dir.list()) {
      if (entry is! File) continue;
      final name = p.basename(entry.path);
      final hash = p.basenameWithoutExtension(name);
      // Notes and half-written files are not media.
      if (isSha256Hex(hash) && !name.endsWith('.part')) names[hash] = name;
    }
    return IoMediaFiles._(dir, names);
  }

  @override
  bool has(String hash) => _names.containsKey(hash);

  @override
  String? pathOf(String hash) {
    final name = _names[hash];
    return name == null ? null : p.join(_dir.path, name);
  }

  @override
  Future<Uint8List?> read(String hash) async {
    final path = pathOf(hash);
    if (path == null) return null;
    try {
      return await File(path).readAsBytes();
    } on FileSystemException {
      // Removed behind the app's back: forget it so it is fetched again.
      _names.remove(hash);
      return null;
    }
  }

  @override
  Future<void> write(String hash, Uint8List bytes) async {
    if (!isSha256Hex(hash)) {
      throw ArgumentError.value(hash, 'hash', 'Not a SHA-256');
    }
    if (_names.containsKey(hash)) return;
    final name = '$hash.${sniffFormat(bytes).extension}';
    await _writeWhole(p.join(_dir.path, name), (file) => file.writeAsBytes(bytes, flush: true));
    _names[hash] = name;
  }

  @override
  Future<String?> readNote(String name) async {
    final file = File(p.join(_dir.path, _noteName(name)));
    try {
      return await file.readAsString();
    } on FileSystemException {
      return null;
    }
  }

  @override
  Future<void> writeNote(String name, String text) => _writeWhole(
        p.join(_dir.path, _noteName(name)),
        (file) => file.writeAsString(text, flush: true),
      );

  /// Writes beside [path] and renames, so a crash never leaves half a file
  /// under a name that claims to be whole.
  Future<void> _writeWhole(
    String path,
    Future<File> Function(File file) write,
  ) async {
    await _dir.create(recursive: true);
    final part = File('$path.part');
    await write(part);
    await part.rename(path);
  }

  /// Notes keep to letters, digits, dash and underscore, so a note can never
  /// be mistaken for a media file or leave the directory.
  static String _noteName(String name) =>
      'note_${name.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}.json';
}
