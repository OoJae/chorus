/// Replica file clean-up on platforms with a file system.
library;

import 'dart:io';

/// Deletes the SQLite file at [path] and its write-ahead-log companions.
/// Missing files are ignored.
Future<void> deleteReplicaFiles(String path) async {
  for (final suffix in const ['', '-wal', '-shm']) {
    final file = File('$path$suffix');
    if (await file.exists()) await file.delete();
  }
}
