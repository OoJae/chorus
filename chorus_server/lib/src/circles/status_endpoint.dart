import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// What a client checks before it starts syncing. No sign-in needed.
class StatusEndpoint extends Endpoint {
  /// Raise this when a release changes the synced tables: older builds then
  /// see an "update needed" state instead of a failed sync handshake.
  static const minBuild = 1;

  Future<ServerInfo> info(Session session) async =>
      ServerInfo(serverTime: DateTime.now().toUtc(), minBuild: minBuild);
}
