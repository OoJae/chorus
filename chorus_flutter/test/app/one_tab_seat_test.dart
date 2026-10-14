import 'package:chorus_flutter/src/tabs/tab_seat.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('where there are no tabs the seat is always held', () async {
    final seat = openTabSeat();
    final other = openTabSeat();
    var taken = 0;
    final sub = seat.taken.listen((_) => taken++);
    addTearDown(sub.cancel);

    expect(await seat.claim(), isTrue);
    // Nothing to contend with: a second seat is held as well.
    expect(await other.claim(), isTrue);
    await other.takeOver();
    await Future<void>.delayed(Duration.zero);
    expect(taken, 0);

    seat.release();
    expect(await seat.claim(), isTrue);
  });
}
