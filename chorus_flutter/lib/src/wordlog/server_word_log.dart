/// The opt-in word log, over the server's `wordLog` endpoint.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:chorus_client/chorus_client.dart' hide CircleRole;
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart'
    show CircleRole, SyncState, SyncStatus;
import 'package:chorus_ui/contracts_wordlog.dart';
import 'package:flutter/foundation.dart';

import 'word_log_storage.dart';

/// How old a word may be and still be sent. The server takes nothing older
/// than 30 days; a day less leaves room for a device clock that is behind.
const Duration wordLogSendWithin = Duration(days: 29);

/// A [WordLog] that keeps the child's spoken words on this device and sends
/// them to the circle's log on the server.
///
/// Whether the log is on, and whether this adult may change it, come from
/// the server and are remembered on this device, so the child's board keeps
/// noting words with no signal. Words wait in a queue that survives a
/// restart (see `word_use.dart` for its rules) and go in batches while sync
/// is live and the adult has not paused it.
///
/// What the server answers decides what happens to a batch:
///  * any count, 0 included, is success: the server drops words spoken
///    before the log was last switched or deleted, and says how many it
///    kept, so the batch leaves the queue either way;
///  * "off" turns the log off here and empties the queue;
///  * a tile it does not know yet (perhaps not synced) is tried again later,
///    a few times, before the batch is given up;
///  * a bad time, or too many, cannot be sent at all: the batch is dropped;
///  * not being allowed (a partner, someone no longer in the circle) stops
///    the log on this device;
///  * no answer is tried again later, with a growing wait.
///
/// [noteSpoken] never throws and never waits: the child's tap is not slowed
/// by any of this.
class ServerWordLog extends WordLog {
  /// [status], [setEnabled], [record] and [deleteAll] are the server's
  /// calls for the circle. [mayRecord] is false for a read-only partner,
  /// whose device sends nothing. [canChange] is what to assume (a guardian)
  /// until the server or this device's last answer says.
  ServerWordLog({
    required this._status,
    required this._setEnabled,
    required this._record,
    required this._deleteAll,
    required this._storage,
    this._sync,
    this._mayRecord = true,
    this._canChange = false,
    DateTime Function()? now,
    this.callTimeout = const Duration(seconds: 20),
    this.retryBase = const Duration(seconds: 30),
    this.retryMax = const Duration(minutes: 10),
    this.unknownTileTries = 5,
  }) : _now = now ?? DateTime.now {
    _sync?.addListener(_onSync);
    _wasOnline = _online;
    _loading = _load();
    if (_online) unawaited(_refreshStatus());
  }

  /// The log the app uses for [circleSpace], kept on this device under
  /// [userId].
  factory ServerWordLog.forClient(
    Client client, {
    required UuidValue circleSpace,
    required String userId,
    required CircleRole role,
    SyncStatus? sync,
  }) => ServerWordLog(
    status: () => client.wordLog.status(circleSpace),
    setEnabled: (value) => client.wordLog.setEnabled(circleSpace, value),
    record: (uses) => client.wordLog.record(circleSpace, [
      for (final use in uses)
        if (_isUuid(use.tileId) && _isUuid(use.boardId))
          WordUseEntry(
            tileId: UuidValue.fromString(use.tileId),
            boardId: UuidValue.fromString(use.boardId),
            spokenAt: use.spokenAt,
          ),
    ]),
    deleteAll: () => client.wordLog.deleteAll(circleSpace),
    storage: DeviceWordLogStorage(userId: userId, circleId: circleSpace.uuid),
    sync: sync,
    mayRecord: role != CircleRole.partner,
    canChange: role == CircleRole.guardian,
  );

  final Future<WordLogStatus> Function() _status;
  final Future<WordLogStatus> Function(bool enabled) _setEnabled;
  final Future<int> Function(List<WordUse> uses) _record;
  final Future<int> Function() _deleteAll;
  final WordLogStorage _storage;
  final SyncStatus? _sync;
  final DateTime Function() _now;

  /// Longest wait for one server call.
  final Duration callTimeout;

  /// The first wait before a batch that got no answer is tried again; it
  /// doubles each time, up to [retryMax].
  final Duration retryBase;
  final Duration retryMax;

  /// How often a batch naming a tile the server does not know is tried
  /// before it is given up.
  final int unknownTileTries;

  static const String _queueKey = 'queue.json';
  static const String _statusKey = 'status.json';

  bool _enabled = false;
  bool _canChange;
  bool _mayRecord;
  bool _private = false;
  List<WordUse> _queue = const [];

  late final Future<void> _loading;
  bool _loaded = false;
  bool _heard = false;
  bool _disposed = false;
  bool _wasOnline = false;
  bool _checking = false;
  bool _sending = false;
  bool _saveQueued = false;
  bool _saveAfterLoad = false;
  Future<void> _saving = Future<void>.value();
  Timer? _retry;
  int _failures = 0;
  int _unknownTries = 0;

  @override
  bool get enabled => _enabled;

  @override
  bool get private => _private;

