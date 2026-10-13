/// The sync status chip.
library;

import 'package:flutter/material.dart';

import '../contracts.dart';

/// Plain-words description of [sync]'s state.
String syncLabel(SyncStatus sync) => switch (sync.state) {
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
class SyncChip extends StatelessWidget {
  const SyncChip({super.key, required this.sync});

  final SyncStatus sync;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sync,
      builder: (context, _) {
        final state = sync.state;
        final live = state == SyncState.live;
        final label = syncLabel(sync);
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
                Icon(_icon(state, sync.hasUnsent),
                    size: 18, color: Colors.black),
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
