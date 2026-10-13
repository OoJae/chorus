/// Replica file clean-up where there is no file system (the browser).
library;

/// Does nothing: a browser database has no files this app can remove.
Future<void> deleteReplicaFiles(String path) async {}
