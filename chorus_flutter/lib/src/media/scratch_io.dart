/// Scratch files on phones and desktops: short-lived files in the system's
/// temporary directory, for a recording in progress and for playing back a
/// clip that has not been saved.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// A path for a scratch file called [name]. Nothing is created.
Future<String?> scratchPath(String name) async =>
    p.join((await getTemporaryDirectory()).path, name);

/// Writes [bytes] to a scratch file called [name], replacing any earlier
/// one, and completes with its path.
Future<String?> writeScratch(String name, Uint8List bytes) async {
  final path = (await scratchPath(name))!;
  await File(path).writeAsBytes(bytes, flush: true);
  return path;
}

/// Deletes a scratch file. A missing file is ignored.
Future<void> deleteScratch(String path) async {
  try {
    await File(path).delete();
  } on FileSystemException {
    // Already gone.
  }
}
