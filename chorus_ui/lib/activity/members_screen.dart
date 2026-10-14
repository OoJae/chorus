/// "People in this circle": who can see and edit the board, and a
/// guardian's way to remove someone.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../brand/haptics.dart';
import '../brand/tokens.dart';
import '../contracts_activity.dart';
import '../features/flags/w2.dart' as w2;
import 'activity_screen.dart' show ActorBadge;

/// Title of the screen and of its home entry.
const String membersTitle = 'People in this circle';

/// One line under the home entry.
const String membersEntryDetail = 'Who can see and edit the board';

/// The action on each other member, for a guardian.
const String removeFromCircleLabel = 'Remove from circle';

/// Shown when the list could not be read.
const String membersUnavailableMessage =
    'The list needs a connection. Try again when this device is online.';

/// Shown when someone could not be removed.
const String memberNotRemovedMessage =
    'That could not be done. Check the connection and try again.';

/// The question before removing [name].
String removeMemberQuestion(String name) => 'Remove $name from the circle?';

/// What removing [name] does, in plain words.
String removeMemberExplanation(String name) =>
    '$name will no longer see or change the board, from any device. The '
    'words they added stay. You can invite them again later.';

/// Shown once [name] is removed.
String memberRemovedMessage(String name) => '$name was removed.';

/// The circle's members. A guardian sees "Remove from circle" on everyone
/// but themselves, when [offerRemove] is on.
class MembersScreen extends StatefulWidget {
  const MembersScreen({
    super.key,
    required this.members,
    this.offerRemove = w2.removeFromCircleEnabled,
  });

  final CircleMembers members;

  /// Whether "Remove from circle" is offered at all. Defaults to the W2
  /// flag `removeFromCircleEnabled`.
  final bool offerRemove;

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  List<CircleMember>? _list;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final list = await widget.members.list();
      if (mounted) {
        setState(() {
          _list = list;
          _failed = false;
        });
      }
    } on Object {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _remove(CircleMember member) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(removeMemberQuestion(member.name)),
        content: Text(removeMemberExplanation(member.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.members.remove(member);
      messenger?.showSnackBar(
        SnackBar(content: Text(memberRemovedMessage(member.name))),
      );
      await _load();
    } on Object {
      ChorusHaptics.failed();
      messenger?.showSnackBar(
        const SnackBar(content: Text(memberNotRemovedMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final list = _list;
    final Widget body;
    if (_failed) {
      body = Padding(
        padding: const EdgeInsets.all(ChorusSpace.marginPhone),
        child: Text(
          membersUnavailableMessage,
          style: ChorusType.body.copyWith(color: colors.inkMuted),
        ),
      );
    } else if (list == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final member in list)
            ListTile(
              key: ValueKey(member.userId),
              minTileHeight: 56,
              leading: ExcludeSemantics(child: ActorBadge(name: member.name)),
              title: Text(member.isMe ? '${member.name} (you)' : member.name),
              subtitle: Text(member.roleName),
              trailing:
                  widget.offerRemove && widget.members.canRemove && !member.isMe
                  ? TextButton(
                      onPressed: () => _remove(member),
                      child: Text(
                        'Remove',
                        semanticsLabel:
                            '$removeFromCircleLabel: ${member.name}',
                      ),
                    )
                  : null,
            ),
        ],
      );
    }
    return Scaffold(
      backgroundColor: colors.card,
      appBar: AppBar(title: const Text(membersTitle)),
      body: body,
    );
  }
}
