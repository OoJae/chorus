import 'dart:async';

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_flutter/src/sync/sync_supervisor.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_offline_sync_client/offline_sync.dart';

/// A scripted server. Every call is counted; what it answers is set by the
/// test. Time comes from the test's fake clock.
class FakeLink implements SyncLink {
  FakeLink(this.now);

  final DateTime Function() now;

  @override
  bool isSignedIn = true;

  /// Thrown by [serverInfo] while set.
  Object? infoError;

  /// How far the server clock is ahead of the device.
  Duration serverAhead = Duration.zero;
  int minBuild = 1;

  /// Thrown by [syncOnce] while set.
  Object? onceError;

  /// When set, [syncOnce] waits for it instead of finishing at once.
  Completer<void>? onceGate;

  /// Thrown synchronously by [syncContinuously] while set.
  Object? streamOpenError;

  int infoCalls = 0;
  int onceCalls = 0;
  int streamCalls = 0;
  int cancels = 0;

  /// The merge callback and end of the stream that is currently open.
  VoidCallback? merge;
  Completer<void>? stream;

  @override
  Future<ServerInfo> serverInfo() async {
    infoCalls++;
    final error = infoError;
    if (error != null) throw error;
    return ServerInfo(serverTime: now().add(serverAhead), minBuild: minBuild);
  }

  @override
  Future<void> syncOnce(VoidCallback onMerge) async {
    onceCalls++;
    merge = onMerge;
    final gate = onceGate;
    if (gate != null) await gate.future;
    final error = onceError;
    if (error != null) throw error;
  }

  @override
  SyncRun syncContinuously(VoidCallback onMerge) {
    final error = streamOpenError;
    if (error != null) throw error;
    streamCalls++;
    merge = onMerge;
    final opened = stream = Completer<void>();
    return SyncRun(
      done: opened.future,
      cancel: () async {
        cancels++;
        if (!opened.isCompleted) opened.complete();
      },
    );
  }
}

const _network = ServerpodClientNetworkException('no route');

