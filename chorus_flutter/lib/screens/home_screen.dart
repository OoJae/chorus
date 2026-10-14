/// Home for one circle: the child's board as an object, in reach, and the
/// adult's quiet list under it.
library;

import 'dart:async';

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_shared/chorus_shared.dart'
    show BoardFacts, boardToPrint, gridOf, printSnapshotJson;
import 'package:chorus_ui/brand/motion.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:chorus_ui/contracts.dart' hide CircleRole;
import 'package:chorus_ui/contracts_live.dart';
import 'package:chorus_ui/contracts_media.dart';
import 'package:chorus_ui/contracts_sharing.dart';
import 'package:chorus_ui/credits/credits_screen.dart';
import 'package:chorus_ui/editor/editor_screen.dart';
import 'package:chorus_ui/features/features.dart';
import 'package:chorus_ui/home/home.dart';
import 'package:chorus_ui/talker/talker_screen.dart';
import 'package:chorus_ui/widgets/sync_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../src/live/live_scope.dart';
import '../src/sharing/share_link.dart';
import '../src/sync/replica_board_store.dart';
import 'invite_screen.dart';
import 'messages.dart';
import 'services.dart';

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

/// The primary action on home: opens the child's board.
String openBoardLabel(String childName) => "Open $childName's board";

/// The primary action for a read-only partner.
String viewBoardLabel(String childName) => "View $childName's board";

/// Opens the editor; not offered to a read-only partner.
const String editWordsLabel = 'Edit words';

/// Adds a circle: another child, not another board of this child.
const String addAnotherChildLabel = "Add or join another child's board";

/// Opens the view-only page for a babysitter.
const String shareViewOnlyLabel = 'Share a view-only board';

