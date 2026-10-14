/// The words of the trust signals: what the status chip says when this
/// device is level with the others or holds changes they have not seen.
library;

import '../../contracts.dart';
import '../flags/w1.dart';

/// The chip when nothing waits to be sent and the last sync worked.
const String everyoneUpToDateLabel = "Everyone's up to date";

/// "1 change waiting to send", "2 changes waiting to send".
String changesWaitingLabel(int count) =>
    count == 1 ? '1 change waiting to send' : '$count changes waiting to send';

/// What the chip says instead of its plain words, or null to keep them.
///
/// Live with nothing waiting: [everyoneUpToDateLabel]. With a known number
/// of changes waiting: that number, live or not, after "Working offline"
/// or "Offline" where the device is not connected.
String? trustSyncLabel(SyncStatus sync) {
  if (!trustChipWordsEnabled) return null;
  final waiting = sync.unsentChanges;
  final counted = waiting != null && waiting > 0 && sync.hasUnsent;
  if (sync.workingOffline) {
    return counted ? 'Working offline, ${changesWaitingLabel(waiting)}' : null;
  }
  return switch (sync.state) {
    SyncState.live when !sync.hasUnsent => everyoneUpToDateLabel,
    SyncState.live when counted => changesWaitingLabel(waiting),
    SyncState.offline when counted =>
      'Offline, ${changesWaitingLabel(waiting)}',
    _ => null,
  };
}
