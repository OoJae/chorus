/// "This week": the words the child used, from the word log.
library;

import 'dart:async';

import 'package:chorus_shared/chorus_shared.dart' show TileFacts;
import 'package:flutter/material.dart';

import '../brand/tokens.dart';
import '../contracts.dart';
import '../contracts_modelling.dart';
import '../contracts_wordlog.dart';
import '../modelling/week_modelling.dart';
import 'feature_page.dart';

/// The week so far: the most used words as laminated tiles with their
/// counts, the words used for the first time, the words added and the
/// words not used yet.
///
/// While it loads, grey tiles hold the space. A log that is off, a week
/// with nothing in it, a role that may not see it and a week that could not
/// be had (no connection) each say so in plain words.
class ThisWeekScreen extends StatefulWidget {
  const ThisWeekScreen({
    super.key,
    required this.source,
    required this.childName,
    this.log,
    this.tiles = const [],
    this.role,
    this.onOpenWordLog,
    this.modelling,
  });

  final WeekSummarySource source;

  /// Offers the progress report to guardians and therapists; null leaves it
  /// out.
  final ModellingSource? modelling;
  final String childName;

  /// The circle's word log, to tell "off" from "could not be had".
  final WordLog? log;

  /// The circle's words, which give each word in the week its colour.
  final List<TileFacts> tiles;

  /// The adult's role. Only guardians and therapists may see the week.
  final CircleRole? role;

  /// Opens "Word log", offered when the log is off.
  final VoidCallback? onOpenWordLog;

  /// How many "not used yet" words show before "Show all".
  static const int notUsedShown = 12;

  @override
  State<ThisWeekScreen> createState() => _ThisWeekScreenState();
}

enum _Phase { loading, ready, failed }

class _ThisWeekScreenState extends State<ThisWeekScreen> {
  _Phase _phase = _Phase.loading;
  WeekSummary? _week;
  bool _allNotUsed = false;
  int _asked = 0;

  bool get _mayView {
    final role = widget.role;
    return role == null ||
        role == CircleRole.guardian ||
        role == CircleRole.therapist;
  }

  bool get _logOff => widget.log?.enabled == false;

  /// Whether the log was off when last looked at, so only a switch from
  /// off to on loads the week, not every word the log notes.
  bool _wasOff = false;

  @override
  void initState() {
    super.initState();
    _wasOff = _logOff;
    widget.log?.addListener(_onLog);
    if (_mayView && !_logOff) unawaited(_load());
  }

  @override
  void didUpdateWidget(ThisWeekScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.log != widget.log) {
      oldWidget.log?.removeListener(_onLog);
      widget.log?.addListener(_onLog);
      _wasOff = _logOff;
    }
  }

  @override
  void dispose() {
    widget.log?.removeListener(_onLog);
    super.dispose();
  }

  /// A log turned on from here or elsewhere: load the week. Turned off: say
  /// so.
  void _onLog() {
    if (!mounted) return;
    final off = _logOff;
    final turnedOn = _wasOff && !off;
    final turned = _wasOff != off;
    _wasOff = off;
    if (turnedOn && _mayView) {
      unawaited(_load());
    } else if (turned) {
      setState(() {});
    }
  }

  Future<void> _load() async {
    final ask = ++_asked;
    setState(() => _phase = _Phase.loading);
    WeekSummary? week;
    try {
      week = await widget.source.thisWeek();
    } catch (_) {
      week = null;
    }
    if (!mounted || ask != _asked) return;
    setState(() {
      _week = week;
      _phase = week == null ? _Phase.failed : _Phase.ready;
    });
  }

  /// Each word's colour family, by its label as the week names it.
  Map<String, TileFamily> _families() {
    final families = <String, TileFamily>{};
    // Words still on a board first, so a word's live colour wins.
    for (final archived in [false, true]) {
      for (final tile in widget.tiles) {
        if (tile.archived != archived) continue;
        families.putIfAbsent(
          tile.label.trim().toLowerCase(),
          () => TileFamily.forKey(tile.colorKey),
        );
      }
    }
    return families;
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.childName;
    final Widget body;
    final List<Widget> actions;
    var canRefresh = false;

    if (!_mayView) {
      body = _Empty(
        key: const ValueKey('not-allowed'),
        headline: 'This week is for guardians and therapists.',
        message:
            'It shows which words $child used. Ask a guardian if you would '
            'like to see it.',
      );
      actions = const [];
    } else if (_logOff) {
      body = _Empty(
        key: const ValueKey('off'),
        headline: 'The word log is off.',
        message:
            'Turn it on in Word log to see which words $child uses each '
            'week. Nothing is noted while it is off.',
      );
      actions = [
        if (widget.onOpenWordLog case final open?)
          FilledButton.icon(
            onPressed: open,
            icon: const Icon(Icons.toggle_on_rounded),
            label: const Text('Open Word log'),
          ),
      ];
    } else {
      switch (_phase) {
        case _Phase.loading:
          body = const _Loading(key: ValueKey('loading'));
          actions = const [];
        case _Phase.failed:
          body = Column(
            key: const ValueKey('failed'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FeatureNote(
                icon: Icons.cloud_off_rounded,
                alert: true,
                message:
                    'This week could not be loaded. It is worked out on the '
                    'server, so it needs a connection.',
              ),
            ],
          );
          actions = [
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ];
        case _Phase.ready:
          canRefresh = true;
          body = _Week(
            key: const ValueKey('ready'),
            week: _week!,
            childName: child,
            families: _families(),
            allNotUsed: _allNotUsed,
            onShowAllNotUsed: () => setState(() => _allNotUsed = true),
          );
          actions = const [];
      }
    }

    return FeaturePage(
      title: 'This week',
      barActions: [
        if (widget.modelling case final modelling? when _mayView)
          ProgressReportAction(modelling: modelling),
        if (canRefresh)
          IconButton(
            onPressed: _load,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
          ),
      ],
      actions: actions,
      content: [FeatureSwitcher(child: body)],
    );
  }
}

