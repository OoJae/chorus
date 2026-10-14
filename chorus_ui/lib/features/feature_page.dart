/// The page, notes, skeletons and word tiles the feature screens share:
/// "Word log", "This week", "Share a view-only board" and "Export as Open
/// Board Format".
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../brand/motion.dart';
import '../brand/symbols.dart';
import '../brand/tokens.dart';

/// Opens the system's share sheet for [url], with [text] and [title] beside
/// it, and completes with false when nothing was shared. The app passes one
/// where the device has a share sheet it can reach; without it the screens
/// offer Copy alone.
typedef ShareLinkAction =
    Future<bool> Function(Uri url, String text, String title);

/// An adult screen on the card: a Fraunces title, reading text, and the
/// thumb's actions pinned in the bottom third.
///
/// When the screen is short (a phone on its side) the actions follow the
/// text instead, so the text keeps the room. The body comes in once, on the
/// entrance curve; under reduced motion it fades in over 150 ms.
class FeaturePage extends StatelessWidget {
  const FeaturePage({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
    this.barActions = const [],
  });

  final String title;

  /// The reading part, top to bottom.
  final List<Widget> content;

  /// The thumb's buttons, most important last (nearest the thumb). Each is
  /// stretched to the column's width.
  final List<Widget> actions;

  /// Small actions in the top bar, such as Refresh.
  final List<Widget> barActions;

  /// Below this height, at normal text size, the actions scroll with the
  /// text. Larger text needs more: see [pinsActions].
  static const double pinActionsFrom = 520;

  /// Whether a screen [height] tall, with text at [textScale], pins the
  /// actions. Large text makes the actions taller too, and a pinned panel
  /// must not take the screen from the text.
  static bool pinsActions(double height, double textScale) =>
      height >= pinActionsFrom + 200 * (textScale.clamp(1.0, 3.0) - 1);

  /// The widest the reading column grows.
  static const double maxWidth = 640;

  /// The pinned actions panel, for tests.
  @visibleForTesting
  static const Key pinnedActionsKey = ValueKey('FeaturePage.pinnedActions');

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final size = MediaQuery.sizeOf(context);
    final margin = ChorusSpace.margin(size.width);
    final pin =
        actions.isNotEmpty &&
        pinsActions(size.height, MediaQuery.textScalerOf(context).scale(1));

    Widget column(List<Widget> children) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );

    final heading = Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineLarge,
          textScaler: ChorusType.displayScaler(context),
        ),
      ),
    );

    final reading = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(margin, 8, margin, 24),
      child: column([
        heading,
        ...content,
        if (!pin && actions.isNotEmpty) ...[
          const SizedBox(height: 24),
          _ActionColumn(actions: actions),
        ],
      ]),
    );

    return Scaffold(
      backgroundColor: colors.card,
      appBar: AppBar(
        backgroundColor: colors.card,
        actions: [...barActions, const SizedBox(width: 4)],
      ),
      body: SafeArea(
        top: false,
        child: FeatureEntrance(
          child: pin
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: reading),
                    DecoratedBox(
                      key: pinnedActionsKey,
                      decoration: BoxDecoration(
                        color: colors.card,
                        border: Border(top: BorderSide(color: colors.line)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(margin, 12, margin, 16),
                        child: column([_ActionColumn(actions: actions)]),
                      ),
                    ),
                  ],
                )
              : reading,
        ),
      ),
    );
  }
}

/// The actions, full width, 8 dp apart.
class _ActionColumn extends StatelessWidget {
  const _ActionColumn({required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, action) in actions.indexed) ...[
          if (i > 0) const SizedBox(height: ChorusSpace.targetGap),
          action,
        ],
      ],
    );
  }
}

/// Brings [child] in once: a short rise and fade on the entrance curve, or
/// a 150 ms fade under reduced motion.
class FeatureEntrance extends StatefulWidget {
  const FeatureEntrance({super.key, required this.child});

  final Widget child;

  /// How far the body rises as it comes in.
  static const double rise = 16;

  @override
  State<FeatureEntrance> createState() => _FeatureEntranceState();
}

