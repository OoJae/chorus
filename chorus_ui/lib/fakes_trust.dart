/// In-memory devices and replica report for the trust screens.
library;

import 'contracts_trust.dart';

/// Answers [devices] with [list], or throws [failWith] when set.
class FakeDeviceDirectory implements DeviceDirectory {
  FakeDeviceDirectory({
    this.thisDeviceId = 'this-device',
    List<DeviceSeenInfo>? list,
    this.failWith,
  }) : list = list ?? _sample();

  @override
  final String thisDeviceId;

  List<DeviceSeenInfo> list;
  Object? failWith;

  /// How many times [devices] was asked.
  int asked = 0;

  @override
  Future<List<DeviceSeenInfo>> devices() async {
    asked++;
    final error = failWith;
    if (error != null) throw error;
    return list;
  }

  static List<DeviceSeenInfo> _sample() {
    final now = DateTime.now();
    return [
      DeviceSeenInfo(
        userId: 'mum',
        userName: 'Mum',
        deviceId: 'this-device',
        deviceLabel: 'Web browser',
        lastSyncAt: now,
      ),
      DeviceSeenInfo(
        userId: 'rivera',
        userName: 'Ms Rivera',
        deviceId: 'rivera-laptop',
        deviceLabel: 'Web browser',
        lastSyncAt: now.subtract(const Duration(hours: 2)),
      ),
      DeviceSeenInfo(
        userId: 'gran',
        userName: 'Grandma',
        deviceId: 'gran-tablet',
        deviceLabel: 'Android tablet',
        lastSyncAt: now.subtract(const Duration(days: 3)),
      ),
    ];
  }
}

/// Answers [inspect] with [report].
class FakeReplicaInspector implements ReplicaInspector {
  FakeReplicaInspector([ReplicaReport? report])
    : report =
          report ??
          ReplicaReport(
            boards: 2,
            tiles: 38,
            tileEdits: 5,
            unsentChanges: 0,
            hasUnsent: false,
            lastSyncAt: DateTime.now(),
            circleSpaceId: '6f1d2c3a-0b4e-4c5d-8e9f-a1b2c3d4e5f6',
            parked: const [
              ParkedWord(
                label: 'juice',
                cellKey: 'board:2:3__conflict__tile-7',
                byName: 'Mum',
              ),
            ],
            moduleVersion: '0.0.10',
            serverAddress: 'https://chorus.example/',
          );

  ReplicaReport report;

  @override
  Future<ReplicaReport> inspect() async => report;
}