/// The week, section by section. Sections with nothing in them are left
/// out; a week with no taps says so first.
class _Week extends StatelessWidget {
  const _Week({
    super.key,
    required this.week,
    required this.childName,
    required this.families,
    required this.allNotUsed,
    required this.onShowAllNotUsed,
  });

  final WeekSummary week;
  final String childName;
  final Map<String, TileFamily> families;
  final bool allNotUsed;
  final VoidCallback onShowAllNotUsed;

  TileFamily _family(String label) =>
      families[label.trim().toLowerCase()] ?? TileFamily.other;

  Widget _words(List<String> labels) => Wrap(
    spacing: ChorusSpace.targetGap,
    runSpacing: ChorusSpace.targetGap,
    children: [
      for (final label in labels)
        WordTile(label: label, family: _family(label)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final lastDay = week.weekEnd.subtract(const Duration(days: 1));
    final notUsed = week.notUsedYet;
    final shown = allNotUsed || notUsed.length <= ThisWeekScreen.notUsedShown
        ? notUsed
        : notUsed.take(ThisWeekScreen.notUsedShown).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatusText(
          '${featureDay(context, week.weekStart)} to '
          '${featureDay(context, lastDay)}',
        ),
        const SizedBox(height: 4),
        StatusText(
          '${countOf(week.totalUses, 'tap')} · '
          '${countOf(week.wordsUsed, 'word')}',
          color: ChorusColors.of(context).ink,
        ),
        if (week.totalUses == 0) ...[
          const SizedBox(height: 16),
          _Empty(
            headline: 'Nothing tapped yet this week.',
            message:
                'When $childName taps words on the board, they show here '
                'once that device is online.',
          ),
        ],
        if (week.topWords.isNotEmpty) ...[
          const FeatureHeading('Most used'),
          Wrap(
            spacing: ChorusSpace.targetGap,
            runSpacing: ChorusSpace.targetGap,
            children: [
              for (final word in week.topWords)
                WordTile(
                  label: word.label,
                  family: _family(word.label),
                  count: word.count,
                  large: true,
                ),
            ],
          ),
        ],
        // Draws nothing when nothing was modelled.
        ModelledSection(week: week),
        if (week.firstTimeWords.isNotEmpty) ...[
          const FeatureHeading('Used for the first time'),
          _words(week.firstTimeWords),
        ],
        if (week.addedWords.isNotEmpty) ...[
          const FeatureHeading('Added this week'),
          _words(week.addedWords),
        ],
        if (notUsed.isNotEmpty) ...[
          const FeatureHeading('Not used yet'),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('On a board, and not tapped by $childName yet.'),
          ),
          _words(shown),
          if (shown.length < notUsed.length)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: onShowAllNotUsed,
                  child: Text('Show all ${notUsed.length}'),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// A plain empty state: a headline in the display face and a line under it.
class _Empty extends StatelessWidget {
  const _Empty({super.key, required this.headline, required this.message});

  final String headline;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            headline,
            style: Theme.of(context).textTheme.headlineSmall,
            textScaler: ChorusType.displayScaler(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(message),
      ],
    );
  }
}

/// Grey laminated tiles where the week will be.
class _Loading extends StatelessWidget {
  const _Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading this week',
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonTile(width: 200, height: 16, radius: 8),
          const SizedBox(height: 8),
          const SkeletonTile(width: 140, height: 16, radius: 8),
          const SizedBox(height: 32),
          const SkeletonTile(width: 120, height: 20, radius: 8),
          const SizedBox(height: 12),
          Wrap(
            spacing: ChorusSpace.targetGap,
            runSpacing: ChorusSpace.targetGap,
            children: [
              for (var i = 0; i < 6; i++)
                const SkeletonTile(
                  width: WordTile.largeSide,
                  height: WordTile.largeSide,
                ),
            ],
          ),
          const SizedBox(height: 32),
          const SkeletonTile(width: 160, height: 20, radius: 8),
          const SizedBox(height: 12),
          Wrap(
            spacing: ChorusSpace.targetGap,
            runSpacing: ChorusSpace.targetGap,
            children: [
              for (final width in const [72.0, 96.0, 64.0, 88.0, 72.0])
                SkeletonTile(width: width, height: 44),
            ],
          ),
        ],
      ),
    );
  }
}
