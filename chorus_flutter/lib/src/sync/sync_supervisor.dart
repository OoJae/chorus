/// Keeps sync running, because the sync module does not.
///
/// The module offers a one-shot sync and a continuous stream, with no
/// reconnect and no status. [SyncSupervisor] loops over both, retries with
/// backoff, checks the device clock first, and turns whatever happens into
/// the [SyncState] the status chip shows.
library;

import 'dart:async';

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:serverpod_offline_sync_client/offline_sync.dart';

/// A running continuous sync: [done] completes when the stream ends and
/// fails when it breaks; [cancel] stops it.
class SyncRun {
  const SyncRun({required this.done, required this.cancel});

  final Future<void> done;
  final Future<void> Function() cancel;
}

/// The four calls the supervisor makes. The real one talks to the server;
/// tests script their own.
abstract class SyncLink {
  /// False once the user has signed out; no attempt is made then.
  bool get isSignedIn;

  /// The server's clock and the oldest build it accepts. Needs no sign-in.
  Future<ServerInfo> serverInfo();

  /// Pushes and pulls once. [onMerge] is called for every merged batch.
  Future<void> syncOnce(VoidCallback onMerge);

  /// Opens the continuous stream.
  SyncRun syncContinuously(VoidCallback onMerge);
}

/// [SyncLink] over the generated client and the user's replica session.
class ClientSyncLink implements SyncLink {
  ClientSyncLink(this._client, this._session);

  final Client _client;
  final OfflineSyncDatabaseSession _session;

  @override
  bool get isSignedIn => _client.auth.isAuthenticated;

  @override
  Future<ServerInfo> serverInfo() => _client.status.info();

  @override
  Future<void> syncOnce(VoidCallback onMerge) => _client.offlineSync.syncOnce(
    _session,
    onMergeSuccess: (_, _) => onMerge(),
  );

  @override
  SyncRun syncContinuously(VoidCallback onMerge) {
    final subscription = _client.offlineSync.syncContinuously(
      _session,
      onMergeSuccess: (_, _) => onMerge(),
    );
    return SyncRun(done: subscription.done, cancel: subscription.cancel);
  }
}

/// Why the supervisor is being nudged.
enum SyncKick {
  /// The network changed. A stream that looks alive may be dead, so a live
  /// connection is rebuilt.
  network,

  /// The app came back from the background, where the system may have cut
  /// the connection. Treated like [network].
  resumed,

  /// The app regained focus without having been in the background. Only
  /// shortens a wait; a live connection is left alone.
  foreground,
}

/// Kicks from the device: connectivity changes and app lifecycle.
///
/// Listening needs the widgets binding. Where a platform has no connectivity
/// plugin the stream simply carries lifecycle kicks only.
Stream<SyncKick> deviceKicks() {
  late final StreamController<SyncKick> controller;
  StreamSubscription<List<ConnectivityResult>>? connectivity;
  AppLifecycleListener? lifecycle;

  void listen() {
    // The first report describes the present, not a change, so it is only
    // remembered.
    Set<ConnectivityResult>? known;
    void report(List<ConnectivityResult> results) {
      final now = results.toSet();
      final changed = known != null && !setEquals(known, now);
      known = now;
      if (changed && !controller.isClosed) controller.add(SyncKick.network);
    }

    try {
      final plugin = Connectivity();
      connectivity = plugin.onConnectivityChanged.listen(
        report,
        onError: (Object _) {},
      );
      unawaited(
        plugin.checkConnectivity().then<void>(
          (results) {
            known ??= results.toSet();
          },
          onError: (Object _) {},
        ),
      );
    } catch (_) {
      // No connectivity plugin here; backoff and lifecycle still apply.
    }

    var wasInBackground = false;
    lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        switch (state) {
          case AppLifecycleState.paused || AppLifecycleState.hidden:
            wasInBackground = true;
          case AppLifecycleState.resumed:
            controller.add(
              wasInBackground ? SyncKick.resumed : SyncKick.foreground,
            );
            wasInBackground = false;
          case AppLifecycleState.inactive || AppLifecycleState.detached:
            break;
        }
      },
    );
  }

  Future<void> cancel() async {
    await connectivity?.cancel();
    lifecycle?.dispose();
  }

  // Broadcast, so a supervisor that is stopped and started again can
  // listen a second time; the sources are attached only while it does.
  controller = StreamController<SyncKick>.broadcast(
    onListen: listen,
    onCancel: cancel,
  );
  return controller.stream;
}