class _FeatureEntranceState extends State<FeatureEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(vsync: this);
  bool _started = false;
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = ChorusMotion.reduced(context);
    if (_started) return;
    _started = true;
    _in.duration = ChorusMotion.duration(context, ChorusMotion.entranceLong);
    _in.forward();
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = _reduced;
    return AnimatedBuilder(
      animation: _in,
      builder: (context, child) {
        final t = reduced
            ? _in.value
            : ChorusMotion.entrance.transform(_in.value);
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          // A screen reader has the page from the first frame.
          alwaysIncludeSemantics: true,
          child: reduced
              ? child
              : Transform.translate(
                  offset: Offset(0, FeatureEntrance.rise * (1 - t)),
                  child: child,
                ),
        );
      },
      child: widget.child,
    );
  }
}

/// Swaps between a screen's states (loading, done, failed) with a short
/// fade; 150 ms under reduced motion.
class FeatureSwitcher extends StatelessWidget {
  const FeatureSwitcher({super.key, required this.child});

  /// Give each state its own key.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: ChorusMotion.duration(context, ChorusMotion.entranceShort),
      switchInCurve: ChorusMotion.entrance,
      switchOutCurve: ChorusMotion.entrance,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      child: child,
    );
  }
}

/// A section head in the headline face.
class FeatureHeading extends StatelessWidget {
  const FeatureHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

/// One fact in a list: an ink icon and a line of reading text.
class FeatureFact extends StatelessWidget {
  const FeatureFact({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: ExcludeSemantics(child: Icon(icon, size: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/// Text in the status face: the machine's voice, for counts, dates and
/// links.
class StatusText extends StatelessWidget {
  const StatusText(this.text, {super.key, this.color, this.semanticsLabel});

  final String text;

  /// Null is muted ink.
  final Color? color;

  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final style = ChorusType.status.copyWith(
      color: color ?? ChorusColors.of(context).inkMuted,
    );
    return Text(text, style: style, semanticsLabel: semanticsLabel);
  }
}

/// A note on a panel: what is happening, what went wrong, or that the
/// device is offline. An [alert] note is the only colour of its kind on
/// the page: errors only.
class FeatureNote extends StatelessWidget {
  const FeatureNote({
    super.key,
    required this.icon,
    required this.message,
    this.alert = false,
    this.action,
  });

  final IconData icon;
  final String message;
  final bool alert;

  /// A text button under the message, such as Try again.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    return Semantics(
      container: true,
      liveRegion: alert,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(ChorusSpace.buttonRadius),
          border: Border.all(
            color: alert ? colors.alert : colors.line,
            width: alert ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Icon(icon, color: alert ? colors.alert : null),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(message)),
                ],
              ),
              if (action != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 24),
                  child: action,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A grey laminated block that holds the space of something still loading.
/// Silent to screen readers; wrap a group of them in one label.
class SkeletonTile extends StatelessWidget {
  const SkeletonTile({
    super.key,
    this.width,
    required this.height,
    this.radius = ChorusSpace.tileRadius,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final corner = BorderRadius.circular(radius);
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: ChorusSpace.edge),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: edgeFor(colors.line),
                  borderRadius: corner,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: ChorusSpace.edge),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.line,
                  borderRadius: corner,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A word as a small laminated tile in its colour family, with its symbol
/// when it has one and, for a count, the number in the status face.
///
/// Not a button: screen readers hear the word and the count as one line.
class WordTile extends StatelessWidget {
  const WordTile({
    super.key,
    required this.label,
    this.family = TileFamily.other,
    this.count,
    this.large = false,
  });

  final String label;
  final TileFamily family;

  /// Times spoken; null shows the word alone.
  final int? count;

  /// A square tile with a picture, for the most used words; otherwise a
  /// chip that grows with its word.
  final bool large;

  /// The side of a large tile at normal text size.
  static const double largeSide = 96;

  @override
  Widget build(BuildContext context) {
    final colors = family.colorsFor(Theme.of(context).brightness);
    final count = this.count;
    final spoken = count == null
        ? label
        : '$label, ${count == 1 ? 'once' : '$count times'}';
    final corner = BorderRadius.circular(ChorusSpace.tileRadius);
    final face = large ? _large(context, count) : _chip(count);
    return Semantics(
      label: spoken,
      excludeSemantics: true,
      child: DecoratedBox(
        // The laminated edge, under the face.
        decoration: BoxDecoration(color: colors.edge, borderRadius: corner),
        child: Padding(
          padding: const EdgeInsets.only(bottom: ChorusSpace.edge),
          child: DecoratedBox(
            decoration: BoxDecoration(color: colors.fill, borderRadius: corner),
            child: face,
          ),
        ),
      ),
    );
  }

  Widget _chip(int? count) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: ChorusType.label.copyWith(color: tileLabelInk),
                softWrap: true,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              Text(
                '$count',
                style: ChorusType.status.copyWith(color: tileLabelInk),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _large(BuildContext context, int? count) {
    // Grows with large text, so the word stays readable, up to half again.
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);
    final side = largeSide * scale;
    final symbol = symbolImageFor(label);
    final word = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        label,
        maxLines: 1,
        textScaler: TextScaler.noScaling,
        style: ChorusType.tileLabel(18 * scale).copyWith(color: tileLabelInk),
      ),
    );
    return SizedBox(
      width: side,
      height: side,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: symbol == null
                  ? Center(child: word)
                  : Column(
                      children: [
                        Expanded(
                          child: Image(
                            image: symbol,
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                        word,
                      ],
                    ),
            ),
            if (count != null)
              Expanded(
                flex: 2,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomRight,
                  child: Text(
                    '×$count',
                    textScaler: TextScaler.noScaling,
                    style: ChorusType.status.copyWith(
                      color: tileLabelInk,
                      fontSize: 13 * scale,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A link to hand on: the address in the status face on a panel, with Copy
/// and, where the device has a share sheet, Share.
class LinkPanel extends StatelessWidget {
  const LinkPanel({
    super.key,
    required this.url,
    required this.shareText,
    required this.shareTitle,
    this.onShare,
    this.footnote,
  });

  final Uri url;

  /// What goes beside the link in the share sheet.
  final String shareText;
  final String shareTitle;
  final ShareLinkAction? onShare;

  /// A line under the link, such as when it stops opening.
  final String? footnote;

  Future<void> _copy(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    await Clipboard.setData(ClipboardData(text: url.toString()));
    messenger?.showSnackBar(const SnackBar(content: Text('Link copied.')));
  }

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final share = onShare;
    final footnote = this.footnote;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(ChorusSpace.panelRadius),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StatusText(
              url.toString(),
              color: colors.ink,
              semanticsLabel: 'Link: $url',
            ),
            if (footnote != null) ...[
              const SizedBox(height: 8),
              StatusText(footnote),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: ChorusSpace.targetGap,
              runSpacing: ChorusSpace.targetGap,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _copy(context),
                  icon: const Icon(Icons.content_copy_rounded),
                  label: const Text('Copy link'),
                ),
                if (share != null)
                  OutlinedButton.icon(
                    onPressed: () =>
                        share(url, shareText, shareTitle).catchError((_) {
                          return false;
                        }),
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('Share'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The day [time] falls on, as the adult reads it in their own locale:
/// "Wed, Oct 21". The date is read as given: pass a UTC week start as it
/// is, and a moment such as an expiry `toLocal()`.
String featureDay(BuildContext context, DateTime time) =>
    MaterialLocalizations.of(context).formatMediumDate(time);

/// [count] [one]s, or "1 [one]": "3 words", "1 word".
String countOf(int count, String one, [String? many]) =>
    count == 1 ? '1 $one' : '$count ${many ?? '${one}s'}';

/// A link panel's space, held while the link is made, with [message] under
/// it.
class LinkLoading extends StatelessWidget {
  const LinkLoading({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: message,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FeatureHeading('The link'),
          const SkeletonTile(height: 132, radius: ChorusSpace.panelRadius),
          const SizedBox(height: 8),
          StatusText(message),
        ],
      ),
    );
  }
}

/// After the next frame, scrolls so the whole of what [key] holds is on
/// screen: a link that was just made, below the explanation. On the
/// entrance curve; at once under reduced motion.
void revealAfterFrame(GlobalKey key) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final target = key.currentContext;
    if (target == null || !target.mounted) return;
    unawaited(
      Scrollable.ensureVisible(
        target,
        duration: ChorusMotion.reduced(target)
            ? Duration.zero
            : ChorusMotion.entranceShort,
        curve: ChorusMotion.entrance,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      ),
    );
  });
}
