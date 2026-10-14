/// The Thursday nudge on home: a kind word when a focus word has not been
/// modelled yet this week.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../contracts_modelling.dart';
import '../features/flags/w6.dart';
import '../home/home_actions.dart';

/// Tooltip of the button that hides the nudge on this device.
const String dismissNudgeLabel = 'Hide this note';

/// Home's note for this week's nudge, when there is one. Draws nothing
/// while it loads, when there is none, and once dismissed here.
class FocusNudgeNoteView extends StatefulWidget {
  const FocusNudgeNoteView({super.key, required this.modelling});

  final ModellingSource modelling;

  @override
  State<FocusNudgeNoteView> createState() => _FocusNudgeNoteViewState();
}

class _FocusNudgeNoteViewState extends State<FocusNudgeNoteView> {
  FocusNudgeNote? _note;

  @override
  void initState() {
    super.initState();
    if (focusNudgeEnabled) unawaited(_load());
  }

  @override
  void didUpdateWidget(FocusNudgeNoteView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.modelling, widget.modelling) &&
        focusNudgeEnabled) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    FocusNudgeNote? note;
    try {
      note = await widget.modelling.nudge();
    } catch (_) {
      note = null;
    }
    if (mounted) setState(() => _note = note);
  }

  void _dismiss(FocusNudgeNote note) {
    setState(() => _note = null);
    unawaited(
      Future<void>.sync(
        () => widget.modelling.dismissNudge(note),
      ).then<void>((_) {}, onError: (Object _) {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final note = _note;
    if (!focusNudgeEnabled || note == null) return const SizedBox.shrink();
    return HomeNote(
      icon: const Icon(Icons.push_pin_outlined),
      message: focusNudgeMessage(note),
      action: IconButton(
        tooltip: dismissNudgeLabel,
        onPressed: () => _dismiss(note),
        icon: const Icon(Icons.close_rounded),
      ),
    );
  }
}
