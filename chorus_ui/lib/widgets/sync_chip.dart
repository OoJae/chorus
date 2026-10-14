/// The sync status chip.
library;

import 'package:flutter/material.dart';

import '../brand/tokens.dart';
import '../contracts.dart';

/// Plain-words description of [sync]'s state.
String syncLabel(SyncStatus sync) => sync.workingOffline
    ? 'Working offline, saved on this device'
    : switch (sync.state) {
        SyncState.signedOut => 'Signed out, saved on this device',
        SyncState.offline => 'Offline, saved on this device',
        SyncState.clockSkew => "Check this device's clock",
        SyncState.connecting => 'Connecting',
        SyncState.live => sync.hasUnsent ? 'Sending changes' : 'Up to date',
        SyncState.backoff => 'Reconnecting',
        SyncState.needsUpdate => 'Update the app to sync',
        SyncState.accessLost => 'No longer shared with you',
      };

/// Whether "Sync now" is offered for [sync]'s state.
///
/// Only where the device is waiting before it tries again and the adult can
/// do something about the cause first (find a network, set the clock): there
/// a press tries at once, and the state lasts long enough to press it.
bool offersSyncNow(SyncStatus sync) =>
    !sync.workingOffline &&
    switch (sync.state) {
      SyncState.offline || SyncState.backoff || SyncState.clockSkew => true,
      // An attempt is already under way, and over in a moment either way.
      SyncState.connecting => false,
      SyncState.live => false,
      // Signing in again, a newer app or a new invitation ends these; trying
      // again does not.
      SyncState.signedOut ||
      SyncState.needsUpdate ||
      SyncState.accessLost => false,
    };

/// Says in plain words whether this device is in step with the others, and
/// offers "Sync now" where trying again can help: see [offersSyncNow].
///
/// It speaks in the status face (IBM Plex Mono), the machine's voice, in ink
/// on the surface colour: no state has a colour of its own, as colour on a
/// Chorus screen belongs to words.
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
        final colors = ChorusColors.of(context);
        final icon = _icon(sync.state, sync.hasUnsent, sync.workingOffline);
        final canRetry = offersSyncNow(sync);
        final label = syncLabel(sync);
        void retry() {
          // Failures show up as the next state; nothing to await.
          sync.syncNow().catchError((Object _) {});
        }

        if (compact) {
          return Semantics(
            container: true,
            liveRegion: true,
            button: canRetry,
            label: canRetry ? '$label. Tap to sync now' : label,
            excludeSemantics: true,
            onTap: canRetry ? retry : null,
            child: Tooltip(
              message: label,
              // Reached by Tab and pressed by Enter, with no ripple: on the
              // child's board nothing spreads or moves.
              child: InkResponse(
                onTap: canRetry ? retry : null,
                radius: 24,
                splashFactory: NoSplash.splashFactory,
                child: SizedBox(
                  width: ChorusSpace.minTarget,
                  height: ChorusSpace.minTarget,
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.ink, width: 1.5),
                      ),
                      child: Icon(icon, size: 18, color: colors.ink),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        final style = ChorusType.status.copyWith(color: colors.ink);
        return Semantics(
          container: true,
          liveRegion: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: EdgeInsets.only(left: 10, right: canRetry ? 2 : 12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(ChorusSpace.buttonRadius),
              border: Border.all(color: colors.ink, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: colors.ink),
                const SizedBox(width: 8),
                // Wraps rather than cut: at a large text size the words
                // are the whole point of the chip.
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(label, style: style),
                  ),
                ),
                if (canRetry) ...[
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: retry,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      // On the chip's own face, not the page.
                      foregroundColor: colors.ink,
                      textStyle: ChorusType.label,
                    ),
                    child: const Text('Sync now'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static IconData _icon(SyncState state, bool hasUnsent, bool working) =>
      working
      ? Icons.phone_android_rounded
      : switch (state) {
          SyncState.live =>
            hasUnsent ? Icons.upload_rounded : Icons.check_circle_rounded,
          SyncState.connecting || SyncState.backoff => Icons.sync_rounded,
          SyncState.offline ||
          SyncState.signedOut => Icons.phone_android_rounded,
          SyncState.clockSkew => Icons.schedule_rounded,
          SyncState.needsUpdate => Icons.system_update_rounded,
          SyncState.accessLost => Icons.block_rounded,
        };
}
