/// Media storage in a browser: IndexedDB, which keeps bytes across reloads
/// and has room for a few hundred small pictures. Local storage is too small
/// and holds only text.
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'media_files.dart';
import 'media_hash.dart';

const String _database = 'chorus_media';
const String _fileStore = 'files';
const String _noteStore = 'notes';

/// Opens the browser database. Throws when the browser refuses storage (a
/// private window, blocked site data); the caller then keeps files in
/// memory.
Future<MediaFiles> openPlatformMediaFiles() async {
  final db = await _openDatabase().timeout(const Duration(seconds: 5));
  final keys = await _done(
    db.transaction(_fileStore.toJS).objectStore(_fileStore).getAllKeys(),
  );
  final held = <String>{};
  if (keys != null) {
    for (final key in (keys as JSArray<JSAny?>).toDart) {
      if (key.isA<JSString>()) held.add((key as JSString).toDart);
    }
  }
  return _IndexedDbMediaFiles(db, held);
}

Future<web.IDBDatabase> _openDatabase() {
  final opened = Completer<web.IDBDatabase>();
  final request = web.window.indexedDB.open(_database, 1);
  request.onupgradeneeded = ((web.Event _) {
    final db = request.result as web.IDBDatabase;
    for (final name in const [_fileStore, _noteStore]) {
      if (!db.objectStoreNames.contains(name)) db.createObjectStore(name);
    }
  }).toJS;
  request.onsuccess = ((web.Event _) {
    if (!opened.isCompleted) opened.complete(request.result as web.IDBDatabase);
  }).toJS;
  void fail(web.Event _) {
    if (!opened.isCompleted) {
      opened.completeError(StateError('The browser refused media storage.'));
    }
  }

  request.onerror = fail.toJS;
  request.onblocked = fail.toJS;
  return opened.future;
}

/// The result of [request] once the browser has finished it.
Future<JSAny?> _done(web.IDBRequest request) {
  final done = Completer<JSAny?>();
  request.onsuccess = ((web.Event _) {
    if (!done.isCompleted) done.complete(request.result);
  }).toJS;
  request.onerror = ((web.Event _) {
    if (!done.isCompleted) {
      done.completeError(StateError('A media storage request failed.'));
    }
  }).toJS;
  return done.future;
}

class _IndexedDbMediaFiles implements MediaFiles {
  _IndexedDbMediaFiles(this._db, this._held);

  final web.IDBDatabase _db;

  /// Every hash in the database, so [has] needs no round trip.
  final Set<String> _held;

  web.IDBObjectStore _store(String name, {bool write = false}) => _db
      .transaction(name.toJS, write ? 'readwrite' : 'readonly')
      .objectStore(name);

  @override
  bool has(String hash) => _held.contains(hash);

  @override
  String? pathOf(String hash) => null;

  @override
  Future<Uint8List?> read(String hash) async {
    if (!_held.contains(hash)) return null;
    final value = await _done(_store(_fileStore).get(hash.toJS));
    if (value == null || !value.isA<JSUint8Array>()) {
      // Cleared behind the app's back: forget it so it is fetched again.
      _held.remove(hash);
      return null;
    }
    return (value as JSUint8Array).toDart;
  }

  @override
  Future<void> write(String hash, Uint8List bytes) async {
    if (!isSha256Hex(hash)) {
      throw ArgumentError.value(hash, 'hash', 'Not a SHA-256');
    }
    if (_held.contains(hash)) return;
    await _done(_store(_fileStore, write: true).put(bytes.toJS, hash.toJS));
    _held.add(hash);
  }

  @override
  Future<String?> readNote(String name) async {
    final value = await _done(_store(_noteStore).get(name.toJS));
    if (value == null || !value.isA<JSString>()) return null;
    return (value as JSString).toDart;
  }

  @override
  Future<void> writeNote(String name, String text) async {
    await _done(_store(_noteStore, write: true).put(text.toJS, name.toJS));
  }
}
