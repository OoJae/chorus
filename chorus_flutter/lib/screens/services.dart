/// What the app shell needs from the server and from the local replica.
///
/// The screens are written against these two interfaces so widget tests can
/// run them on small fakes. The real implementations live in `app.dart`.
library;

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_ui/contracts.dart' show BoardStore, SyncStatus;

/// The circle calls on the server, plus the circles remembered on this
/// device for a start with no signal.
abstract class CircleGateway {
  /// Every circle the signed-in adult belongs to. Needs the network.
  Future<List<CircleInfo>> myCircles();

  /// The circles this device saw last time. Never throws; empty when
  /// nothing was saved.
  Future<List<CircleInfo>> rememberedCircles();

  Future<CircleInfo> createCircle({
    required String childName,
    required String displayName,
  });

  Future<CircleInfo> acceptInvite({
    required String code,
    required String displayName,
  });

  /// A single-use code that lets one more adult join [circle] as [role].
  Future<String> createInvite(CircleInfo circle, CircleRole role);

  Future<void> signOut();
}

/// The signed-in adult's local replica, already syncing.
abstract class Workspace {
  SyncStatus get sync;

  /// Waits until this device may write into [circle]'s boards, and seeds the
  /// starter board when asked and none exists.
  Future<void> ensureCircleReady(CircleInfo circle, {bool seedIfEmpty = false});

  BoardStore boardStore(CircleInfo circle);

  /// Stops sync and closes the replica.
  Future<void> close();
}

typedef WorkspaceOpener = Future<Workspace> Function();
