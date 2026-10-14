import 'package:chorus_client/chorus_client.dart' as api;
import 'package:chorus_flutter/src/modelling/browser_speech_listener.dart';
import 'package:chorus_flutter/src/modelling/server_modelling.dart';
import 'package:chorus_flutter/src/wordlog/server_week_summary.dart';
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart' show CircleRole;
import 'package:chorus_ui/fakes.dart' show FakeSyncStatus;
import 'package:chorus_ui/fakes_features.dart' show FakeWordLog;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late api.Client client;
  final space = api.UuidValue.withValidation(
    '6f1d2c3a-0b4e-4c5d-8e9f-a1b2c3d4e5f6',
  );

  setUp(() => client = api.Client('http://localhost:1/'));
  tearDown(() => client.close());

  ServerModelling modelling(CircleRole role, {FakeWordLog? log}) =>
      ServerModelling(
        client: client,
        space: space,
        userId: 'me',
        role: role,
        log: log,
        timeout: const Duration(milliseconds: 200),
      );

  test('guardians and therapists may pin focus words and make reports', () {
    expect(modelling(CircleRole.guardian).canPinFocus, isTrue);
    expect(modelling(CircleRole.therapist).canPinFocus, isTrue);
    expect(modelling(CircleRole.teacher).canPinFocus, isFalse);
    expect(modelling(CircleRole.partner).canPinFocus, isFalse);
  });

  test('a teacher may not pin or make a report', () async {
    final source = modelling(CircleRole.teacher);
    await expectLater(source.setFocusWords(const []), throwsStateError);
    await expectLater(source.makeProgressReport(), throwsStateError);
  });

  test('a modelled tap never throws, whatever the log and the network', () {
    const tile = TileFacts(
      id: '0b8c2f4e-2d1a-4c3b-9e8f-7a6b5c4d3e2f',
      boardId: '1c9d3e5f-3e2b-4d4c-8f9a-8b7c6d5e4f3a',
      cellKey: '1c9d3e5f-3e2b-4d4c-8f9a-8b7c6d5e4f3a:0:0',
      label: 'go',
    );
    final off = FakeWordLog();
    final on = FakeWordLog(enabled: true);
    for (final log in [null, off, on]) {
      modelling(CircleRole.guardian, log: log).noteModelled(tile);
    }
    on.setPrivate(true);
    modelling(CircleRole.guardian, log: on).noteModelled(tile);
  });

  test(
    'no server gives no focus words and no nudge, without throwing',
    () async {
      final source = modelling(CircleRole.guardian);
      await source.refreshFocus();
      expect(source.focusWords, isEmpty);
      expect(await source.nudge(), isNull);
      expect(source.shownNudge, isNull);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(source.shownNudge, isNull);
    },
  );

  test('nothing is asked while working offline', () async {
    final sync = FakeSyncStatus();
    await sync.setWorkingOffline(true);
    final source = ServerModelling(
      client: client,
      space: space,
      userId: 'me',
      role: CircleRole.guardian,
      sync: sync,
    );
    expect(await source.nudge(), isNull);
  });

  test('the week carries modelled against said', () {
    final week = weekSummaryOf(
      api.WeekReport(
        weekStart: DateTime.utc(2026, 10, 12),
        topWords: [],
        firstTimeWords: [],
        addedWords: [],
        notUsedYet: [],
        totalUses: 0,
        wordsUsed: 0,
        computedAt: DateTime.utc(2026, 10, 14),
        modelled: [api.ModelledTally(label: 'go', modelled: 14, said: 3)],
      ),
    );
    expect(week.modelled, const [ModelledCount('go', modelled: 14, said: 3)]);
  });

  test('outside a browser "Listen" is not available', () {
    final speech = browserSpeechListener();
    expect(speech.available, isFalse);
    speech.start((_) {});
    expect(speech.listening, isFalse);
  });
}
