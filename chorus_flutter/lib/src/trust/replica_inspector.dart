/// "Under the hood" over the replica on this device.
library;

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_shared/chorus_shared.dart' show conflictMarker;
import 'package:chorus_ui/contracts.dart' show SyncStatus;
import 'package:chorus_ui/contracts_trust.dart';

import '../sync/replica_service.dart';

/// The module version this build pins.
const String offlineSyncModuleVersion = '0.0.10';

/// [ReplicaInspector] for one circle: reads its rows through the replica's
/// queue, so it never reads while the app is writing.
class LocalReplicaInspector implements ReplicaInspector {
  LocalReplicaInspector({
    required this.replica,
    required this.circleSpace,
    required this.sync,
    required this.serverAddress,
  });

  final ReplicaService replica;
  final UuidValue circleSpace;
  final SyncStatus sync;
  final String serverAddress;

  @override
  Future<ReplicaReport> inspect() async {
    final counts = await replica.read((session) async {
      final boards = await Board.db.count(
        session,
        where: (t) => t.circleId.equals(circleSpace),
      );
      final tiles = await Tile.db.find(
        session,
        where: (t) => t.circleId.equals(circleSpace),
      );
      final edits = await TileEdit.db.count(
        session,
        where: (t) => t.circleId.equals(circleSpace),
      );
      return (boards: boards, tiles: tiles, edits: edits);
    });
    return ReplicaReport(
      boards: counts.boards,
      tiles: counts.tiles.length,
      tileEdits: counts.edits,
      unsentChanges: sync.unsentChanges,
      hasUnsent: sync.hasUnsent,
      lastSyncAt: sync.lastMergeAt,
      circleSpaceId: circleSpace.uuid,
      parked: [
        for (final tile in counts.tiles)
          if (tile.cellKey.contains(conflictMarker) && tile.archivedAt == null)
            ParkedWord(
              label: tile.label,
              cellKey: tile.cellKey,
              byName: tile.createdByName,
            ),
      ],
      moduleVersion: offlineSyncModuleVersion,
      serverAddress: serverAddress,
      syncState: sync.workingOffline
          ? 'paused (Work offline)'
          : sync.state.name,
    );
  }
}
