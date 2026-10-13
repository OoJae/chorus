/// One circle's photos and clips on this device.
///
/// Everything a tile needs is read from the local files, so a board with
/// pictures and voices works with no connection. The network is used for
/// two things only, both in the background: sending files this device made,
/// and fetching files other devices made.
library;

import 'dart:async';

import 'package:chorus_client/chorus_client.dart'
    show CircleException, CircleFailure;
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/contracts_media.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'image_shrink.dart';
import 'media_files.dart';
import 'media_gateway.dart';
import 'media_hash.dart';
import 'upload_queue.dart';

/// Upper limit for a stored clip, in bytes: the server's own limit for
/// audio, so a clip this device accepts is one the server will take. Five
/// seconds of speech in a compact codec is a few tens of kilobytes; five
/// seconds of uncompressed audio, the fallback in a browser with no
/// encoder, is about 160 KB.
const int maxClipBytes = 600 * 1024;

/// Where a speaker finds a tile's recorded clip.
abstract class ClipSource {
  /// True when the clip for [hash] is on this device.
  bool hasAudio(String? hash);

  /// File path of the clip where files have paths; null in a browser.
  String? clipPath(String hash);

  /// The clip's bytes, or null when it is not on this device.
  Future<Uint8List?> clipBytes(String hash);
}

/// The [MediaStore] of one circle, backed by [MediaFiles] and a
/// [MediaGateway].
class CachedMediaStore extends MediaStore implements ClipSource {
  /// [files] is usually `openMediaFiles()`. [queueName] names this circle's
  /// saved upload queue; use a different one per user and circle. When
  /// [sync] is given, uploads and downloads are retried at once each time
  /// it goes live. [shrink] exists so tests can skip the image work.
  CachedMediaStore({
    required Future<MediaFiles> files,
    required this._gateway,
    required String queueName,
    SyncStatus? sync,
    Future<Uint8List> Function(Uint8List bytes)? shrink,
    Duration retryBase = const Duration(seconds: 2),
    Duration retryMax = const Duration(minutes: 5),
  }) : _sync = sync,
       _shrink = shrink ?? _shrinkOffThread,
       _retryBase = retryBase,
       _retryMax = retryMax,
       _queueName = 'uploads_$queueName' {
    _queue = MediaUploadQueue(
      send: _send,
      load: () async => (await _opening).readNote(_queueName),
      save: (text) async => (await _opening).writeNote(_queueName, text),
      onChanged: _changed,
      retryBase: retryBase,
      retryMax: retryMax,
    );
    _wasLive =
        sync?.state == SyncState.live && !(sync?.workingOffline ?? false);
    sync?.addListener(_onSync);
    _opening = files.then((opened) {
      _files = opened;
      if (_disposed) return opened;
      unawaited(_queue.start());
      // Tiles drawn before the files opened asked and got nothing.
      _changed();
      return opened;
    });
  }

  final MediaGateway _gateway;
  final SyncStatus? _sync;
  final Future<Uint8List> Function(Uint8List bytes) _shrink;
  final Duration _retryBase;
  final Duration _retryMax;
  final String _queueName;

  late final MediaUploadQueue _queue;
  late final Future<MediaFiles> _opening;
  MediaFiles? _files;
  bool _disposed = false;
  bool _wasLive = false;

  /// Decoded-on-demand pictures, one provider per hash so the framework's
  /// image cache can match them.
  final Map<String, MemoryImage> _images = {};
  final Set<String> _loading = {};

  /// Hashes some tile needs that are not on this device.
  final Set<String> _wanted = {};
  bool _fetching = false;
  int _failedFetches = 0;
  Timer? _fetchTimer;

  /// Completes when the local files are open.
  Future<void> get ready => _opening.then((_) {});

  @override
  int get pendingUploads => _queue.length;

  /// Hashes some tile needs that have not arrived yet.
  Set<String> get missing => Set.unmodifiable(_wanted);

  // ---- Reading -----------------------------------------------------------

  @override
  ImageProvider? imageFor(String? hash) {
    if (hash == null || !isSha256Hex(hash)) return null;
    final image = _images[hash];
    if (image != null) return image;
    final files = _files;
    if (files == null) return null;
    if (files.has(hash)) {
      unawaited(_loadImage(files, hash));
    } else {
      _want(hash);
    }
    return null;
  }

  Future<void> _loadImage(MediaFiles files, String hash) async {
    if (!_loading.add(hash)) return;
    try {
      final bytes = await files.read(hash);
      if (_disposed) return;
      if (bytes == null) {
        // Listed but gone: ask the server for it again.
        _want(hash);
        return;
      }
      _images[hash] = MemoryImage(bytes);
      _changed();
    } catch (_) {
      // Unreadable now; the next build asks again.
    } finally {
      _loading.remove(hash);
    }
  }

  @override
  bool hasAudio(String? hash) {
    if (hash == null || !isSha256Hex(hash)) return false;
    final files = _files;
    if (files == null) return false;
    if (files.has(hash)) return true;
    _want(hash);
    return false;
  }

