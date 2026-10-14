/// "Export as Open Board Format": a link to the board as an .obf file.
library;

import 'dart:async';

import 'package:chorus_shared/chorus_shared.dart' show BoardFacts;
import 'package:flutter/material.dart';

import '../brand/haptics.dart';
import '../contracts.dart';
import '../contracts_sharing.dart';
import 'feature_page.dart';

/// How long an export link opens. The file is made from a stored copy of
/// the board, which the server keeps as long as a paper copy.
const Duration obfExportLinkLasts = Duration(days: 30);

/// The label of the button that makes the file.
const String makeObfFileLabel = 'Make the file';

/// Explains what an .obf file is and holds, makes it, and shows the link
/// to download it with Copy and Share.
///
/// The file is made only when asked: opening the screen sends nothing.
class ExportObfScreen extends StatefulWidget {
  const ExportObfScreen({
    super.key,
    required this.sharing,
    required this.board,
    required this.childName,
    this.onShare,
    this.sync,
  });

  final BoardSharing sharing;

  /// The board to export.
  final BoardFacts board;
  final String childName;

  /// The device's share sheet; without it the link has Copy alone.
  final ShareLinkAction? onShare;

  /// Says whether the device is offline, so the screen can say why making
  /// the file would fail before it is tried.
  final SyncStatus? sync;

  @override
  State<ExportObfScreen> createState() => _ExportObfScreenState();
}

class _ExportObfScreenState extends State<ExportObfScreen> {
  final GlobalKey _resultKey = GlobalKey();
  bool _making = false;
  Uri? _url;
  String? _error;

  Future<void> _make() async {
    setState(() {
      _making = true;
      _error = null;
    });
    try {
      final url = await widget.sharing.exportObf(widget.board);
      if (!mounted) return;
      setState(() => _url = url);
      revealAfterFrame(_resultKey);
    } catch (error) {
      ChorusHaptics.failed();
      if (!mounted) return;
      setState(
        () => _error = error is SharingFailed
            ? error.message
            : 'The file could not be made. Try again.',
      );
    } finally {
      if (mounted) setState(() => _making = false);
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
        final url = _url;
        final days = obfExportLinkLasts.inDays;
        final Widget result = _making
            ? const LinkLoading(
                key: ValueKey('making'),
                message: 'Making the file…',
              )
            : url == null
            ? const SizedBox.shrink(key: ValueKey('ready'))
            : Column(
                key: const ValueKey('made'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FeatureHeading('The link'),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Open it on the device that has the other app, and '
                      'the file downloads. Then open the file in that app.',
                    ),
                  ),
                  LinkPanel(
                    url: url,
                    onShare: widget.onShare,
                    shareTitle: '$board.obf',
                    shareText:
                        "${widget.childName}'s board \"$board\" as an Open "
                        'Board Format file, for another AAC app.',
                    footnote: 'Works for $days days',
                  ),
                ],
              );
        return FeaturePage(
          title: 'Export as Open Board Format',
          content: [
            const Text(
              'Open Board Format (.obf) is a kind of file that other AAC '
              'apps can open. Use it to take a board from Chorus into '
              'another app.',
            ),
            const FeatureHeading('What the file holds'),
            FeatureFact(
              icon: Icons.grid_view_rounded,
              text:
                  'The words on "$board", each in its place, with what it '
                  'says and its colour.',
            ),
            const FeatureFact(
              icon: Icons.no_photography_outlined,
              text: 'No photos and no recordings. They stay in Chorus.',
            ),
            FeatureFact(
              icon: Icons.schedule_rounded,
              text:
                  'Anyone with the link can download the file for $days '
                  'days.',
            ),
            if (offline && url == null) ...[
              const SizedBox(height: 16),
              FeatureNote(
                icon: Icons.cloud_off_rounded,
                message: sync.workingOffline
                    ? 'This device is set to work offline. Making the file '
                          'needs a connection.'
                    : 'This device is offline. Making the file needs a '
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
            if (url != null && !_making)
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Done'),
              )
            else
              FilledButton.icon(
                onPressed: _making ? null : _make,
                icon: const Icon(Icons.file_download_outlined),
                label: Text(_making ? 'Making the file…' : makeObfFileLabel),
              ),
          ],
        );
      },
    );
  }
}
