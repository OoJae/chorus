/// Trust signals and "Under the hood", as the screens see them.
///
/// Kept apart from `contracts.dart`: home and the editor work exactly as
/// before without any of it.
library;

/// One device of one member, as it last reported to the server.
class DeviceSeenInfo {
  const DeviceSeenInfo({
    required this.userId,
    required this.userName,
    required this.deviceId,
    required this.deviceLabel,
    required this.lastSyncAt,
  });

  final String userId;

  /// The member's name in the circle.
  final String userName;

  final String deviceId;

  /// "Android phone", "Web browser".
  final String deviceLabel;

  /// When the device last finished a sync.
  final DateTime lastSyncAt;
}

/// "Who is up to date": every member's devices.
abstract class DeviceDirectory {
  /// The id this device reports itself with.
  String get thisDeviceId;

  /// Every device that has reported a sync of the circle, most recently
  /// synced first. Needs the network; throws when it cannot be read.
  Future<List<DeviceSeenInfo>> devices();
}

/// A word the sync engine parked: it lost its spot to a word that got
/// there first, and waits under "Needs a home".
class ParkedWord {
  const ParkedWord({
    required this.label,
    required this.cellKey,
    required this.byName,
  });

  final String label;

  /// The raw key, engine suffix included.
  final String cellKey;
  final String byName;
}

/// What the replica on this device holds, for "Under the hood".
class ReplicaReport {
  const ReplicaReport({
    required this.boards,
    required this.tiles,
    required this.tileEdits,
    required this.unsentChanges,
    required this.hasUnsent,
    required this.lastSyncAt,
    required this.circleSpaceId,
    required this.parked,
    required this.moduleVersion,
    required this.serverAddress,
  });

  /// Rows of the circle in each synced table on this device.
  final int boards;
  final int tiles;
  final int tileEdits;

  /// Local writes the server has not confirmed, when known.
  final int? unsentChanges;
  final bool hasUnsent;

  /// When the last merge with the server completed; null before any.
  final DateTime? lastSyncAt;

  /// The circle's shared sync space.
  final String circleSpaceId;

  /// Tiles whose key carries the engine's suffix.
  final List<ParkedWord> parked;

  /// `serverpod_offline_sync` on this build.
  final String moduleVersion;

  /// The API server this device syncs with.
  final String serverAddress;
}

/// Reads the [ReplicaReport] of one circle on this device.
abstract class ReplicaInspector {
  Future<ReplicaReport> inspect();
}
