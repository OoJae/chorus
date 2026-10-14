/// The first screen for an adult who is not in any circle yet.
library;

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_ui/brand/haptics.dart';
import 'package:chorus_ui/brand/mark.dart';
import 'package:chorus_ui/brand/motion.dart';
import 'package:chorus_ui/brand/pressable_surface.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:chorus_ui/onboarding/fill_or_scroll.dart';
import 'package:flutter/material.dart';

import 'messages.dart';
import 'services.dart';

/// Asks "Who is the board for?" and offers three ways to get one, as large
/// choices in the thumb zone: make one, join one with a code, or try a
/// demo. Each only makes the server call; the caller prepares the board
/// once [onCircle] hands it the new circle.
///
/// While a call runs the choices stay where they are, dimmed, with a line
/// above them saying what is happening; a failure takes that line's place,
/// with Retry.
class FirstRunScreen extends StatefulWidget {
  const FirstRunScreen({
    super.key,
    required this.gateway,
    required this.onCircle,
    this.onSignOut,
    this.addingAnother = false,
  });

  final CircleGateway gateway;
  final ValueChanged<CircleInfo> onCircle;
  final VoidCallback? onSignOut;

  /// True when opened from home by an adult who already has a board: the
  /// screen then has a back button and a different heading.
  final bool addingAnother;

  @override
  State<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends State<FirstRunScreen> {
  /// What is being done right now, in words; null when idle.
  String? _busy;

  String? _error;

  /// The call that failed, kept so Retry repeats it with the same answers.
  Future<CircleInfo> Function()? _failed;
  String _failedBusy = '';

  Future<void> _run(String busy, Future<CircleInfo> Function() call) async {
    setState(() {
      _busy = busy;
      _error = null;
      _failed = null;
    });
    try {
      final circle = await call();
      if (!mounted) return;
      setState(() => _busy = null);
      widget.onCircle(circle);
    } catch (error) {
      if (!mounted) return;
      ChorusHaptics.failed();
      setState(() {
        _busy = null;
        _error = failureMessage(error);
        _failed = call;
        _failedBusy = busy;
      });
    }
  }

  Future<void> _start() async {
    final answers = await showDialog<(String, String)>(
      context: context,
      builder: (_) => const _TwoFieldDialog(
        title: 'Make a board',
        firstLabel: "Child's name",
        secondLabel: 'Your name',
        secondHint: 'For example: Mum',
        action: 'Start',
      ),
    );
    if (answers == null) return;
    await _run(
      'Making the board…',
      () => widget.gateway.createCircle(
        childName: answers.$1,
        displayName: answers.$2,
      ),
    );
  }

  Future<void> _join() async {
    final answers = await showDialog<(String, String)>(
      context: context,
      builder: (_) => const _TwoFieldDialog(
        title: 'Join with a code',
        firstLabel: 'Code',
        firstHint: 'The code you were given',
        firstIsCode: true,
        secondLabel: 'Your name',
        secondHint: 'For example: Ms Lee',
        action: 'Join',
      ),
    );
    if (answers == null) return;
    await _run(
      'Joining…',
      () => widget.gateway.acceptInvite(
        code: answers.$1,
        displayName: answers.$2,
      ),
    );
  }

  Future<void> _demo() => _run(
    'Making a demo board…',
    () => widget.gateway.createCircle(childName: 'Maya', displayName: 'Parent'),
  );

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final busy = _busy;
    final error = _error;
    final retry = _failed;
    final size = MediaQuery.sizeOf(context);
    final margin = ChorusSpace.margin(size.width);
    // Side by side where a row of three still leaves each a good width: a
    // phone on its side, a tablet, a desktop window.
    final across = size.width >= 720 && size.width > size.height;
    // A phone on its side: less height for the heading and the cards.
    final short = size.height < 500;
    // On a phone the choices wait in the thumb zone at the bottom; on a
    // tablet or a desktop the heading and choices sit together in the
    // middle.
    final thumbZone = size.shortestSide < ChorusSpace.wideFrom;
    final enabled = busy == null;
    final choices = [
      _Choice(
        icon: Icons.child_care_rounded,
        title: 'Make a board',
        detail: 'It starts with 36 everyday words.',
        primary: true,
        across: across,
        short: short,
        onTap: enabled ? _start : null,
      ),
      _Choice(
        icon: Icons.vpn_key_rounded,
        title: 'Join with a code',
        detail: 'Use the code someone in the circle sent you.',
        across: across,
        short: short,
        onTap: enabled ? _join : null,
      ),
      _Choice(
        icon: Icons.play_circle_outline_rounded,
        title: 'Try a demo board',
        detail: 'A board for a pretend child called Maya.',
        across: across,
        short: short,
        onTap: enabled ? _demo : null,
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const ChorusLockup(size: 22),
        automaticallyImplyLeading: widget.addingAnother,
        actions: [
          if (widget.onSignOut != null)
            TextButton(
              onPressed: enabled ? widget.onSignOut : null,
              child: const Text('Sign out'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: across ? 1040 : 560),
            child: FillOrScroll(
              padding: EdgeInsets.fromLTRB(margin, 8, margin, 16),
              children: [
                if (!thumbZone) const Spacer(flex: 2),
                Semantics(
                  header: true,
                  child: Text(
                    widget.addingAnother
                        ? 'Who is the new board for?'
                        : 'Who is the board for?',
                    textScaler: ChorusType.displayScaler(context),
                    style:
                        (short
                                ? ChorusType.frauncesAt(
                                    ChorusType.display,
                                    40,
                                    42,
                                  )
                                : ChorusType.display)
                            .copyWith(color: colors.ink),
                  ),
                ),
                if (thumbZone) const Spacer(),
                SizedBox(height: thumbZone ? 24 : 40),
                // Above the choices, so they do not move when it comes or
                // goes.
                if (busy != null)
                  _BusyLine(message: busy)
                else if (error != null)
                  _ErrorCard(
                    message: error,
                    onRetry: retry == null
                        ? null
                        : () => _run(_failedBusy, retry),
                  ),
                if (across)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (i, choice) in choices.indexed) ...[
                          if (i > 0) const SizedBox(width: 12),
                          Expanded(child: choice),
                        ],
                      ],
                    ),
                  )
                else
                  for (final (i, choice) in choices.indexed) ...[
                    if (i > 0) const SizedBox(height: 12),
                    choice,
                  ],
                const SizedBox(height: 16),
                Text(
                  'Everyone you invite to a board can see all of it.',
                  style: ChorusType.body.copyWith(color: colors.inkMuted),
                ),
                if (!thumbZone) const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One way to get a board: a large laminated card that presses. The first
/// is ink, the others outlined; each is dimmed while another is working.
class _Choice extends StatelessWidget {
  const _Choice({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
    this.primary = false,
    this.across = false,
    this.short = false,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback? onTap;
  final bool primary;

  /// One of a row: the card as tall as the row, and the icon above the
  /// words unless the screen is [short].
  final bool across;

  /// A screen with little height: the icon stays beside the words.
  final bool short;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final face = primary ? colors.ink : colors.surface;
    final ink = primary ? colors.card : colors.ink;
    const radius = ChorusSpace.buttonRadius;
    final words = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: ChorusType.headline.copyWith(color: ink)),
        const SizedBox(height: 2),
        Text(
          detail,
          style: ChorusType.body.copyWith(
            fontSize: 16,
            height: 22 / 16,
            color: ink,
          ),
        ),
      ],
    );
    final mark = Icon(icon, size: 28, color: ink);
    final content = across && !short
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [mark, const SizedBox(height: 12), words],
          )
        : Row(
            children: [
              mark,
              const SizedBox(width: 16),
              Expanded(child: words),
            ],
          );
    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: primary ? null : Border.all(color: colors.ink, width: 1.5),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: content),
    );
    return AnimatedOpacity(
      opacity: onTap == null ? 0.5 : 1,
      duration: ChorusMotion.duration(context, ChorusMotion.toggleDuration),
      child: PressableSurface(
        onTap: onTap,
        color: face,
        edgeColor: primary ? null : colors.ink,
        foregroundColor: ink,
        borderRadius: radius,
        // The outline follows the face to its edges.
        child: across
            ? SizedBox.expand(child: card)
            : SizedBox(width: double.infinity, child: card),
      ),
    );
  }
}

