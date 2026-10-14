import 'package:chorus_client/chorus_client.dart'
    show
        CircleException,
        CircleFailure,
        ServerpodClientNetworkException,
        WordLogException,
        WordLogFailure,
        WordLogStatus;
import 'package:chorus_flutter/src/wordlog/server_word_log.dart';
import 'package:chorus_flutter/src/wordlog/word_log_storage.dart';
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/fakes.dart' show FakeSyncStatus;
import 'package:flutter_test/flutter_test.dart';

/// The circle's word log as the server keeps it.
class _Server {
  bool enabled = false;
  bool canChange = true;

  /// Every batch sent, as sent.
  final List<List<WordUse>> batches = [];

  /// What the next calls to record do, in order; empty means take them.
  final List<Object Function(List<WordUse>)> answers = [];

  /// Thrown by every call while set.
  Object? down;

  int statusCalls = 0;
  int deletes = 0;

  List<WordUse> get kept => [for (final batch in batches) ...batch];

  Future<WordLogStatus> status() async {
    statusCalls++;
    if (down case final error?) throw error;
    return WordLogStatus(enabled: enabled, canChange: canChange);
  }

  Future<WordLogStatus> setEnabled(bool value) async {
    if (down case final error?) throw error;
    if (!canChange) throw CircleException(failure: CircleFailure.notAllowed);
    enabled = value;
    return WordLogStatus(enabled: enabled, canChange: canChange);
  }

  Future<int> record(List<WordUse> uses) async {
    if (down case final error?) throw error;
    if (answers.isNotEmpty) {
      final answer = answers.removeAt(0)(uses);
      if (answer is int) {
        batches.add(uses);
        return answer;
      }
      throw answer;
    }
    if (!enabled) throw WordLogException(failure: WordLogFailure.off);
    batches.add(uses);
    return uses.length;
  }

  Future<int> deleteAll() async {
    if (down case final error?) throw error;
    deletes++;
    final gone = kept.length;
    batches.clear();
    return gone;
  }
}

