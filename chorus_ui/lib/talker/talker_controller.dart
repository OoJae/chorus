/// State behind the child's board.
library;

import 'dart:async';

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/foundation.dart';

import '../contracts.dart';
import '../contracts_live.dart';
import '../contracts_media.dart';
import '../contracts_wordlog.dart';

/// Holds the board the child sees and the sentence being built.
///
/// The held snapshot is not the replica: merges from other devices are kept
/// as a waiting plan and only the automatic part of it is applied, and only at
/// a safe point (strip empty, nothing playing, no finger down and no touch
/// for [quiet]). Changes that would swap or move a visible tile, and a resize
/// of the grid, wait for [applyAdultChanges]. The board tabs are held the
/// same way; see [tabs].
/// This class only reads the store.
///
/// With a [LiveSession] the controller also reports which tiles an adult is
/// pointing at ([pulsing]) and, only while a guardian has sharing on, sends
/// each spoken sentence to the circle. A glow never changes the snapshot.
///
/// With a [WordLog] each tapped word is offered to it ([WordLog.noteSpoken]),
/// which keeps it only while a guardian has the log on. [setPrivate] pauses
/// the log and the sharing of sentences for the session.
class TalkerController extends ChangeNotifier {
  TalkerController({
    required this._store,
    required this._speech,
    this._speaker,
    this._live,
    this._wordLog,
    this._boardId,
    this._quiet = const Duration(seconds: 2),
  }) {
    final board = _targetBoard();
    if (board != null) {
      _held = BoardSnapshot.of(board, _store.tiles, _store.boards);
      _fresh = _held;
    }
    _tabs = nextTabs(const [], _store.boards, onShow: _held?.board.id);
    _store.addListener(_onStoreChanged);
    _live?.addListener(_onLiveChanged);
    _wordLog?.addListener(_onLiveChanged);
    _timer = Timer.periodic(recheckEvery, (_) => checkSafePoint());
  }

  /// How often a waiting plan is re-tested against the safe point.
  static const Duration recheckEvery = Duration(milliseconds: 500);

  final BoardStore _store;
  final SpeechService _speech;

  /// Plays a tile's recorded clip. Null falls back to [_speech] when that
  /// can play clips itself, and to the tile's text otherwise.
  final TileSpeaker? _speaker;
  final LiveSession? _live;
  final WordLog? _wordLog;
  String? _boardId;

  /// Private mode where there is no word log to keep it: for as long as
  /// this controller lives.
  bool _private = false;
  final Duration _quiet;

  Timer? _timer;
  BoardSnapshot? _held;
  BoardSnapshot? _fresh;
  SnapshotPlan? _plan;

  /// The tabs the child sees; see [tabs].
  List<BoardFacts?> _tabs = const [];

  /// The tabs as the replica has them now, while that differs from
  /// [_tabs]: they wait like a word does.
  List<BoardFacts?>? _nextTabs;

  /// What the child last saw on each board they have left, by board id.
  /// Coming back to a board starts from this, not from the replica.
  final Map<String, BoardSnapshot> _heldByBoard = {};
  final List<TileFacts> _strip = [];
  // Monotonic: a wall clock set backwards would stall every merge.
  final Stopwatch _sinceTouch = Stopwatch()..start();
  int _pointersDown = 0;
  bool _disposed = false;

  /// What the child sees. Null until the circle has a board to show.
  BoardSnapshot? get snapshot => _held;

  /// The sentence so far, oldest first.
  List<TileFacts> get strip => List.unmodifiable(_strip);

  /// Changes held back from the child's board, automatic or not. A resize
  /// of the grid counts as one.
  int get waitingCount => (_plan?.waitingCount ?? 0) + (_resized ? 1 : 0);

  /// True when some waiting change would swap or move a visible tile, or
  /// the grid was resized.
  bool get needsAdult => (_plan?.needsAdult.isNotEmpty ?? false) || _resized;