  @override
  String? clipPath(String hash) => _files?.pathOf(hash);

  @override
  Future<Uint8List?> clipBytes(String hash) async {
    if (!isSha256Hex(hash)) return null;
    return (await _opening).read(hash);
  }

  // ---- Adding ------------------------------------------------------------

  @override
  Future<String> addImage(Uint8List bytes) async {
    final jpeg = await _shrink(bytes);
    final hash = await _keep(jpeg, isAudio: false);
    _images[hash] ??= MemoryImage(jpeg);
    _changed();
    return hash;
  }

  @override
  Future<String> addAudio(Uint8List bytes) async {
    if (bytes.isEmpty) {
      throw ArgumentError.value(bytes, 'bytes', 'An empty recording');
    }
    if (bytes.length > maxClipBytes) {
      throw ArgumentError.value(
        bytes.length,
        'bytes',
        'A clip is at most $maxClipBytes bytes',
      );
    }
    final hash = await _keep(bytes, isAudio: true);
    _changed();
    return hash;
  }

  /// Stores [bytes] locally first, then queues the upload: the hash is safe
  /// to put on a tile as soon as this completes, connection or not.
  Future<String> _keep(Uint8List bytes, {required bool isAudio}) async {
    if (_disposed) throw StateError('The media store is closed.');
    final hash = sha256Hex(bytes);
    final files = await _opening;
    await files.write(hash, bytes);
    _wanted.remove(hash);
    _queue.add(hash, isAudio: isAudio, bytes: bytes.length);
    return hash;
  }

  /// True while an adult has this device working offline: nothing is sent
  /// or fetched, and everything waits for sync to resume.
  bool get _paused => _sync?.workingOffline ?? false;

  Future<UploadOutcome> _send(QueuedUpload upload) async {
    // Kept in the queue without touching the network.
    if (_paused) return UploadOutcome.retryLater;
    final bytes = await (await _opening).read(upload.hash);
    // The local file was removed: there is nothing left to send.
    if (bytes == null) return UploadOutcome.dropped;
    try {
      await _gateway.upload(upload.hash, bytes, isAudio: upload.isAudio);
    } on CircleException catch (refusal) {
      // The server will never take this file from this adult (read-only
      // now, or the file is not one it accepts). Asking again changes
      // nothing, so it leaves the queue; the local copy stays.
      if (refusal.failure == CircleFailure.notAllowed) {
        return UploadOutcome.dropped;
      }
      rethrow;
    }
    return UploadOutcome.sent;
  }

  // ---- Fetching ----------------------------------------------------------

  void _want(String hash) {
    if (_disposed || !_wanted.add(hash)) return;
    // Asked for while a frame is being built: gather the whole board's
    // hashes into one request.
    if (!_fetching && _fetchTimer == null) {
      _fetchTimer = Timer(const Duration(milliseconds: 50), _fetch);
    }
  }

  Future<void> _fetch() async {
    _fetchTimer?.cancel();
    _fetchTimer = null;
    if (_fetching || _disposed || _wanted.isEmpty) return;
    // Working offline: what is wanted is asked for when sync resumes.
    if (_paused) return;
    _fetching = true;
    var arrived = false;
    try {
      final files = await _opening;
      final asked = _wanted.take(100).toList();
      final urls = await _gateway.downloadUrls(asked);
      for (final hash in asked) {
        final url = urls[hash];
        // Not on the server yet: its author has not been online since.
        if (url == null) continue;
        try {
          final bytes = await _gateway.fetch(url);
          if (_disposed) return;
          // Never trust the link: only bytes that hash to the name are kept.
          if (sha256Hex(bytes) != hash) continue;
          await files.write(hash, bytes);
          _wanted.remove(hash);
          arrived = true;
          _changed();
        } catch (_) {
          // This one failed; the others may still arrive.
        }
      }
    } catch (_) {
      // No signal or no server. Tried again below.
    } finally {
      _fetching = false;
    }
    if (_disposed || _wanted.isEmpty) {
      _failedFetches = 0;
      return;
    }
    if (arrived) _failedFetches = 0;
    _fetchTimer = Timer(
      backoffDelay(_failedFetches++, base: _retryBase, max: _retryMax),
      _fetch,
    );
  }

  /// Tries the waiting uploads and downloads now. Called when the
  /// connection comes back; safe to call at any time.
  void retryNow() {
    if (_disposed) return;
    _queue.kick();
    if (_wanted.isNotEmpty && !_fetching) {
      _failedFetches = 0;
      unawaited(_fetch());
    }
  }

  void _onSync() {
    final live = _sync?.state == SyncState.live && !_paused;
    if (live && !_wasLive) retryNow();
    _wasLive = live;
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _sync?.removeListener(_onSync);
    _fetchTimer?.cancel();
    _queue.dispose();
    super.dispose();
  }
}

/// Decoding a camera photo in pure Dart takes long enough to drop frames,
/// so it runs on another isolate (in a browser, where there is none, it
/// runs in place).
Future<Uint8List> _shrinkOffThread(Uint8List bytes) =>
    compute(shrinkToJpeg, bytes);
