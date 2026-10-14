/// "Try a clash": a guide in three steps that lets one adult, on one
/// device, watch two offline words meet in one spot and both survive.
///
/// The guide lives in the editor, above the board, so it stays put while
/// the add-word sheet opens and closes over it. It never says which word
/// will keep the spot: the word that got there first does, and the guide
/// only says which one did once both have arrived.
library;

import 'dart:async';

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';

import '../../brand/haptics.dart';
import '../../brand/motion.dart';
import '../../brand/tokens.dart';
import '../../contracts.dart';
import '../../contracts_clash.dart';
import '../../editor/tray_panel.dart' show GridGeometry;
import '../flags/w1.dart';

/// The board menu's entry that opens the guide.
const String tryAClashLabel = 'Try a clash';

/// The guide's heading.
const String clashGuideTitle = 'Try a clash';

/// Step 1, while the device goes offline and the partner is asked.
const String clashPreparingMessage =
    'Getting ready. This device is switching to Work offline, like a phone '
    'with no signal.';

/// Step 2: the partner's word is down; the adult adds theirs.
String clashPlaceYoursMessage(String partnerWord) =>
    'The practice partner just put "$partnerWord" here on their own device. '
    'Now put your own word in the glowing spot.';

/// Step 3: the adult's word is down; time to reconnect.
const String clashGoOnlineMessage =
    'Your word is saved on this device. Now turn Work offline off.';

/// The button in step 3.
const String clashGoOnlineAction = 'Turn Work offline off';

/// While the two words travel.
const String clashWaitingMessage = 'Sending your word and bringing in theirs…';

/// The end: both words are here.
String clashDoneMessage({required String kept, required String waiting}) =>
    'Both words are safe. "$kept" got to the spot first, so it keeps it. '
    '"$waiting" waits under Needs a home, on every adult\'s device. Nothing '
    'was lost: choose a new spot for it whenever you like. Tap a practice '
    'word to remove it when you are done.';

/// The partner's word arrived before the adult's.
const String clashMissedMessage =
    'The practice partner\'s word arrived first, because Work offline was '
    'turned off before your word went in. Try again to see two words meet.';

/// No empty spot on any board.
const String clashNoSpotMessage =
    'Every spot is taken. Remove a word, or add a board with +, then try '
    'again.';

/// The partner may not add more words this hour.
const String clashTooManyMessage =
    'The practice partner needs a rest. Try again in an hour.';

/// The board has not reached the others yet.
const String clashNoSuchCellMessage =
    'This board has not reached the others yet. Turn Work offline off for a '
    'moment, then try again.';

/// The partner could not be reached.
const String clashUnreachableMessage =
    'This needs a connection for a moment. Check the connection, then try '
    'again.';

/// This adult may not change the board.
const String clashNotAllowedMessage =
    'Only the family and therapist can change this board.';

/// The buttons.
const String clashCloseAction = 'Close';
const String clashTryAgainAction = 'Try again';
const String clashDoneAction = 'Done';

/// Where the guide is.
enum ClashStep { preparing, placeYours, goOnline, waiting, done, stopped }

/// Runs the guide over a [store], its [sync] and the practice [partner].
///
/// [preferBoard] is the board on show; the guide uses it when it has an
/// empty spot, else the first board that does.
class ClashGuide extends ChangeNotifier {
  ClashGuide({
    required this.store,
    required this.sync,
    required this.partner,
    this.preferBoard,
    this.settleTimeout = const Duration(seconds: 8),
  }) {
    store.addListener(_onChange);
    sync.addListener(_onChange);
  }

  final BoardStore store;
  final SyncStatus sync;
  final ClashPartner partner;
  final String? preferBoard;

  /// How long the guide waits for a sync before going offline.
  final Duration settleTimeout;

  ClashStep _step = ClashStep.preparing;
  ClashStep get step => _step;

  /// The spot that glows: set from step 2 on.
  PlacedCell? _spot;
  PlacedCell? get spot => _spot;

  PartnerWord? _word;
  PartnerWord? get word => _word;

  /// Why the guide stopped, in words for the adult; null unless [step] is
  /// [ClashStep.stopped].
  String? _stopped;
  String? get stoppedMessage => _stopped;

  /// The labels of the two words once both are here.
  ({String kept, String waiting})? _outcome;
  ({String kept, String waiting})? get outcome => _outcome;

  bool _turnedOffline = false;
  bool _disposed = false;

  /// The message for the step the guide is on.
  String get message => switch (_step) {
    ClashStep.preparing => clashPreparingMessage,
    ClashStep.placeYours => clashPlaceYoursMessage(_word?.label ?? ''),
    ClashStep.goOnline => clashGoOnlineMessage,
    ClashStep.waiting => clashWaitingMessage,
    ClashStep.done => clashDoneMessage(
      kept: _outcome?.kept ?? '',
      waiting: _outcome?.waiting ?? '',
    ),
    ClashStep.stopped => _stopped ?? '',
  };