  /// The replica's grid has a different size from the one shown. The plan
  /// keeps the held board, so this is true until an adult accepts.
  bool get _resized {
    final held = _held, fresh = _fresh;
    return held != null &&
        fresh != null &&
        (held.board.rows != fresh.board.rows ||
            held.board.cols != fresh.board.cols);
  }

  /// Ids of the tiles an adult is pointing at from another device. Empty
  /// without a live session.
  Set<String> get pulsing => _live?.pulsing ?? const {};

  /// True while this board is joined to the circle's live session.
  bool get liveConnected => _live?.connected ?? false;

  /// True while a guardian has sharing on for this device, private or not.
  bool get sharingOn => _live?.shareSaid ?? false;

  /// True while each spoken sentence is being sent to the circle: a
  /// guardian turned sharing on and the board is not [private].
  bool get sharingSaid => sharingOn && !private;

  /// Turns sharing off on this device. Turning it on is a guardian's
  /// choice, made outside the child's board.
  void stopSharingSaid() {
    noteTouch();
    final live = _live;
    if (live != null && live.shareSaid) live.shareSaid = false;
  }

  /// True when there is something for [private] to pause: a word log or a
  /// live session that can share sentences.
  bool get offersPrivate => _wordLog != null || _live != null;

  /// True while the board is private: no word is logged and no sentence is
  /// shared. Kept by the word log for the whole session when there is one,
  /// otherwise for as long as this board is open.
  bool get private => _wordLog?.private ?? _private;

  /// Pauses ([value] true) or resumes the word log and the sharing of
  /// sentences. It does not change the guardian's sharing setting, which
  /// comes back as it was when private mode ends.
  void setPrivate(bool value) {
    noteTouch();
    final log = _wordLog;
    if (log == null) {
      if (_private == value) return;
      _private = value;
      notifyListeners();
      return;
    }
    // The log tells its listeners, this controller among them.
    try {
      log.setPrivate(value);
    } catch (_) {
      // The board must keep working whatever the log does.
    }
  }

  /// Ids of the boards that hold a tile an adult is pointing at, so a tab
  /// can show where the word is when it is not on the board on show.
  Set<String> get pulsingBoardIds {
    final ids = pulsing;
    if (ids.isEmpty) return const {};
    return {
      for (final tile in _store.tiles)
        if (!tile.archived && ids.contains(tile.id)) tile.boardId,
    };
  }

  /// Id of the board on show, if any.
  String? get boardId => _held?.board.id;

  /// The board tabs, in the places the child knows them: a child finds a
  /// board by where its tab is.
  ///
  /// Like the words, they are held: a board added, renamed or archived on
  /// another device shows here only at a safe point (see [checkSafePoint]),
  /// when the child goes to another board, or when an adult accepts the
  /// waiting changes. Each board keeps its place. A board that leaves
  /// leaves an empty place (null), so no other tab moves, and a new board
  /// takes the first empty place or else goes at the end. The board on show
  /// keeps its tab even after an adult archives it, so the child can always
  /// get back to the others.
  List<BoardFacts?> get tabs => List.unmodifiable(_tabs);

  /// True when the tabs are drawn: there are two places or more. Once
  /// drawn they stay for as long as this board is open, so the grid under
  /// them never moves up.
  bool get showsTabs => _tabs.length > 1;

  /// The tabs after the circle's boards became [boards]: see [tabs]. Pure.
  /// [onShow] is the id of the board on show.
  @visibleForTesting
  static List<BoardFacts?> nextTabs(
    List<BoardFacts?> tabs,
    Iterable<BoardFacts> boards, {
    String? onShow,
  }) {
    // Home first, then in the order the circle made them.
    final inUse = <String, BoardFacts>{
      for (final board in boards.where((b) => b.isHome && !b.archived))
        board.id: board,
      for (final board in boards.where((b) => !b.isHome && !b.archived))
        board.id: board,
    };
    final next = <BoardFacts?>[];
    for (final tab in tabs) {
      final now = tab == null ? null : inUse.remove(tab.id);
      next.add(now ?? (tab != null && tab.id == onShow ? tab : null));
    }
    for (final board in inUse.values) {
      final empty = next.indexOf(null);
      if (empty < 0) {
        next.add(board);
      } else {
        next[empty] = board;
      }
    }
    return next;
  }

