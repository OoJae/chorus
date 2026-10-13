/// The optional word suggestion, over the server's `suggest.fromPhoto`.
library;

import 'dart:async';

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_ui/contracts.dart' show SyncState, SyncStatus;
import 'package:chorus_ui/contracts_suggest.dart';
import 'package:flutter/foundation.dart';

import '../media/image_shrink.dart';
import '../media/media_hash.dart';

/// Asks the server for a word that fits a photo an adult just picked.
///
/// The server only looks at pictures the circle has stored, so the photo is
/// first shrunk exactly as the media store shrinks it and uploaded under
/// the same hash. If the adult then saves the word, the store finds the
/// file already on the server; if they do not, the picture stays in the
/// circle's private storage and on no tile.
///
/// Every failure is the same quiet answer, null: no connection, the
/// service not set up, the day's budget used, a photo that cannot be read.
/// When the server says the service is not set up, [available] turns false
/// for as long as this object lives, so the offer is not made again.
class ServerWordSuggester implements WordSuggester {
  /// [upload] puts verified image bytes on the server under their hash.
  /// [suggest] is `client.suggest.fromPhoto` for the circle. [shrink]
  /// exists so tests can skip the image work.
  ServerWordSuggester({
    required this._upload,
    required this._suggest,
    this._sync,
    Future<Uint8List> Function(Uint8List bytes)? shrink,
    this.locale = 'en',
    this.timeout = const Duration(seconds: 75),
  }) : _shrink = shrink ?? _shrinkOffThread {
    _sync?.addListener(_update);
    _update();
  }

  /// The suggester the app uses for one circle.
  factory ServerWordSuggester.forClient(
    Client client, {
    required UuidValue circleSpace,
    required Future<void> Function(String hash, Uint8List bytes) upload,
    SyncStatus? sync,
    String locale = 'en',
  }) => ServerWordSuggester(
    upload: upload,
    suggest: (hash, locale) =>
        client.suggest.fromPhoto(circleSpace, hash, locale),
    sync: sync,
    locale: locale,
  );

  final Future<void> Function(String hash, Uint8List bytes) _upload;
  final Future<WordSuggestion> Function(String hash, String locale) _suggest;
  final SyncStatus? _sync;
  final Future<Uint8List> Function(Uint8List bytes) _shrink;

  /// Language the word should be in, as a language tag.
  final String locale;

  /// Longest wait for the upload and the answer together.
  final Duration timeout;

  final ValueNotifier<bool> _available = ValueNotifier(false);
  bool _notConfigured = false;
  bool _disposed = false;

  @override
  ValueListenable<bool> get available => _available;

  /// Online means sync is live: the same server answers both. Never while
  /// an adult has this device working offline.
  void _update() {
    if (_disposed) return;
    final sync = _sync;
    _available.value =
        !_notConfigured &&
        (sync == null ||
            (sync.state == SyncState.live && !sync.workingOffline));
  }

  @override
  Future<WordIdea?> fromPhoto(Uint8List photo) async {
    if (_disposed || !_available.value) return null;
    try {
      return await _ask(photo).timeout(timeout);
    } on SuggestException catch (refusal) {
      if (refusal.failure == SuggestFailure.notConfigured) {
        _notConfigured = true;
        _update();
      }
      return null;
    } catch (_) {
      // No connection, a timeout, a picture that will not decode: the adult
      // types the word.
      return null;
    }
  }

  Future<WordIdea?> _ask(Uint8List photo) async {
    final jpeg = await _shrink(photo);
    final hash = sha256Hex(jpeg);
    await _upload(hash, jpeg);
    final answer = await _suggest(hash, locale);
    final label = answer.label.trim();
    if (label.isEmpty) return null;
    final speech = answer.speech.trim();
    final colour = answer.colorKey.trim();
    return WordIdea(
      label: label,
      speech: speech == label ? '' : speech,
      colorKey: colour.isEmpty ? null : colour,
      alternatives: [
        for (final other in answer.alternatives)
          if (other.trim().isNotEmpty && other.trim() != label) other.trim(),
      ],
    );
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _sync?.removeListener(_update);
    _available.dispose();
  }
}

Future<Uint8List> _shrinkOffThread(Uint8List bytes) =>
    compute(shrinkToJpeg, bytes);
