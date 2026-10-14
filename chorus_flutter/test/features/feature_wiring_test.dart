// The features a circle gets, by role, made over a real replica. The client
// never connects: sync is offline here, so nothing is asked of a server.
import 'package:chorus_client/chorus_client.dart' as api;
import 'package:chorus_flutter/screens/services.dart';
import 'package:chorus_flutter/src/features/feature_wiring.dart';
import 'package:chorus_flutter/src/sharing/server_board_sharing.dart';
import 'package:chorus_flutter/src/sync/adapters.dart';
import 'package:chorus_flutter/src/sync/chorus_session.dart';
import 'package:chorus_flutter/src/sync/replica_board_store.dart';
import 'package:chorus_flutter/src/sync/sync_supervisor.dart';
import 'package:chorus_flutter/src/wordlog/server_week_summary.dart';
import 'package:chorus_flutter/src/wordlog/server_word_log.dart';
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/fakes.dart' show FakeSyncStatus;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../sync/replica_harness.dart';

/// A server that is never there.
class _NoServer implements SyncLink {
  @override
  bool get isSignedIn => true;

  @override
  Future<api.ServerInfo> serverInfo() async =>
      throw const api.ServerpodClientNetworkException('down');

  @override
  Future<void> syncOnce(VoidCallback onMerge) async {}

  @override
  SyncRun syncContinuously(VoidCallback onMerge) =>
      SyncRun(done: Future<void>.value(), cancel: () async {});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ReplicaHarness harness;
  late ChorusSession session;
  late api.Client client;
  late FakeSyncStatus status;
  final opened = <CircleFeatures>[];

  api.CircleInfo circleAs(api.CircleRole role) => api.CircleInfo(
    spaceUuid: harness.userId,
    childName: 'Maya',
    myRole: role,
    myDisplayName: 'Ada',
    members: const [],
  );

  CircleFeatures open(api.CircleRole role, {List<ReplicaBoardStore>? stores}) {
    final circle = circleAs(role);
    final features = openCircleFeatures(
      client,
      circle: circle,
      userId: idOf(harness.userId),
      sync: status,
      openStore: () {
        final store = session.boardStore(circle);
        stores?.add(store);
        return store;
      },
    );
    opened.add(features);
    return features;
  }

  setUp(() async {
    harness = await ReplicaHarness.open();
    final sync = SyncSupervisor(_NoServer());
    session = ChorusSession.of(harness.replica, sync);
    await session.ensureCircleReady(circleAs(api.CircleRole.guardian));
    // ensureCircleReady needs no seed here; write the starter board itself.
    final seeder = session.boardStore(circleAs(api.CircleRole.guardian));
    await seeder.addBoard('Home');
    seeder.dispose();
    client = api.Client('http://localhost:1/');
    status = FakeSyncStatus(state: SyncState.offline);
  });

  tearDown(() async {
    for (final features in opened) {
      features.dispose();
    }
    opened.clear();
    client.close();
    await session.close();
    await harness.close();
  });

  test('a guardian gets every feature', () {
    final features = open(api.CircleRole.guardian);
    expect(features.wordLog, isA<ServerWordLog>());
    expect(features.wordLog.canChange, isTrue);
    expect(features.summary, isA<ServerWeekSummary>());
    expect(features.sharing, isA<ServerBoardSharing>());
    expect(features.boards, isNotNull);
  });

  test('a therapist sees the week but may not change the log', () {
    final features = open(api.CircleRole.therapist);
    expect(features.wordLog.canChange, isFalse);
    expect(features.summary, isNotNull);
    expect(features.sharing, isNotNull);
    expect(features.boards, isNotNull);
  });

  test('a teacher does not get the week', () {
    final features = open(api.CircleRole.teacher);
    expect(features.summary, isNull);
    expect(features.sharing, isNotNull);
  });

  test('a partner gets the log to read, and nothing that writes or shares', () {
    final features = open(api.CircleRole.partner);
    expect(features.wordLog, isNotNull);
    expect(features.summary, isNull);
    expect(features.sharing, isNull);
    expect(features.boards, isNull);
  });

  test('board management writes the replica that every store reads, and '
      'opens one store, closed with the features', () async {
    final stores = <ReplicaBoardStore>[];
    final features = open(api.CircleRole.guardian, stores: stores);
    expect(stores, isEmpty, reason: 'nothing opened until it is used');

    final id = await features.boards!.addBoard('Park');
    await features.boards!.renameBoard(id, 'Playground');
    expect(stores, hasLength(1));

    final reader = session.boardStore(circleAs(api.CircleRole.guardian));
    await reader.refresh();
    expect(reader.boards.singleWhere((b) => b.id == id).name, 'Playground');
    reader.dispose();

    features.dispose();
    features.dispose();
    await expectLater(features.boards!.addBoard('Late'), throwsStateError);
  });

  test(
    'a snapshot reads this device through a store it closes again',
    () async {
      final stores = <ReplicaBoardStore>[];
      final circle = circleAs(api.CircleRole.guardian);
      final snapshot = await readSnapshot(() {
        final store = session.boardStore(circle);
        stores.add(store);
        return store;
      });
      expect(snapshot.childName, 'Maya');
      expect(snapshot.boards.map((b) => b.name), contains('Home'));
      expect(stores, hasLength(1));
      // Disposed: a second dispose is a no-op, a listener cannot be added.
      expect(() => stores.single.addListener(() {}), throwsFlutterError);
    },
  );

  test('the services carry the features', () {
    final features = open(api.CircleRole.guardian);
    final services = CircleServices(
      userId: idOf(harness.userId),
      wordLog: features.wordLog,
      summary: features.summary,
      sharing: features.sharing,
      boards: features.boards,
    );
    expect(services.wordLog, same(features.wordLog));
    expect(services.boards, same(features.boards));
    expect(services.sharing, same(features.sharing));
    expect(services.summary, same(features.summary));
  });

  test('sharing builds its snapshot from this device', () async {
    final features = open(api.CircleRole.guardian);
    final board = BoardFacts(
      id: deterministicId(idOf(harness.userId), 'none'),
      name: 'Nothing',
      rows: 6,
      cols: 6,
    );
    // Offline: refused before anything is read.
    await expectLater(
      features.sharing!.shareViewOnly(board),
      throwsA(anything),
    );
  });
}
