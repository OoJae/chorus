/// "This week"'s modelling parts: modelled versus said per word, and the
/// one-page progress report.
library;

import 'dart:async';

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';

import '../brand/tokens.dart';
import '../contracts_modelling.dart';
import '../features/feature_page.dart';
import '../features/flags/w6.dart';

/// Heading of the modelled words in "This week".
const String modelledHeading = 'Modelled and said';

/// Tooltip and title of the progress report action.
const String progressReportLabel = 'Progress report';

/// Shown while the report is made.
const String progressReportMaking = 'Making the report…';

/// Shown when it could not be made.
const String progressReportFailed =
    'The report could not be made. It needs a connection: try again when '
    'this device is online.';

/// What the report is, beside its link.
const String progressReportExplain =
    'One page of counts for this week: how many words, which were new, what '
    'was modelled and said, and how the focus words are going. No sentences '
    'are kept. Anyone with the link can open it, and it stops working after '
    '30 days.';

/// "go" with "modelled 14 · said 3", for the words an adult modelled this
/// week. Draws nothing when the flag is off or nothing was modelled.
class ModelledSection extends StatelessWidget {
  const ModelledSection({super.key, required this.week});

  final WeekSummary week;

  @override
  Widget build(BuildContext context) {
    if (!modelledWordsEnabled || week.modelled.isEmpty) {
      return const SizedBox.shrink();
    }
    final colors = ChorusColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const FeatureHeading(modelledHeading),
        for (final row in week.modelled)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    row.label,
                    style: ChorusType.label.copyWith(color: colors.ink),
                  ),
                ),
                Text(
                  modelledLine(row.modelled, row.said),
                  style: ChorusType.body.copyWith(color: colors.inkMuted),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The "Progress report" action for the bar of "This week": makes the
/// report and opens it, or shows its link where it cannot open one. Draws
/// nothing when the flag is off or the adult may not make one.
class ProgressReportAction extends StatelessWidget {
  const ProgressReportAction({super.key, required this.modelling});

  final ModellingSource modelling;

  Future<void> _make(BuildContext context) async {
    final link = Future<String>.sync(modelling.makeProgressReport)
      // The dialog reads the failure; this only keeps it from being
      // reported before the dialog is up.
      ..ignore();
    await showDialog<void>(
      context: context,
      builder: (_) => _ReportDialog(link: link, modelling: modelling),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!progressReportEnabled || !modelling.canPinFocus) {
      return const SizedBox.shrink();
    }
    return IconButton(
      tooltip: progressReportLabel,
      onPressed: () => _make(context),
      icon: const Icon(Icons.summarize_outlined),
    );
  }
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog({required this.link, required this.modelling});

  final Future<String> link;
  final ModellingSource modelling;

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  String? _url;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_wait());
  }

  Future<void> _wait() async {
    try {
      final url = await widget.link;
      if (!mounted) return;
      setState(() => _url = url);
      // Opened straight away where the device can.
      await widget.modelling.openLink(url);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _url;
    return AlertDialog(
      title: const Text(progressReportLabel),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: _failed
            ? const Text(progressReportFailed)
            : url == null
            ? const Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  SizedBox(width: 16),
                  Expanded(child: Text(progressReportMaking)),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(progressReportExplain),
                  const SizedBox(height: 12),
                  LinkPanel(
                    url: Uri.parse(url),
                    shareText: progressReportLabel,
                    shareTitle: progressReportLabel,
                  ),
                ],
              ),
      ),
      actions: [
        if (url != null)
          TextButton(
            onPressed: () => widget.modelling.openLink(url),
            child: const Text('Open'),
          ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(url == null && !_failed ? 'Cancel' : 'Done'),
        ),
      ],
    );
  }
}
