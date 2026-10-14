// The status chip: what it says in each state, and when it offers a retry.
import 'package:chorus_ui/brand/tokens.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/theme.dart';
import 'package:chorus_ui/widgets/sync_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  group('its look', () {
    for (final dark in [false, true]) {
      testWidgets('speaks in the status face, in ink on the surface, with '
          'no colour of its own (${dark ? 'dark' : 'light'})', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? chorusDarkTheme() : chorusTheme(),
            home: Scaffold(
              body: Center(
                child: SyncChip(sync: FakeSyncStatus(state: SyncState.offline)),
              ),
            ),
          ),
        );
        final colors = dark ? ChorusColors.dark : ChorusColors.light;
        final words = tester.widget<Text>(
          find.text('Offline, saved on this device'),
        );
        expect(words.style!.fontFamily, ChorusType.status.fontFamily);
        expect(words.style!.fontSize, ChorusType.status.fontSize);
        expect(words.style!.color, colors.ink);
        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.color, colors.ink);
        expect(icon.icon, Icons.phone_android_rounded);
        final face = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(SyncChip),
                matching: find.byType(Container),
              )
              .first,
        );
        final decoration = face.decoration! as BoxDecoration;
        expect(decoration.color, colors.surface);
        expect((decoration.border! as Border).top.color, colors.ink);
      });
    }

    testWidgets('every state has a rounded icon', (tester) async {
      final sync = FakeSyncStatus();
      await _pump(tester, sync);
      for (final state in SyncState.values) {
        sync.state = state;
        await tester.pump();
        final icon = tester.widget<Icon>(find.byType(Icon)).icon!;
        expect(
          [
            Icons.check_circle_rounded,
            Icons.upload_rounded,
            Icons.sync_rounded,
            Icons.phone_android_rounded,
            Icons.schedule_rounded,
            Icons.system_update_rounded,
            Icons.block_rounded,
          ],
          contains(icon),
          reason: '$state',
        );
      }
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

  testWidgets('as an icon it is a 48 dp target, the floor for a touch', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeSyncStatus(state: SyncState.offline),
      compact: true,
    );
    final size = tester.getSize(find.byType(SyncChip));
    expect(size.width, greaterThanOrEqualTo(ChorusSpace.minTarget));
    expect(size.height, greaterThanOrEqualTo(ChorusSpace.minTarget));
  });

  testWidgets('at twice the text size on a narrow phone the words wrap '
      'instead of being cut', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final sync = FakeSyncStatus(state: SyncState.offline);
    await tester.pumpWidget(
      MaterialApp(
        theme: chorusTheme(),
        home: MediaQuery.withClampedTextScaling(
          minScaleFactor: 2,
          maxScaleFactor: 2,
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: Align(
                alignment: Alignment.topLeft,
                child: SyncChip(sync: sync),
              ),
            ),
          ),
        ),
      ),
    );
    final label = syncLabel(sync);
    final words = tester.renderObject<RenderParagraph>(find.text(label));
    expect(words.didExceedMaxLines, isFalse);
    final lines = words
        .getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: label.length),
        )
        .map((box) => box.top)
        .toSet();
    expect(lines.length, greaterThan(1));
    expect(tester.takeException(), isNull);
  });
}
