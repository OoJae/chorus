/// "Who is up to date": every member's devices and when each last synced,
/// so an adult can see whether Grandma's tablet has today's words.
library;

import 'package:flutter/material.dart';

import '../../contracts.dart';
import '../../contracts_trust.dart';
import '../feature_page.dart';
import 'trust_words.dart';

/// The home entry and the screen's title.
const String whoIsUpToDateTitle = 'Who is up to date';

/// Above the list.
const String whoIsUpToDateIntro =
    'Each device checks in after it syncs. A device that has not checked in '
    'for a while may be missing the newest words.';

/// While the list loads.
const String whoIsUpToDateLoading = 'Asking the other devices…';

/// When the list could not be read.
const String whoIsUpToDateFailed =
    'The list needs a connection. The board on this device still works.';

/// When no device has checked in yet.
const String whoIsUpToDateEmpty =
    'No device has checked in yet. Each one appears here after its next '
    'sync.';

/// The refresh button's tooltip.
const String whoIsUpToDateRefresh = 'Check again';

/// "just now", "5 minutes ago", "3 hours ago", "3 days ago".
String agoLabel(DateTime when, {DateTime? now}) {
  final gap = (now ?? DateTime.now()).difference(when);
  if (gap.inMinutes < 1) return 'just now';
  if (gap.inHours < 1) {
    return gap.inMinutes == 1 ? '1 minute ago' : '${gap.inMinutes} minutes ago';
  }
  if (gap.inDays < 1) {
    return gap.inHours == 1 ? '1 hour ago' : '${gap.inHours} hours ago';
  }
  return gap.inDays == 1 ? '1 day ago' : '${gap.inDays} days ago';
}

/// One line: "Grandma's Android tablet: last synced 3 days ago", or for this
/// device what the status chip knows now.
String deviceLine(
  DeviceSeenInfo device, {
  required bool isThisDevice,
  required SyncStatus sync,
  DateTime? now,
}) {
  if (isThisDevice) {
    final waiting = sync.unsentChanges;
    if (sync.state == SyncState.live && !sync.hasUnsent) {
      return 'This device: up to date';
    }
    if (sync.hasUnsent && waiting != null && waiting > 0) {
      return 'This device: ${changesWaitingLabel(waiting)}';
    }
    return 'This device: last synced ${agoLabel(device.lastSyncAt, now: now)}';
  }
  return "${device.userName}'s ${device.deviceLabel.toLowerCase()}: last "
      'synced ${agoLabel(device.lastSyncAt, now: now)}';
}

/// The screen. [sync] says how this device is doing now.
class WhoIsUpToDateScreen extends StatefulWidget {
  const WhoIsUpToDateScreen({
    super.key,
    required this.directory,
    required this.sync,
  });

  final DeviceDirectory directory;
  final SyncStatus sync;

  @override
  State<WhoIsUpToDateScreen> createState() => _WhoIsUpToDateScreenState();
}

class _WhoIsUpToDateScreenState extends State<WhoIsUpToDateScreen> {
  late Future<List<DeviceSeenInfo>> _list = widget.directory.devices();

  void _refresh() {
    final next = widget.directory.devices();
    setState(() {
      _list = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.sync,
      builder: (context, _) => FutureBuilder<List<DeviceSeenInfo>>(
        future: _list,
        builder: (context, snapshot) {
          final reported = snapshot.data;
          // This device is listed even before its first report arrives.
          final thisId = widget.directory.thisDeviceId;
          final list =
              reported == null ||
                  thisId.isEmpty ||
                  reported.any((d) => d.deviceId == thisId)
              ? reported
              : [
                  DeviceSeenInfo(
                    userId: '',
                    userName: '',
                    deviceId: thisId,
                    deviceLabel: '',
                    lastSyncAt: widget.sync.lastMergeAt ?? DateTime.now(),
                  ),
                  ...reported,
                ];
          final content = <Widget>[
            const Text(whoIsUpToDateIntro),
            const SizedBox(height: 16),
            if (snapshot.hasError)
              FeatureNote(
                icon: Icons.cloud_off_rounded,
                message: whoIsUpToDateFailed,
                action: TextButton(
                  onPressed: _refresh,
                  child: const Text(whoIsUpToDateRefresh),
                ),
              )
            else if (list == null)
              const FeatureFact(
                icon: Icons.hourglass_empty_rounded,
                text: whoIsUpToDateLoading,
              )
            else if (list.isEmpty)
              const FeatureNote(
                icon: Icons.devices_rounded,
                message: whoIsUpToDateEmpty,
              )
            else
              for (final device in list)
                FeatureFact(
                  icon: device.deviceId == widget.directory.thisDeviceId
                      ? Icons.check_circle_rounded
                      : Icons.devices_rounded,
                  text: deviceLine(
                    device,
                    isThisDevice:
                        device.deviceId == widget.directory.thisDeviceId,
                    sync: widget.sync,
                  ),
                ),
          ];
          return FeaturePage(
            title: whoIsUpToDateTitle,
            barActions: [
              IconButton(
                tooltip: whoIsUpToDateRefresh,
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
            content: content,
          );
        },
      ),
    );
  }
}
