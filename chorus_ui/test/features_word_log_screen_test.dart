import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/contracts_wordlog.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_features.dart';
import 'package:chorus_ui/features/feature_page.dart';
import 'package:chorus_ui/features/this_week_screen.dart';
import 'package:chorus_ui/features/word_log_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features_harness.dart';

/// A log whose server never answers a change.
class _UnreachableLog extends FakeWordLog {
  _UnreachableLog() : super(enabled: true);

  int asked = 0;

  @override
  Future<void> setEnabled(bool value) async {
    asked++;
    throw StateError(
      'The word log could not be changed. Check the connection and try '
      'again.',
    );
  }
}

void main() {
  late FakeBoardStore store;

  setUp(() => store = FakeBoardStore.seeded());

  Future<void> pump(
    WidgetTester tester,
    WordLog log, {
    WeekSummarySource? summary,
    BoardStore? withStore,
    SyncStatus? sync,
  }) async {
    setScreen(tester, const Size(360, 820));
    await tester.pumpWidget(
      featureApp(
        WordLogScreen(
          log: log,
          childName: 'Maya',
          summary: summary,
          store: withStore,
          sync: sync,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('says exactly what is kept: the word and when, never '
      'sentences, on the server for this circle, removable', (tester) async {
    await pump(tester, FakeWordLog());
    expect(find.text('Word log'), findsOneWidget);
    expect(find.text('Which word was tapped, and when.'), findsOneWidget);
    expect(
      find.text('Never sentences, and never who was there.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('kept on the server, for this circle only'),
      findsOneWidget,
    );
    expect(
      find.text('A guardian can delete the whole log at any time.'),
      findsOneWidget,
    );
    expect(find.textContaining('Private on Maya'), findsOneWidget);
  });

  testWidgets('a guardian turns the log on with the switch, and off again', (
    tester,
  ) async {
    final log = FakeWordLog();
    await pump(tester, log);
    expect(find.text(keepWordLogLabel), findsOneWidget);
    expect(log.enabled, isFalse);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(log.enabled, isTrue);
    expect(
      find.textContaining('on every device in the circle'),
      findsOneWidget,
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(log.enabled, isFalse);
    expect(find.textContaining('Words noted before stay'), findsOneWidget);
  });

  testWidgets('a change the server refuses is said plainly, and the switch '
      'stays where it was', (tester) async {
    final log = _UnreachableLog();
    await pump(tester, log);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(log.asked, 1);
    expect(log.enabled, isTrue);
    expect(
      find.text(
        'The word log could not be changed. Check the connection and try '
        'again.',
      ),
      findsOneWidget,
    );
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });

  testWidgets('others see whether it is on, with no switch and no delete', (
    tester,
  ) async {
    final log = FakeWordLog(role: CircleRole.therapist, enabled: true);
    await pump(tester, log);
    expect(find.byType(Switch), findsNothing);
    expect(find.text(deleteWordLogLabel), findsNothing);
    expect(find.text('The word log is on.'), findsOneWidget);
    expect(find.text('Only a guardian can turn it on or off.'), findsOneWidget);

    log.role = CircleRole.teacher;
    await log.setEnabledAsGuardian(false);
    await tester.pumpAndSettle();
    expect(find.text('The word log is off.'), findsOneWidget);
  });

  testWidgets('deleting asks first, then removes the whole log', (
    tester,
  ) async {
    final log = FakeWordLog(enabled: true);
    await pump(tester, log);

    await tester.tap(find.text(deleteWordLogLabel));
    await tester.pumpAndSettle();
    expect(find.text('Delete the word log?'), findsOneWidget);
    expect(find.textContaining('cannot be undone'), findsOneWidget);
    expect(find.textContaining('stays on and starts again'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(log.deletions, 0);

    await tester.tap(find.text(deleteWordLogLabel));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(deleteWordLogLabel),
      ),
    );
    await tester.pumpAndSettle();
    expect(log.deletions, 1);
    expect(find.text('The word log was deleted.'), findsOneWidget);
  });

  testWidgets('a delete with no connection says nothing was removed', (
    tester,
  ) async {
    final log = FakeWordLog(enabled: true, online: false);
    log.noteSpoken(store.tiles.first);
    await pump(tester, log, sync: FakeSyncStatus(state: SyncState.offline));
    expect(find.textContaining('This device is offline.'), findsOneWidget);
    expect(
      find.text('1 word waiting on this device to be sent'),
      findsOneWidget,
    );

    await tester.tap(find.text(deleteWordLogLabel));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(deleteWordLogLabel),
      ),
    );
    await tester.pumpAndSettle();
    expect(log.deletions, 0);
    expect(log.pending, 1);
    expect(find.textContaining('Nothing was removed.'), findsOneWidget);
  });

  testWidgets('"See this week" opens the week for a guardian', (tester) async {
    final log = FakeWordLog(enabled: true);
    final summary = FakeWeekSummarySource(store: store, log: log);
    await pump(tester, log, summary: summary, withStore: store);
    await tester.tap(find.text('See this week'));
    await tester.pumpAndSettle();
    expect(find.byType(ThisWeekScreen), findsOneWidget);
    expect(summary.asked, 1);
  });

  testWidgets('"See this week" is not offered to a teacher', (tester) async {
    final log = FakeWordLog(role: CircleRole.teacher, enabled: true);
    store.role = CircleRole.teacher;
    await pump(
      tester,
      log,
      summary: FakeWeekSummarySource(store: store, log: log),
      withStore: store,
    );
    expect(find.text('See this week'), findsNothing);
  });

  testWidgets('the actions sit in the bottom third on a phone', (tester) async {
    await pump(tester, FakeWordLog());
    final panel = tester.getRect(find.byKey(FeaturePage.pinnedActionsKey));
    expect(panel.top, greaterThanOrEqualTo(820 * 2 / 3));
    expect(panel.bottom, 820);
    expect(
      find.descendant(
        of: find.byKey(FeaturePage.pinnedActionsKey),
        matching: find.byType(Switch),
      ),
      findsOneWidget,
    );
  });
}

extension on FakeWordLog {
  /// Changes the log as a guardian elsewhere would.
  Future<void> setEnabledAsGuardian(bool value) async {
    final was = role;
    role = CircleRole.guardian;
    await setEnabled(value);
    role = was;
  }
}
