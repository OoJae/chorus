/// "Share a view-only board": a speaking page of the board for a babysitter.
library;

import 'dart:async';

import 'package:chorus_shared/chorus_shared.dart' show BoardFacts;
import 'package:flutter/material.dart';

import '../brand/haptics.dart';
import '../contracts.dart';
import '../contracts_sharing.dart';
import 'feature_page.dart';

/// The label of the button that makes the link.
const String makeViewOnlyLinkLabel = 'Make a view-only link';

/// The label of the button that withdraws it.
const String stopSharingLabel = 'Stop sharing';

/// Explains who a view-only board is for and what it shows, makes the link,
/// and shows it with Copy and Share, the day it stops opening, and "Stop
/// sharing".
///
/// The link is made only when asked: opening the screen shares nothing.
class ShareViewOnlyScreen extends StatefulWidget {
  const ShareViewOnlyScreen({
    super.key,
    required this.sharing,
    required this.board,
    required this.childName,
    this.onShare,
    this.sync,
  });

  final BoardSharing sharing;

  /// The board to share, usually the home board.
  final BoardFacts board;
  final String childName;

  /// The device's share sheet; without it the link has Copy alone.
  final ShareLinkAction? onShare;

  /// Says whether the device is offline, so the screen can say why making
  /// the link would fail before it is tried.
  final SyncStatus? sync;

  @override
  State<ShareViewOnlyScreen> createState() => _ShareViewOnlyScreenState();
}

enum _Step { ready, making, shared, stopping, stopped }

class _ShareViewOnlyScreenState extends State<ShareViewOnlyScreen> {
  final GlobalKey _resultKey = GlobalKey();
  _Step _step = _Step.ready;
  SharedLink? _link;
  String? _error;

  String get _child => widget.childName;

  Future<void> _make() async {
    final before = _step;
    setState(() {
      _step = _Step.making;
      _error = null;
    });
    try {
      final link = await widget.sharing.shareViewOnly(widget.board);
      if (!mounted) return;
      setState(() {
        _link = link;
        _step = _Step.shared;
      });
      revealAfterFrame(_resultKey);
    } catch (error) {
      ChorusHaptics.failed();
      if (!mounted) return;
      setState(() {
        _step = before;
        _error = error is SharingFailed
            ? error.message
            : 'The link could not be made. Try again.';
      });
    }
  }

  Future<void> _stop() async {
    final link = _link;
    if (link == null) return;
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Stop sharing this board?'),
        content: const Text(
          'The link stops opening now, on every phone it was sent to.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(stopSharingLabel),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    setState(() {
      _step = _Step.stopping;
      _error = null;
    });
    try {
      await widget.sharing.withdraw(link);
      if (!mounted) return;
      setState(() {
        _step = _Step.stopped;
        _link = null;
      });
    } catch (error) {
      ChorusHaptics.failed();
      if (!mounted) return;
      setState(() {
        _step = _Step.shared;
        _error = error is SharingFailed
            ? error.message
            : 'The link could not be stopped. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sync = widget.sync;
    return ListenableBuilder(
      listenable: Listenable.merge([?sync]),
      builder: (context, _) {
        final offline =
            sync != null &&
            (sync.workingOffline || sync.state == SyncState.offline);
        final board = widget.board.name;
        final link = _link;
        final Widget result = switch (_step) {
          _Step.ready => const SizedBox.shrink(key: ValueKey('ready')),
          _Step.making => const LinkLoading(
            key: ValueKey('making'),
            message: 'Making the link…',
          ),
          _Step.shared || _Step.stopping when link != null => Column(
            key: const ValueKey('shared'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FeatureHeading('The link'),
              LinkPanel(
                url: link.url,
                onShare: widget.onShare,
                shareTitle: "$_child's board",
                shareText:
                    "$_child's board. Tap a word to hear it. The link works "
                    'until ${featureDay(context, link.expiresAt.toLocal())}.',
                footnote:
                    'Opens until '
                    '${featureDay(context, link.expiresAt.toLocal())}',
              ),
            ],
          ),
          _ => const Padding(
            key: ValueKey('stopped'),
            padding: EdgeInsets.only(top: 16),
            child: FeatureNote(
              icon: Icons.link_off_rounded,
              message:
                  'You stopped sharing. The link no longer opens, on any '
                  'phone.',
            ),
          ),
        };
        return FeaturePage(
          title: 'Share a view-only board',
          content: [
            Text(
              'For a babysitter, a grandparent or anyone looking after '
              '$_child for a while. They open the link on their phone, with '
              'no account, and tap the words to hear them.',
            ),
            const FeatureHeading('What they get'),
            FeatureFact(
              icon: Icons.grid_view_rounded,
              text:
                  'The words on "$board" as they are on this device now, '
                  "with their colours and $_child's name.",
            ),
            const FeatureFact(
              icon: Icons.edit_off_rounded,
              text:
                  'They cannot change anything. Words added later are not '
                  'on it: make a new link to share them.',
            ),
            const FeatureFact(
              icon: Icons.no_photography_outlined,
              text:
                  'No photos and no recordings. The browser speaks the '
                  'words.',
            ),
            const FeatureFact(
              icon: Icons.schedule_rounded,
              text:
                  'The link stops opening after 7 days, or as soon as you '
                  'stop sharing.',
            ),
            if (offline && _step != _Step.shared) ...[
              const SizedBox(height: 16),
              FeatureNote(
                icon: Icons.cloud_off_rounded,
                message: sync.workingOffline
                    ? 'This device is set to work offline. Making a link '
                          'needs a connection.'
                    : 'This device is offline. Making a link needs a '
                          'connection.',
              ),
            ],
            KeyedSubtree(
              key: _resultKey,
              child: FeatureSwitcher(child: result),
            ),
            if (_error case final error?) ...[
              const SizedBox(height: 16),
              FeatureNote(
                icon: Icons.error_outline_rounded,
                message: error,
                alert: true,
              ),
            ],
          ],
          actions: [
            if (_step == _Step.shared || _step == _Step.stopping) ...[
              OutlinedButton.icon(
                onPressed: _step == _Step.shared ? _stop : null,
                icon: const Icon(Icons.link_off_rounded),
                label: Text(
                  _step == _Step.stopping ? 'Stopping…' : stopSharingLabel,
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Done'),
              ),
            ] else
              FilledButton.icon(
                onPressed: _step == _Step.making ? null : _make,
                icon: const Icon(Icons.link_rounded),
                label: Text(switch (_step) {
                  _Step.making => 'Making the link…',
                  _Step.stopped => 'Make a new link',
                  _ => makeViewOnlyLinkLabel,
                }),
              ),
          ],
        );
      },
    );
  }
}
