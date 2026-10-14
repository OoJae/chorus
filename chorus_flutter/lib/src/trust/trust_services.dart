/// "Try a clash", "Who is up to date" and "Under the hood" for one circle,
/// made for the app's `CircleServices`.
library;

import 'dart:async';

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_ui/contracts.dart' show SyncStatus;
import 'package:chorus_ui/contracts_clash.dart';
import 'package:chorus_ui/contracts_trust.dart';
import 'package:chorus_ui/features/flags/w1.dart';

import '../practice/server_clash_partner.dart';
import '../sync/replica_service.dart';
import '../sync/sync_supervisor.dart';
import 'device_heartbeat.dart';
import 'device_identity.dart';
import 'replica_inspector.dart';
import 'server_device_directory.dart';

/// What the screens get. Each part is null where its flag is off or the
/// adult's role has no use for it.
class TrustServices {
  const TrustServices({this.clash, this.devices, this.inspector});

  /// The practice partner. Null for a read-only partner.
  final ClashPartner? clash;

  /// "Who is up to date".
  final DeviceDirectory? devices;

  /// "Under the hood".
  final ReplicaInspector? inspector;
}

/// The long-lived part of one circle's trust features: the heartbeat that
/// reports this device after each sync. Made once per circle and disposed
/// with it.
class TrustParts {
  TrustParts._(this._client, this._space, this._sync, this._replica);

  /// Starts the heartbeat for [space] when its flag is on.
  factory TrustParts.open(
    Client client, {
    required UuidValue space,
    required SyncStatus sync,
    ReplicaService? replica,
  }) {
    final parts = TrustParts._(client, space, sync, replica);
    if (whoIsUpToDateEnabled) unawaited(parts._startHeartbeat());
    return parts;
  }

  final Client _client;
  final UuidValue _space;
  final SyncStatus _sync;
  final ReplicaService? _replica;
  DeviceHeartbeat? _heartbeat;
  String _deviceId = '';
  bool _disposed = false;

  Future<void> _startHeartbeat() async {
    _deviceId = await deviceId();
    if (_disposed) return;
    final label = deviceLabel();
    _heartbeat = DeviceHeartbeat(
      sync: _sync,
      send: (at) => _client.deviceSeen
          .heartbeat(_space, _deviceId, label, at)
          .timeout(const Duration(seconds: 15)),
    );
  }

  /// The services for an adult who [canEdit] or not.
  TrustServices services({required bool canEdit}) {
    final sync = _sync;
    final replica = _replica;
    return TrustServices(
      clash: tryAClashEnabled && canEdit
          ? ServerClashPartner.forClient(
              _client,
              circleSpace: _space,
              supervisor: sync is SyncSupervisor ? sync : null,
            )
          : null,
      devices: whoIsUpToDateEnabled
          ? _LazyDirectory(_client, _space, () => _deviceId)
          : null,
      inspector: underTheHoodEnabled && replica != null
          ? LocalReplicaInspector(
              replica: replica,
              circleSpace: _space,
              sync: sync,
              serverAddress: _client.host,
            )
          : null,
    );
  }

  void dispose() {
    _disposed = true;
    _heartbeat?.dispose();
  }
}

/// Reads this device's id when first asked, since it is loaded after the
/// services are made.
class _LazyDirectory implements DeviceDirectory {
  _LazyDirectory(this._client, this._space, this._id);

  final Client _client;
  final UuidValue _space;
  final String Function() _id;

  @override
  String get thisDeviceId => _id();

  @override
  Future<List<DeviceSeenInfo>> devices() async {
    if (_id().isEmpty) await deviceId();
    return ServerDeviceDirectory(_client, _space, thisDeviceId).devices();
  }
}