  /// Step 1: goes offline, picks a spot and has the partner fill it.
  Future<void> start() async {
    _step = ClashStep.preparing;
    _stopped = null;
    _outcome = null;
    _word = null;
    _spot = null;
    _notify();

    final spots = _emptySpots();
    if (spots.isEmpty) return _stop(clashNoSpotMessage);

    if (!sync.workingOffline) {
      // Brings the board to the server and this device up to date first.
      try {
        await sync.syncNow().timeout(settleTimeout);
      } catch (_) {
        // Carry on: the partner's answer says whether the board is there.
      }
      if (_disposed) return;
      await sync.setWorkingOffline(true);
      _turnedOffline = true;
      if (_disposed) return;
    }

    for (final spot in spots.take(4)) {
      try {
        final word = await partner.putWord(
          boardId: spot.boardId,
          row: spot.row,
          col: spot.col,
        );
        if (_disposed) return;
        _word = word;
        _spot = spot;
        _step = ClashStep.placeYours;
        ChorusHaptics.wordAdded();
        _notify();
        _onChange();
        return;
      } on PracticeRefused catch (refused) {
        if (refused.reason == PracticeRefusal.cellTaken) continue;
        return _stop(switch (refused.reason) {
          PracticeRefusal.tooMany => clashTooManyMessage,
          PracticeRefusal.noSuchCell => clashNoSuchCellMessage,
          PracticeRefusal.notAllowed => clashNotAllowedMessage,
          PracticeRefusal.unreachable ||
          PracticeRefusal.cellTaken => clashUnreachableMessage,
        });
      } catch (_) {
        return _stop(clashUnreachableMessage);
      }
    }
    return _stop(clashNoSpotMessage);
  }

  /// Step 3's button.
  Future<void> goOnline() => sync.setWorkingOffline(false);

  /// Puts the device back online if the guide took it offline and the
  /// adult has not done so yet. Called when the guide is closed.
  Future<void> close() async {
    if (_turnedOffline && sync.workingOffline) {
      _turnedOffline = false;
      await sync.setWorkingOffline(false);
    }
  }

  Future<void> _stop(String message) async {
    if (_disposed) return;
    ChorusHaptics.failed();
    _step = ClashStep.stopped;
    _stopped = message;
    _spot = null;
    _notify();
    if (_turnedOffline && sync.workingOffline) {
      _turnedOffline = false;
      await sync.setWorkingOffline(false);
    }
  }

  /// Empty spots, the preferred board's first, each board in reading
  /// order.
  List<PlacedCell> _emptySpots() {
    final boards = store.boards.where((b) => !b.archived).toList()
      ..sort((a, b) {
        if (a.id == preferBoard) return -1;
        if (b.id == preferBoard) return 1;
        return 0;
      });
    return [
      for (final board in boards)
        for (final (row, col) in _free(board)) PlacedCell(board.id, row, col),
    ];
  }

  Iterable<(int, int)> _free(BoardFacts board) sync* {
    final taken = gridOf(board.id, store.tiles, store.boards);
    for (var row = 0; row < board.rows; row++) {
      for (var col = 0; col < board.cols; col++) {
        if (!taken.containsKey((row, col))) yield (row, col);
      }
    }
  }

  void _onChange() {
    if (_disposed) return;
    final spot = _spot;
    final word = _word;
    if (spot == null || word == null) return;
    final holder = gridOf(
      spot.boardId,
      store.tiles,
      store.boards,
    )[(spot.row, spot.col)];
    switch (_step) {
      case ClashStep.placeYours:
        if (holder == null) return;
        if (holder.id == word.tileId ||
            (holder.createdByName == word.partnerName &&
                holder.label == word.label)) {
          _turnedOffline = false;
          unawaited(_stop(clashMissedMessage));
          return;
        }
        _step = ClashStep.goOnline;
        _notify();
      case ClashStep.goOnline:
        if (sync.workingOffline) return;
        _step = ClashStep.waiting;
        _notify();
        _onChange();
      case ClashStep.waiting:
        final waiting = store.tiles.where((tile) {
          final key = CellKey.parse(tile.cellKey);
          return !tile.archived && key is ContestedCell && key.wanted == spot;
        }).firstOrNull;
        if (holder == null || waiting == null || sync.hasUnsent) return;
        _outcome = (kept: holder.label, waiting: waiting.label);
        _step = ClashStep.done;
        _turnedOffline = false;
        ChorusHaptics.clashArrived();
        _notify();
      case ClashStep.preparing || ClashStep.done || ClashStep.stopped:
        return;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    store.removeListener(_onChange);
    sync.removeListener(_onChange);
    super.dispose();
  }
}

/// Whether the editor offers "Try a clash": the flag is on, a partner is
/// wired in and the adult may edit.
bool offersClash(ClashPartner? partner, BoardStore store) =>
    tryAClashEnabled && partner != null && store.role.canEdit;

/// The guide's card, above the board in the editor.
class ClashGuideCard extends StatelessWidget {
  const ClashGuideCard({super.key, required this.guide, required this.onClose});