/// Lets queued microtasks and zero-length timers run.
Future<void> _settle() async {
  for (var i = 0; i < 30; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  // Wednesday 14 October 2026, 09:00 UTC.
  var clock = DateTime.utc(2026, 10, 14, 9);
  DateTime now() => clock;

  late _Server server;
  late MemoryWordLogStorage storage;
  late FakeSyncStatus sync;
  final logs = <ServerWordLog>[];

  const board = '0190e0a0-0000-7000-8000-00000000b0a1';
  TileFacts tile(int n) => TileFacts(
    id: '0190e0a0-0000-7000-8000-${n.toString().padLeft(12, '0')}',
    boardId: board,
    cellKey: placedKey(board, n ~/ 6, n % 6),
    label: 'word $n',
  );

  ServerWordLog open({
    bool mayRecord = true,
    bool canChange = true,
    Duration retryBase = const Duration(milliseconds: 1),
    int unknownTileTries = 3,
  }) {
    final log = ServerWordLog(
      status: server.status,
      setEnabled: server.setEnabled,
      record: server.record,
      deleteAll: server.deleteAll,
      storage: storage,
      sync: sync,
      mayRecord: mayRecord,
      canChange: canChange,
      now: now,
      retryBase: retryBase,
      retryMax: const Duration(milliseconds: 20),
      unknownTileTries: unknownTileTries,
    );
    logs.add(log);
    return log;
  }

  Future<ServerWordLog> openReady({bool mayRecord = true}) async {
    final log = open(mayRecord: mayRecord);
    await log.ready;
    await _settle();
    return log;
  }

  setUp(() {
    clock = DateTime.utc(2026, 10, 14, 9);
    server = _Server();
    storage = MemoryWordLogStorage();
    sync = FakeSyncStatus();
  });

  tearDown(() {
    for (final log in logs) {
      log.dispose();
    }
    logs.clear();
  });

  test('is off until the server says otherwise, and notes nothing', () async {
    final log = await openReady();
    expect(log.enabled, isFalse);
    log.noteSpoken(tile(1));
    expect(log.pending, 0);
    expect(server.batches, isEmpty);
  });

  test('when on, a spoken word goes to the server at once while sync is '
      'live: tile, board and time, nothing else', () async {
    server.enabled = true;
    final log = await openReady();
    expect(log.enabled, isTrue);
    log.noteSpoken(tile(1));
    await _settle();
    expect(server.kept, [
      WordUse(tileId: tile(1).id, boardId: board, spokenAt: clock),
    ]);
    expect(log.pending, 0);
  });

  test('offline, words wait on the device, survive a restart, and go when '
      'sync is live again', () async {
    server.enabled = true;
    final first = await openReady();
    sync.state = SyncState.offline;
    for (var i = 0; i < 3; i++) {
      first.noteSpoken(tile(i));
    }
    expect(first.pending, 3);
    await first.saved;
    first.dispose();

    // The app starts again with no signal: the log is still on here.
    server.down = const ServerpodClientNetworkException('no signal');
    final again = await openReady();
    expect(again.enabled, isTrue, reason: 'remembered on the device');
    expect(again.pending, 3);
    again.noteSpoken(tile(3));
    expect(again.pending, 4);
    expect(server.batches, isEmpty);

    server.down = null;
    sync.state = SyncState.live;
    await _settle();
    expect(server.kept.map((use) => use.tileId), [
      for (var i = 0; i < 4; i++) tile(i).id,
    ]);
    expect(again.pending, 0);
  });

  test('pauses while an adult has the device working offline', () async {
    server.enabled = true;
    final log = await openReady();
    await sync.setWorkingOffline(true);
    log.noteSpoken(tile(1));
    await _settle();
    expect(server.batches, isEmpty);
    expect(log.pending, 1);
    await sync.setWorkingOffline(false);
    await _settle();
    expect(server.batches, hasLength(1));
  });

  test('sends in batches of 200, oldest first', () async {
    server.enabled = true;
    final log = await openReady();
    sync.state = SyncState.offline;
    for (var i = 0; i < 450; i++) {
      clock = clock.add(const Duration(seconds: 1));
      log.noteSpoken(tile(i % 36));
    }
    sync.state = SyncState.live;
    await _settle();
    expect([for (final batch in server.batches) batch.length], [200, 200, 50]);
    expect(
      server.kept.first.spokenAt.isBefore(server.kept.last.spokenAt),
      isTrue,
    );
    expect(log.pending, 0);
  });

  test('a reply of 0 is success: the server dropped words from before the '
      'log restarted, and the batch leaves the queue', () async {
    server.enabled = true;
    final log = await openReady();
    server.answers.add((_) => 0);
    log.noteSpoken(tile(1));
    await _settle();
    expect(log.pending, 0);
    expect(log.retryPending, isFalse);
  });

  test(
    '"off" from the server turns the log off here and drops the queue',
    () async {
      server.enabled = true;
      final log = await openReady();
      server.answers.add((_) => WordLogException(failure: WordLogFailure.off));
      log.noteSpoken(tile(1));
      await _settle();
      expect(log.enabled, isFalse);
      expect(log.pending, 0);
      log.noteSpoken(tile(2));
      expect(log.pending, 0);
    },
  );

  test(
    'a status that says off, read when sync comes back, drops the queue',
    () async {
      server.enabled = true;
      final log = await openReady();
      sync.state = SyncState.offline;
      log.noteSpoken(tile(1));
      server.enabled = false;
      sync.state = SyncState.live;
      await _settle();
      expect(log.enabled, isFalse);
      expect(log.pending, 0);
      expect(server.batches, isEmpty);
    },
  );

  test(
    'a tile the server does not know yet is tried again, then given up',
    () async {
      server.enabled = true;
      final log = await openReady();
      WordLogException unknown(_) =>
          WordLogException(failure: WordLogFailure.unknownTile);
      server.answers.addAll([unknown, unknown]);
      log.noteSpoken(tile(1));
      await _settle();
      expect(log.pending, 1);
      expect(log.retryPending, isTrue);
      // The next try finds the tile synced.
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await _settle();
      expect(log.pending, 0);
      expect(server.kept, hasLength(1));

      server.answers.addAll([unknown, unknown, unknown]);
      log.noteSpoken(tile(2));
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await _settle();
      }
      expect(log.pending, 0, reason: 'given up after three tries');
      expect(server.kept, hasLength(1));
    },
  );

  test('a bad time drops the batch rather than blocking the queue', () async {
    server.enabled = true;
    final log = await openReady();
    server.answers.add(
      (_) => WordLogException(failure: WordLogFailure.badTime),
    );
    log.noteSpoken(tile(1));
    await _settle();
    expect(log.pending, 0);
    log.noteSpoken(tile(2));
    await _settle();
    expect(server.kept.single.tileId, tile(2).id);
  });

  test(
    'words older than the server takes are dropped before sending',
    () async {
      server.enabled = true;
      final log = await openReady();
      sync.state = SyncState.offline;
      log.noteSpoken(tile(1));
      clock = clock.add(wordLogSendWithin + const Duration(hours: 1));
      log.noteSpoken(tile(2));
      sync.state = SyncState.live;
      await _settle();
      expect(server.kept.single.tileId, tile(2).id);
    },
  );

  test('no answer keeps the words and tries again later', () async {
    server.enabled = true;
    final log = await openReady();
    server.down = const ServerpodClientNetworkException('timeout');
    log.noteSpoken(tile(1));
    await _settle();
    expect(log.pending, 1);
    expect(log.retryPending, isTrue);
    server.down = null;
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await _settle();
    expect(log.pending, 0);
  });

  test('a partner is told no by the server: nothing more is noted', () async {
    server.enabled = true;
    final log = await openReady();
    server.answers.add(
      (_) => CircleException(failure: CircleFailure.notAllowed),
    );
    log.noteSpoken(tile(1));
    await _settle();
    expect(log.pending, 0);
    log.noteSpoken(tile(2));
    expect(log.pending, 0);
  });

  test("a partner's device notes nothing at all", () async {
    server.enabled = true;
    final log = await openReady(mayRecord: false);
    expect(log.enabled, isTrue);
    log.noteSpoken(tile(1));
    expect(log.pending, 0);
  });

  test('private mode pauses it for the session only', () async {
    server.enabled = true;
    final log = await openReady();
    log.setPrivate(true);
    expect(log.private, isTrue);
    log.noteSpoken(tile(1));
    expect(log.pending, 0);
    log.setPrivate(false);
    log.noteSpoken(tile(2));
    await _settle();
    expect(server.kept.single.tileId, tile(2).id);

    log.setPrivate(true);
    await log.saved;
    log.dispose();
    final again = await openReady();
    expect(again.private, isFalse, reason: 'forgotten on restart');
  });

  test('never throws into the child\'s tap', () async {
    server.enabled = true;
    final log = await openReady();
    storage.failWith = StateError('storage refused');
    server.down = StateError('broken');
    expect(() => log.noteSpoken(tile(1)), returnsNormally);
    await _settle();
    expect(log.pending, 1);
    log.dispose();
    expect(() => log.noteSpoken(tile(2)), returnsNormally);
  });

  group('the guardian', () {
    test(
      'turns it on and off through the server; off drops the queue',
      () async {
        final log = await openReady();
        await log.setEnabled(true);
        expect(server.enabled, isTrue);
        expect(log.enabled, isTrue);

        sync.state = SyncState.connecting;
        log.noteSpoken(tile(1));
        expect(log.pending, 1);
        sync.state = SyncState.live;
        await log.setEnabled(false);
        expect(server.enabled, isFalse);
        expect(log.pending, 0);
      },
    );

    test('deletes the log on the server and the words waiting here', () async {
      server.enabled = true;
      final log = await openReady();
      log.noteSpoken(tile(1));
      await _settle();
      sync.state = SyncState.connecting;
      log.noteSpoken(tile(2));
      expect(log.pending, 1);

      await log.deleteAll();
      expect(server.deletes, 1);
      expect(server.kept, isEmpty);
      expect(log.pending, 0);
    });

    test('a delete the server did not get removes nothing', () async {
      server.enabled = true;
      final log = await openReady();
      sync.state = SyncState.connecting;
      log.noteSpoken(tile(1));
      server.down = const ServerpodClientNetworkException('timeout');
      await expectLater(log.deleteAll(), throwsStateError);
      expect(log.pending, 1);
      expect(server.deletes, 0);
    });

    test('with the device offline or paused, is told at once', () async {
      final log = await openReady();
      sync.state = SyncState.offline;
      await expectLater(
        log.setEnabled(true),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('needs a connection'),
          ),
        ),
      );
      await sync.setWorkingOffline(true);
      await expectLater(log.deleteAll(), throwsStateError);
      expect(server.enabled, isFalse);
      expect(server.deletes, 0);
    });
  });

  test('anyone else cannot change it, and the server is not asked', () async {
    server.canChange = false;
    final log = await openReady();
    expect(log.canChange, isFalse);
    await expectLater(log.setEnabled(true), throwsStateError);
    await expectLater(log.deleteAll(), throwsStateError);
    expect(server.enabled, isFalse);
    expect(server.deletes, 0);
  });

  test('the server answering first is not overwritten by an older copy on '
      'the device', () async {
    await storage.write('status.json', '{"enabled":true,"canChange":true}');
    server.enabled = false;
    final log = await openReady();
    expect(log.enabled, isFalse);
    expect(server.statusCalls, 1);
  });
}
