import 'package:chorus_client/chorus_client.dart'
    show
        Client,
        UuidValue,
        CircleException,
        CircleFailure,
        ServerpodClientNetworkException,
        WeekReport,
        WordTally;
import 'package:chorus_flutter/src/wordlog/server_week_summary.dart';
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/fakes.dart' show FakeSyncStatus;
import 'package:flutter_test/flutter_test.dart';

void main() {
  final monday = DateTime.utc(2026, 10, 12);
  final report = WeekReport(
    weekStart: monday,
    topWords: [
      WordTally(label: 'want', count: 5),
      WordTally(label: 'go', count: 2),
    ],
    firstTimeWords: ['go'],
    addedWords: ['banana'],
    notUsedYet: ['stop'],
    totalUses: 7,
    wordsUsed: 2,
    computedAt: DateTime.utc(2026, 10, 14, 9),
  );

  test('reads the server\'s week as the screens see it', () async {
    var asked = 0;
    final source = ServerWeekSummary(
      week: () async {
        asked++;
        return report;
      },
    );
    final week = (await source.thisWeek())!;
    expect(asked, 1);
    expect(week.weekStart, monday);
    expect(week.topWords, const [WordCount('want', 5), WordCount('go', 2)]);
    expect(week.firstTimeWords, ['go']);
    expect(week.addedWords, ['banana']);
    expect(week.notUsedYet, ['stop']);
    expect(week.totalUses, 7);
    expect(week.wordsUsed, 2);
  });

  test('is null, with no call, for a role that may not see it, a log that '
      'is off, or a device working offline', () async {
    var asked = 0;
    Future<WeekReport> week() async {
      asked++;
      return report;
    }

    expect(
      await ServerWeekSummary(week: week, mayView: false).thisWeek(),
      isNull,
    );
    expect(
      await ServerWeekSummary(week: week, logOn: () => false).thisWeek(),
      isNull,
    );
    final paused = FakeSyncStatus();
    await paused.setWorkingOffline(true);
    expect(
      await ServerWeekSummary(week: week, sync: paused).thisWeek(),
      isNull,
    );
    expect(asked, 0);
  });

  test('is null when the server cannot be reached or refuses', () async {
    expect(
      await ServerWeekSummary(
        week: () async =>
            throw const ServerpodClientNetworkException('no signal'),
      ).thisWeek(),
      isNull,
    );
    expect(
      await ServerWeekSummary(
        week: () async =>
            throw CircleException(failure: CircleFailure.notAllowed),
      ).thisWeek(),
      isNull,
    );
  });

  test("the app's source lets guardians and therapists ask, no one else", () {
    // Never connects: only the role is read here.
    final client = Client('http://localhost:1/');
    addTearDown(client.close);
    final space = UuidValue.fromString('6f1d2c3a-0b4e-4c5d-8e9f-a1b2c3d4e5f6');
    for (final role in CircleRole.values) {
      final source = ServerWeekSummary.forClient(
        client,
        circleSpace: space,
        role: role,
      );
      expect(
        source.mayView,
        role == CircleRole.guardian || role == CircleRole.therapist,
        reason: role.name,
      );
    }
  });
}
