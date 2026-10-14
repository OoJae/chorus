/// The first screen for an adult who is not in any circle yet.
library;

import 'package:chorus_client/chorus_client.dart';
import 'package:flutter/material.dart';

import 'messages.dart';
import 'services.dart';
import 'status_views.dart';

/// Offers three ways to get a board: start one, join one with a code, or
/// try a demo. Each only makes the server call; the caller prepares the
/// board once [onCircle] hands it the new circle.
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
        title: 'Start a board',
        firstLabel: "Child's name",
        secondLabel: 'Your name',
        secondHint: 'For example: Mum',
        action: 'Start',
      ),
    );
    if (answers == null) return;
    await _run(
      'Starting the board…',
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
    final theme = Theme.of(context);
    final busy = _busy;
    final retry = _failed;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chorus'),
        automaticallyImplyLeading: widget.addingAnother,
        actions: [
          if (widget.onSignOut != null)
            TextButton(
              onPressed: busy == null ? widget.onSignOut : null,
              child: const Text('Sign out'),
            ),
        ],
      ),
      body: SafeArea(
        child: busy != null
            ? LoadingView(message: busy)
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        widget.addingAnother
                            ? 'Add another board'
                            : 'Welcome to Chorus',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A talking picture board that a child and the '
                        'adults around them share. It speaks with no '
                        'signal.',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 20),
                      if (_error != null)
                        _ErrorCard(
                          message: _error!,
                          onRetry: retry == null
                              ? null
                              : () => _run(_failedBusy, retry),
                        ),
                      BigButton(
                        icon: Icons.child_care,
                        label: 'Start a board for my child',
                        onPressed: _start,
                      ),
                      BigButton(
                        icon: Icons.vpn_key,
                        label: 'Join with a code',
                        onPressed: _join,
                        primary: false,
                      ),
                      BigButton(
                        icon: Icons.play_circle_outline,
                        label: 'Try a demo board',
                        onPressed: _demo,
                        primary: false,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The demo makes a board for a pretend child called '
                        'Maya. Everyone you invite to a board can see all '
                        'of it.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
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