/// Runs sync for one signed-in user and reports how it is going.
class SyncSupervisor extends SyncStatus {
  SyncSupervisor(
    this._link, {
    this._kicks,
    DateTime Function()? now,
    this.build = 1,
    this.maxSkew = const Duration(seconds: 45),
    this.infoTimeout = const Duration(seconds: 8),
    this.onceTimeout = const Duration(seconds: 60),
    this.probeEvery = const Duration(seconds: 20),
    this.mergeDebounce = const Duration(milliseconds: 150),
    this.unsentGrace = const Duration(milliseconds: 500),
  }) : _now = now ?? DateTime.now;

  /// The supervisor the app uses: the real server calls and device kicks.
  factory SyncSupervisor.forClient(
    Client client,
    OfflineSyncDatabaseSession session, {
    int build = 1,
  }) => SyncSupervisor(
    ClientSyncLink(client, session),
    kicks: deviceKicks(),
    build: build,
  );

  final SyncLink _link;

  /// Nudges from outside. Listened to between [start] and [stop], so it
  /// must be a broadcast stream if the supervisor is ever started twice.
  final Stream<SyncKick>? _kicks;
  final DateTime Function() _now;

  /// This app's build number, compared with the server's minimum.
  final int build;

  /// Largest difference from the server clock sync is attempted with. The
  /// engine refuses changes stamped more than a minute off, so this stops
  /// short of that.
  final Duration maxSkew;

  /// How long the status call may take before the server counts as
  /// unreachable.
  final Duration infoTimeout;

  /// How long a one-shot sync may take.
  final Duration onceTimeout;

  /// How often a live connection is checked by calling the status endpoint.
  /// A stream over a dead network can stay open without an error; this is
  /// what notices.
  final Duration probeEvery;

  /// Merges arrive in bursts, one callback per space and batch. Listeners
  /// hear about a burst once, this long after it starts.
  final Duration mergeDebounce;

  /// A merge reported sooner than this after a local write may not have
  /// carried that write, so it does not clear [hasUnsent] by itself.
  final Duration unsentGrace;

  final ValueNotifier<int> _revision = ValueNotifier<int>(0);

  SyncState _state = SyncState.connecting;
  DateTime? _lastMergeAt;

  /// Starts true: edits made offline before the last restart may still be
  /// waiting in the replica, and only a finished one-shot sync shows that
  /// they are not.
  bool _hasUnsent = true;

  bool _running = false;
  bool _disposed = false;
  Future<void>? _loopDone;
  StreamSubscription<SyncKick>? _kickSub;

  /// Completed by a kick and replaced when the loop acts on it. A kick that
  /// arrives while an attempt is under way stays set, so the loop goes round
  /// once more as soon as that attempt settles.
  Completer<void> _signal = Completer<void>();

  /// Completed by [stop] to interrupt whatever the loop is waiting for.
  Completer<void> _stopSignal = Completer<void>();

  /// Number of the attempt in progress, or of the last one.
  int _attempt = 0;

  /// Callers of [syncAttempt], each waiting for an attempt numbered at least
  /// its key to finish its one-shot sync.
  final List<({int from, Completer<bool> done})> _waiters = [];

  /// The one-shot sync the engine is still running, with its outcome
  /// dropped. Set even after the loop has given up on it: the engine cannot
  /// be cancelled, and a second sync must not start on the same replica
  /// while the first may still be merging.
  Future<void>? _onceInFlight;

  Timer? _mergeTimer;
  Timer? _settleTimer;
  DateTime? _lastWriteAt;
  int _writes = 0;
  bool _clearUnsentOnFlush = false;

  /// Bumped whenever the replica may hold different rows: after each merge
  /// burst and after each local write. Stores re-read on every change.
  ValueListenable<int> get revision => _revision;

  @override
  SyncState get state => _state;

  @override
  DateTime? get lastMergeAt => _lastMergeAt;

  /// True from a local write until a merge confirms it, and from creation
  /// until the first one-shot sync finishes: it is kept in memory only, so
  /// after a restart the supervisor assumes there may be edits waiting.
  @override
  bool get hasUnsent => _hasUnsent;

  bool _workingOffline = false;

  @override
  bool get workingOffline => _workingOffline;

