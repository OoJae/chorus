/// Lets a guardian invite one more adult to the circle.
library;

import 'package:chorus_client/chorus_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'messages.dart';
import 'services.dart';
import 'status_views.dart';

/// Pick who is being invited, then show a single-use code to pass on.
class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key, required this.gateway, required this.circle});

  final CircleGateway gateway;
  final CircleInfo circle;

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
        child: _busy
            ? const LoadingView(message: 'Making a code…')
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _code == null ? _picker(context) : _result(context),
                ),
              ),
      ),
    );
  }

  Widget _picker(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          "Who are you inviting to ${widget.circle.childName}'s board?",
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        for (final role in CircleRole.values)
          _RoleOption(
            role: role,
            selected: role == _role,
            onTap: () => setState(() => _role = role),
          ),
        const SizedBox(height: 8),
        if (_error != null) ...[
          Text(_error!, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 12),
        ],
        BigButton(
          icon: _error == null ? Icons.vpn_key : Icons.refresh,
          label: _error == null ? 'Make a code' : 'Retry',
          onPressed: _makeCode,
        ),
        Text(
          'Everyone in the circle can see the whole board.',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _result(BuildContext context) {
    final theme = Theme.of(context);
    final code = _code!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Give this code to the person you are inviting.',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SelectableText(
              code,
              key: const ValueKey('invite-code'),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                letterSpacing: 6,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        BigButton(
          icon: Icons.copy,
          label: 'Copy code',
          onPressed: () => _copy(code),
        ),
        Text(
          'They join as: ${roleLabel(_codeRole!)}. They sign in, choose '
          '"Join with a code" and type it in. The code works once and '
          'runs out after 7 days.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        BigButton(
          icon: Icons.person_add_alt,
          label: 'Invite someone else',
          primary: false,
          onPressed: () => setState(() {
            _code = null;
            _codeRole = null;
          }),
        ),
      ],
    );
  }
}

/// One selectable role, named in plain words.
class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final CircleRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black, width: selected ? 3 : 1),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        roleLabel(role),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(roleDetail(role)),
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