  @override
  bool get canChange => _canChange;

  @override
  int get pending => _queue.length;

  /// The words waiting on this device, oldest first.
  @visibleForTesting
  List<WordUse> get queued => List.unmodifiable(_queue);

  /// Completes once what this device kept has been read.
  @visibleForTesting
  Future<void> get ready => _loading;

  /// Completes once every save asked for so far has been written.
  @visibleForTesting
  Future<void> get saved => _saving;

  /// True while a batch waits for its next try.
  @visibleForTesting
  bool get retryPending => _retry != null;

  /// Sync is live and the adult has not paused it. With no supervisor (as
  /// in a test) the server is taken to be there.
  bool get _online {
    final sync = _sync;
    return sync == null ||
        (sync.state == SyncState.live && !sync.workingOffline);
  }

  // ---- The contract ------------------------------------------------------

  @override
  void noteSpoken(TileFacts tile) {
    try {
      if (_disposed || !_loaded || !_enabled || _private || !_mayRecord) {
        return;
      }
      _queue = enqueueWordUses(_queue, [
        WordUse(tileId: tile.id, boardId: tile.boardId, spokenAt: _now()),
      ]);
      _save();
      _notify();
      // A batch waiting out a failure is not hurried by every tap.
      if (_retry == null) _kick();
    } catch (_) {
      // The child's tap must never fail because of the log.
    }
  }

  @override
  Future<void> setEnabled(bool value) async {
    _requireGuardian();
    _requireConnection();
    final WordLogStatus status;
    try {
      status = await _setEnabled(value).timeout(callTimeout);
    } on CircleException {
      _lostGuardian();
      throw StateError(_guardianOnly);
    } catch (_) {
      throw StateError(
        'The word log could not be changed. Check the connection and try '
        'again.',
      );
    }
    if (_disposed) return;
    _heard = true;
    _apply(status);
    _kick();
  }

  @override
  void setPrivate(bool value) {
    if (_disposed || value == _private) return;
    _private = value;
    _notify();
  }

  @override
  Future<void> deleteAll() async {
    _requireGuardian();
    _requireConnection();
    try {
      await _deleteAll().timeout(callTimeout);
    } on CircleException {
      _lostGuardian();
      throw StateError(_guardianOnly);
    } catch (_) {
      throw StateError(
        'The word log could not be deleted. Check the connection and try '
        'again.',
      );
    }
    if (_disposed) return;
    _queue = const [];
    _unknownTries = 0;
    _save();
    _notify();
  }

  static const String _guardianOnly =
      'Only a guardian can change the word log.';

  void _requireGuardian() {
    if (!_canChange) throw StateError(_guardianOnly);
  }

  /// Fails at once when this device is known to have no way to the server.
  void _requireConnection() {
    final sync = _sync;
    if (sync == null) return;
    if (sync.workingOffline) {
      throw StateError(
        'This device is set to work offline. Switch off "Work offline" and '
        'try again.',
      );
    }
    if (sync.state == SyncState.offline) {
      throw StateError(
        'This needs a connection. Try again when the device is online.',
      );
    }
  }

  /// The server says this adult may not change the log.
  void _lostGuardian() {
    if (_disposed) return;
    _canChange = false;
    _save();
    _notify();
  }

  // ---- Status ------------------------------------------------------------

  void _onSync() {
    if (_disposed) return;
    final online = _online;
    final cameOnline = online && !_wasOnline;
    _wasOnline = online;
    if (!online) return;
    if (cameOnline) {
      // A fresh connection: ask again, and send at once.
      _retry?.cancel();
      _retry = null;
      _failures = 0;
      unawaited(_refreshStatus());
      return;
    }
    // A merge may have brought the server the tile it did not know.
    if (_retry != null && _unknownTries > 0) {
      _retry?.cancel();
      _retry = null;
    }
    if (_retry == null) _kick();
  }

  Future<void> _refreshStatus() async {
    if (_disposed || _checking) return;
    _checking = true;
    try {
      final status = await _status().timeout(callTimeout);
      if (_disposed) return;
      _heard = true;
      _apply(status);
    } on CircleException {
      // No longer in the circle: nothing more is noted or sent from here.
      if (_disposed) return;
      _heard = true;
      _mayRecord = false;
      _canChange = false;
      _queue = const [];
      _save();
      _notify();
    } catch (_) {
      // No answer: what this device knew stands.
    } finally {
      _checking = false;
    }
    _kick();
  }

  /// Takes the server's word. A log that is off holds nothing here.
  void _apply(WordLogStatus status) {
    final changed =
        status.enabled != _enabled ||
        status.canChange != _canChange ||
        (!status.enabled && _queue.isNotEmpty);
    _enabled = status.enabled;
    _canChange = status.canChange;
    if (!_enabled) _queue = const [];
    if (!changed) return;
    _save();
    _notify();
  }

  // ---- Sending -----------------------------------------------------------

  void _kick() {
    if (_disposed || _sending) return;
    unawaited(_flush().catchError((Object _) {}));
  }

