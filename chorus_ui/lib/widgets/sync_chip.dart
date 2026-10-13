/// The sync status chip.
library;

import 'package:flutter/material.dart';

import '../contracts.dart';

/// Plain-words description of [sync]'s state.
String syncLabel(SyncStatus sync) => sync.workingOffline
    ? 'Working offline, saved on this phone'
    : switch (sync.state) {
        SyncState.signedOut => 'Signed out, saved on this phone',
        SyncState.offline => 'Offline, saved on this phone',
        SyncState.clockSkew => "Check this phone's clock",
        SyncState.connecting => 'Connecting',
        SyncState.live => sync.hasUnsent ? 'Sending changes' : 'Up to date',
        SyncState.backoff => 'Reconnecting',
        SyncState.needsUpdate => 'Update the app to sync',
        SyncState.accessLost => 'No longer shared with you',
      };

/// Says in plain words whether this phone is in step with the others, and
/// offers "Sync now" whenever it is not live.
///
/// With [compact] it is the state's icon alone in a 48dp target, for a row
/// with no room for the words: the words are its tooltip and what a screen
/// reader says, and a tap retries whenever "Sync now" would be offered.
class SyncChip extends StatelessWidget {
  const SyncChip({super.key, required this.sync, this.compact = false});

  final SyncStatus sync;

  /// Icon only.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sync,
      builder: (context, _) {
        final state = sync.state;
        // Nothing to retry while live, or while paused on purpose.
        final live = state == SyncState.live || sync.workingOffline;
        final label = syncLabel(sync);
        if (compact) {
          void retry() {
            // Failures show up as the next state; nothing to await.
            sync.syncNow().catchError((Object _) {});
          }

          return Semantics(
            container: true,
            liveRegion: true,
            button: !live,
            label: live ? label : '$label. Tap to sync now',
            excludeSemantics: true,
            onTap: live ? null : retry,
            child: Tooltip(
              message: label,
              child: InkResponse(
                onTap: live ? null : retry,
                radius: 24,
                child: SizedBox(
                  width: 44,
                  height: 48,
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: Icon(
                        _icon(state, sync.hasUnsent),
                        size: 18,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return Semantics(
          container: true,
          liveRegion: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: EdgeInsets.only(left: 10, right: live ? 12 : 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _icon(state, sync.hasUnsent),
                  size: 18,
                  color: Colors.black,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                if (!live)
                  TextButton(
                    onPressed: () {
                      // Failures show up as the next state; nothing to await.
                      sync.syncNow().catchError((Object _) {});
                    },
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: const Text('Sync now'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static IconData _icon(SyncState state, bool hasUnsent) => switch (state) {
    SyncState.live => hasUnsent ? Icons.upload : Icons.check_circle,
    SyncState.connecting || SyncState.backoff => Icons.sync,
    SyncState.offline || SyncState.signedOut => Icons.phone_android,
    SyncState.clockSkew => Icons.schedule,
    SyncState.needsUpdate => Icons.system_update,
    SyncState.accessLost => Icons.block,
  };
}
