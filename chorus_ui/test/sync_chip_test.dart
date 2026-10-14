// The status chip: what it says in each state, and when it offers a retry.
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/theme.dart';
import 'package:chorus_ui/widgets/sync_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  SyncStatus sync, {
  bool compact = false,
}) => tester.pumpWidget(
  MaterialApp(
    theme: chorusTheme(),
    home: Scaffold(
      body: Center(
        child: SyncChip(sync: sync, compact: compact),
      ),
    ),
  ),
);

/// The states in which the device is waiting before it tries again and the
/// adult can do something about the cause first.
const _retryable = {SyncState.offline, SyncState.backoff, SyncState.clockSkew};

void main() {
  test('the chip says "this device", never "this phone"', () async {
    final sync = FakeSyncStatus();
    for (final state in SyncState.values) {
      sync.state = state;
      expect(syncLabel(sync), isNot(contains('phone')), reason: '$state');
    }
    expect(
      syncLabel(FakeSyncStatus(state: SyncState.offline)),
      'Offline, saved on this device',
    );
    expect(
      syncLabel(FakeSyncStatus(state: SyncState.signedOut)),
      'Signed out, saved on this device',
    );
    expect(
      syncLabel(FakeSyncStatus(state: SyncState.clockSkew)),
      "Check this device's clock",
    );
    await sync.setWorkingOffline(true);
    expect(syncLabel(sync), 'Working offline, saved on this device');
  });

  group('"Sync now"', () {
    for (final state in SyncState.values) {
      final offered = _retryable.contains(state);
      testWidgets('${offered ? 'is' : 'is not'} offered while ${state.name}', (
        tester,
      ) async {
        final sync = FakeSyncStatus(state: state);
        expect(offersSyncNow(sync), offered);
        await _pump(tester, sync);
        expect(find.text(syncLabel(sync)), findsOneWidget);
        expect(find.text('Sync now'), offered ? findsOneWidget : findsNothing);
        if (offered) {
          await tester.tap(find.text('Sync now'));
          expect(sync.syncNowCalls, 1);
        }
      });
    }

    testWidgets('does not show while connecting, shows once the attempt has '
        'failed, and goes when the next attempt starts', (tester) async {
      // The start of the app, and "Work offline" switched off.
      final sync = FakeSyncStatus(state: SyncState.connecting);
      await _pump(tester, sync);
      expect(find.text('Connecting'), findsOneWidget);
      expect(find.text('Sync now'), findsNothing);

      sync.state = SyncState.offline;
      await tester.pump();
      expect(find.text('Sync now'), findsOneWidget);

      sync.state = SyncState.connecting;
      await tester.pump();
      expect(find.text('Sync now'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('is not offered while working offline on purpose', (
      tester,
    ) async {
      final sync = FakeSyncStatus();
      await sync.setWorkingOffline(true);
      expect(sync.state, SyncState.offline);
      expect(offersSyncNow(sync), isFalse);
      await _pump(tester, sync);
      expect(find.text('Sync now'), findsNothing);
    });
  });

  group('as an icon', () {
    for (final state in SyncState.values) {
      final offered = _retryable.contains(state);
      testWidgets('a tap ${offered ? 'retries' : 'does nothing'} while '
          '${state.name}, and its words are the tooltip', (tester) async {
        final sync = FakeSyncStatus(state: state);
        await _pump(tester, sync, compact: true);
        final label = syncLabel(sync);
        expect(find.byTooltip(label), findsOneWidget);
        expect(
          find.bySemanticsLabel(offered ? '$label. Tap to sync now' : label),
          findsOneWidget,
        );
        await tester.tap(find.byType(SyncChip));
        expect(sync.syncNowCalls, offered ? 1 : 0);
        // Let the tooltip's timers run out.
        await tester.pump(const Duration(seconds: 3));
      });
    }
  });
}
