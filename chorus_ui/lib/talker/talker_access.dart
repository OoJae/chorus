/// The small hooks the child's board calls for the access features: touch
/// settings, switch scanning, keyguard mode and recent sentences. Each one
/// checks its flag, so a flag set to false leaves the board as it was.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/widgets.dart';

import '../contracts.dart';
import '../device/device_settings_scope.dart';
import '../features/flags/w3.dart';
import 'recent_sentences.dart';
import 'sentence_tools.dart';
import 'talker_tabs.dart';

export 'switch_scanner.dart' show SwitchScanner, scanStripHighlightKey;
export 'touch_gate.dart' show TouchGate;

/// Whether this device has keyguard mode on: the grid keeps one fixed size
/// and place (see `KeyguardGeometry`).
bool keyguardOn(BuildContext context) =>
    keyguardEnabled && DeviceSettingsScope.of(context).keyguard;

/// Notes the sentence on [strip] as just spoken, for "Recent". While the
/// board is [private] nothing is noted.
void noteSentenceSpoken(
  List<TileFacts> strip, {
  bool private = false,
  RecentSentences? recent,
}) {
  if (!shareSentenceEnabled || private || strip.isEmpty) return;
  (recent ?? RecentSentences.session).add(
    sentenceOf(strip),
    spoken: strip.map((tile) => tile.spokenText).join(' '),
  );
}

/// The words on [strip] as the sentence reads.
String sentenceOf(List<TileFacts> strip) =>
    strip.map((tile) => tile.label).join(' ');

/// What a screen reader says for [tile]: the word it speaks.
String tileSemanticLabel(TileFacts tile) => tile.spokenText;

/// "Share" and "Recent" for the status row, or nothing with the feature
/// off.
List<Widget> sentenceToolsFor(String sentence, SpeechService speech) => [
  if (shareSentenceEnabled) SentenceTools(sentence: sentence, speech: speech),
];

/// The row kept for board tabs in keyguard mode while there is only one
/// board, so a second board's tabs arriving later move nothing.
class KeptTabsRow extends StatelessWidget {
  const KeptTabsRow({super.key});

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: TalkerBoardTabs.height);
}
