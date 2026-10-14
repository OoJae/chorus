/// Choosing the focus words of the week: up to three, each with a one-line
/// modelling tip.
library;

import 'dart:async';

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';

import '../brand/tokens.dart';
import '../contracts.dart';
import '../contracts_modelling.dart';
import '../features/flags/w6.dart';

/// Title of the screen.
const String focusWordsTitle = 'Focus words';

/// What the screen is for.
const String focusWordsIntro =
    'Pick up to three words to model this week. Everyone in the circle sees '
    "a ring on them while editing, and the tip while showing words. The "
    "child's board stays as it is.";

/// Hint of a tip field.
const String focusTipHint = "A tip, like At bath time: 'more bubbles?'";

/// The save button.
const String saveFocusLabel = 'Save focus words';

/// Said once saved.
const String focusSavedMessage = 'Focus words saved for this week.';

/// Said when saving did not work.
const String focusNotSavedMessage =
    'The focus words could not be saved. They need a connection: try again '
    'when this device is online.';

/// Said when three are already chosen.
const String focusFullMessage = 'Three words is the most for one week.';

/// Opens the focus words, when the flag is on and the adult may pin them.
void openFocusWords(
  BuildContext context, {
  required BoardStore store,
  required ModellingSource modelling,
}) {
  if (!focusWordsEnabled || !modelling.canPinFocus) return;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => FocusWordsScreen(store: store, modelling: modelling),
    ),
  );
}

/// The focus words of the week, with a tip each, and the words to pick
/// them from.
class FocusWordsScreen extends StatefulWidget {
  const FocusWordsScreen({
    super.key,
    required this.store,
    required this.modelling,
  });

  final BoardStore store;
  final ModellingSource modelling;

  @override
  State<FocusWordsScreen> createState() => _FocusWordsScreenState();
}

class _FocusWordsScreenState extends State<FocusWordsScreen> {
  late final List<String> _chosen = [
    for (final pin in widget.modelling.focusWords) pin.tileId,
  ];
  late final Map<String, TextEditingController> _tips = {
    for (final pin in widget.modelling.focusWords)
      pin.tileId: TextEditingController(text: pin.tip),
  };
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in _tips.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// The words placed on a board still in use, by label.
  List<TileFacts> _words() {
    final store = widget.store;
    final seen = <String>{};
    final words = <TileFacts>[];
    for (final board in store.boards) {
      if (board.archived) continue;
      for (final tile in gridOf(board.id, store.tiles, store.boards).values) {
        if (seen.add(tile.id)) words.add(tile);
      }
    }
    words.sort(
      (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
    return words;
  }

  void _toggle(TileFacts tile) {
    setState(() {
      if (_chosen.remove(tile.id)) {
        _tips.remove(tile.id)?.dispose();
      } else if (_chosen.length < maxFocusWords) {
        _chosen.add(tile.id);
        _tips[tile.id] = TextEditingController();
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text(focusFullMessage)));
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    var saved = false;
    try {
      await widget.modelling.setFocusWords([
        for (final id in _chosen)
          FocusPin(
            tileId: id,
            tip: _tips[id]!.text
                .trim()
                .characters
                .take(maxFocusTipLength)
                .toString(),
          ),
      ]);
      saved = true;
    } catch (_) {
      saved = false;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(saved ? focusSavedMessage : focusNotSavedMessage),
        ),
      );
    if (saved) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final margin = ChorusSpace.margin(MediaQuery.sizeOf(context).width);
    final words = _words();
    final byId = {for (final tile in widget.store.tiles) tile.id: tile};
    return Scaffold(
      appBar: AppBar(title: const Text(focusWordsTitle)),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(margin, 12, margin, 24),
          children: [
            Text(
              focusWordsIntro,
              style: ChorusType.body.copyWith(color: colors.inkMuted),
            ),
            const SizedBox(height: 16),
            for (final id in _chosen) ...[
              Text(
                byId[id]?.label ?? '',
                style: ChorusType.label.copyWith(color: colors.ink),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _tips[id],
                maxLength: maxFocusTipLength,
                decoration: const InputDecoration(hintText: focusTipHint),
              ),
              const SizedBox(height: 8),
            ],
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.push_pin_rounded),
              label: const Text(saveFocusLabel),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tile in words)
                  FilterChip(
                    label: Text(tile.label),
                    selected: _chosen.contains(tile.id),
                    onSelected: (_) => _toggle(tile),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// [child] with a quiet ring drawn over its edge, taking no space: how the
/// editor marks a focus word. Ink, like the rest of the adult chrome.
class FocusRing extends StatelessWidget {
  const FocusRing({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ink = ChorusColors.of(context).ink;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ChorusSpace.tileRadius),
                border: Border.all(
                  color: ink.withValues(alpha: 0.55),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The ids of [modelling]'s focus words, when focus words are on; empty
/// otherwise.
Set<String> focusIdsOf(ModellingSource? modelling) {
  if (!focusWordsEnabled || modelling == null) return const {};
  return {for (final pin in modelling.focusWords) pin.tileId};
}