void main() {
  late FakeLink link;
  late SyncSupervisor sync;
  late StreamController<SyncKick> kicks;

  /// Builds a supervisor on the tester's fake clock.
  void setUpSupervisor(WidgetTester tester, {int build = 1}) {
    DateTime now() => tester.binding.clock.now();
    link = FakeLink(now);
    kicks = StreamController<SyncKick>.broadcast();
    sync = SyncSupervisor(link, kicks: kicks.stream, now: now, build: build);
  }

  /// A test on fake time. The supervisor is stopped inside the test body,
  /// because the binding checks for leftover timers before tear-downs run.
  void supervised(
    String description,
    Future<void> Function(WidgetTester tester) body, {
    int build = 1,
  }) {
    testWidgets(description, (tester) async {
      setUpSupervisor(tester, build: build);
      try {
        await body(tester);
      } finally {
        await sync.stop();
        sync.dispose();
        unawaited(kicks.close());
      }
    });
  }

  /// Lets queued microtasks and zero-length timers run.
  Future<void> settle(WidgetTester tester) => tester.pump(Duration.zero);

  supervised('goes connecting, then live, and holds one stream', (
    tester,
  ) async {
    final seen = <SyncState>[];
    sync.addListener(() {
      if (seen.isEmpty || seen.last != sync.state) seen.add(sync.state);
    });
    expect(sync.state, SyncState.connecting);

    sync.start();
    await settle(tester);

    expect(sync.state, SyncState.live);
    // The first notice comes while still connecting: the one-shot sync
    // finished, so nothing from before the start is unsent any more.
    expect(seen, [SyncState.connecting, SyncState.live]);
    expect((link.infoCalls, link.onceCalls, link.streamCalls), (1, 1, 1));

    sync.start();
    await settle(tester);
    expect(link.streamCalls, 1, reason: 'start is idempotent');
  });

  supervised('an unreachable server is offline and retried with backoff', (
    tester,
  ) async {
    link.infoError = _network;
    sync.start();
    await settle(tester);
    expect(sync.state, SyncState.offline);
    expect(link.infoCalls, 1);
    expect(link.onceCalls, 0);

    // Retries 1 s later, then 2 s after that, then 4 s after that.
    await tester.pump(const Duration(milliseconds: 900));
    expect(link.infoCalls, 1);
    await tester.pump(const Duration(milliseconds: 200));
    expect(link.infoCalls, 2);
    await tester.pump(const Duration(milliseconds: 1800));
    expect(link.infoCalls, 2);
    await tester.pump(const Duration(milliseconds: 200));
    expect(link.infoCalls, 3);
    await tester.pump(const Duration(milliseconds: 3800));
    expect(link.infoCalls, 3);
    expect(sync.state, SyncState.offline, reason: 'quiet retries');

    link.infoError = null;
    await tester.pump(const Duration(milliseconds: 200));
    expect(link.infoCalls, 4);
    expect(sync.state, SyncState.live);
  });

  supervised('the wait never exceeds thirty seconds', (tester) async {
    link.infoError = _network;
    sync.start();
    // Retries at 1, 3, 7, 15 and 31 s; every wait after that is 30 s.
    await tester.pump(const Duration(seconds: 32));
    expect(link.infoCalls, 6);
    await tester.pump(const Duration(seconds: 28));
    expect(link.infoCalls, 6);
    await tester.pump(const Duration(seconds: 2));
    expect(link.infoCalls, 7);
    await tester.pump(const Duration(seconds: 28));
    expect(link.infoCalls, 7);
    await tester.pump(const Duration(seconds: 2));
    expect(link.infoCalls, 8);
  });

  supervised('a kick ends the wait at once', (tester) async {
    link.infoError = _network;
    sync.start();
    await tester.pump(const Duration(seconds: 40));
    final before = link.infoCalls;

    link.infoError = null;
    kicks.add(SyncKick.network);
    await settle(tester);
    expect(link.infoCalls, before + 1);
    expect(sync.state, SyncState.live);
  });

  supervised('a device clock 46 s off stops before any sync', (tester) async {
    link.serverAhead = const Duration(seconds: 46);
    sync.start();
    await settle(tester);
    expect(sync.state, SyncState.clockSkew);
    expect(link.onceCalls, 0);
    expect(link.streamCalls, 0);

    // Behind is as bad as ahead; 44 s either way is tolerated.
    link.serverAhead = const Duration(seconds: -46);
    await tester.pump(const Duration(seconds: 1));
    expect(sync.state, SyncState.clockSkew);
    link.serverAhead = const Duration(seconds: -44);
    await tester.pump(const Duration(seconds: 2));
    expect(sync.state, SyncState.live);
  });

  supervised('a server that wants a newer build is needsUpdate', build: 3, (
    tester,
  ) async {
    link.minBuild = 4;
    sync.start();
    await settle(tester);
    expect(sync.state, SyncState.needsUpdate);
    expect(link.onceCalls, 0);

    link.minBuild = 3;
    await tester.pump(const Duration(seconds: 1));
    expect(sync.state, SyncState.live);
  });

  supervised('not signed in is signedOut without calling the server', (
    tester,
  ) async {
    link.isSignedIn = false;
    sync.start();
    await settle(tester);
    expect(sync.state, SyncState.signedOut);
    expect(link.infoCalls, 0);
  });

  supervised('failures map to the state the chip shows', (tester) async {
    final cases = <Object, SyncState>{
      ServerpodClientUnauthorized(): SyncState.signedOut,
      ServerpodClientForbidden(): SyncState.accessLost,
      ServerpodClientInternalServerError(): SyncState.backoff,
      const WebSocketClosedException(): SyncState.offline,
      TimeoutException('slow'): SyncState.offline,
      const OfflineSyncStreamClosedException(phase: 'connect'):
          SyncState.offline,
      const OfflineSyncTablesHashMismatchException(
        received: 'a',
        expected: 'b',
      ): SyncState.needsUpdate,
      ClockDriftException(
        DateTime(2026, 1, 1, 0, 2),
        DateTime(2026),
        const Duration(minutes: 1),
      ): SyncState.clockSkew,
      StateError('anything else'): SyncState.backoff,
    };
    sync.start();
    await settle(tester);
    for (final MapEntry(key: error, value: expected) in cases.entries) {
      link.onceError = error;
      kicks.add(SyncKick.network);
      await settle(tester);
      expect(sync.state, expected, reason: '$error');
      link.onceError = null;
      kicks.add(SyncKick.network);
      await settle(tester);
      expect(sync.state, SyncState.live, reason: 'recovers after $error');
    }
  });

  supervised('a broken stream is offline, then reconnects by itself', (
    tester,
  ) async {
    sync.start();
    await settle(tester);
    expect(sync.state, SyncState.live);

    link.stream!.completeError(const WebSocketClosedException());
    await settle(tester);
    expect(sync.state, SyncState.offline);
    expect(link.cancels, 1);

    await tester.pump(const Duration(seconds: 1));
    expect(sync.state, SyncState.live);
    expect(link.streamCalls, 2);
  });

  supervised('a stream the server closes is reopened after a short wait', (
    tester,
  ) async {
    sync.start();
    await settle(tester);
    link.stream!.complete();
    await settle(tester);
    expect(sync.state, SyncState.backoff);
    await tester.pump(const Duration(seconds: 1));
    expect(sync.state, SyncState.live);
    expect(link.streamCalls, 2);
  });

  supervised('a stream that keeps dropping at once backs off further', (
    tester,
  ) async {
    sync.start();
    await settle(tester);
    expect(link.streamCalls, 1);

    // Up and down straight away, three times: waits of 1, 2 and 4 s.
    link.stream!.complete();
    await tester.pump(const Duration(seconds: 1));
    expect(link.streamCalls, 2);
    link.stream!.completeError(const WebSocketClosedException());
    await tester.pump(const Duration(seconds: 1));
    expect(link.streamCalls, 2, reason: 'the second wait is longer');
    await tester.pump(const Duration(seconds: 1));
    expect(link.streamCalls, 3);
    link.stream!.complete();
    await tester.pump(const Duration(seconds: 3));
    expect(link.streamCalls, 3);
    await tester.pump(const Duration(seconds: 1));
    expect(link.streamCalls, 4);

    // A stream that passed a probe counts as working: back to 1 s.
    await tester.pump(const Duration(seconds: 21));
    expect(sync.state, SyncState.live);
    link.stream!.complete();
    await tester.pump(const Duration(seconds: 1));
    expect(link.streamCalls, 5);
  });

  supervised('a live stream over a dead network is found by the probe', (
    tester,
  ) async {
    sync.start();
    await settle(tester);
    expect(link.infoCalls, 1);

    await tester.pump(const Duration(seconds: 20));
    expect(link.infoCalls, 2);
    expect(sync.state, SyncState.live);

    link.infoError = _network;
    await tester.pump(const Duration(seconds: 20));
    expect(sync.state, SyncState.offline);
    expect(link.cancels, 1, reason: 'the dead stream is cancelled');
  });

  supervised('a network kick rebuilds a live stream; a focus kick does not', (
    tester,
  ) async {
    sync.start();
    await settle(tester);

    kicks.add(SyncKick.foreground);
    await settle(tester);
    expect(link.streamCalls, 1);
    expect(link.cancels, 0);

    kicks.add(SyncKick.resumed);
    await settle(tester);
    expect(link.cancels, 1);
    expect(link.streamCalls, 2);
    expect(link.onceCalls, 2);
    expect(sync.state, SyncState.live);
  });

  supervised('merges bump the revision once per burst', (tester) async {
    sync.start();
    await settle(tester);
    final start = sync.revision.value;
    var notified = 0;
    sync.addListener(() => notified++);
    expect(sync.lastMergeAt, isNull);

    link.merge!();
    link.merge!();
    link.merge!();
    expect(sync.revision.value, start, reason: 'debounced');
    expect(sync.lastMergeAt, isNotNull);

    await tester.pump(const Duration(milliseconds: 149));
    expect(sync.revision.value, start);
    await tester.pump(const Duration(milliseconds: 2));
    expect(sync.revision.value, start + 1);
    expect(notified, 1);

    link.merge!();
    await tester.pump(const Duration(milliseconds: 151));
    expect(sync.revision.value, start + 2);
  });

  supervised('after a restart edits count as unsent until a sync finishes', (
    tester,
  ) async {
    expect(sync.hasUnsent, isTrue, reason: 'unknown until a sync says so');
    link.onceGate = Completer<void>();
    sync.start();
    await settle(tester);

    // A merged batch is not the end of the sync.
    link.merge!();
    await tester.pump(const Duration(milliseconds: 151));
    expect(sync.hasUnsent, isTrue);

    link.onceGate!.complete();
    link.onceGate = null;
    await settle(tester);
    expect(sync.state, SyncState.live);
    expect(sync.hasUnsent, isFalse);
  });

  supervised('a local write is unsent until a later merge', (tester) async {
    sync.start();
    await settle(tester);
    final start = sync.revision.value;
    expect(sync.hasUnsent, isFalse);

    sync.noteLocalWrite();
    expect(sync.hasUnsent, isTrue);
    expect(sync.revision.value, start + 1, reason: 'bumped at once');

    await tester.pump(const Duration(seconds: 1));
    link.merge!();
    await tester.pump(const Duration(milliseconds: 151));
    expect(sync.hasUnsent, isFalse);
    expect(sync.revision.value, start + 2);
  });

  supervised('a merge right after a write does not clear it on its own', (
    tester,
  ) async {
    sync.start();
    await settle(tester);

    sync.noteLocalWrite();
    await tester.pump(const Duration(milliseconds: 50));
    link.merge!();
    await tester.pump(const Duration(milliseconds: 151));
    expect(sync.hasUnsent, isTrue, reason: 'may have missed the write');

    // Still live a second later with nothing newer written: it has gone.
    await tester.pump(const Duration(seconds: 1));
    expect(sync.hasUnsent, isFalse);
  });

  supervised('a write during the settling wait keeps it unsent', (
    tester,
  ) async {
    sync.start();
    await settle(tester);

    sync.noteLocalWrite();
    link.merge!();
    await tester.pump(const Duration(milliseconds: 400));
    sync.noteLocalWrite();
    await tester.pump(const Duration(seconds: 2));
    expect(sync.hasUnsent, isTrue);
  });

  supervised('a write made offline is sent by the next one-shot sync', (
    tester,
  ) async {
    link.infoError = _network;
    sync.start();
    await settle(tester);
    sync.noteLocalWrite();
    expect(sync.hasUnsent, isTrue);

    await tester.pump(const Duration(seconds: 5));
    expect(sync.hasUnsent, isTrue);
    link.infoError = null;
    kicks.add(SyncKick.network);
    await settle(tester);
    expect(sync.state, SyncState.live);
    expect(sync.hasUnsent, isFalse);
  });

  supervised('syncNow completes after the retry it started, never throwing', (
    tester,
  ) async {
    link.infoError = _network;
    sync.start();
    await tester.pump(const Duration(seconds: 20));
    final before = link.infoCalls;

    var done = false;
    unawaited(sync.syncNow().then((_) => done = true));
    await settle(tester);
    expect(link.infoCalls, before + 1);
    expect(done, isTrue, reason: 'a failed attempt still completes it');

    link.infoError = null;
    expect(await sync.syncAttempt(), isTrue);
    expect(sync.state, SyncState.live);
  });

  supervised('syncAttempt reports failure and success', (tester) async {
    link.onceError = _network;
    sync.start();
    await settle(tester);
    expect(await sync.syncAttempt(), isFalse);
    link.onceError = null;
    expect(await sync.syncAttempt(), isTrue);
  });

  supervised('syncAttempt asked mid-sync waits for a sync that starts later', (
    tester,
  ) async {
    link.onceGate = Completer<void>();
    sync.start();
    await settle(tester);
    expect(link.onceCalls, 1);

    bool? result;
    unawaited(sync.syncAttempt().then((ok) => result = ok));
    link.onceGate!.complete();
    link.onceGate = null;
    await settle(tester);
    expect(link.onceCalls, 2, reason: 'the first sync began before the ask');
    expect(result, isTrue);
    expect(sync.state, SyncState.live);
  });

  supervised('syncNow while live runs a fresh one-shot sync', (tester) async {
    sync.start();
    await settle(tester);
    await sync.syncNow();
    expect(link.onceCalls, 2);
    await settle(tester);
    expect(sync.state, SyncState.live);
  });

  supervised('syncNow before start and after stop completes at once', (
    tester,
  ) async {
    await sync.syncNow();
    expect(await sync.syncAttempt(), isFalse);
    sync.start();
    await settle(tester);
    await sync.stop();
    await sync.syncNow();
    expect(link.onceCalls, 1);
  });

  supervised('stop cancels the stream and releases anyone waiting', (
    tester,
  ) async {
    link.onceGate = Completer<void>();
    sync.start();
    await settle(tester);
    bool? result;
    unawaited(sync.syncAttempt().then((ok) => result = ok));

    await sync.stop();
    await settle(tester);
    expect(result, isFalse);

    // Nothing more happens, even once the stuck sync finally returns.
    link.onceGate!.complete();
    await tester.pump(const Duration(minutes: 2));
    expect(link.streamCalls, 0);
    expect(link.onceCalls, 1);
  });

  supervised('stop while live cancels the stream; start runs it again', (
    tester,
  ) async {
    sync.start();
    await settle(tester);
    await sync.stop();
    expect(link.cancels, 1);
    await tester.pump(const Duration(minutes: 2));
    expect(link.infoCalls, 1);

    sync.start();
    await settle(tester);
    expect(sync.state, SyncState.live);
    expect(link.streamCalls, 2);
  });

  supervised('nothing the link throws escapes the loop', (tester) async {
    link.streamOpenError = StateError('could not open');
    sync.start();
    await settle(tester);
    expect(sync.state, SyncState.backoff);

    link.streamOpenError = null;
    link.onceError = 'not even an exception';
    await tester.pump(const Duration(seconds: 1));
    expect(sync.state, SyncState.backoff);

    link.onceError = null;
    await tester.pump(const Duration(seconds: 2));
    expect(sync.state, SyncState.live);
    expect(tester.takeException(), isNull);
  });

  supervised('a one-shot sync that hangs is given up on after a minute', (
    tester,
  ) async {
    link.onceGate = Completer<void>();
    sync.start();
    await tester.pump(const Duration(seconds: 59));
    expect(sync.state, SyncState.connecting);
    await tester.pump(const Duration(seconds: 2));
    expect(sync.state, SyncState.offline);
  });

  supervised('no second sync starts while an abandoned one still runs', (
    tester,
  ) async {
    final stuck = link.onceGate = Completer<void>();
    sync.start();
    await tester.pump(const Duration(seconds: 61));
    expect(sync.state, SyncState.offline);
    expect(link.onceCalls, 1);

    link.onceGate = null;
    await tester.pump(const Duration(seconds: 40));
    expect(link.onceCalls, 1, reason: 'the first is still in the engine');
    expect(sync.state, SyncState.offline);

    var settled = false;
    unawaited(sync.settled().then((_) => settled = true));
    await settle(tester);
    expect(settled, isFalse);

    stuck.complete();
    await settle(tester);
    expect(settled, isTrue);
    await tester.pump(const Duration(seconds: 30));
    expect(link.onceCalls, 2);
    expect(sync.state, SyncState.live);
  });

  supervised('working offline switched on and straight off again leaves '
      'exactly one stream open', (tester) async {
    sync.start();
    await settle(tester);
    expect(sync.state, SyncState.live);
    expect(link.streamCalls - link.cancels, 1);

    // Neither call is awaited: the second lands while the first is still
    // stopping the loop.
    final on = sync.setWorkingOffline(true);
    final off = sync.setWorkingOffline(false);
    await settle(tester);
    await on;
    await off;
    await tester.pump(const Duration(seconds: 5));

    expect(sync.workingOffline, isFalse);
    expect(sync.state, SyncState.live);
    expect(link.streamCalls - link.cancels, 1, reason: 'one loop, one stream');

    // And the single loop still answers a stop.
    await sync.setWorkingOffline(true);
    expect(sync.state, SyncState.offline);
    expect(link.streamCalls - link.cancels, 0);
    await tester.pump(const Duration(minutes: 1));
    expect(link.streamCalls - link.cancels, 0);
  });

  supervised('on, off and on again without waiting ends up offline', (
    tester,
  ) async {
    sync.start();
    await settle(tester);
    final calls = [
      sync.setWorkingOffline(true),
      sync.setWorkingOffline(false),
      sync.setWorkingOffline(true),
    ];
    await settle(tester);
    await Future.wait(calls);
    await tester.pump(const Duration(minutes: 1));
    expect(sync.workingOffline, isTrue);
    expect(sync.state, SyncState.offline);
    expect(link.streamCalls - link.cancels, 0);
  });

  testWidgets('calls after dispose are ignored', (tester) async {
    DateTime now() => tester.binding.clock.now();
    final local = SyncSupervisor(FakeLink(now), now: now);
    local.start();
    await settle(tester);
    local.dispose();
    local.noteLocalWrite();
    local.kick(SyncKick.network);
    await tester.pump(const Duration(minutes: 1));
    expect(tester.takeException(), isNull);
  });
}
