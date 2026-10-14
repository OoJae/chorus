// The app's side of "Try a clash" and "Who is up to date": the practice
// partner's answers in the screens' terms, and the heartbeat's pace.

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_flutter/src/practice/server_clash_partner.dart';
import 'package:chorus_flutter/src/trust/device_heartbeat.dart';
import 'package:chorus_flutter/src/trust/device_identity.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/contracts_clash.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('The practice partner', () {
    final space = UuidValue.fromString('6f1d2c3a-0b4e-4c5d-8e9f-a1b2c3d4e5f6');
    const board = '0192f0a4-1111-7000-8000-000000000001';

    test('asks for the spot by its placed key and returns the word', () async {
      late String asked;
      final partner = ServerClashPartner((s, b, cell) async {
        asked = cell;
        return PracticeWord(
          tileId: UuidValue.fromString('0192f0a4-2222-7000-8000-000000000002'),
          label: 'bubbles',
          cellKey: cell,
          partnerName: 'Practice partner',
        );
      }, circleSpace: space);
      final word = await partner.putWord(boardId: board, row: 2, col: 3);
      expect(asked, '$board:2:3');
      expect(word.label, 'bubbles');
      expect(word.partnerName, 'Practice partner');
    });

    for (final (thrown, reason) in [
      (
        PracticeException(failure: PracticeFailure.cellTaken),
        PracticeRefusal.cellTaken,
      ),
      (
        PracticeException(failure: PracticeFailure.tooMany),
        PracticeRefusal.tooMany,
      ),
      (
        PracticeException(failure: PracticeFailure.noSuchCell),
        PracticeRefusal.noSuchCell,
      ),
      (
        CircleException(failure: CircleFailure.notAllowed),
        PracticeRefusal.notAllowed,
      ),
      (
        const ServerpodClientNetworkException('no route'),
        PracticeRefusal.unreachable,
      ),
    ]) {
      test('turns ${thrown.runtimeType} into ${reason.name}', () async {
        final partner = ServerClashPartner(
          (_, _, _) async => throw thrown,
          circleSpace: space,
        );
        await expectLater(
          partner.putWord(boardId: board, row: 0, col: 0),
          throwsA(
            isA<PracticeRefused>().having((e) => e.reason, 'reason', reason),
          ),
        );
      });
    }
  });

  group('The heartbeat', () {
    testWidgets('reports while live with nothing waiting, at most once a '
        'minute, and never while working offline', (tester) async {
      final sync = FakeSyncStatus(state: SyncState.connecting);
      final sent = <DateTime>[];
      final beat = DeviceHeartbeat(
        sync: sync,
        send: (at) async => sent.add(at),
        now: () => tester.binding.clock.now(),
      );
      expect(sent, isEmpty);

      sync.state = SyncState.live;
      await tester.pump();
      expect(sent, hasLength(1));

      // Merges and notices within the minute send nothing more.
      sync.lastMergeAt = DateTime.now();
      await tester.pump(const Duration(seconds: 30));
      expect(sent, hasLength(1));

      await tester.pump(const Duration(seconds: 31));
      expect(sent, hasLength(2));

      await sync.setWorkingOffline(true);
      await tester.pump(const Duration(minutes: 2));
      expect(sent, hasLength(2));

      sync.hasUnsent = true;
      await sync.setWorkingOffline(false);
      await tester.pump(const Duration(minutes: 2));
      expect(sent, hasLength(2), reason: 'changes still waiting to send');

      sync.hasUnsent = false;
      await tester.pump();
      expect(sent, hasLength(3));
      beat.dispose();
    });

    testWidgets('tries again after a failed report', (tester) async {
      final sync = FakeSyncStatus();
      var calls = 0;
      final beat = DeviceHeartbeat(
        sync: sync,
        send: (_) async {
          calls++;
          if (calls == 1) throw StateError('offline');
        },
        now: () => tester.binding.clock.now(),
      );
      await tester.pump();
      expect(calls, 1);
      sync.lastMergeAt = DateTime.now();
      await tester.pump();
      expect(calls, 2);
      beat.dispose();
    });
  });

  test('a device describes itself in plain words', () {
    expect(deviceLabel(), isNotEmpty);
  });

  test('a device keeps one id', () async {
    final first = await deviceId();
    expect(first.length, greaterThanOrEqualTo(8));
    expect(await deviceId(), first);
  });
}
