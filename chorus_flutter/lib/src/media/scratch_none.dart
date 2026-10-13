/// Scratch files where there is no file system (the browser): none.
library;

import 'dart:typed_data';

/// Null: a browser recorder keeps the clip itself and a browser player
/// takes bytes.
Future<String?> scratchPath(String name) async => null;

Future<String?> writeScratch(String name, Uint8List bytes) async => null;

Future<void> deleteScratch(String path) async {}
