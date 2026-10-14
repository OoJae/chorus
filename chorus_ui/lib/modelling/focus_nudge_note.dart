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

/// The note home shows for [modelling]'s nudge, or null when there is none
/// (or the flag is off), so home adds nothing at all.
Widget? focusNudgeNoteFor(ModellingSource? modelling) {
  if (!focusNudgeEnabled || modelling == null) return null;
  final note = modelling.shownNudge;
  if (note == null) return null;
  return FocusNudgeNoteView(modelling: modelling, note: note);
}

/// Home's note for this week's nudge, with a button that hides it on this
/// device.
class FocusNudgeNoteView extends StatelessWidget {
  const FocusNudgeNoteView({
    super.key,
    required this.modelling,
    required this.note,
  });

  final ModellingSource modelling;
  final FocusNudgeNote note;

  @override
  Widget build(BuildContext context) {
    return HomeNote(
      icon: const Icon(Icons.push_pin_outlined),
      message: focusNudgeMessage(note),
      action: IconButton(
        tooltip: dismissNudgeLabel,
        onPressed: () => unawaited(
          Future<void>.sync(
            () => modelling.dismissNudge(note),
          ).then<void>((_) {}, onError: (Object _) {}),
        ),
        icon: const Icon(Icons.close_rounded),
      ),
    );
  }
}