  /// Pausing stops the loop and cancels the stream, exactly as losing the
  /// connection would; resuming starts it again and the usual one-shot sync
  /// sends whatever was written meanwhile.
  @override
  Future<void> setWorkingOffline(bool value) async {
    if (_workingOffline == value || _disposed) return;
    _workingOffline = value;
    notifyListeners();
    if (value) {
      await stop();
      // The adult may have switched back while the loop was stopping; a
      // late "offline" must not land on a supervisor that is running again.
      if (_workingOffline && !_disposed) _setState(SyncState.offline);
    } else {
      // A loop that is still stopping has to be gone first, or it would see
      // the new run's flag and carry on beside the new loop. It never
      // throws.
      await _loopDone;
      if (!_workingOffline && !_disposed) start();
    }
  }

  /// Starts the loop. Does nothing if it is already running, or while an
  /// adult has this device working offline.
  void start() {
    if (_running || _disposed || _workingOffline) return;
    _running = true;
    _stopSignal = Completer<void>();
    _kickSub = _kicks?.listen(kick, onError: (Object _) {});
    _loopDone = _loop();
  }

  /// Stops the loop and cancels the stream. Completes when both are done.
  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    if (!_stopSignal.isCompleted) _stopSignal.complete();
    unawaited(_kickSub?.cancel());
    _kickSub = null;
    await _loopDone;
    _settle(_attempt, false);
  }

  /// Completes when no abandoned one-shot sync is still running, or after
  /// [limit], whichever is first. Call it after [stop] and before closing
  /// the database the engine merges into. Never throws.
  Future<void> settled({Duration limit = const Duration(seconds: 2)}) async {
    final once = _onceInFlight;
    if (once == null) return;
    await once.timeout(limit, onTimeout: () {});
  }

  /// Tells the supervisor the replica has a change the server has not seen.
  void noteLocalWrite() {
    if (_disposed) return;
    _writes++;
    _lastWriteAt = _now();
    _clearUnsentOnFlush = false;
    _hasUnsent = true;
    _revision.value++;
    notifyListeners();
  }

  /// Retries now instead of waiting out the backoff. Completes when the
  /// attempt's one-shot sync has finished, whether it worked or not, and
  /// never throws.
  @override
  Future<void> syncNow() => syncAttempt();

  /// Completes with whether the next one-shot sync that starts from now on
  /// succeeded. With [nudge] it starts at once; without, at the loop's own
  /// pace. Completes with false if the supervisor is stopped first.
  Future<bool> syncAttempt({bool nudge = true}) {
    if (!_running) return Future<bool>.value(false);
    final waiter = (from: _attempt + 1, done: Completer<bool>());
    _waiters.add(waiter);
    if (nudge) _poke();
    return waiter.done.future;
  }

  /// Nudges the loop: see [SyncKick] for what each kind does.
  void kick(SyncKick kind) {
    if (!_running) return;
    if (kind == SyncKick.foreground && _state == SyncState.live) return;
    _poke();
  }

  void _poke() {
    if (!_signal.isCompleted) _signal.complete();
  }

  /// Completes the waiters that attempt number [attempt] answers.
  void _settle(int attempt, bool ok) {
    _waiters.removeWhere((waiter) {
      if (waiter.from > attempt && _running) return false;
      waiter.done.complete(ok);
      return true;
    });
  }

  void _setState(SyncState next) {
    if (_state == next || _disposed) return;
    _state = next;
    notifyListeners();
  }

  // ---- The loop ----------------------------------------------------------

  /// Attempt, wait, attempt again, until stopped. Nothing escapes it.
  Future<void> _loop() async {
    var failures = 0;
    // A retry after a failure keeps showing that failure; "connecting" is
    // for the first attempt, a dropped stream and anything a kick started.
    var announce = true;
    while (_running) {
      _attempt++;
      final attempt = _attempt;
      _Outcome outcome;
      try {
        outcome = await _runAttempt(attempt, announce: announce);
      } catch (error) {
        // _runAttempt catches everything itself; this is the last line of
        // defence for the promise that the loop never throws.
        outcome = _Outcome(_classify(error));
      }
      _settle(attempt, false);
      if (!_running) break;
      // Only a stream that stayed up starts the backoff afresh. One that
      // opens and drops straight away, round after round, keeps growing it.
      if (outcome.wasLive && outcome.stable) failures = 0;

      final state = outcome.state;
      if (state == null) {
        announce = true;
        continue;
      }
      _setState(state);
      announce = await _pause(backoffDelay(failures));
      failures++;
    }
  }

  /// One round: check the clock, sync once, then hold the stream open until
  /// it ends, breaks or is kicked. A null state means "go again now".
  Future<_Outcome> _runAttempt(int attempt, {required bool announce}) async {
    var wasLive = false;
    DateTime? liveSince;
    var probed = false;
    // Whether the stream lasted: one clean probe, or a probe's length.
    bool stable() {
      final since = liveSince;
      return probed ||
          (since != null && _now().difference(since) >= probeEvery);
    }

    SyncRun? run;
    try {
      if (!_link.isSignedIn) return const _Outcome(SyncState.signedOut);
      // An earlier one-shot sync was given up on but has not returned. Wait
      // for it rather than run two syncs into one replica.
      if (_onceInFlight != null) return const _Outcome(SyncState.offline);
      if (announce) _setState(SyncState.connecting);

      final blocked = await _preflight();
      if (blocked != null) return _Outcome(blocked);

      final onceStarted = _now();
      final once = Future<void>.sync(() => _link.syncOnce(_onMerge));
      late final Future<void> tracked;
      tracked = once.then<void>((_) {}, onError: (Object _) {}).whenComplete(
        () {
          if (identical(_onceInFlight, tracked)) _onceInFlight = null;
        },
      );
      _onceInFlight = tracked;
      await _guard(once, onceTimeout);
      // Everything written before the one-shot sync began went out with it;
      // with no write since the app started, that is everything there was.
      final lastWrite = _lastWriteAt;
      if (_hasUnsent &&
          (lastWrite == null || lastWrite.isBefore(onceStarted))) {
        _hasUnsent = false;
        if (!_disposed) notifyListeners();
      }
      _settle(attempt, true);

      run = _link.syncContinuously(_onMerge);
      // The error becomes a value, so a stream that breaks after it has
      // been cancelled cannot surface as an unhandled error.
      final ended = run.done.then<Object>(
        (_) => _Ended.closed,
        onError: (Object error, StackTrace _) => _Broken(error),
      );
      wasLive = true;
      liveSince = _now();
      _setState(SyncState.live);

      while (true) {
        final event = await _firstOf(ended, probeEvery);
        switch (event) {
          case _Ended.stopped:
            return _Outcome(null, wasLive: true, stable: stable());
          case _Ended.kicked:
            _signal = Completer<void>();
            return _Outcome(null, wasLive: true, stable: stable());
          case _Ended.closed:
            // The server closed the stream without an error. Come back
            // after a wait rather than spin.
            return _Outcome(
              SyncState.backoff,
              wasLive: true,
              stable: stable(),
            );
          case _Ended.probe:
            final nowBlocked = await _preflight();
            if (nowBlocked != null) {
              return _Outcome(nowBlocked, wasLive: true, stable: stable());
            }
            probed = true;
          case _Broken(:final error):
            return _Outcome(
              _classify(error),
              wasLive: true,
              stable: stable(),
            );
        }
      }
    } on _Stopped {
      return _Outcome(null, wasLive: wasLive, stable: stable());
    } catch (error) {
      return _Outcome(_classify(error), wasLive: wasLive, stable: stable());
    } finally {
      if (run != null) {
        try {
          await run.cancel();
        } catch (_) {
          // The stream is going away either way.
        }
      }
    }
  }

  /// Asks the server what time it is and which builds it accepts. Returns
  /// the state that blocks sync, or null when sync may go ahead. Throws
  /// when the server cannot be reached.
  Future<SyncState?> _preflight() async {
    final asked = _now();
    final info = await _guard(_link.serverInfo(), infoTimeout);
    final answered = _now();
    if (info.minBuild > build) return SyncState.needsUpdate;
    // The server stamped its answer somewhere between asking and hearing
    // back; the midpoint keeps a slow connection from looking like skew.
    final local = asked.add(answered.difference(asked) ~/ 2);
    final skew = local.toUtc().difference(info.serverTime.toUtc()).abs();
    return skew > maxSkew ? SyncState.clockSkew : null;
  }

  /// What a failure means for the chip.
  SyncState _classify(Object error) => switch (error) {
    ServerpodClientUnauthorized() => SyncState.signedOut,
    ServerpodClientForbidden() => SyncState.accessLost,
    OfflineSyncIntegrityViolationException() => SyncState.accessLost,
    ClockDriftException() => SyncState.clockSkew,
    OfflineSyncTablesHashMismatchException() => SyncState.needsUpdate,
    ServerpodClientNetworkException() => SyncState.offline,
    MethodStreamException() => SyncState.offline,
    TimeoutException() => SyncState.offline,
    OfflineSyncStreamClosedException() => SyncState.offline,
    _ => SyncState.backoff,
  };

  /// [future], unless it takes longer than [limit] (a [TimeoutException])
  /// or [stop] is called first. The timer is cancelled either way, and a
  /// late result or error of an abandoned [future] is dropped.
  Future<T> _guard<T>(Future<T> future, Duration limit) {
    final done = Completer<T>();
    void fail(Object error, [StackTrace? stack]) {
      if (!done.isCompleted) done.completeError(error, stack);
    }

    final timer = Timer(limit, () => fail(TimeoutException(null, limit)));
    future.then((value) {
      if (!done.isCompleted) done.complete(value);
    }, onError: fail);
    unawaited(_stopSignal.future.then((_) => fail(const _Stopped())));
    return done.future.whenComplete(timer.cancel);
  }

  /// Waits for [delay], a kick or [stop], whichever is first, and returns
  /// whether it was a kick. A kick that is already waiting ends the pause
  /// at once.
  Future<bool> _pause(Duration delay) async {
    final done = Completer<void>();
    void finish([Object? _]) {
      if (!done.isCompleted) done.complete();
    }

    final timer = Timer(delay, finish);
    final signal = _signal;
    unawaited(signal.future.then(finish));
    unawaited(_stopSignal.future.then(finish));
    await done.future;
    timer.cancel();
    if (!signal.isCompleted) return false;
    _signal = Completer<void>();
    return true;
  }

  /// The first of: the stream ending, a kick, a stop, or the probe timer.
  Future<Object> _firstOf(Future<Object> ended, Duration probe) async {
    final done = Completer<Object>();
    void finish(Object event) {
      if (!done.isCompleted) done.complete(event);
    }

    final timer = Timer(probe, () => finish(_Ended.probe));
    unawaited(ended.then(finish));
    unawaited(_signal.future.then((_) => finish(_Ended.kicked)));
    unawaited(_stopSignal.future.then((_) => finish(_Ended.stopped)));
    final event = await done.future;
    timer.cancel();
    return event;
  }

  // ---- Merges ------------------------------------------------------------

  /// Called by the engine after each merged batch, in either direction.
  /// Must stay synchronous: the engine waits for it.
  void _onMerge() {
    if (_disposed) return;
    final now = _now();
    _lastMergeAt = now;
    if (_hasUnsent) {
      // With no write since the app started, only a finished one-shot
      // sync shows that nothing from before the restart is left.
      final lastWrite = _lastWriteAt;
      if (lastWrite == null) {
        // Left to the one-shot sync.
      } else if (now.difference(lastWrite) >= unsentGrace) {
        _clearUnsentOnFlush = true;
      } else {
        _armSettle();
      }
    }
    _mergeTimer ??= Timer(mergeDebounce, _flushMerge);
  }

  void _flushMerge() {
    _mergeTimer = null;
    if (_disposed) return;
    if (_clearUnsentOnFlush) {
      _clearUnsentOnFlush = false;
      _hasUnsent = false;
    }
    _revision.value++;
    notifyListeners();
  }

  /// A merge came right after a write and may or may not have carried it.
  /// If the stream is still up a little later and nothing newer was
  /// written, the stream's next round has sent it.
  void _armSettle() {
    final writes = _writes;
    _settleTimer?.cancel();
    _settleTimer = Timer(unsentGrace * 2, () {
      if (_disposed || writes != _writes || !_hasUnsent) return;
      if (_state != SyncState.live) return;
      _hasUnsent = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _running = false;
    if (!_stopSignal.isCompleted) _stopSignal.complete();
    unawaited(_kickSub?.cancel());
    _kickSub = null;
    _mergeTimer?.cancel();
    _settleTimer?.cancel();
    _settle(_attempt, false);
    _revision.dispose();
    super.dispose();
  }
}

/// How one attempt ended. A null [state] asks for another attempt at once.
class _Outcome {
  const _Outcome(this.state, {this.wasLive = false, this.stable = false});

  final SyncState? state;

  /// The stream came up.
  final bool wasLive;

  /// The stream stayed up long enough to count as working, so the next
  /// failure starts the backoff afresh.
  final bool stable;
}

/// Why a live stream stopped being waited on, other than by breaking.
enum _Ended { closed, kicked, stopped, probe }

/// A live stream broke with [error].
class _Broken {
  const _Broken(this.error);

  final Object error;
}

/// Thrown inside the loop when [SyncSupervisor.stop] interrupts a wait.
class _Stopped implements Exception {
  const _Stopped();
}
