/// The list of media files this device still owes the server.
///
/// A photo or clip added with no signal is usable at once from the local
/// files; this queue remembers that it has not been sent, across restarts,
/// and keeps trying until it has.
library;

import 'dart:async';
import 'dart:convert';

import 'package:chorus_shared/chorus_shared.dart';

/// One file waiting to be sent.
class QueuedUpload {
  QueuedUpload({required this.hash, required this.isAudio, required this.bytes});

  /// SHA-256 of the file, lowercase hex.
  final String hash;

  /// A recorded clip; otherwise a picture.
  final bool isAudio;

  /// Size of the file, as the server is told before the upload.
  final int bytes;

  /// Failed tries since the app started. Not saved.
  int attempts = 0;

  Map<String, Object> toJson() =>
      {'hash': hash, 'audio': isAudio, 'bytes': bytes};

  /// Null for an entry that is not understood, which is then dropped.
  static QueuedUpload? fromJson(Object? json) {
    if (json is! Map) return null;
    final hash = json['hash'], audio = json['audio'], bytes = json['bytes'];
    if (hash is! String || audio is! bool || bytes is! int) return null;
    return QueuedUpload(hash: hash, isAudio: audio, bytes: bytes);
  }
}

/// What became of one try.
enum UploadOutcome {
  /// The server holds the file. It leaves the queue.
  sent,

  /// Nothing more can be done for it on this device (its bytes are gone).
  /// It leaves the queue.
  dropped,

  /// Not now: no signal, the server is down, the upload did not verify.
  /// It keeps its place and is tried again later.
  retryLater,
}

/// Sends queued files oldest first, and keeps what could not be sent.
///
/// A pass tries every waiting file once, in the order they were added. A
/// file that fails keeps its place and does not hold up the files behind
/// it. While anything is left, another pass follows after a delay that
/// doubles from [retryBase] up to [retryMax]; [kick] starts one at once.
class MediaUploadQueue {
  MediaUploadQueue({
    required this._send,
    required this._load,
    required this._save,
    this._onChanged,
    this.retryBase = const Duration(seconds: 2),
    this.retryMax = const Duration(minutes: 5),
  });

  /// Tries one file. A thrown error counts as [UploadOutcome.retryLater].
  final Future<UploadOutcome> Function(QueuedUpload upload) _send;

  /// Reads and writes the saved queue, as one piece of text.
  final Future<String?> Function() _load;
  final Future<void> Function(String text) _save;

  /// Called whenever [length] changes.
  final void Function()? _onChanged;

  final Duration retryBase;
  final Duration retryMax;

  final List<QueuedUpload> _waiting = [];
  bool _started = false;
  bool _running = false;
  bool _disposed = false;

  /// Passes in a row that left something unsent.
  int _failedPasses = 0;
  Timer? _retry;
  Future<void> _saving = Future<void>.value();

  /// Files not yet on the server.
  int get length => _waiting.length;

  /// Hashes waiting, oldest first.
  List<String> get hashes => [for (final upload in _waiting) upload.hash];

  /// The delay before the automatic pass now scheduled; null when none is.
  Duration? get retryDelay => _retry == null ? null : _lastDelay;
  Duration? _lastDelay;

  /// Loads what an earlier run left unsent and starts sending. Files added
  /// before this completes go behind the loaded ones. Never throws.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    var loaded = const <QueuedUpload>[];
    try {
      final text = await _load();
      if (text != null) {
        loaded = [
          for (final item in jsonDecode(text) as List)
            ?QueuedUpload.fromJson(item),
        ];
      }
    } catch (_) {
      // An unreadable queue is an empty one: the files are still local.
    }
    if (_disposed) return;
    final added = {for (final upload in _waiting) upload.hash};
    _waiting.insertAll(0, loaded.where((u) => !added.contains(u.hash)));
    if (loaded.isNotEmpty) _onChanged?.call();
    kick();
  }

  /// Adds a file to the end of the queue and starts sending. A hash already
  /// waiting is not added twice.
  void add(String hash, {required bool isAudio, required int bytes}) {
    if (_disposed || _waiting.any((upload) => upload.hash == hash)) return;
    _waiting.add(QueuedUpload(hash: hash, isAudio: isAudio, bytes: bytes));
    _persist();
    _onChanged?.call();
    kick();
  }

  /// Starts a pass now instead of waiting out the delay, for example when
  /// the connection comes back. Does nothing while a pass is running.
  void kick() {
    if (_disposed || !_started) return;
    _retry?.cancel();
    _retry = null;
    if (!_running) unawaited(_pass());
  }

  Future<void> _pass() async {
    _running = true;
    final tried = <String>{};
    try {
      while (!_disposed) {
        // Looked up again each time round: files may be added mid-pass.
        final next =
            _waiting.where((u) => !tried.contains(u.hash)).firstOrNull;
        if (next == null) break;
        tried.add(next.hash);
        UploadOutcome outcome;
        try {
          outcome = await _send(next);
        } catch (_) {
          outcome = UploadOutcome.retryLater;
        }
        if (_disposed) return;
        if (outcome == UploadOutcome.retryLater) {
          next.attempts++;
        } else {
          _waiting.remove(next);
          _persist();
          _onChanged?.call();
        }
      }
    } finally {
      _running = false;
    }
    if (_disposed) return;
    if (_waiting.isEmpty) {
      _failedPasses = 0;
      return;
    }
    final delay =
        backoffDelay(_failedPasses++, base: retryBase, max: retryMax);
    _lastDelay = delay;
    _retry?.cancel();
    _retry = Timer(delay, () {
      _retry = null;
      if (!_running && !_disposed) unawaited(_pass());
    });
  }

  /// Saves the queue. Writes follow one another, so an older list can never
  /// land on top of a newer one.
  void _persist() {
    final text = jsonEncode([for (final upload in _waiting) upload.toJson()]);
    _saving = _saving.then((_) => _save(text)).catchError((_) {});
  }

  /// Completes when every save asked for so far has finished.
  Future<void> get saved => _saving;

  /// Stops sending. What is waiting stays saved for the next run.
  void dispose() {
    _disposed = true;
    _retry?.cancel();
    _retry = null;
  }
}
