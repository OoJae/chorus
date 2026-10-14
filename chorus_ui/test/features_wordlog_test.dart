import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/contracts_wordlog.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_features.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Wednesday 14 October 2026, 09:00 UTC.
  var clock = DateTime.utc(2026, 10, 14, 9);
  DateTime now() => clock;

  final store = FakeBoardStore.seeded();
  TileFacts word(String label) =>
      store.tiles.singleWhere((tile) => tile.label == label);

  setUp(() => clock = DateTime.utc(2026, 10, 14, 9));

  group('word log', () {
    test('is off by default and records nothing', () {
      final log = FakeWordLog(now: now);
      expect(log, isA<WordLog>());
      expect(log.enabled, isFalse);
      expect(log.private, isFalse);
      log.noteSpoken(word('want'));
      expect(log.kept, isEmpty);
      expect(log.pending, 0);
    });

    test('only a guardian may turn it on or off, or delete it', () async {
      for (final role in [
        CircleRole.therapist,
        CircleRole.teacher,
        CircleRole.partner,
      ]) {
        final log = FakeWordLog(role: role, now: now);
        expect(log.canChange, isFalse, reason: role.name);
        await expectLater(log.setEnabled(true), throwsStateError);
        await expectLater(log.deleteAll(), throwsStateError);
        expect(log.enabled, isFalse);
      }
      final guardian = FakeWordLog(now: now);
      expect(guardian.canChange, isTrue);
      await guardian.setEnabled(true);
      expect(guardian.enabled, isTrue);
    });

    test('once on, records tile, board and time, never the sentence', () async {
      final log = FakeWordLog(now: now);
      var heard = 0;
      log.addListener(() => heard++);
      await log.setEnabled(true);
      log.noteSpoken(word('want'));
      expect(log.kept, [
        WordUse(
          tileId: word('want').id,
          boardId: store.homeBoardId,
          spokenAt: clock,
        ),
      ]);
      expect(heard, 2);
    });

    test('private mode pauses it for the session', () async {
      final log = FakeWordLog(enabled: true, now: now);
      log.setPrivate(true);
      expect(log.private, isTrue);
      log.noteSpoken(word('want'));
      expect(log.kept, isEmpty);
      expect(log.pending, 0);
      log.setPrivate(false);
      log.noteSpoken(word('more'));
      expect(log.kept, hasLength(1));
    });

    test('anyone at the board may go private', () {
      final log = FakeWordLog(role: CircleRole.partner, enabled: true);
      log.setPrivate(true);
      expect(log.private, isTrue);
    });

    test('offline uses wait on the device and are sent on return', () {
      final log = FakeWordLog(enabled: true, online: false, now: now);
      for (var i = 0; i < 3; i++) {
        log.noteSpoken(word('go'));
      }
      expect(log.pending, 3);
      expect(log.kept, isEmpty);
      log.online = true;
      expect(log.pending, 0);
      expect(log.kept, hasLength(3));
    });

    test('the queue keeps the newest 2,000', () {
      final log = FakeWordLog(enabled: true, online: false, now: now);
      for (var i = 0; i < wordLogQueueCap + 5; i++) {
        clock = clock.add(const Duration(seconds: 1));
        log.noteSpoken(word('go'));
      }
      expect(log.pending, wordLogQueueCap);
      expect(log.queued.last.spokenAt, clock);
    });

    test('delete removes the kept log and what is waiting', () async {
      final log = FakeWordLog(enabled: true, now: now);
      log.noteSpoken(word('want'));
      log.online = false;
      log.noteSpoken(word('more'));
      log.online = true;
      log.online = false;
      log.noteSpoken(word('go'));
      await expectLater(log.deleteAll(), throwsStateError);
      expect(log.kept, hasLength(2));
      log.online = true;
      await log.deleteAll();
      expect(log.kept, isEmpty);
      expect(log.pending, 0);
      expect(log.deletions, 1);
    });

    test('noting a word never throws', () {
      final log = FakeWordLog(enabled: true, now: () => throw StateError('x'));
      expect(() => log.noteSpoken(word('want')), returnsNormally);
    });
  });

  group('this week', () {
    test('sums the kept log against the tiles', () async {
      final log = FakeWordLog(enabled: true, now: now);
      final week = FakeWeekSummarySource(store: store, log: log, now: now);
      log.noteSpoken(word('want'));
      log.noteSpoken(word('want'));
      log.noteSpoken(word('more'));
      final summary = await week.thisWeek();
      expect(summary, isNotNull);
      expect(summary!.weekStart, DateTime.utc(2026, 10, 12));
      expect(summary.topWords, const [
        WordCount('want', 2),
        WordCount('more', 1),
      ]);
      expect(summary.totalUses, 3);
      expect(summary.notUsedYet, hasLength(34));
    });

    test('is null when off, offline, or for a teacher or partner', () async {
      final log = FakeWordLog(now: now);
      final week = FakeWeekSummarySource(store: store, log: log, now: now);
      expect(await week.thisWeek(), isNull);
      await log.setEnabled(true);
      log.online = false;
      expect(await week.thisWeek(), isNull);
      log.online = true;
      expect(await week.thisWeek(), isNotNull);
      for (final role in [CircleRole.teacher, CircleRole.partner]) {
        final other = FakeBoardStore.seeded(role: role);
        expect(
          await FakeWeekSummarySource(store: other, log: log).thisWeek(),
          isNull,
          reason: role.name,
        );
      }
      final therapist = FakeBoardStore.seeded(role: CircleRole.therapist);
      expect(
        await FakeWeekSummarySource(store: therapist, log: log).thisWeek(),
        isNotNull,
      );
    });
  });
}