/// Opens the word log settings and "This week".
const String wordLogLabel = 'Word log and this week';

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

  /// Adds or joins another child's circle.
  final VoidCallback? onAddBoard;

  /// Photos and voices, the live session, the word suggestion, the paper
  /// copy, the word log, sharing and board management of the selected
  /// circle. Null leaves all of them out.
  final CircleServices? services;

  void _open(BuildContext context, Widget screen) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  /// The child's board, flying in from the hero: see [BoardRoute].
  void _openTalker(BuildContext context) {
    final services = this.services;
    final makeLive = services?.live;
    final reduced = ChorusMotion.reduced(context);
    final board = heroBoardOf(store);
    // The tag pairs the hero with the talker's grid; under reduced motion
    // home has no hero, so nothing flies.
    final heroTag = board == null || reduced ? null : boardHeroTag(board.id);
    // The talker blocks system back; its held leave control calls onExit.
    Widget talker(LiveSession? live) => Builder(
      builder: (talkerContext) => TalkerScreen(
        store: store,
        speech: speech,
        sync: sync,
        live: live,
        media: services?.media,
        speaker: services?.speaker,
        wordLog: services?.wordLog,
        heroTag: heroTag,
        onExit: () => Navigator.of(talkerContext).pop(),
      ),
    );
    Navigator.of(context).push(
      BoardRoute<void>(
        reducedMotion: reduced,
        builder: (_) => makeLive == null
            ? talker(null)
            // The live session lasts exactly as long as the board is open.
            : LiveScope(
                create: () => makeLive(forTalker: true),
                builder: (_, live) => talker(live),
              ),
      ),
    );
  }

  /// "Share a view-only board": a speaking page of the board home shows,
  /// for a babysitter.
  void _shareViewOnly(BuildContext context, BoardSharing sharing) {
    final board = heroBoardOf(store);
    if (board == null) return;
    _open(
      context,
      ShareViewOnlyScreen(
        sharing: sharing,
        board: board,
        childName: selected.childName,
        onShare: systemShareLink(),
        sync: sync,
      ),
    );
  }

  /// "Word log and this week": the log's settings, which lead on to the
  /// week; or the week alone where the circle has no log here.
  void _openWordLog(BuildContext context) {
    final services = this.services;
    final log = services?.wordLog;
    final summary = services?.summary;
    if (log != null) {
      _open(
        context,
        WordLogScreen(
          log: log,
          childName: selected.childName,
          summary: summary,
          store: store,
          sync: sync,
        ),
      );
    } else if (summary != null) {
      _open(
        context,
        ThisWeekScreen(
          source: summary,
          childName: selected.childName,
          tiles: store.tiles,
          role: store.role,
        ),
      );
    }
  }

  void _openEditor(BuildContext context) {
    final services = this.services;
    final makeLive = services?.live;
    final sharing = services?.sharing;
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
      // So is the .obf file.
      onExport: sharing == null
          ? null
          : (board) => _open(
              context,
              ExportObfScreen(
                sharing: sharing,
                board: board,
                childName: selected.childName,
                onShare: systemShareLink(),
                sync: sync,
              ),
            ),
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
    final canInvite = selected.myRole == CircleRole.guardian;
    final canEdit = selected.myRole != CircleRole.partner;
    final childName = selected.childName;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        // A board already on this device can be used straight away,
        // whatever the network is doing.
        final hasBoard = store.boards.any((board) => !board.archived);
        // The replica's own store says when it has read this device; any
        // other store (tests, fakes) is read from the start.
        final current = store;
        final loaded = current is! ReplicaBoardStore || current.hasLoaded;
        final board = heroBoardOf(store);
        final noWords =
            board != null &&
            gridOf(board.id, store.tiles, store.boards).isEmpty;
        final services = this.services;
        final open = hasBoard ? () => _openTalker(context) : null;

        final readinessNote = _readinessNote(
          context,
          hasBoard: hasBoard,
          loaded: loaded,
        );
        return HomeLayout(
          status: SyncChip(sync: sync),
          title: "$childName's board",
          hero: (context, lean) => HomeHero(
            store: store,
            childName: childName,
            media: services?.media,
            lean: lean,
            loading: !loaded && !hasBoard,
            onOpen: open,
          ),
          actions: HomeActions(
            openLabel: canEdit
                ? openBoardLabel(childName)
                : viewBoardLabel(childName),
            onOpen: open,
            editLabel: canEdit ? editWordsLabel : null,
            onEdit: hasBoard ? () => _openEditor(context) : null,
          ),
          notes: [
            ?readinessNote,
            if (noWords)
              HomeNote(
                icon: const Icon(Icons.grid_view_rounded),
                message: canEdit
                    ? "There are no words on $childName's board yet. Add "
                          'the first ones with Edit words.'
                    : "There are no words on $childName's board yet. They "
                          'appear here when someone in the circle adds them.',
              ),
          ],
          list: _list(context, hasBoard: hasBoard, canInvite: canInvite),
        );
      },
    );
  }

  /// The quiet list, in groups with a hairline between them.
  List<Widget> _list(
    BuildContext context, {
    required bool hasBoard,
    required bool canInvite,
  }) {
    final services = this.services;
    final media = services?.media;
    final sharing = services?.sharing;

    final groups = <List<Widget>>[
      [
        ListenableBuilder(
          listenable: sync,
          builder: (context, _) => LayoutBuilder(
            builder: (context, box) {
              const explanation = Text(
                'Pauses sync on this device. Changes are kept here and sent '
                'when you switch it back.',
              );
              void onChanged(bool value) =>
                  unawaited(sync.setWorkingOffline(value));
              // As with "Share what is said": on a phone the explanation
              // would be a narrow column between the icon and the switch, so
              // it goes under them at the full width.
              if (box.maxWidth >= 480) {
                return SwitchListTile(
                  secondary: const Icon(Icons.cloud_off_rounded),
                  title: const Text('Work offline'),
                  subtitle: explanation,
                  value: sync.workingOffline,
                  onChanged: onChanged,
                );
              }
              final theme = Theme.of(context);
              return MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.cloud_off_rounded),
                      title: const Text('Work offline'),
                      value: sync.workingOffline,
                      onChanged: onChanged,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 24, 12),
                      child: DefaultTextStyle.merge(
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        child: explanation,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (media != null) _WaitingUploads(media: media),
      ],
      [
        if (canInvite)
          HomeEntry(
            icon: Icons.person_add_alt_rounded,
            label: 'Invite someone',
            onTap: () => _open(
              context,
              InviteScreen(gateway: gateway, circle: selected),
            ),
          ),
        if (sharing != null)
          HomeEntry(
            icon: Icons.link_rounded,
            label: shareViewOnlyLabel,
            onTap: hasBoard ? () => _shareViewOnly(context, sharing) : null,
          ),
        if (services?.publishBoard != null)
          HomeEntry(
            icon: Icons.print_rounded,
            label: printCopyLabel,
            opensScreen: false,
            onTap: hasBoard ? () => _printCopy(context) : null,
          ),
        if (services?.wordLog != null || services?.summary != null)
          HomeEntry(
            icon: Icons.bar_chart_rounded,
            label: wordLogLabel,
            onTap: () => _openWordLog(context),
          ),
        // Sharing is a guardian's choice, made here and never on the
        // child's board, which can only turn it off.
        if (canInvite && services?.live != null)
          ShareSaidSwitch(
            userId: services!.userId,
            circleId: selected.spaceUuid.uuid,
            childName: selected.childName,
          ),
      ],
      [
        HomeEntry(
          icon: Icons.info_outline_rounded,
          label: 'Credits',
          onTap: () => _open(context, const CreditsScreen()),
        ),
        HomeEntry(
          icon: Icons.logout_rounded,
          label: 'Sign out',
          opensScreen: false,
          onTap: onSignOut,
        ),
      ],
      [
        _CircleSwitcher(
          circles: circles,
          selected: selected,
          onSelect: onSelect,
        ),
        if (onAddBoard != null)
          HomeEntry(
            icon: Icons.add_rounded,
            label: addAnotherChildLabel,
            onTap: onAddBoard,
          ),
      ],
    ];
    return [
      for (final (i, group) in groups.where((g) => g.isNotEmpty).indexed) ...[
        if (i > 0) const Divider(height: 33, indent: 16, endIndent: 16),
        ...group,
      ],
    ];
  }

  /// What this device is still doing for the circle, or what failed; null
  /// once the circle is ready and its board is here.
  Widget? _readinessNote(
    BuildContext context, {
    required bool hasBoard,
    required bool loaded,
  }) {
    if (readiness == CircleReadiness.ready && hasBoard) return null;
    final childName = selected.childName;
    final working = ChorusMotion.reduced(context)
        ? const Icon(Icons.hourglass_empty_rounded)
        : const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          );
    if (!loaded && !hasBoard) {
      return HomeNote(icon: working, message: "Opening $childName's board…");
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
    return HomeNote(
      alert: failed,
      icon: failed
          ? const Icon(Icons.error_outline_rounded)
          : waiting
          ? const Icon(Icons.hourglass_empty_rounded)
          : working,
      message: message,
      action: failed || waiting
          ? TextButton(onPressed: onRetryReady, child: const Text('Retry'))
          : null,
    );
  }
}

/// Who the adult is in this circle, and the other children's boards they
/// help with.
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
    final colors = ChorusColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You are ${selected.myDisplayName} '
            '(${roleLabel(selected.myRole)}).',
            style: ChorusType.body.copyWith(color: colors.inkMuted),
          ),
          if (circles.length > 1) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: ChorusSpace.targetGap,
              runSpacing: ChorusSpace.targetGap,
              children: [
                for (final circle in circles)
                  ChoiceChip(
                    label: Text(circle.childName),
                    selected: circle.spaceUuid == selected.spaceUuid,
                    onSelected: (_) => onSelect(circle),
                  ),
              ],
            ),
          ],
        ],
      ),
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
        return ListTile(
          leading: const Icon(Icons.cloud_upload_rounded),
          title: Text(
            waiting == 1
                ? '1 photo or recording is waiting to be sent from this '
                      'device.'
                : '$waiting photos or recordings are waiting to be sent '
                      'from this device.',
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
                        style: ChorusType.status.copyWith(
                          fontSize: 15,
                          height: 20 / 15,
                        ),
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
