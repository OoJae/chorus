/// "Word log": what the opt-in log keeps, the guardian's switch, and
/// deleting it.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../brand/haptics.dart';
import '../contracts.dart';
import '../contracts_wordlog.dart';
import 'feature_page.dart';
import 'this_week_screen.dart';

/// The label of the guardian's switch.
const String keepWordLogLabel = 'Keep a word log';

/// The label of the button that deletes the log.
const String deleteWordLogLabel = 'Delete the word log';

/// Says exactly what the word log keeps, and lets a guardian turn it on or
/// off and delete it. Everyone else sees whether it is on.
///
/// With a [summary] and a [store], "See this week" opens [ThisWeekScreen]
/// for the guardians and therapists who may see it.
class WordLogScreen extends StatefulWidget {
  const WordLogScreen({
    super.key,
    required this.log,
    required this.childName,
    this.summary,
    this.store,
    this.sync,
  });

  final WordLog log;
  final String childName;

  /// "This week", when this adult may see it.
  final WeekSummarySource? summary;

  /// The circle's boards: the adult's role, and the colours of the words in
  /// "This week".
  final BoardStore? store;

  /// Says whether the device is offline, so the screen can say why a change
  /// would fail before it is tried.
  final SyncStatus? sync;

  @override
  State<WordLogScreen> createState() => _WordLogScreenState();
}

class _WordLogScreenState extends State<WordLogScreen> {
  bool _busy = false;
  String? _error;

  String get _child => widget.childName;

  bool get _mayOpenWeek {
    final role = widget.store?.role;
    return widget.summary != null &&
        widget.store != null &&
        (role == CircleRole.guardian || role == CircleRole.therapist);
  }

  Future<void> _setEnabled(bool value) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.log.setEnabled(value);
    } catch (error) {
      ChorusHaptics.failed();
      if (mounted) {
        setState(
          () => _error = _messageOf(
            error,
            value
                ? 'The word log could not be turned on. Check the connection '
                      'and try again.'
                : 'The word log could not be turned off. Check the '
                      'connection and try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    if (_busy) return;
    final staysOn = widget.log.enabled
        ? ' The log stays on and starts again from now.'
        : '';
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete the word log?'),
        content: Text(
          'Every word noted for $_child is removed from the server, with '
          'any waiting on this device. This cannot be undone.$staysOn',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(deleteWordLogLabel),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.log.deleteAll();
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('The word log was deleted.')),
      );
    } catch (error) {
      ChorusHaptics.failed();
      if (mounted) {
        setState(
          () => _error = _messageOf(
            error,
            'The word log could not be deleted. Check the connection and '
            'try again. Nothing was removed.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openWeek() {
    final summary = widget.summary;
    final store = widget.store;
    if (summary == null || store == null) return;
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ThisWeekScreen(
            source: summary,
            childName: _child,
            log: widget.log,
            tiles: store.tiles,
            role: store.role,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sync = widget.sync;
    return ListenableBuilder(
      listenable: Listenable.merge([widget.log, ?sync]),
      builder: (context, _) {
        final log = widget.log;
        final offline =
            sync != null &&
            (sync.workingOffline || sync.state == SyncState.offline);
        return FeaturePage(
          title: 'Word log',
          content: [
            Text(
              "When the word log is on, $_child's board notes each word "
              '$_child taps, and when. The adults who plan $_child\'s words '
              'see it as "This week".',
            ),
            const FeatureHeading('What is kept'),
            const FeatureFact(
              icon: Icons.check_rounded,
              text: 'Which word was tapped, and when.',
            ),
            const FeatureFact(
              icon: Icons.block_rounded,
              text: 'Never sentences, and never who was there.',
            ),
            const FeatureFact(
              icon: Icons.cloud_outlined,
              text:
                  'It is kept on the server, for this circle only. Words '
                  'tapped with no signal wait on the device and are sent '
                  'later.',
            ),
            const FeatureFact(
              icon: Icons.delete_outline_rounded,
              text: 'A guardian can delete the whole log at any time.',
            ),
            FeatureFact(
              icon: Icons.lock_outline_rounded,
              text:
                  "Private on $_child's board pauses it on that device until "
                  'Chorus is closed.',
            ),
            if (log.pending > 0) ...[
              const SizedBox(height: 12),
              StatusText(
                '${countOf(log.pending, 'word')} waiting on this device to '
                'be sent',
              ),
            ],
            if (offline && log.canChange) ...[
              const SizedBox(height: 16),
              FeatureNote(
                icon: Icons.cloud_off_rounded,
                message: sync.workingOffline
                    ? 'This device is set to work offline. Turning the log '
                          'on or off, and deleting it, need a connection.'
                    : 'This device is offline. Turning the log on or off, '
                          'and deleting it, need a connection.',
              ),
            ],
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
            if (log.canChange)
              _LogSwitch(
                on: log.enabled,
                busy: _busy,
                childName: _child,
                onChanged: _setEnabled,
              )
            else
              _LogState(on: log.enabled),
            if (_mayOpenWeek)
              FilledButton.icon(
                onPressed: _openWeek,
                icon: const Icon(Icons.calendar_view_week_rounded),
                label: const Text('See this week'),
              ),
            if (log.canChange)
              OutlinedButton.icon(
                onPressed: _busy ? null : _delete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text(deleteWordLogLabel),
              ),
          ],
        );
      },
    );
  }
}

/// The guardian's switch, with what it means now underneath.
class _LogSwitch extends StatelessWidget {
  const _LogSwitch({
    required this.on,
    required this.busy,
    required this.childName,
    required this.onChanged,
  });

  final bool on;
  final bool busy;
  final String childName;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          keepWordLogLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          busy
              ? 'Asking the server…'
              : on
              ? "On for $childName's board, on every device in the circle."
              : 'Off. Words noted before stay until you delete them.',
        ),
        value: on,
        onChanged: busy ? null : onChanged,
      ),
    );
  }
}

/// Whether the log is on, for an adult who may not change it.
class _LogState extends StatelessWidget {
  const _LogState({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(
                on ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    on ? 'The word log is on.' : 'The word log is off.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Text('Only a guardian can turn it on or off.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The words a [StateError] carries for the adult, or [fallback].
String _messageOf(Object error, String fallback) {
  if (error is StateError) {
    final message = error.message.trim();
    if (message.isNotEmpty) return message;
  }
  return fallback;
}
