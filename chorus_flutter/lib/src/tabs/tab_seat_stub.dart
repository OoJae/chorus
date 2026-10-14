/// The seat where the app has no tabs (phones, desktops, tests): always held.
library;

import 'tab_seat.dart';

TabSeat openPlatformTabSeat() => const _OnlySeat();

class _OnlySeat implements TabSeat {
  const _OnlySeat();

  @override
  Future<bool> claim() async => true;

  @override
  Future<void> takeOver() async {}

  @override
  Stream<void> get taken => const Stream<void>.empty();

  @override
  void release() {}
}
