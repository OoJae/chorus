/// State behind the child's board.
library;

import 'dart:async';

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/foundation.dart';

import '../contracts.dart';

/// Holds the board the child sees and the sentence being built.
///
/// The held snapshot is not the replica: merges from other devices are kept
/// as a waiting plan and only the automatic part of it is applied, and only at
/// a safe point (strip empty, nothing playing, no finger down and no touch
/// for [quiet]). Changes that would swap or move a visible tile, and a resize
/// of the grid, wait for [applyAdultChanges].
/// This class only reads the store.
class TalkerController extends ChangeNotifier {
  TalkerController({
    required this._store,
    required this._speech,
    this._boardId,
    this._quiet = const Duration(seconds: 2),
  }) {
    final board = _targetBoard();
    if (board != null) {
      _held = BoardSnapshot.of(board, _store.tiles, _store.boards);
      _fresh = _held;
    }
    _store.addListener(_onStoreChanged);
    _timer = Timer.periodic(recheckEvery, (_) => checkSafePoint());
  }

  /// How often a waiting plan is re-tested against the safe point.
  static const Duration recheckEvery = Duration(milliseconds: 500);

  final BoardStore _store;
  final SpeechService _speech;
  String? _boardId;
  final Duration _quiet;

  Timer? _timer;
  BoardSnapshot? _held;
  BoardSnapshot? _fresh;
  SnapshotPlan? _plan;
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

  /// Id of the board on show, if any.
  String? get boardId => _held?.board.id;

  /// Every board of the circle, for the tabs.
  List<BoardFacts> get boards => _store.boards;

  /// Goes to another board. Moving between boards is the child's own act,
  /// so the board is shown as the replica has it now, with nothing waiting.
  void showBoard(String boardId) {
    noteTouch();
    final board = _store.boards
        .where((b) => !b.archived && b.id == boardId)
        .firstOrNull;
    if (board == null || board.id == _held?.board.id) return;
    _boardId = board.id;
    final fresh = BoardSnapshot.of(board, _store.tiles, _store.boards);
    _held = fresh;
    _fresh = fresh;
    _plan = null;
    notifyListeners();
  }

  /// Adds [tile] to the strip and speaks it.
  void tapTile(TileFacts tile) {
    noteTouch();
    _strip.add(tile);
    notifyListeners();
    unawaited(_say(tile.spokenText));
  }

  /// Speaks the whole strip as one sentence. Does nothing when it is empty.
  Future<void> speakStrip() async {
    noteTouch();
    if (_strip.isEmpty) return;
    await _say(_strip.map((t) => t.spokenText).join(' '));
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
    notifyListeners();
  }

  /// Applies the automatic part of the waiting plan if this is a safe point.
  /// Returns true when the held snapshot changed. The timer calls this.
  @visibleForTesting
  bool checkSafePoint() {
    final plan = _plan;
    final fresh = _fresh;
    if (_disposed ||
        plan == null ||
        fresh == null ||
        plan.auto.isEmpty ||
        _pointersDown > 0) {
      return false;
    }
    final activity = TalkerActivity(
      stripEmpty: _strip.isEmpty,
      speaking: _speech.speaking.value,
      sinceLastTouch: _sinceTouch.elapsed,
    );
    if (!isSafePoint(activity, quiet: _quiet)) return false;
    _held = plan.next;
    // What is left is only what needs an adult.
    final rest = reconcileSnapshot(plan.next, fresh);
    _plan = rest.isEmpty ? null : rest;
    notifyListeners();
    return true;
  }

  void _onStoreChanged() {
    final board = _targetBoard();
    if (board == null) {
      // The board is gone or archived: keep showing what the child has.
      if (_plan != null) {
        _plan = null;
        notifyListeners();
      }
      return;
    }
    final fresh = BoardSnapshot.of(board, _store.tiles, _store.boards);
    _fresh = fresh;
    final held = _held;
    if (held == null) {
      _held = fresh;
      notifyListeners();
      return;
    }
    final plan = reconcileSnapshot(held, fresh);
    _plan = plan.isEmpty ? null : plan;
    if (!checkSafePoint()) notifyListeners();
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

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }
}
