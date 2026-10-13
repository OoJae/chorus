/// Home for one circle: the large actions an adult chooses from.
library;

import 'dart:async';

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_ui/contracts.dart' hide CircleRole;
import 'package:chorus_ui/credits/credits_screen.dart';
import 'package:chorus_ui/editor/editor_screen.dart';
import 'package:chorus_ui/talker/talker_screen.dart';
import 'package:chorus_ui/widgets/sync_chip.dart';
import 'package:flutter/material.dart';

import '../src/sync/replica_board_store.dart';

import 'invite_screen.dart';
import 'messages.dart';
import 'services.dart';
import 'status_views.dart';

/// Whether this device has finished getting a circle's board ready.
enum CircleReadiness { preparing, ready, failed }

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.circles,
    required this.selected,
    required this.onSelect,
    required this.store,
    required this.sync,
    required this.speech,
    required this.gateway,
    required this.readiness,
    required this.onRetryReady,
    required this.onSignOut,
    this.onAddBoard,
  });

  /// Every circle the adult belongs to; [selected] is one of them.
  final List<CircleInfo> circles;
  final CircleInfo selected;
  final ValueChanged<CircleInfo> onSelect;

  /// The selected circle's boards.
  final BoardStore store;
  final SyncStatus sync;
  final SpeechService speech;
  final CircleGateway gateway;

  final CircleReadiness readiness;
  final VoidCallback onRetryReady;
  final VoidCallback onSignOut;
  final VoidCallback? onAddBoard;

  void _open(BuildContext context, Widget screen, {bool fullscreen = false}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: fullscreen,
        builder: (_) => screen,
      ),
    );
  }

  void _openTalker(BuildContext context) {
    _open(
      context,
      // The talker blocks system back; its held lock calls onExit.
      Builder(
        builder: (talkerContext) => TalkerScreen(
          store: store,
          speech: speech,
          sync: sync,
          onExit: () => Navigator.of(talkerContext).pop(),
        ),
      ),
      fullscreen: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canInvite = selected.myRole == CircleRole.guardian;
    final canEdit = selected.myRole != CircleRole.partner;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chorus'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: SyncChip(sync: sync)),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListenableBuilder(
              listenable: store,
              builder: (context, _) {
                // A board already on this device can be used straight away,
                // whatever the network is doing.
                final hasBoard = store.boards.any((board) => !board.archived);
                // The replica's own store says when it has read this device;
                // any other store (tests, fakes) is read from the start.
                final current = store;
                final loaded =
                    current is! ReplicaBoardStore || current.hasLoaded;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      "${selected.childName}'s board",
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You are ${selected.myDisplayName} '
                      '(${roleLabel(selected.myRole)}).',
                      style: theme.textTheme.bodyLarge,
                    ),
                    if (circles.length > 1) ...[
                      const SizedBox(height: 12),
                      _CircleSwitcher(
                        circles: circles,
                        selected: selected,
                        onSelect: onSelect,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _ReadinessNote(
                      readiness: readiness,
                      hasBoard: hasBoard,
                      loaded: loaded,
                      childName: selected.childName,
                      onRetry: onRetryReady,
                    ),
                    BigButton(
                      icon: Icons.record_voice_over,
                      label: 'Talker',
                      onPressed: hasBoard ? () => _openTalker(context) : null,
                    ),
                    BigButton(
                      icon: canEdit ? Icons.edit : Icons.grid_view,
                      label: canEdit ? 'Edit board' : 'View board',
                      onPressed: hasBoard
                          ? () => _open(
                              context,
                              EditorScreen(store: store, sync: sync),
                            )
                          : null,
                    ),
                    ListenableBuilder(
                      listenable: sync,
                      builder: (context, _) => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Work offline'),
                        subtitle: const Text(
                          'Pauses sync on this device. Changes are kept here '
                          'and sent when you switch it back.',
                        ),
                        value: sync.workingOffline,
                        onChanged: (value) =>
                            unawaited(sync.setWorkingOffline(value)),
                      ),
                    ),
                    if (canInvite)
                      BigButton(
                        icon: Icons.person_add_alt,
                        label: 'Invite someone',
                        primary: false,
                        onPressed: () => _open(
                          context,
                          InviteScreen(gateway: gateway, circle: selected),
                        ),
                      ),
                    BigButton(
                      icon: Icons.info_outline,
                      label: 'Credits',
                      primary: false,
                      onPressed: () => _open(context, const CreditsScreen()),
                    ),
                    BigButton(
                      icon: Icons.logout,
                      label: 'Sign out',
                      primary: false,
                      onPressed: onSignOut,
                    ),
                    if (onAddBoard != null)
                      TextButton(
                        onPressed: onAddBoard,
                        child: const Text('Add or join another board'),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Says what this device is still doing for the circle, or what failed.
/// Shows nothing once the circle is ready and its board is here.
class _ReadinessNote extends StatelessWidget {
  const _ReadinessNote({
    required this.readiness,
    required this.hasBoard,
    required this.loaded,
    required this.childName,
    required this.onRetry,
  });

  final CircleReadiness readiness;
  final bool hasBoard;

  /// Whether the boards saved on this device have been read yet.
  final bool loaded;
  final String childName;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (readiness == CircleReadiness.ready && hasBoard) {
      return const SizedBox.shrink();
    }
    if (!loaded && !hasBoard) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text("Opening $childName's board…")),
          ],
        ),
      );
    }
    final failed = readiness == CircleReadiness.failed;
    // Ready with no board: an invited adult whose device is ahead of the
    // one that makes the starter board. Nothing is wrong, but nothing is
    // under way here either, so the note explains and offers Retry.
    final waiting = readiness == CircleReadiness.ready;
    final String message;
    if (waiting) {
      message =
          'There is no board here yet. It will appear when the device of '
          'the person who started it has connected.';
    } else if (!failed) {
      message = hasBoard
          ? 'Checking for changes from other devices…'
          : "Getting $childName's board ready…";
    } else {
      message = hasBoard
          ? 'This device could not check in with the others. The board '
                'saved here still works.'
          : "This device could not get $childName's board yet. Check the "
                'connection.';
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Row(
        children: [
          if (failed)
            const Icon(Icons.error_outline)
          else if (waiting)
            const Icon(Icons.hourglass_empty)
          else
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
          ),
          if (failed || waiting)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/// Chooses between the adult's circles.
class _CircleSwitcher extends StatelessWidget {
  const _CircleSwitcher({
    required this.circles,
    required this.selected,
    required this.onSelect,
  });

  final List<CircleInfo> circles;
  final CircleInfo selected;
  final ValueChanged<CircleInfo> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final circle in circles)
          ChoiceChip(
            label: Text(circle.childName),
            selected: circle.spaceUuid == selected.spaceUuid,
            onSelected: (_) => onSelect(circle),
          ),
      ],
    );
  }
}
