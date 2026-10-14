// The supervisor's count of changes waiting to send, behind "2 changes
// waiting to send" on the status chip.
import 'dart:async';

import 'package:chorus_flutter/src/sync/sync_supervisor.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sync_supervisor_test.dart' show FakeLink;

void main() {
  late FakeLink link;
  late SyncSupervisor sync;

  void supervised(
    String description,
    Future<void> Function(WidgetTester tester) body,
  ) {
    testWidgets(description, (tester) async {
      DateTime now() => tester.binding.clock.now();
      link = FakeLink(now);
      sync = SyncSupervisor(link, now: now);
      try {
        await body(tester);
      } finally {
        await sync.stop();
        sync.dispose();
      }
    });
  }

  Future<void> settle(WidgetTester tester) => tester.pump(Duration.zero);

  supervised('is unknown before the first sync, then counts each local '
      'write until a merge confirms them', (tester) async {
    expect(sync.hasUnsent, isTrue);
    expect(sync.unsentChanges, isNull, reason: 'edits from before a restart');

    sync.start();
    await settle(tester);
    expect(sync.state, SyncState.live);
    expect(sync.unsentChanges, 0);

    sync
      ..noteLocalWrite()
      ..noteLocalWrite();
    expect(sync.unsentChanges, 2);

    await tester.pump(const Duration(seconds: 1));
    link.merge!();
    await tester.pump(const Duration(milliseconds: 151));
    expect(sync.hasUnsent, isFalse);
    expect(sync.unsentChanges, 0);
  });

  supervised('counts the writes made while working offline and clears them '
      'once sync resumes', (tester) async {
    sync.start();
    await settle(tester);
    await sync.setWorkingOffline(true);
    await settle(tester);
    for (var i = 0; i < 3; i++) {
      sync.noteLocalWrite();
    }
    expect(sync.unsentChanges, 3);

    await tester.pump(const Duration(seconds: 1));
    unawaited(sync.setWorkingOffline(false));
    await settle(tester);
    await settle(tester);
    expect(sync.state, SyncState.live);
    expect(sync.unsentChanges, 0);
  });
}
