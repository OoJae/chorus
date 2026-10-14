/// Lets a guardian invite one more adult to the circle.
library;

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_ui/brand/pressable_surface.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'messages.dart';
import 'services.dart';

/// Pick who is being invited, then show a single-use code to pass on.
///
/// The choices read from the top; the action is at the bottom, in reach of
/// the thumb. While the code is being made the choices stay where they are
/// and the button says so.
class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key, required this.gateway, required this.circle});

  final CircleGateway gateway;
  final CircleInfo circle;

  /// The code, for tests.
  @visibleForTesting
  static const Key codeKey = ValueKey('invite-code');

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  CircleRole _role = CircleRole.therapist;
  bool _busy = false;
  String? _error;

  /// The code just made, and the role it was made for.
  String? _code;
  CircleRole? _codeRole;

  Future<void> _makeCode() async {
    final role = _role;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final code = await widget.gateway.createInvite(widget.circle, role);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _code = code;
        _codeRole = role;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = failureMessage(error);
      });
    }
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Code copied')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invite someone')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _code == null ? _picker(context) : _result(context),
          ),
        ),
      ),
    );
  }

  Widget _picker(BuildContext context) {
    final colors = ChorusColors.of(context);
    final error = _error;
    return _Page(
      key: const ValueKey('invite-picker'),
      content: [
        Semantics(
          header: true,
          child: Text(
            "Who are you inviting to ${widget.circle.childName}'s board?",
            style: ChorusType.headline.copyWith(color: colors.ink),
          ),
        ),
        const SizedBox(height: 16),
        for (final role in CircleRole.values) ...[
          _RoleOption(
            role: role,
            selected: role == _role,
            onTap: _busy ? null : () => setState(() => _role = role),
          ),
          const SizedBox(height: ChorusSpace.targetGap + 4),
        ],
        const SizedBox(height: 4),
        Text(
          'Everyone in the circle can see the whole board.',
          style: ChorusType.body.copyWith(color: colors.inkMuted),
        ),
      ],
      actions: [
        if (error != null) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              error,
              style: ChorusType.body.copyWith(color: colors.alert),
            ),
          ),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          onPressed: _busy ? null : _makeCode,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          icon: Icon(
            error == null ? Icons.vpn_key_rounded : Icons.refresh_rounded,
          ),
          label: Text(
            _busy
                ? 'Making a code…'
                : (error == null ? 'Make a code' : 'Retry'),
          ),
        ),
      ],
    );
  }

  Widget _result(BuildContext context) {
    final colors = ChorusColors.of(context);
    final code = _code!;
    // A page of its own, read from the top.
    return _Page(
      key: const ValueKey('invite-result'),
      content: [
        Semantics(
          header: true,
          child: Text(
            'Give this code to the person you are inviting.',
            style: ChorusType.headline.copyWith(color: colors.ink),
          ),
        ),
        const SizedBox(height: 20),
        // The code on a laminated card, in the machine's face: it is made
        // by Chorus, to be read out or typed.
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.line,
            borderRadius: BorderRadius.circular(ChorusSpace.panelRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: ChorusSpace.edge),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(ChorusSpace.panelRadius),
                border: Border.all(color: colors.line),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SelectableText(
                    code,
                    key: InviteScreen.codeKey,
                    style: ChorusType.status.copyWith(
                      fontSize: 44,
                      height: 52 / 44,
                      letterSpacing: 8,
                      color: colors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'They join as: ${roleLabel(_codeRole!)}. They sign in, choose '
          '"Join with a code" and type it in. The code works once and '
          'runs out after 7 days.',
          style: ChorusType.body.copyWith(color: colors.ink),
        ),
      ],
      actions: [
        FilledButton.icon(
          onPressed: () => _copy(code),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          icon: const Icon(Icons.copy_rounded),
          label: const Text('Copy code'),
        ),
        const SizedBox(height: ChorusSpace.targetGap + 4),
        OutlinedButton.icon(
          onPressed: () => setState(() {
            _code = null;
            _codeRole = null;
          }),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
          ),
          icon: const Icon(Icons.person_add_alt_rounded),
          label: const Text('Invite someone else'),
        ),
      ],
    );
  }
}

/// [content] from the top, [actions] at the bottom in reach of the thumb.
/// On a window too short for both, the actions follow the content in one
/// scroll.
class _Page extends StatelessWidget {
  const _Page({super.key, required this.content, required this.actions});

  final List<Widget> content;
  final List<Widget> actions;

  /// Below this height the actions are not held at the bottom.
  static const double _pinFrom = 480;

  @override
  Widget build(BuildContext context) {
    final margin = ChorusSpace.marginOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final actionColumn = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: actions,
        );
        if (box.maxHeight < _pinFrom) {
          return ListView(
            padding: EdgeInsets.fromLTRB(margin, 16, margin, 24),
            children: [...content, const SizedBox(height: 24), actionColumn],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(margin, 16, margin, 16),
                children: content,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(margin, 8, margin, 24),
              child: actionColumn,
            ),
          ],
        );
      },
    );
  }
}

/// One selectable role, named in plain words, on a laminated card.
class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final CircleRole role;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final radius = BorderRadius.circular(ChorusSpace.buttonRadius);
    // One node for a screen reader: a radio button with its words, in
    // place of the surface's own.
    return Semantics(
      container: true,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      enabled: onTap != null,
      label: '${roleLabel(role)}. ${roleDetail(role)}',
      onTap: onTap,
      excludeSemantics: true,
      child: PressableSurface(
        onTap: onTap,
        color: colors.surface,
        edgeColor: selected ? colors.ink : colors.line,
        foregroundColor: colors.ink,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: selected ? colors.ink : colors.inkMuted,
              width: selected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        roleLabel(role),
                        style: ChorusType.label.copyWith(
                          fontSize: 17,
                          height: 22 / 17,
                          color: colors.ink,
                        ),
                      ),
                      Text(
                        roleDetail(role),
                        style: ChorusType.body.copyWith(
                          color: colors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
