// More of the signed-in shell; its first tests are in home_screen_test.dart.
import 'dart:async';

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_flutter/screens/signed_in_shell.dart';
import 'package:chorus_flutter/src/sync/replica_board_store.dart';
import 'package:chorus_flutter/src/sync/replica_service.dart';
import 'package:chorus_shared/chorus_shared.dart' show BoardFacts, TileFacts;
import 'package:chorus_ui/contracts.dart' as ui;
import 'package:chorus_ui/editor/editor_screen.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/talker/talker_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// Never reached: [_CountingStore] answers every read itself.
class _NoReplica extends Fake implements ReplicaService {}

/// The replica's store with the reading taken out: it shows the starter
/// board and counts how often it is asked to read again.
class _CountingStore extends ReplicaBoardStore {
  _CountingStore()
    : super(
        replica: _NoReplica(),
        revision: ValueNotifier<int>(0),
        circleId: mayaSpace,
        role: ui.CircleRole.guardian,
        childName: 'Maya',
        myName: 'Mum',
      );

  final FakeBoardStore _rows = FakeBoardStore.seeded();

  int refreshes = 0;

  /// When set, every [refresh] fails with it.
  Object? refreshError;

  @override
  List<BoardFacts> get boards => _rows.boards;

  @override
  List<TileFacts> get tiles => _rows.tiles;

  @override
  Future<void> refresh() async {
    refreshes++;
    final error = refreshError;
    if (error != null) throw error;
  }
}

/// A workspace whose one circle is held by [store].
class _StoreWorkspace extends FakeWorkspace {
  _StoreWorkspace(this.store);

  final ui.BoardStore store;

  @override
  ui.BoardStore boardStore(CircleInfo circle) => store;
}

void main() {
  Future<void> pumpShell(WidgetTester tester, FakeWorkspace workspace) =>
      pumpScreen(
        tester,
        SignedInShell(
          gateway: FakeGateway(circles: [circle()]),
          openWorkspace: () async => workspace,
          speech: FakeSpeech(),
        ),
      );

  group('a readying wait that was given up on', () {
    testWidgets('still clears the note when the work finishes, with no '
        'Retry', (tester) async {
      final workspace = FakeWorkspace()..readyGate = Completer<void>();
      await pumpShell(tester, workspace);
      await tester.pump();
      await tester.pump();

      await tester.pump(const Duration(seconds: 46));
      expect(find.textContaining('could not check in'), findsOneWidget);

      // The connection comes back and the work ends by itself.
      workspace.readyGate!.complete();
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('could not check in'), findsNothing);
      expect(find.text('Retry'), findsNothing);
      expect(workspace.readied, hasLength(1));
      expect(workspace.sync.syncNowCalls, 0, reason: 'nobody tapped Retry');
    });

    testWidgets('keeps the note when the work fails in the end', (
      tester,
    ) async {
      final workspace = FakeWorkspace()..readyGate = Completer<void>();
      await pumpShell(tester, workspace);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 46));

      workspace.readyGate!.completeError(StateError('closed'));
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('could not check in'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('the store the shell keeps for a circle', () {
    testWidgets('is asked to read the replica again each time the editor or '
        'the talker opens', (tester) async {
      final store = _CountingStore();
      await pumpShell(tester, _StoreWorkspace(store));
      await tester.pumpAndSettle();
      // Whatever it read while being made and shown on home.
      final atHome = store.refreshes;

      await tester.tap(find.text('Edit board'));
      await tester.pumpAndSettle();
      expect(find.byType(EditorScreen), findsOneWidget);
      expect(store.refreshes, atHome + 1);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(EditorScreen), findsNothing);
      expect(store.refreshes, atHome + 1, reason: 'nothing on the way back');

      // The same store again: it must not open on what it held last time.
      await tester.tap(find.text('Edit board'));
      await tester.pumpAndSettle();
      expect(store.refreshes, atHome + 2);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Talker'));
      await tester.pumpAndSettle();
      expect(find.byType(TalkerScreen), findsOneWidget);
      expect(store.refreshes, atHome + 3);
    });

    testWidgets('opens the editor even when that read fails', (tester) async {
      final store = _CountingStore();
      await pumpShell(tester, _StoreWorkspace(store));
      await tester.pumpAndSettle();
      final atHome = store.refreshes;

      store.refreshError = StateError('The replica is closed.');
      await tester.tap(find.text('Edit board'));
      await tester.pumpAndSettle();
      expect(store.refreshes, atHome + 1);
      expect(find.byType(EditorScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('a workspace that finishes opening after a sign-out is '
      'closed', (tester) async {
    final opening = Completer<FakeWorkspace>();
    await pumpScreen(
      tester,
      SignedInShell(
        gateway: FakeGateway(circles: [circle()]),
        openWorkspace: () => opening.future,
        speech: FakeSpeech(),
      ),
    );
    expect(find.text('Opening Chorus…'), findsOneWidget);

    // Signed out from elsewhere: the sign-in screen takes the shell's place.
    await pumpScreen(tester, const Text('signed out'));
    final workspace = FakeWorkspace();
    opening.complete(workspace);
    await tester.pump();

    expect(workspace.closed, isTrue);
    expect(tester.takeException(), isNull);
  });
}