/// What is being done, in place of a failure, while the choices wait.
class _BusyLine extends StatelessWidget {
  const _BusyLine({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: ChorusType.body)),
          ],
        ),
      ),
    );
  }
}

/// A failure shown above the actions, with Retry.
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(ChorusSpace.buttonRadius),
          border: Border.all(color: colors.alert, width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(message, style: ChorusType.body),
              ),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// Asks for two short answers; pops with both, trimmed, or null on cancel.
class _TwoFieldDialog extends StatefulWidget {
  const _TwoFieldDialog({
    required this.title,
    required this.firstLabel,
    required this.secondLabel,
    required this.action,
    this.firstHint,
    this.secondHint,
    this.firstIsCode = false,
  });

  final String title;
  final String firstLabel;
  final String? firstHint;
  final String secondLabel;
  final String? secondHint;
  final String action;

  /// Invite codes are typed in capitals with no suggestions.
  final bool firstIsCode;

  @override
  State<_TwoFieldDialog> createState() => _TwoFieldDialogState();
}

class _TwoFieldDialogState extends State<_TwoFieldDialog> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _second = TextEditingController();

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pop((_first.text.trim(), _second.text.trim()));
  }

  String? _required(String? value) =>
      (value ?? '').trim().isEmpty ? 'Please fill this in' : null;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const ValueKey('first-field'),
                controller: _first,
                autofocus: true,
                autocorrect: !widget.firstIsCode,
                enableSuggestions: !widget.firstIsCode,
                textCapitalization: widget.firstIsCode
                    ? TextCapitalization.characters
                    : TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: widget.firstLabel,
                  hintText: widget.firstHint,
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('second-field'),
                controller: _second,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: widget.secondLabel,
                  hintText: widget.secondHint,
                ),
                validator: _required,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.action)),
      ],
    );
  }
}