  /// [nextTabs] for the replica as it is now, or null when nothing changes.
  List<BoardFacts?>? _tabsToApply() {
    final next = nextTabs(_tabs, _store.boards, onShow: boardId);
    return listEquals(next, _tabs) ? null : next;
  }

  /// Shows the replica's boards in the tabs now.
  void _applyTabs() {
    _tabs = _tabsToApply() ?? _tabs;
    _nextTabs = null;
  }

  /// Goes to another board. Moving between boards is the child's own act,
  /// so it happens at once, strip or no strip.
  ///
  /// A board the child has not opened yet is shown as the replica has it
  /// now. A board they are coming back to is shown as they left it: what
  /// adults changed meanwhile waits like any other merge, and a swap, a move
  /// or a resize still needs [applyAdultChanges]. Switching tabs is never a
  /// way round that.
  void showBoard(String boardId) {
    noteTouch();
    final board = _store.boards
        .where((b) => !b.archived && b.id == boardId)
        .firstOrNull;
    final leaving = _held;
    if (board == null || board.id == leaving?.board.id) return;
    if (leaving != null) _heldByBoard[leaving.board.id] = leaving;
    _boardId = board.id;
    final fresh = BoardSnapshot.of(board, _store.tiles, _store.boards);
    final held = _heldByBoard[board.id] ?? fresh;
    _held = held;
    _fresh = fresh;
    final plan = reconcileSnapshot(held, fresh);
    _plan = plan.isEmpty ? null : plan;
    // The child's own act: the tabs catch up too, and the board left, if
    // it was archived meanwhile, leaves its place empty.
    _applyTabs();
    notifyListeners();
  }

  /// Adds [tile] to the strip and speaks it: its recorded clip when the
  /// speech service can play clips, its text otherwise. The word log, if
  /// any, is told; it keeps the word only while it is on and not private.
  void tapTile(TileFacts tile) {
    noteTouch();
    _strip.add(tile);
    notifyListeners();
    unawaited(_sayTile(tile));
    // After the word is spoken: the log must never slow or break a tap.
    try {
      _wordLog?.noteSpoken(tile);
    } catch (_) {}
  }

  /// Adds a word that is no tile of a board, such as a picture scene's
  /// spot, to the strip and speaks it. The word log never hears of it.
  void addOtherWord(TileFacts word) {
    noteTouch();
    _strip.add(word);
    notifyListeners();
    unawaited(_say(word.spokenText));
  }

  /// Speaks the whole strip as one sentence. Does nothing when it is empty.
  /// Shares the sentence only while [sharingSaid].
  Future<void> speakStrip() async {
    noteTouch();
    if (_strip.isEmpty) return;
    final live = _live;
    if (live != null && sharingSaid) {
      // The live session must never break the board either.
      try {
        live.sendSaid(_strip.map((t) => t.label).join(' '));
      } catch (_) {}
    }
    if (_strip.length == 1) {
      // A sentence of one word keeps that word's recorded voice.
      await _sayTile(_strip.single);
    } else {
      await _say(_strip.map((t) => t.spokenText).join(' '));
    }
  }

  void clearStrip() {
    noteTouch();
    if (_strip.isEmpty) return;
    _strip.clear();
    notifyListeners();
  }

  /// Removes the last word.
  void backspace() {
    noteTouch();
    if (_strip.isEmpty) return;
    _strip.removeLast();
    notifyListeners();
  }

  /// Records that a finger touched the board just now.
  void noteTouch() => _sinceTouch.reset();

