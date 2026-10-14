@TestOn('browser')
library;

import 'dart:async';

import 'package:chorus_flutter/src/tabs/tab_seat.dart';
import 'package:flutter_test/flutter_test.dart';

/// Run with `flutter test --platform chrome test/app/one_tab_seat_web_test.dart`.
/// Skipped by the ordinary test run, which has no browser. Two seats on one
/// page stand in for two tabs: the browser treats two requests for a lock
/// the same wherever they come from.
void main() {
  test('the browser gives the seat to one at a time, and it can be taken '
      'over', () async {
    final first = openTabSeat();
    final second = openTabSeat();
    addTearDown(first.release);
    addTearDown(second.release);
    var firstTaken = 0;
    var secondTaken = 0;
    final subs = [
      first.taken.listen((_) => firstTaken++),
      second.taken.listen((_) => secondTaken++),
    ];
    addTearDown(() => Future.wait([for (final sub in subs) sub.cancel()]));

    expect(await first.claim(), isTrue);
    expect(await second.claim(), isFalse);
    // Asking again changes nothing for the tab that has it.
    expect(await first.claim(), isTrue);

    await second.takeOver();
    await _until(() => firstTaken == 1);
    expect(secondTaken, 0);
    expect(await first.claim(), isFalse);

    // Given up, it is free again. The browser frees it a moment later.
    second.release();
    await _until(() async => await first.claim());
    expect(secondTaken, 0);
    expect(firstTaken, 1);
  });

  test(
    'a seat given up while the browser is still asked is not kept',
    () async {
      final first = openTabSeat();
      final second = openTabSeat();
      addTearDown(first.release);
      addTearDown(second.release);

      final asked = first.claim();
      first.release();
      // Whichever the browser got to first, the claim or the release.
      await asked;

      await _until(() async => await second.claim());
    },
  );
}

/// Waits until [done] answers true, for at most two seconds.
Future<void> _until(FutureOr<bool> Function() done) async {
  final give = DateTime.now().add(const Duration(seconds: 2));
  while (!await done()) {
    if (DateTime.now().isAfter(give)) fail('Still waiting after two seconds.');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}
