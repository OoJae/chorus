// Trust signals and "Under the hood": the chip's words, "Who is up to
// date", the presence line, and the replica report, against fakes.
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/contracts_trust.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_live.dart';
import 'package:chorus_ui/fakes_trust.dart';
import 'package:chorus_ui/features/trust/presence_line.dart';
import 'package:chorus_ui/features/trust/trust_words.dart';
import 'package:chorus_ui/features/trust/under_the_hood_screen.dart';
import 'package:chorus_ui/features/trust/who_is_up_to_date_screen.dart';
import 'package:chorus_ui/widgets/sync_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features_harness.dart';

/// A fake sync that also knows how many changes wait to be sent.
class _CountingSync extends FakeSyncStatus {
  _CountingSync({super.state, super.hasUnsent, this.count});

  int? count;

  @override
  int? get unsentChanges => count;
}

void main() {
  group('The status chip', () {
    test('says everyone is up to date when live with nothing waiting', () {
      expect(syncLabel(FakeSyncStatus()), everyoneUpToDateLabel);
      expect(everyoneUpToDateLabel, "Everyone's up to date");
    });

    test('counts the changes waiting to send, singular for one', () {
      expect(changesWaitingLabel(1), '1 change waiting to send');
      expect(changesWaitingLabel(2), '2 changes waiting to send');
      expect(
        syncLabel(_CountingSync(hasUnsent: true, count: 2)),
        '2 changes waiting to send',
      );
      expect(
        syncLabel(
          _CountingSync(state: SyncState.offline, hasUnsent: true, count: 1),
        ),
        'Offline, 1 change waiting to send',
      );
    });

    test('keeps its plain words where the count is not known, and every '
        'other state as it was', () {
      expect(syncLabel(FakeSyncStatus(hasUnsent: true)), 'Sending changes');
      expect(
        syncLabel(FakeSyncStatus(state: SyncState.connecting)),
        'Connecting',
      );
      expect(
        syncLabel(FakeSyncStatus(state: SyncState.offline)),
        'Offline, saved on this device',
      );
      expect(
        syncLabel(FakeSyncStatus(state: SyncState.backoff)),
        'Reconnecting',
      );
    });

    test('while working offline, says how many changes wait', () async {
      final sync = _CountingSync(count: 3);
      await sync.setWorkingOffline(true);
      expect(syncLabel(sync), 'Working offline, saved on this device');
      sync.hasUnsent = true;
      expect(syncLabel(sync), 'Working offline, 3 changes waiting to send');
    });

    testWidgets('shows the words on its face', (tester) async {
      await tester.pumpWidget(
        featureApp(
          Scaffold(
            body: Center(
              child: SyncChip(sync: _CountingSync(hasUnsent: true, count: 2)),
            ),
          ),
        ),
      );
      expect(find.text('2 changes waiting to send'), findsOneWidget);
    });
  });

  group('Who is up to date', () {
    test('says how long ago in plain words', () {
      final now = DateTime(2026, 10, 14, 12);
      expect(agoLabel(now, now: now), 'just now');
      expect(
        agoLabel(now.subtract(const Duration(minutes: 5)), now: now),
        '5 minutes ago',
      );
      expect(
        agoLabel(now.subtract(const Duration(hours: 1)), now: now),
        '1 hour ago',
      );
      expect(
        agoLabel(now.subtract(const Duration(days: 3)), now: now),
        '3 days ago',
      );
    });

    test('names each device, and this one by what it knows now', () {
      final now = DateTime(2026, 10, 14, 12);
      final gran = DeviceSeenInfo(
        userId: 'g',
        userName: 'Grandma',
        deviceId: 'tab',
        deviceLabel: 'Android tablet',
        lastSyncAt: now.subtract(const Duration(days: 3)),
      );
      expect(
        deviceLine(gran, isThisDevice: false, sync: FakeSyncStatus(), now: now),
        "Grandma's android tablet: last synced 3 days ago",
      );
      expect(
        deviceLine(gran, isThisDevice: true, sync: FakeSyncStatus(), now: now),
        'This device: up to date',
      );
      expect(
        deviceLine(
          gran,
          isThisDevice: true,
          sync: _CountingSync(
            state: SyncState.offline,
            hasUnsent: true,
            count: 2,
          ),
          now: now,
        ),
        'This device: 2 changes waiting to send',
      );
    });

    for (final size in featureSizes) {
      testWidgets('lists every device at ${size.width.toInt()}x'
          '${size.height.toInt()}', (tester) async {
        setScreen(tester, size);
        await tester.pumpWidget(
          featureApp(
            WhoIsUpToDateScreen(
              directory: FakeDeviceDirectory(),
              sync: FakeSyncStatus(),
            ),
            reduced: true,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(whoIsUpToDateTitle), findsOneWidget);
        expect(find.text('This device: up to date'), findsOneWidget);
        expect(
          find.text("Ms Rivera's web browser: last synced 2 hours ago"),
          findsOneWidget,
        );
        expect(
          find.text("Grandma's android tablet: last synced 3 days ago"),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('says plainly when the list cannot be read, and tries again', (
      tester,
    ) async {
      final directory = FakeDeviceDirectory(failWith: StateError('offline'));
      await tester.pumpWidget(
        featureApp(
          WhoIsUpToDateScreen(directory: directory, sync: FakeSyncStatus()),
          reduced: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(whoIsUpToDateFailed), findsOneWidget);
      directory.failWith = null;
      await tester.tap(find.text(whoIsUpToDateRefresh).last);
      await tester.pumpAndSettle();
      expect(directory.asked, 2);
      expect(find.text('This device: up to date'), findsOneWidget);
    });

    testWidgets('says when no device has checked in yet', (tester) async {
      await tester.pumpWidget(
        featureApp(
          WhoIsUpToDateScreen(
            directory: FakeDeviceDirectory(thisDeviceId: '', list: const []),
            sync: FakeSyncStatus(),
          ),
          reduced: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(whoIsUpToDateEmpty), findsOneWidget);
    });

    testWidgets('lists this device before its first report arrives', (
      tester,
    ) async {
      await tester.pumpWidget(
        featureApp(
          WhoIsUpToDateScreen(
            directory: FakeDeviceDirectory(list: const []),
            sync: FakeSyncStatus(),
          ),
          reduced: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('This device: up to date'), findsOneWidget);
      expect(find.text(whoIsUpToDateEmpty), findsNothing);
    });
  });

  group('The presence line', () {
    test('names who else is looking', () {
      expect(presenceText(const []), isNull);
      expect(presenceText(const ['  ']), isNull);
      expect(
        presenceText(const ['Ms Rivera']),
        'Ms Rivera is looking at the board',
      );
      expect(
        presenceText(const ['Ms Rivera', 'Dad']),
        'Ms Rivera and Dad are looking at the board',
      );
      expect(
        presenceText(const ['Ms Rivera', 'Dad', 'Grandma']),
        'Ms Rivera, Dad and Grandma are looking at the board',
      );
    });

    testWidgets('shows one quiet line while connected, and nothing when '
        'nobody else is here', (tester) async {
      final live = FakeLiveSession(present: const ['Ms Rivera']);
      await tester.pumpWidget(
        featureApp(Scaffold(body: PresenceLine(live: live))),
      );
      expect(find.text('Ms Rivera is looking at the board'), findsOneWidget);

      final alone = FakeLiveSession();
      await tester.pumpWidget(
        featureApp(Scaffold(body: PresenceLine(live: alone))),
      );
      expect(find.textContaining('looking at the board'), findsNothing);
    });
  });

  group('Under the hood', () {
    for (final size in featureSizes) {
      testWidgets('shows the replica at ${size.width.toInt()}x'
          '${size.height.toInt()}', (tester) async {
        setScreen(tester, size);
        await tester.pumpWidget(
          featureApp(
            UnderTheHoodScreen(inspector: FakeReplicaInspector()),
            reduced: true,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(underTheHoodTitle), findsOneWidget);
        expect(find.text('tile'), findsOneWidget);
        expect(find.text('38'), findsOneWidget);
        expect(
          find.text('6f1d2c3a-0b4e-4c5d-8e9f-a1b2c3d4e5f6'),
          findsOneWidget,
        );
        expect(find.text('0.0.10'), findsOneWidget);
        expect(find.text('https://chorus.example/'), findsOneWidget);
        expect(find.text('live'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('board:2:3__conflict__tile-7'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('"juice" by Mum'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('says when no word is parked', (tester) async {
      final inspector = FakeReplicaInspector();
      inspector.report = ReplicaReport(
        boards: 1,
        tiles: 36,
        tileEdits: 0,
        unsentChanges: null,
        hasUnsent: true,
        lastSyncAt: null,
        circleSpaceId: 'space',
        parked: const [],
        moduleVersion: '0.0.10',
        serverAddress: 'http://localhost:8080/',
      );
      setScreen(tester, const Size(1280, 1400));
      await tester.pumpWidget(
        featureApp(UnderTheHoodScreen(inspector: inspector), reduced: true),
      );
      await tester.pumpAndSettle();
      expect(find.text(underTheHoodNoneParked), findsOneWidget);
      expect(find.text('some, from before a restart'), findsOneWidget);
      expect(find.text('not yet'), findsOneWidget);
    });
  });
}
