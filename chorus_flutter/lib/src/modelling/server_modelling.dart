/// Modelling over the server: modelled taps into the word log, the focus
/// words of the week, the Thursday nudge and the progress report.
library;

import 'dart:async';

import 'package:chorus_client/chorus_client.dart' hide CircleRole;
import 'package:chorus_shared/chorus_shared.dart' show TileFacts;
import 'package:chorus_ui/contracts.dart' show CircleRole, SyncStatus;
import 'package:chorus_ui/contracts_modelling.dart';
import 'package:chorus_ui/contracts_wordlog.dart';
import 'package:flutter/foundation.dart';

import '../../screens/support/circle_cache_none.dart'
    if (dart.library.io) '../../screens/support/circle_cache_io.dart'
    if (dart.library.js_interop) '../../screens/support/circle_cache_web.dart'
    as store;
import 'open_link.dart';

/// How long the focus words read are trusted before they are read again.
const Duration focusFreshFor = Duration(minutes: 1);

/// [ModellingSource] over the circle's endpoints.
class ServerModelling extends ModellingSource {
  ServerModelling({
    required this._client,
    required this._space,
    required this._userId,
    required CircleRole role,
    this._log,
    this._sync,
    this.timeout = const Duration(seconds: 20),
  }) : canPinFocus =
           role == CircleRole.guardian || role == CircleRole.therapist,
       _mayLog = role != CircleRole.partner;

  final Client _client;
  final UuidValue _space;
  final String _userId;
  final WordLog? _log;
  final SyncStatus? _sync;
  final bool _mayLog;
  final Duration timeout;

  @override
  final bool canPinFocus;

  List<FocusPin> _focus = const [];
  DateTime? _readAt;
  bool _reading = false;
  bool _disposed = false;

  @override
  List<FocusPin> get focusWords {
    final readAt = _readAt;
    if (readAt == null || DateTime.now().difference(readAt) > focusFreshFor) {
      unawaited(refreshFocus());
    }
    return _focus;
  }

  bool get _offline => _sync?.workingOffline ?? false;

  @override
  Future<void> refreshFocus() async {
    if (_reading || _offline || _disposed) return;
    _reading = true;
    _readAt = DateTime.now();
    try {
      final words = await _client.focus.words(_space).timeout(timeout);
      final next = [
        for (final word in words)
          FocusPin(tileId: word.tileId.uuid, tip: word.tip),
      ];
      if (!_disposed && !listEquals(next, _focus)) {
        _focus = next;
        notifyListeners();
      }
    } catch (_) {
      // Keeps the last ones; the next read tries again.
    } finally {
      _reading = false;
    }
  }

  @override
  Future<void> setFocusWords(List<FocusPin> pins) async {
    if (!canPinFocus) throw StateError('Only guardians and therapists.');
    final week = DateTime.now().toUtc();
    final kept = await _client.focus
        .setWords(_space, [
          for (final pin in pins)
            FocusWordInfo(
              tileId: UuidValue.withValidation(pin.tileId),
              tip: pin.tip,
              weekStart: week,
            ),
        ])
        .timeout(timeout);
    _focus = [
      for (final word in kept)
        FocusPin(tileId: word.tileId.uuid, tip: word.tip),
    ];
    _readAt = DateTime.now();
    if (!_disposed) notifyListeners();
  }

  @override
  void noteModelled(TileFacts tile) {
    final log = _log;
    if (!_mayLog || log == null || !log.enabled || log.private) return;
    if (_offline) return;
    final UuidValue tileId;
    final UuidValue boardId;
    try {
      tileId = UuidValue.withValidation(tile.id);
      boardId = UuidValue.withValidation(tile.boardId);
    } catch (_) {
      return;
    }
    unawaited(
      Future<void>.sync(
        () => _client.wordLog.recordModelled(_space, [
          WordUseEntry(
            tileId: tileId,
            boardId: boardId,
            spokenAt: DateTime.now().toUtc(),
          ),
        ]),
      ).then<void>((_) {}, onError: (Object _) {}),
    );
  }

  @override
  Future<FocusNudgeNote?> nudge() async {
    if (_offline) return null;
    try {
      final info = await _client.focus.nudge(_space).timeout(timeout);
      if (info == null) return null;
      final note = FocusNudgeNote(
        tileId: info.tileId.uuid,
        label: info.label,
        tip: info.tip,
        weekStart: info.weekStart.toUtc(),
      );
      final dismissed = await store.readText(_dismissFile);
      return dismissed == _dismissKey(note) ? null : note;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> dismissNudge(FocusNudgeNote note) =>
      store.writeText(_dismissFile, _dismissKey(note));

  String get _dismissFile => 'chorus_nudge_${_userId}_${_space.uuid}.txt';

  String _dismissKey(FocusNudgeNote note) =>
      '${note.weekStart.toIso8601String()}|${note.tileId}';

  @override
  Future<String> makeProgressReport() async {
    if (!canPinFocus) throw StateError('Only guardians and therapists.');
    final token = await _client.progress.makeReport(_space).timeout(timeout);
    // In the released web app the page is on the server the app came from.
    if (kIsWeb && kReleaseMode) {
      return Uri.base.resolve('/report/$token').toString();
    }
    return _client.progress.reportUrl(token).timeout(timeout);
  }

  @override
  Future<bool> openLink(String url) async => openInNewTab(url);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
