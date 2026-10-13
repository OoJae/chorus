/// Home for one circle: the large actions an adult chooses from.
library;

import 'dart:async';

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_shared/chorus_shared.dart'
    show BoardFacts, boardToPrint, printSnapshotJson;
import 'package:chorus_ui/contracts.dart' hide CircleRole;
import 'package:chorus_ui/contracts_live.dart';
import 'package:chorus_ui/contracts_media.dart';
import 'package:chorus_ui/credits/credits_screen.dart';
import 'package:chorus_ui/editor/editor_screen.dart';
import 'package:chorus_ui/talker/talker_screen.dart';
import 'package:chorus_ui/widgets/sync_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../src/live/live_scope.dart';
import '../src/sync/replica_board_store.dart';
import 'invite_screen.dart';
import 'messages.dart';
import 'services.dart';
import 'status_views.dart';

/// Label of the action that makes a printable page of the board.
const String printCopyLabel = 'Print a paper copy';

/// Shown when the printable page could not be made.
const String printCopyFailedMessage =
    'The paper copy could not be made. It needs a connection: try again '
    'when this device is online.';

/// Shown instead of making the page while the adult has sync paused.
const String printCopyOfflineMessage =
    'The paper copy needs a connection. Switch off "Work offline" and try '
    'again.';

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
    this.services,
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

  /// Photos and voices, the live session, the word suggestion and the
  /// paper copy of the selected circle. Null leaves all of them out.
  final CircleServices? services;

  void _open(BuildContext context, Widget screen, {bool fullscreen = false}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: fullscreen,
        builder: (_) => screen,
      ),
    );
  }

  void _openTalker(BuildContext context) {
    final services = this.services;
    final makeLive = services?.live;
    // The talker blocks system back; its held leave control calls onExit.
    Widget talker(LiveSession? live) => Builder(
      builder: (talkerContext) => TalkerScreen(
        store: store,
        speech: speech,
        sync: sync,
        live: live,
        media: services?.media,
        speaker: services?.speaker,
        onExit: () => Navigator.of(talkerContext).pop(),
      ),
    );
    _open(
      context,
      // The live session lasts exactly as long as the board is open.
      makeLive == null
          ? talker(null)
          : LiveScope(
              create: () => makeLive(forTalker: true),
              builder: (_, live) => talker(live),
            ),
      fullscreen: true,
    );
  }

  void _openEditor(BuildContext context) {
    final services = this.services;
    final makeLive = services?.live;
    Widget editor(LiveSession? live) => EditorScreen(
      store: store,
      sync: sync,
      live: live,
      media: services?.media,
      capture: services?.capture,
      speaker: services?.speaker,
      suggester: services?.suggester,
      // From the editor the page is of the board the adult is looking at.
      onPrint: services?.publishBoard == null
          ? null
          : (board) => _printCopy(context, board: board),
    );
    _open(
      context,
      makeLive == null
          ? editor(null)
          : LiveScope(
              create: () => makeLive(forTalker: false),
              builder: (_, live) => editor(live),
            ),
    );
  }

  /// Builds the snapshot from the board on this device and shows where its
  /// printable page is. Prints [board] when given (the editor's selected
  /// board), else the home board.
  void _printCopy(BuildContext context, {BoardFacts? board}) {
    final publish = services?.publishBoard;
    board ??= boardToPrint(store.boards);
    if (publish == null || board == null) return;
    if (sync.workingOffline) {
      // Paused on purpose: say so instead of reaching for the network.
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Paper copy'),
          content: const Text(printCopyOfflineMessage),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      return;
    }
    final boardJson = printSnapshotJson(
      childName: selected.childName,
      board: board,
      tiles: store.tiles,
      boards: store.boards,
    );
    showDialog<void>(
      context: context,
      builder: (_) => _PaperCopyDialog(
        // Never throws synchronously, whatever the service does.
        link: Future<String>.sync(() => publish(boardJson)),
        childName: selected.childName,
      ),
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
                final services = this.services;
                final media = services?.media;
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
                      onPressed: hasBoard ? () => _openEditor(context) : null,
                    ),
                    if (media != null) _WaitingUploads(media: media),
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
                    if (services?.publishBoard != null)
                      BigButton(
                        icon: Icons.print_outlined,
                        label: printCopyLabel,
                        primary: false,
                        onPressed: hasBoard ? () => _printCopy(context) : null,
                      ),
                    // Sharing is a guardian's choice, made here and never on
                    // the child's board, which can only turn it off.
                    if (canInvite && services?.live != null)
                      ShareSaidSwitch(
                        userId: services!.userId,
                        circleId: selected.spaceUuid.uuid,
                        childName: selected.childName,
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

/// Says how many photos and recordings made on this device the server does
/// not hold yet. Shows nothing when there are none.
class _WaitingUploads extends StatelessWidget {
  const _WaitingUploads({required this.media});

  final MediaStore media;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: media,
      builder: (context, _) {
        final waiting = media.pendingUploads;
        if (waiting <= 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Icon(Icons.cloud_upload_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  waiting == 1
                      ? '1 photo or recording is waiting to be sent from '
                            'this device.'
                      : '$waiting photos or recordings are waiting to be '
                            'sent from this device.',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Waits for the printable page and then shows its address.
class _PaperCopyDialog extends StatelessWidget {
  const _PaperCopyDialog({required this.link, required this.childName});

  /// The page's address; fails when the page could not be made.
  final Future<String> link;
  final String childName;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: link,
      builder: (context, snapshot) {
        final address = snapshot.data;
        final failed = snapshot.hasError;
        return AlertDialog(
          title: const Text('Paper copy'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: failed
                ? const Text(printCopyFailedMessage)
                : address == null
                ? const Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                      SizedBox(width: 16),
                      Expanded(child: Text('Making a page to print…')),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Open this link on a computer with a printer. It "
                        "shows the words on $childName's board as they are "
                        'on this device now.',
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        address,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Anyone with the link can see the words, without '
                        'signing in. It shows no photos and plays no '
                        'recordings, and it stops working after 30 days.',
                      ),
                    ],
                  ),
          ),
          actions: [
            if (address != null)
              TextButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  await Clipboard.setData(ClipboardData(text: address));
                  messenger?.showSnackBar(
                    const SnackBar(content: Text('Link copied.')),
                  );
                },
                child: const Text('Copy link'),
              ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(address == null && !failed ? 'Cancel' : 'Done'),
            ),
          ],
        );
      },
    );
  }
}
