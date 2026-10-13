/// Attribution and the plain statement of what Chorus is not.
library;

import 'package:flutter/material.dart';

/// Credits for the starter board, and the limits of what Chorus claims.
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Credits')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
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
                    'Chorus adapted the vocabulary as colour-coded text '
                        'tiles, without the original symbols. The adapted '
                        'starter board is shared under the same licence.',
                    'Chorus is not affiliated with or endorsed by the Center '
                        'for Literacy and Disability Studies or the '
                        'University of North Carolina at Chapel Hill.',
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
                  paragraphs: [
                    'Chorus was built with AI coding tools.',
                  ],
                ),
              ],
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.titleLarge),
          ),
          for (final paragraph in paragraphs)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SelectableText(paragraph),
            ),
        ],
      ),
    );
  }
}
