/// The live session as the screens see it.
///
/// Kept apart from `contracts.dart` so a screen can be given one or not: the
/// talker and the editor work exactly as before without it.
library;

import 'package:flutter/foundation.dart';

/// How long a tile glows after its pulse arrives.
const Duration livePulseFor = Duration(milliseconds: 2500);

/// The members of one circle who are online together, right now.
///
/// Everything here is ephemeral: nothing is stored on this device or on the
/// server, and all of it is empty while [connected] is false. Notifies
/// listeners whenever any getter changes.
abstract class LiveSession extends ChangeNotifier {
  /// True while the stream to the server is open.
  bool get connected;

  /// Ids of the tiles glowing now. A tile leaves the set [livePulseFor]
  /// after its latest pulse; a pulse this device sent glows here too.
  Set<String> get pulsing;

  /// Names of the other members present.
  List<String> get present;

  /// Makes the tile glow on the other devices. Does nothing when
  /// disconnected.
  void sendPulse(String tileId);

  /// Shares a sentence the child's device just spoke. Sends nothing at all
  /// unless [shareSaid] is on and the session is connected.
  void sendSaid(String text);

  /// Whether this device shares what is said. Off unless a guardian turned
  /// it on, and remembered per device.
  bool get shareSaid;
  set shareSaid(bool value);

  /// The latest sentence another device shared; null until one arrives.
  String? get lastSaid;
}
