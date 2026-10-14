/// One tab of a browser at a time runs the signed-in app.
///
/// Every tab of a browser profile shares the one database on this device.
/// Two tabs are two copies of the app over it, each with its own sync and
/// its own screens: "Work offline" in one does not stop the other sending,
/// and neither is told what the other merged. Two tabs can never be two
/// devices, so a tab asks for the seat before it opens the boards, and a
/// second tab says the app is open elsewhere. Phones and desktops have no
/// tabs and always hold the seat.
library;

import 'tab_seat_stub.dart'
    if (dart.library.js_interop) 'tab_seat_web.dart'
    as platform;

/// This tab's claim on being the one that runs the app.
abstract class TabSeat {
  /// Asks for the seat without waiting for it. True when this tab now holds
  /// it, false when another tab does.
  Future<bool> claim();

  /// Takes the seat from the tab that holds it. That tab hears on [taken].
  Future<void> takeOver();

  /// An event each time another tab takes the seat from this one.
  Stream<void> get taken;

  /// Gives the seat up so another tab can claim it. Does nothing when this
  /// tab does not hold it.
  void release();
}

/// The seat of this tab.
TabSeat openTabSeat() => platform.openPlatformTabSeat();