  bool get _canSend =>
      !_disposed &&
      _loaded &&
      _online &&
      _enabled &&
      _mayRecord &&
      _queue.isNotEmpty;

  Future<void> _flush() async {
    if (_sending) return;
    _sending = true;
    try {
      // Words noted while a batch is out join the queue and go next.
      while (_canSend) {
        _dropStale();
        if (_queue.isEmpty) break;
        final batch = nextWordUseBatch(_queue);
        final outcome = await _send(batch);
        if (_disposed) return;
        switch (outcome) {
          case _Outcome.sent || _Outcome.dropBatch:
            _unknownTries = 0;
            _failures = 0;
            _forget(batch);
          case _Outcome.unknownTile:
            if (++_unknownTries < unknownTileTries) {
              _retryLater();
              return;
            }
            _unknownTries = 0;
            _forget(batch);
          case _Outcome.retry:
            _retryLater();
            return;
          case _Outcome.off:
            _enabled = false;
            _queue = const [];
            _save();
            _notify();
            return;
          case _Outcome.refused:
            _mayRecord = false;
            _queue = const [];
            _save();
            _notify();
            return;
        }
      }
    } finally {
      _sending = false;
    }
  }

  Future<_Outcome> _send(List<WordUse> batch) async {
    try {
      await _record(batch).timeout(callTimeout);
      return _Outcome.sent;
    } on WordLogException catch (refusal) {
      return switch (refusal.failure) {
        WordLogFailure.off => _Outcome.off,
        WordLogFailure.unknownTile => _Outcome.unknownTile,
        WordLogFailure.tooMany || WordLogFailure.badTime => _Outcome.dropBatch,
      };
    } on CircleException {
      return _Outcome.refused;
    } catch (_) {
      return _Outcome.retry;
    }
  }

  /// Removes [batch] from the queue wherever it now is: words may have
  /// been added behind it, and the cap may have trimmed its front.
  void _forget(List<WordUse> batch) {
    final sent = batch.toSet();
    _queue = [
      for (final use in _queue)
        if (!sent.contains(use)) use,
    ];
    _save();
    _notify();
  }

  /// Words too old for the server to take go before they block a batch.
  void _dropStale() {
    final oldest = _now().toUtc().subtract(wordLogSendWithin);
    if (!_queue.any((use) => use.spokenAt.isBefore(oldest))) return;
    _queue = [
      for (final use in _queue)
        if (!use.spokenAt.isBefore(oldest)) use,
    ];
    _save();
    _notify();
  }

  void _retryLater() {
    _retry?.cancel();
    final doubled = retryBase * math.pow(2, math.min(_failures, 12)).toInt();
    final wait = doubled > retryMax ? retryMax : doubled;
    _failures++;
    _retry = Timer(wait, () {
      _retry = null;
      _kick();
    });
  }

  // ---- Keeping it on the device ------------------------------------------

  Future<void> _load() async {
    var kept = const <WordUse>[];
    bool? enabled;
    bool? canChange;
    try {
      final text = await _storage.read(_queueKey);
      if (text != null) kept = decodeWordUses(text);
    } catch (_) {
      // Unreadable: nothing was kept.
    }
    try {
      final text = await _storage.read(_statusKey);
      if (text != null) {
        final json = jsonDecode(text);
        if (json is Map<String, Object?>) {
          if (json['enabled'] case final bool on) enabled = on;
          if (json['canChange'] case final bool may) canChange = may;
        }
      }
    } catch (_) {
      // Unreadable: the log stays off until the server says.
    }
    if (_disposed) return;
    _loaded = true;
    // The server's answer, if it came first, outranks the last one kept.
    if (!_heard) {
      if (enabled != null) _enabled = enabled;
      if (canChange != null) _canChange = canChange;
    }
    if (_enabled && _mayRecord) _queue = enqueueWordUses(kept, _queue);
    if (_saveAfterLoad || _queue.length != kept.length) _save();
    _notify();
    _kick();
  }

  /// Writes the queue and the status, after any write already under way.
  /// Nothing is written before the device's copy has been read, so a quick
  /// answer from the server cannot overwrite words kept from last time.
  void _save() {
    if (!_loaded) {
      _saveAfterLoad = true;
      return;
    }
    if (_saveQueued) return;
    _saveQueued = true;
    _saving = _saving.then((_) async {
      _saveQueued = false;
      final queue = encodeWordUses(_queue);
      final status = jsonEncode({
        'enabled': _enabled,
        'canChange': _canChange,
      });
      try {
        await _storage.write(_queueKey, queue);
        await _storage.write(_statusKey, status);
      } catch (_) {
        // A refused store loses this save; the next change tries again.
      }
    });
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _retry?.cancel();
    _retry = null;
    _sync?.removeListener(_onSync);
    super.dispose();
  }
}

enum _Outcome { sent, dropBatch, unknownTile, retry, off, refused }

bool _isUuid(String id) {
  try {
    UuidValue.withFormatValidation(id.toLowerCase());
    return true;
  } on FormatException {
    return false;
  }
}