  final ClashGuide guide;

  /// Closes the guide; the editor drops it.
  final VoidCallback onClose;

  /// The card, for tests.
  @visibleForTesting
  static const Key cardKey = ValueKey('ClashGuideCard');

  static int _number(ClashStep step) => switch (step) {
    ClashStep.preparing => 1,
    ClashStep.placeYours => 2,
    ClashStep.goOnline || ClashStep.waiting || ClashStep.done => 3,
    ClashStep.stopped => 0,
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: guide,
      builder: (context, _) {
        final colors = ChorusColors.of(context);
        final step = guide.step;
        final number = _number(step);
        final busy = step == ClashStep.preparing || step == ClashStep.waiting;
        return Semantics(
          container: true,
          liveRegion: true,
          child: AnimatedSize(
            duration: ChorusMotion.duration(
              context,
              ChorusMotion.entranceShort,
            ),
            curve: ChorusMotion.entrance,
            alignment: Alignment.topCenter,
            child: DecoratedBox(
              key: cardKey,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(ChorusSpace.panelRadius),
                border: Border.all(color: colors.ink, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.call_split_rounded, color: colors.ink),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            number == 0
                                ? clashGuideTitle
                                : '$clashGuideTitle · $number of 3',
                            style: ChorusType.label.copyWith(color: colors.ink),
                          ),
                        ),
                        if (busy)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: ChorusMotion.reduced(context)
                                ? Icon(
                                    Icons.hourglass_empty_rounded,
                                    size: 18,
                                    color: colors.ink,
                                  )
                                : const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        guide.message,
                        style: ChorusType.body.copyWith(color: colors.ink),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: ChorusSpace.targetGap,
                      children: [
                        if (step == ClashStep.stopped)
                          TextButton(
                            onPressed: () => unawaited(guide.start()),
                            child: const Text(clashTryAgainAction),
                          ),
                        if (step == ClashStep.goOnline)
                          FilledButton(
                            onPressed: () => unawaited(guide.goOnline()),
                            child: const Text(clashGoOnlineAction),
                          ),
                        TextButton(
                          onPressed: onClose,
                          child: Text(
                            step == ClashStep.done
                                ? clashDoneAction
                                : clashCloseAction,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// [header] with the guide's card under it, or [header] alone with no
/// guide.
Widget withClashGuide(
  Widget header, {
  required ClashGuide? guide,
  required VoidCallback onClose,
}) {
  if (guide == null || !tryAClashEnabled) return header;
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      header,
      const SizedBox(height: 16),
      ClashGuideCard(guide: guide, onClose: onClose),
    ],
  );
}

/// [grid] of [board] with the guide's spot glowing over it, when the spot
/// is on that board. The glow takes no taps: the empty spot under it still
/// opens the add-word sheet.
Widget withClashGlow(
  Widget grid, {
  required ClashGuide? guide,
  required BoardFacts board,
}) {
  if (guide == null || !tryAClashEnabled) return grid;
  return ListenableBuilder(
    listenable: guide,
    builder: (context, child) {
      final spot = guide.spot;
      final glowing =
          spot != null &&
          spot.boardId == board.id &&
          guide.step == ClashStep.placeYours;
      if (!glowing) return child!;
      return Stack(
        children: [
          child!,
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, box) {
                  final geometry = GridGeometry(
                    rows: board.rows,
                    cols: board.cols,
                    size: box.biggest,
                  );
                  return Stack(
                    children: [
                      Positioned.fromRect(
                        rect: geometry.cell(spot.row, spot.col),
                        child: const ClashGlow(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      );
    },
    child: grid,
  );
}

/// The glowing outline on the spot to fill: ink, breathing slowly, and
/// still under reduced motion.
class ClashGlow extends StatefulWidget {
  const ClashGlow({super.key});

  @override
  State<ClashGlow> createState() => _ClashGlowState();
}

class _ClashGlowState extends State<ClashGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    // Brings the spot into view once, mid-screen, clear of the tray's sheet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: ChorusMotion.duration(context, ChorusMotion.entranceShort),
        curve: ChorusMotion.entrance,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ChorusMotion.reduced(context)) {
      _breath
        ..stop()
        ..value = 1;
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final radius = BorderRadius.circular(
          ChorusSpace.tileRadiusFor(box.biggest.shortestSide),
        );
        return AnimatedBuilder(
          animation: _breath,
          builder: (context, _) {
            final t = ChorusMotion.entrance.transform(_breath.value);
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: colors.ink, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: colors.ink.withValues(alpha: 0.10 + 0.20 * t),
                    blurRadius: 6 + 10 * t,
                    spreadRadius: 1 + 2 * t,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
