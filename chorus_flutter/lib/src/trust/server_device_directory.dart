/// "Who is up to date" over the server's device list.
library;

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_ui/contracts_trust.dart';

/// [DeviceDirectory] for one circle.
class ServerDeviceDirectory implements DeviceDirectory {
  ServerDeviceDirectory(this._client, this.circleSpace, this.thisDeviceId);

  final Client _client;
  final UuidValue circleSpace;

  @override
  final String thisDeviceId;

  @override
  Future<List<DeviceSeenInfo>> devices() async {
    final list = await _client.deviceSeen
        .devices(circleSpace)
        .timeout(const Duration(seconds: 15));
    return [
      for (final d in list)
        DeviceSeenInfo(
          userId: d.userId.uuid,
          userName: d.userName,
          deviceId: d.deviceId,
          deviceLabel: d.deviceLabel,
          lastSyncAt: d.lastSyncAt.toLocal(),
        ),
    ];
  }
}