  /// A finger went down. Nothing swaps until every finger is up again.
  void touchDown() {
    _pointersDown++;
    noteTouch();
  }

  /// A finger lifted or its gesture was cancelled. The quiet period starts
  /// from here.
  void touchUp() {
    if (_pointersDown > 0) _pointersDown--;
    noteTouch();
  }

  /// Shows the replica's present state outright, including swaps and moves.
  /// Call only after an adult has confirmed.
  void applyAdultChanges() {
    final board = _targetBoard();
    if (board == null) return;
    final fresh = BoardSnapshot.of(board, _store.tiles, _store.boards);
    _held = fresh;
    _fresh = fresh;
    _plan = null;
    _applyTabs();
    notifyListeners();
  }

  /// Applies the automatic part of the waiting plan, and any change to the
  /// tabs, if this is a safe point. Returns true when what the child sees
  /// changed. The timer calls this.
  @visibleForTesting
  bool checkSafePoint() {
    if (_disposed || _pointersDown > 0) return false;
    final plan = _plan;
    final fresh = _fresh;
    final words = plan != null && fresh != null && plan.auto.isNotEmpty
        ? (plan, fresh)
        : null;
    final tabs = _nextTabs;
    if (words == null && tabs == null) return false;
    final activity = TalkerActivity(
      stripEmpty: _strip.isEmpty,
      speaking: _speech.speaking.value,
      sinceLastTouch: _sinceTouch.elapsed,
    );
    if (!isSafePoint(activity, quiet: _quiet)) return false;
    if (words case (final plan, final fresh)) {
      _held = plan.next;
      // What is left is only what needs an adult.
      final rest = reconcileSnapshot(plan.next, fresh);
      _plan = rest.isEmpty ? null : rest;
    }
    if (tabs != null) {
      _tabs = tabs;
      _nextTabs = null;
    }
    notifyListeners();
    return true;
  }

  void _onStoreChanged() {
    final board = _targetBoard();
    if (board == null) {
      // The board is gone or archived: keep showing what the child has,
      // its tab included.
      _plan = null;
      _nextTabs = _tabsToApply();
      if (!checkSafePoint()) notifyListeners();
      return;
    }
    final fresh = BoardSnapshot.of(board, _store.tiles, _store.boards);
    _fresh = fresh;
    final held = _held;
    if (held == null) {
      // Nothing was on show to keep still.
      _held = fresh;
      _applyTabs();
      notifyListeners();
      return;
    }
    final plan = reconcileSnapshot(held, fresh);
    _plan = plan.isEmpty ? null : plan;
    _nextTabs = _tabsToApply();
    if (!checkSafePoint()) notifyListeners();
  }

  /// A glow, the sharing switch or private mode changed; the held snapshot
  /// is untouched.
  void _onLiveChanged() {
    if (!_disposed) notifyListeners();
  }

  /// The requested board, else the one already shown, else the home board,
  /// else the first board. Archived boards never qualify.
  BoardFacts? _targetBoard() {
    final live = _store.boards.where((b) => !b.archived);
    final wanted = _boardId ?? _held?.board.id;
    if (wanted != null) {
      return live.where((b) => b.id == wanted).firstOrNull;
    }
    return live.where((b) => b.isHome).firstOrNull ?? live.firstOrNull;
  }

  /// Speech must never break the board: failures are swallowed.
  Future<void> _say(String text) async {
    try {
      await _speech.speak(text);
    } catch (_) {}
  }

  Future<void> _sayTile(TileFacts tile) async {
    final Object speech = _speech;
    final speaker = _speaker ?? (speech is TileSpeaker ? speech : null);
    if (speaker == null) return _say(tile.spokenText);
    try {
      await speaker.speakTile(tile);
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _store.removeListener(_onStoreChanged);
    _live?.removeListener(_onLiveChanged);
    _wordLog?.removeListener(_onLiveChanged);
    super.dispose();
  }
}
