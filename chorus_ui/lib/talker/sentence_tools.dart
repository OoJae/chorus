/// "Share" and "Recent" beside the sentence: send what was said through
/// the share sheet, and the sentences said since the app opened.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../brand/tokens.dart';
import '../contracts.dart';
import '../device/text_share.dart';
import 'recent_sentences.dart';

/// Label of the control that shares the sentence.
const String shareSentenceLabel = 'Share the sentence';

/// Label of the control that opens the recent sentences.
const String recentSentencesLabel = 'Recent sentences';

/// Said when the sentence went to the clipboard instead of a share sheet.
const String sentenceCopiedMessage = 'Copied';

/// Said when there is no sentence to share yet.
const String nothingToShareMessage = 'Make a sentence first';

/// The heading of the recent sentences panel.
const String recentSentencesTitle = 'Recent';

/// Shown in the panel before anything has been said.
const String noRecentSentencesMessage =
    'Sentences said with Speak show here until the app closes.';

/// Label of the button that says a recent sentence again.
const String sayAgainLabel = 'Say it again';

/// Two small ink controls for the status row: share the sentence on the
/// strip, and open the recent sentences. They keep their size whatever the
/// sentence, so nothing round them moves.
class SentenceTools extends StatelessWidget {
  const SentenceTools({
    super.key,
    required this.sentence,
    required this.speech,
    this.recent,
    this.share,
  });

  /// The sentence on the strip now, as it reads.
  final String sentence;
  final SpeechService speech;

  /// Null is the app's own list for this run.
  final RecentSentences? recent;

  /// Null is the system's share sheet where there is one, else Copy.
  final ShareText? Function()? share;

  /// The share control, for tests.
  @visibleForTesting
  static const Key shareKey = ValueKey('SentenceTools.share');

  /// The recent control, for tests.
  @visibleForTesting
  static const Key recentKey = ValueKey('SentenceTools.recent');

  RecentSentences get _recent => recent ?? RecentSentences.session;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToolButton(
          key: shareKey,
          icon: Icons.ios_share_rounded,
          label: shareSentenceLabel,
          onTap: () => shareSentence(context, sentence, share: share),
        ),
        _ToolButton(
          key: recentKey,
          icon: Icons.history_rounded,
          label: recentSentencesLabel,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => RecentSentencesScreen(
                recent: _recent,
                speech: speech,
                share: share,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Sends [sentence] to the share sheet, or copies it and says "Copied"
/// where there is no sheet (or the sheet would not open).
Future<void> shareSentence(
  BuildContext context,
  String sentence, {
  ShareText? Function()? share,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  void say(String message) => messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
  final text = sentence.trim();
  if (text.isEmpty) {
    say(nothingToShareMessage);
    return;
  }
  final sheet = (share ?? systemShareText)();
  if (sheet != null && await sheet(text)) return;
  // Closing the sheet on purpose also lands here; copying then does no
  // harm.
  try {
    await Clipboard.setData(ClipboardData(text: text));
    say(sentenceCopiedMessage);
  } catch (_) {}
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = ChorusColors.of(context).ink;
    return Semantics(
      container: true,
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          // Nothing spreads or moves on the child's board.
          splashFactory: NoSplash.splashFactory,
          borderRadius: BorderRadius.circular(ChorusSpace.minTarget / 2),
          child: SizedBox.square(
            dimension: ChorusSpace.minTarget,
            child: Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ink, width: 1.5),
                ),
                child: Icon(icon, size: 18, color: ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The sentences said since the app opened, newest first, each with "Say
/// it again" and "Share". A screen of its own over the board, so nothing on
/// the board moves.
class RecentSentencesScreen extends StatelessWidget {
  const RecentSentencesScreen({
    super.key,
    required this.recent,
    required this.speech,
    this.share,
  });

  final RecentSentences recent;
  final SpeechService speech;
  final ShareText? Function()? share;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(recentSentencesTitle)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: recent,
          builder: (context, _) {
            final sentences = recent.sentences;
            if (sentences.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(ChorusSpace.marginPhone),
                child: Text(
                  noRecentSentencesMessage,
                  style: ChorusType.body.copyWith(color: colors.inkMuted),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: sentences.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, i) {
                final sentence = sentences[i];
                return ListTile(
                  minTileHeight: 64,
                  title: Text(
                    sentence,
                    style: ChorusType.tileLabel(22).copyWith(color: colors.ink),
                  ),
                  onTap: () => unawaited(
                    speech
                        .speak(recent.spokenOf(sentence))
                        .catchError((Object _) {}),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: sayAgainLabel,
                        icon: const Icon(Icons.volume_up_rounded),
                        onPressed: () => unawaited(
                          speech
                              .speak(recent.spokenOf(sentence))
                              .catchError((Object _) {}),
                        ),
                      ),
                      IconButton(
                        tooltip: shareSentenceLabel,
                        icon: const Icon(Icons.ios_share_rounded),
                        onPressed: () =>
                            shareSentence(context, sentence, share: share),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
