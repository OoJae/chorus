/// "What changed": who added, renamed or put away which word, newest first,
/// grouped by day, each with one tap to undo.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../brand/haptics.dart';
import '../brand/tokens.dart';
import '../contracts.dart';
import '../contracts_activity.dart';
import '../contracts_edits.dart';
import '../editor/tray_panel.dart' show notSavedMessage;
import 'activity_text.dart';

/// The feed of one circle. Rebuilds whenever [store] changes. Undo shows
/// only for an editor, on a store that is also an [ActivityUndo], and only
/// on a line whose change is still the word's current state.
///
/// Opening it counts as looking: [seen] is told now.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({
    super.key,
    required this.store,
    this.seen,
    this.sitterTaps,
    this.now,
  });

  final BoardStore store;
  final ActivitySeen? seen;

  /// Words a sitter tapped on the view-only page, or null where the circle
  /// has none to show.
  final Future<List<SitterTap>> Function()? sitterTaps;

  /// The clock, for tests.
  final DateTime Function()? now;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  List<SitterTap> _taps = const [];
  final Set<String> _undoing = {};

  @override
  void initState() {
    super.initState();
    final now = (widget.now ?? DateTime.now)().toUtc();
    unawaited(widget.seen?.markLooked(now));
    unawaited(_loadTaps());
  }

  Future<void> _loadTaps() async {
    final load = widget.sitterTaps;
    if (load == null) return;
    try {
      final taps = await load();
      if (mounted) setState(() => _taps = taps);
    } on Object {
      // The sitter's words need the network; the feed works without them.
    }
  }

  List<ActivityEntry> _entries() {
    final store = widget.store;
    final edits = store is EditLog ? (store as EditLog).edits : <EditFacts>[];
    final entries = activityOf(store.tiles, edits);
    if (_taps.isEmpty) return entries;
    return [
      ...entries,
      for (final (i, tap) in _taps.indexed)
        ActivityEntry(
          id: 'tap:$i',
          kind: ActivityKind.sitterTap,
          tileId: '',
          label: tap.label,
          actorId: '',
          actorName: 'Sitter',
          at: tap.at,
        ),
    ]..sort((a, b) => b.at.compareTo(a.at));
  }

  Future<void> _undo(ActivityEntry entry, ActivityUndo undo) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _undoing.add(entry.id));
    try {
      final outcome = await undo.undo(entry);
      ChorusHaptics.wordPlaced();
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            outcome == UndoOutcome.waiting
                ? undoWaitingMessage(entry.label)
                : undoneMessage,
          ),
        ),
      );
    } on Object {
      ChorusHaptics.failed();
      messenger?.showSnackBar(const SnackBar(content: Text(notSavedMessage)));
    } finally {
      if (mounted) setState(() => _undoing.remove(entry.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    return Scaffold(
      backgroundColor: colors.card,
      appBar: AppBar(title: const Text(activityTitle)),
      body: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final store = widget.store;
          final entries = _entries();
          if (entries.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(ChorusSpace.marginPhone),
              child: Text(
                activityEmpty,
                style: ChorusType.body.copyWith(color: colors.inkMuted),
              ),
            );
          }
          final now = (widget.now ?? DateTime.now)();
          final undo = store is ActivityUndo && store.role.canEdit
              ? store as ActivityUndo
              : null;
          final rows = <Widget>[];
          String? day;
          for (final entry in entries) {
            final heading = dayHeading(entry.at, now);
            if (heading != day) {
              day = heading;
              rows.add(_DayHeading(heading));
            }
            final plan = undo == null || entry.kind == ActivityKind.sitterTap
                ? null
                : undoPlanOf(entry, store.tiles);
            rows.add(
              _ActivityRow(
                key: ValueKey(entry.id),
                entry: entry,
                onUndo: plan == null || _undoing.contains(entry.id)
                    ? null
                    : () => _undo(entry, undo!),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: ChorusSpace.marginPhone,
              vertical: 12,
            ),
            children: rows,
          );
        },
      ),
    );
  }
}

class _DayHeading extends StatelessWidget {
  const _DayHeading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 4),
        child: Text(text, style: ChorusType.status.copyWith(color: colors.ink)),
      ),
    );
  }
}

/// One change: the adult's initial, the sentence and time, and Undo.
class _ActivityRow extends StatelessWidget {
  const _ActivityRow({super.key, required this.entry, this.onUndo});

  final ActivityEntry entry;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final line = activityLine(entry);
    final time = clockOf(entry.at);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Row(
        children: [
          ExcludeSemantics(child: ActorBadge(name: actorOf(entry))),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: line),
                  TextSpan(
                    text: ' · $time',
                    style: TextStyle(color: colors.inkMuted),
                  ),
                ],
              ),
              style: ChorusType.body.copyWith(color: colors.ink),
            ),
          ),
          if (onUndo != null)
            TextButton(
              onPressed: onUndo,
              child: Text(undoLabel, semanticsLabel: '$undoLabel: $line'),
            ),
        ],
      ),
    );
  }
}

/// A neutral round badge with an adult's initial: ink on card, never a word
/// colour.
class ActorBadge extends StatelessWidget {
  const ActorBadge({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: colors.line, width: 1.5),
      ),
      child: Text(
        initialOf(name),
        style: ChorusType.label.copyWith(color: colors.ink, fontSize: 15),
      ),
    );
  }
}

/// The home banner, "Since you last looked: 3 changes", shown only while
/// there are changes newer than the last look on this device. Tapping it
/// opens the feed through [onOpen].
class ActivityBanner extends StatefulWidget {
  const ActivityBanner({
    super.key,
    required this.store,
    required this.seen,
    required this.onOpen,
  });

  final BoardStore store;
  final ActivitySeen seen;
  final VoidCallback onOpen;

  @override
  State<ActivityBanner> createState() => _ActivityBannerState();
}

class _ActivityBannerState extends State<ActivityBanner> {
  DateTime? _since;
  bool _read = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    DateTime? since;
    try {
      since = await widget.seen.lastLooked();
    } on Object {
      since = null;
    }
    if (!mounted) return;
    setState(() {
      _since = since;
      _read = true;
    });
  }

  void _open() {
    widget.onOpen();
    // The feed records the look; read it again when the adult comes back.
    setState(() => _since = DateTime.now().toUtc());
  }

  @override
  Widget build(BuildContext context) {
    if (!_read) return const SizedBox.shrink();
    final store = widget.store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final edits = store is EditLog
            ? (store as EditLog).edits
            : <EditFacts>[];
        final entries = activityOf(store.tiles, edits);
        // Never opened here: nothing to compare with, so no banner until
        // the first look.
        final since = _since;
        if (since == null && entries.isEmpty) return const SizedBox.shrink();
        final count = changesSince(entries, since);
        if (count == 0) return const SizedBox.shrink();
        final colors = ChorusColors.of(context);
        return Semantics(
          button: true,
          label: sinceLastLookedText(count),
          onTap: _open,
          excludeSemantics: true,
          child: Material(
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ChorusSpace.buttonRadius),
              side: BorderSide(color: colors.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _open,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 12),
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, color: colors.ink),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        sinceLastLookedText(count),
                        style: ChorusType.body.copyWith(color: colors.ink),
                      ),
                    ),
                    TextButton(
                      onPressed: _open,
                      child: const Text(sinceLastLookedAction),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
