/// What model mode offers beyond pointing: the focus words' tips, "Find a
/// word", "Listen" (speech to symbols) and choosing the focus words.
library;

import 'dart:async';

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';

import '../brand/tokens.dart';
import '../contracts.dart';
import '../contracts_live.dart';
import '../contracts_modelling.dart';
import '../features/flags/w6.dart';
import 'focus_words_screen.dart';
import 'word_finder.dart';

/// The button that starts listening.
const String listenLabel = 'Listen';

/// The button that stops listening.
const String stopListeningLabel = 'Stop listening';

/// Shown while listening.
const String listeningMessage =
    'Listening. Talk as you usually do: words on this board glow as you say '
    'them.';

/// Opens the focus words.
const String chooseFocusLabel = 'Focus words';

/// Heading of the focus words' tips in the bar.
const String focusTipsHeading = 'Words of the week';

/// Time between two words glowing, so the child can follow them.
const Duration spokenGlowGap = Duration(milliseconds: 900);

/// The tools under the model-mode switch while it is on.
///
/// [boardTiles] gives the words placed on the board the adult is looking
/// at, which "Listen" matches what it hears against.
class ModellingTools extends StatefulWidget {
  const ModellingTools({
    super.key,
    required this.store,
    required this.live,
    required this.boardTiles,
    this.modelling,
    this.speech,
  });

  final BoardStore store;
  final LiveSession live;
  final Iterable<TileFacts> Function() boardTiles;
  final ModellingSource? modelling;
  final SpeechListener? speech;

  /// The word finder's field in the bar, for tests.
  static const Key findFieldKey = ValueKey('ModellingTools.findField');

  @override
  State<ModellingTools> createState() => _ModellingToolsState();
}

class _ModellingToolsState extends State<ModellingTools> {
  String? _heard;
  final List<Timer> _glows = [];

  @override
  void dispose() {
    _cancelGlows();
    final speech = widget.speech;
    if (speech != null && speech.listening) speech.stop();
    super.dispose();
  }

  void _cancelGlows() {
    for (final timer in _glows) {
      timer.cancel();
    }
    _glows.clear();
  }

  void _find(String query) => openWordFinder(
    context,
    store: widget.store,
    live: widget.live,
    query: query,
  );

  void _toggleListening() {
    final speech = widget.speech;
    if (speech == null) return;
    if (speech.listening) {
      speech.stop();
      _cancelGlows();
      setState(() => _heard = null);
    } else {
      speech.start(_onHeard);
    }
  }

  void _onHeard(String phrase) {
    if (!mounted) return;
    final matched = matchSpokenWords(phrase, widget.boardTiles());
    _cancelGlows();
    for (final (i, tile) in matched.indexed) {
      _glows.add(
        Timer(spokenGlowGap * i, () => widget.live.sendPulse(tile.id)),
      );
    }
    setState(() {
      _heard = matched.isEmpty
          ? null
          : matched.map((tile) => tile.label).join(' · ');
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final modelling = widget.modelling;
    final speech = widget.speech;
    final listenable = Listenable.merge([?modelling, ?speech, widget.store]);
    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) {
        final tips = _tips();
        final canListen =
            speechToSymbolsEnabled && speech != null && speech.available;
        final listening = canListen && speech.listening;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tips.isNotEmpty) ...[
              Text(
                focusTipsHeading,
                style: ChorusType.label.copyWith(color: colors.ink),
              ),
              const SizedBox(height: 4),
              for (final (label, tip) in tips)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    tip.isEmpty ? label : '$label: $tip',
                    style: ChorusType.body.copyWith(color: colors.ink),
                  ),
                ),
              const SizedBox(height: 8),
            ],
            if (listening) ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  _heard == null ? listeningMessage : 'Glowing: $_heard',
                  style: ChorusType.body.copyWith(color: colors.ink),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (wordFinderEnabled) ...[
              TextField(
                key: ModellingTools.findFieldKey,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: findWordLabel,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    tooltip: findWordLabel,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    onPressed: () => _find(''),
                  ),
                ),
                onSubmitted: _find,
              ),
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (canListen)
                  listening
                      ? FilledButton.icon(
                          onPressed: _toggleListening,
                          icon: const Icon(Icons.mic_off_rounded),
                          label: const Text(stopListeningLabel),
                        )
                      : OutlinedButton.icon(
                          onPressed: widget.live.connected
                              ? _toggleListening
                              : null,
                          icon: const Icon(Icons.mic_rounded),
                          label: const Text(listenLabel),
                        ),
                if (focusWordsEnabled &&
                    modelling != null &&
                    modelling.canPinFocus)
                  OutlinedButton.icon(
                    onPressed: () => openFocusWords(
                      context,
                      store: widget.store,
                      modelling: modelling,
                    ),
                    icon: const Icon(Icons.push_pin_outlined),
                    label: const Text(chooseFocusLabel),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// The focus words still on a board, with their tips.
  List<(String, String)> _tips() {
    final modelling = widget.modelling;
    if (!focusWordsEnabled || modelling == null) return const [];
    final byId = {
      for (final tile in widget.store.tiles)
        if (!tile.archived) tile.id: tile,
    };
    return [
      for (final pin in modelling.focusWords)
        if (byId[pin.tileId] case final tile?) (tile.label, pin.tip),
    ];
  }
}
