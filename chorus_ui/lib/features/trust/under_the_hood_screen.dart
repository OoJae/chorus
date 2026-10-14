/// "Under the hood": what the replica on this device holds, read-only, for
/// anyone curious about how Chorus keeps devices in step. Technical words
/// are welcome here.
library;

import 'package:flutter/material.dart';

import '../../brand/tokens.dart';
import '../../contracts_trust.dart';
import '../feature_page.dart';
import 'who_is_up_to_date_screen.dart' show agoLabel;

/// The home entry and the screen's title.
const String underTheHoodTitle = 'Under the hood';

/// Above the facts.
const String underTheHoodIntro =
    'Chorus keeps a full replica of the board in SQLite on this device. The '
    'serverpod_offline_sync module merges it with PostgreSQL on the server, '
    'row by row, field by field, with hybrid logical clocks.';

/// When the replica could not be read.
const String underTheHoodFailed = 'The replica could not be read just now.';

/// Under the parked words heading when there are none.
const String underTheHoodNoneParked =
    'None. No two words have claimed the same cell.';

/// The screen.
class UnderTheHoodScreen extends StatefulWidget {
  const UnderTheHoodScreen({super.key, required this.inspector});

  final ReplicaInspector inspector;

  @override
  State<UnderTheHoodScreen> createState() => _UnderTheHoodScreenState();
}

class _UnderTheHoodScreenState extends State<UnderTheHoodScreen> {
  late Future<ReplicaReport> _report = widget.inspector.inspect();

  void _refresh() {
    final next = widget.inspector.inspect();
    setState(() {
      _report = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ReplicaReport>(
      future: _report,
      builder: (context, snapshot) {
        final report = snapshot.data;
        return FeaturePage(
          title: underTheHoodTitle,
          barActions: [
            IconButton(
              tooltip: 'Read again',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          content: [
            const Text(underTheHoodIntro),
            if (snapshot.hasError)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: FeatureNote(
                  icon: Icons.storage_rounded,
                  message: underTheHoodFailed,
                ),
              )
            else if (report == null)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator(),
              )
            else
              ..._facts(context, report),
          ],
        );
      },
    );
  }

  List<Widget> _facts(BuildContext context, ReplicaReport report) {
    final waiting = report.unsentChanges;
    final last = report.lastSyncAt;
    return [
      const FeatureHeading('Rows in the replica'),
      _Row('board', '${report.boards}'),
      _Row('tile', '${report.tiles}'),
      _Row('tile_edit', '${report.tileEdits}'),
      const FeatureHeading('Sync'),
      _Row(
        'Changes waiting to send',
        !report.hasUnsent
            ? '0'
            : (waiting == null ? 'some, from before a restart' : '$waiting'),
      ),
      _Row('Last successful sync', last == null ? 'not yet' : agoLabel(last)),
      _Row('Circle space id', report.circleSpaceId),
      _Row('serverpod_offline_sync', report.moduleVersion),
      _Row('Server', report.serverAddress),
      const FeatureHeading('Words parked by the sync engine'),
      if (report.parked.isEmpty)
        const Text(underTheHoodNoneParked)
      else
        for (final word in report.parked)
          _Row('"${word.label}" by ${word.byName}', word.cellKey),
    ];
  }
}

/// A name and its value, the value in the status face.
class _Row extends StatelessWidget {
  const _Row(this.name, this.value);

  final String name;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: ChorusType.body.copyWith(color: colors.ink)),
            SelectableText(
              value,
              style: ChorusType.status.copyWith(color: colors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
