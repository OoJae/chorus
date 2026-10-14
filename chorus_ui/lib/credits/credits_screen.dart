/// Attribution and the plain statement of what Chorus is not.
library;

import 'package:flutter/material.dart';

import '../brand/mark.dart';
import '../brand/tokens.dart';

/// Credits for the starter board, its pictures and the typefaces, and the
/// limits of what Chorus claims.
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final margin = ChorusSpace.marginOf(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Credits')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            // One column, all of it built at once: it is short, and every
            // credit is there for a search or a screen reader.
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(margin, 8, margin, 32),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The brand once, quietly, at the head of the page.
                  Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ChorusLockup(size: 28),
                    ),
                  ),
                  _Section(
                    title: 'Starter board',
                    paragraphs: [
                      'The home board starts with the 36 words of the Universal '
                          'Core vocabulary, created by the Center for Literacy '
                          'and Disability Studies, University of North Carolina '
                          'at Chapel Hill.',
                      'It is licensed under the Creative Commons '
                          'Attribution-ShareAlike 4.0 International licence '
                          '(CC BY-SA 4.0).',
                      'Source: project-core.com\n'
                          'Licence: creativecommons.org/licenses/by-sa/4.0',
                      'Chorus adapted the vocabulary as colour-coded tiles, '
                          'without the original Universal Core symbols. Where '
                          'a word has a Mulberry Symbols picture, the tile '
                          'shows it. The adapted starter board is shared under '
                          'the same licence.',
                      'Chorus is not affiliated with or endorsed by the Center '
                          'for Literacy and Disability Studies or the '
                          'University of North Carolina at Chapel Hill.',
                    ],
                  ),
                  _Section(
                    title: 'Symbols',
                    paragraphs: [
                      'Pictures for 23 of the starter words are from Mulberry '
                          'Symbols by Steve Lee (mulberrysymbols.org), licensed '
                          'CC BY-SA 4.0 '
                          '(creativecommons.org/licenses/by-sa/4.0). The other '
                          'words are shown as text.',
                    ],
                  ),
                  _Section(
                    title: 'Typefaces',
                    paragraphs: [
                      'Fraunces, Atkinson Hyperlegible Next and IBM Plex Mono, '
                          'under the SIL Open Font License 1.1.',
                    ],
                  ),
                  _Section(
                    title: 'About this demo',
                    paragraphs: [
                      'The child in the demo is a persona, not a real person.',
                      'Chorus has not been used or validated clinically and is '
                          'not a medical device. It does not replace advice '
                          'from a speech and language therapist.',
                    ],
                  ),
                  _Section(
                    title: 'How it was built',
                    paragraphs: ['Chorus was built with AI coding tools.'],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.paragraphs});

  final String title;
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    // Each section a panel on the card, its head in the section face.
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(ChorusSpace.panelRadius),
          border: Border.all(color: colors.line),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: ChorusType.headline.copyWith(color: colors.ink),
                ),
              ),
              for (final paragraph in paragraphs)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SelectableText(
                    paragraph,
                    style: ChorusType.body.copyWith(color: colors.ink),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
