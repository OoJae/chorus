/// The quick phrases panel: the circle's phrases as large buttons over the
/// whole screen. A tap speaks the phrase at once, adds it to the sentence
/// and goes back to the board.
library;

import 'package:flutter/material.dart';

import '../../brand/haptics.dart';
import '../../brand/pressable_surface.dart';
import '../../brand/tokens.dart';
import '../../contracts_quick_phrases.dart';
import '../talker_controller.dart';
import 'word_tools.dart';

class QuickPhrasesPanel extends StatefulWidget {
  const QuickPhrasesPanel({
    super.key,
    required this.book,
    required this.controller,
  });

  final QuickPhraseBook book;
  final TalkerController controller;

  @override
  State<QuickPhrasesPanel> createState() => _QuickPhrasesPanelState();
}

class _QuickPhrasesPanelState extends State<QuickPhrasesPanel> {
  @override
  void initState() {
    super.initState();
    // What the device has shows at once; the circle's latest follows when
    // there is a connection.
    widget.book.refresh().catchError((Object _) {});
  }

  void _say(String phrase) {
    widget.controller.addWords([stripWord(phrase, kind: 'phrase')]);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    return Scaffold(
      backgroundColor: colors.card,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      quickPhrasesLabel,
                      style: ChorusType.headline.copyWith(color: colors.ink),
                    ),
                  ),
                  SizedBox(
                    height: ChorusSpace.minTarget,
                    child: PressableSurface(
                      onTap: () => Navigator.of(context).pop(),
                      semanticLabel: backToBoardLabel,
                      color: colors.line,
                      foregroundColor: colors.ink,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close_rounded, color: colors.ink),
                          const SizedBox(width: 6),
                          Text(
                            backToBoardLabel,
                            style: ChorusType.label.copyWith(color: colors.ink),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListenableBuilder(
                  listenable: widget.book,
                  builder: (context, _) => LayoutBuilder(
                    builder: (context, box) {
                      final phrases = widget.book.phrases;
                      final cols = box.maxWidth >= 900
                          ? 3
                          : box.maxWidth >= 480
                          ? 2
                          : 1;
                      final rows = (phrases.length / cols).ceil();
                      // As tall as the screen allows, never under a large
                      // target.
                      final height = rows == 0
                          ? 96.0
                          : ((box.maxHeight - (rows - 1) * 12) / rows).clamp(
                              72.0,
                              160.0,
                            );
                      return GridView.builder(
                        itemCount: phrases.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: height,
                        ),
                        itemBuilder: (context, i) => _PhraseButton(
                          phrase: phrases[i],
                          onTap: () => _say(phrases[i]),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One phrase: ink on laminated card, as large as the panel allows.
class _PhraseButton extends StatelessWidget {
  const _PhraseButton({required this.phrase, required this.onTap});

  final String phrase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    return PressableSurface(
      onTap: onTap,
      semanticLabel: phrase,
      haptic: ChorusHaptic.wordTapped,
      color: colors.surface,
      edgeColor: colors.ink,
      foregroundColor: colors.ink,
      borderRadius: ChorusSpace.tileRadius,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            phrase,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: ChorusType.tileLabel(
              36,
            ).copyWith(color: colors.ink, inherit: false),
          ),
        ),
      ),
    );
  }
}
