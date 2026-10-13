/// In-memory stand-ins for the replica, speech and sync status.
///
/// They let every screen run and be tested with no backend. [FakeBoardStore]
/// enforces the same rules the real store will, so a screen that works here
/// is not relying on anything the replica forbids.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/foundation.dart';

import 'contracts.dart';

/// A [BoardStore] held in memory, seeded with the starter board.
class FakeBoardStore extends BoardStore {
  /// Starts from `starterBoard` / `starterTiles`. The starter board fills
  /// every cell, so [leaveEmpty] names (row, col) cells to leave out when a
  /// demo or test needs free spots.
  FakeBoardStore.seeded({
    this._role = CircleRole.guardian,
    this.childName = 'Maya',
    this.myName = 'Mum',
    Set<(int, int)> leaveEmpty = const {},
  }) {
    _boards.add(starterBoard(circleId));
    final seeded = starterTiles(
      circleId: circleId,
      createdBy: _userId(myName),
      createdByName: myName,
      createdAt: _epoch,
    );
    for (final tile in seeded) {
      final key = CellKey.parse(tile.cellKey);
      if (key is PlacedCell && leaveEmpty.contains((key.row, key.col))) {
        continue;
      }
      _tiles.add(tile);
    }
  }

  /// The one circle this fake holds.
  static const String circleId = '6f1d2c3a-0b4e-4c5d-8e9f-a1b2c3d4e5f6';

  static final DateTime _epoch = DateTime.utc(2026, 1, 1, 9);

  final List<BoardFacts> _boards = [];
  final List<TileFacts> _tiles = [];
  CircleRole _role;
  int _sequence = 0;
  int _minutes = 0;

  @override
  final String childName;

  @override
  final String myName;

  @override
  CircleRole get role => _role;

  /// Switches the signed-in adult's role, e.g. to show the read-only view.
  set role(CircleRole value) {
    if (value == _role) return;
    _role = value;
    notifyListeners();
  }

  /// Id of the seeded home board.
  String get homeBoardId => starterBoardId(circleId);

  @override
  List<BoardFacts> get boards => List.unmodifiable(_boards);

  @override
  List<TileFacts> get tiles => List.unmodifiable(_tiles);

  @override
  Future<bool> addTile({
    required String boardId,
    required int row,
    required int col,
    required String label,
    String? speech,
    String? colorKey,
  }) async {
    _requireEditor();
    _requireCell(_board(boardId), row, col);
    final text = _requireLabel(label);
    final id = _nextId();
    final free = _isFree(boardId, row, col);
    _tiles.add(TileFacts(
      id: id,
      boardId: boardId,
      cellKey: free ? placedKey(boardId, row, col) : trayKey(id),
      label: text,
      speech: (speech == null || speech.trim().isEmpty) ? null : speech.trim(),
      colorKey: colorKey,
      createdBy: _userId(myName),
      createdByName: myName,
      createdAt: _tick(),
    ));
    notifyListeners();
    return free;
  }

  /// Throws [StateError] for a tile that already holds a cell or is
  /// archived: only a tile waiting in the tray may be placed.
  @override
  Future<bool> placeTile(String tileId,
      {required int row, required int col}) async {
    _requireEditor();
    final index = _indexOf(tileId);
    final tile = _tiles[index];
    if (!trayOf(_tiles, _boards).any((entry) => entry.tile.id == tileId)) {
      throw StateError(
          'Only a word waiting in the tray can be placed; "${tile.label}" '
          'is not waiting.');
    }
    _requireCell(_board(tile.boardId), row, col);
    if (!_isFree(tile.boardId, row, col)) return false;
    _tiles[index] = tile.copyWith(cellKey: placedKey(tile.boardId, row, col));
    notifyListeners();
    return true;
  }

  /// Pass an empty [speech] to go back to speaking the label.
  @override
  Future<void> updateTile(String tileId,
      {String? label, String? speech, String? colorKey}) async {
    _requireEditor();
    final index = _indexOf(tileId);
    _tiles[index] = _tiles[index].copyWith(
      label: label == null ? null : _requireLabel(label),
      speech: speech?.trim(),
      colorKey: colorKey,
    );
    notifyListeners();
  }

  @override
  Future<void> archiveTile(String tileId) async {
    _requireEditor();
    final index = _indexOf(tileId);
    final tile = _tiles[index];
    // One update: the flag alone would not free the cell.
    _tiles[index] = tile.copyWith(archived: true, cellKey: trayKey(tile.id));
    _handOver(CellKey.parse(tile.cellKey));
    notifyListeners();
  }

  /// What the engine does when a cell is freed: the oldest tile that lost
  /// [freed] in a conflict gets it. Later losers keep waiting.
  void _handOver(CellKey freed) {
    if (freed is! PlacedCell) return;
    int? heir;
    for (var i = 0; i < _tiles.length; i++) {
      final tile = _tiles[i];
      if (tile.archived) continue;
      final key = CellKey.parse(tile.cellKey);
      if (key is! ContestedCell || key.wanted != freed) continue;
      if (heir == null || _older(tile, _tiles[heir])) heir = i;
    }
    if (heir == null) return;
    _tiles[heir] = _tiles[heir].copyWith(
      cellKey: placedKey(freed.boardId, freed.row, freed.col),
    );
  }

  /// Earliest createdAt first, nulls last, then the smallest id.
  static bool _older(TileFacts a, TileFacts b) {
    final at = a.createdAt, bt = b.createdAt;
    if (at != null && bt != null && at != bt) return at.isBefore(bt);
    if ((at == null) != (bt == null)) return at != null;
    return a.id.compareTo(b.id) < 0;
  }

  /// Simulates a merge that adds another adult's tile into an empty cell of
  /// the home board. If the cell is occupied the newcomer loses it, as it
  /// would in a real merge, and arrives as [remoteConflict] instead.
  void remoteAdd({
    required int row,
    required int col,
    required String label,
    String byName = 'Ms Lee',
  }) {
    _remote(row, col, label, byName,
        contested: !_isFree(homeBoardId, row, col));
  }

  /// Simulates the engine's verdict on two offline inserts of one cell: adds
  /// another adult's tile as the loser, with the engine-suffixed key.
  void remoteConflict({
    required int row,
    required int col,
    required String label,
    String byName = 'Teacher',
  }) {
    _remote(row, col, label, byName, contested: true);
  }

  void _remote(int row, int col, String label, String byName,
      {required bool contested}) {
    final boardId = homeBoardId;
    _requireCell(_board(boardId), row, col);
    final id = _nextId();
    final placed = placedKey(boardId, row, col);
    _tiles.add(TileFacts(
      id: id,
      boardId: boardId,
      // Only the engine writes this form, so it is concatenated here and
      // never built through placedKey.
      cellKey: contested ? '$placed$conflictMarker$id' : placed,
      label: _requireLabel(label),
      createdBy: _userId(byName),
      createdByName: byName,
      createdAt: _tick(),
    ));
    notifyListeners();
  }

  void _requireEditor() {
    if (!_role.canEdit) {
      throw StateError('A partner can view this board but not change it.');
    }
  }

  BoardFacts _board(String boardId) => _boards.firstWhere(
        (board) => board.id == boardId && !board.archived,
        orElse: () => throw ArgumentError.value(boardId, 'boardId', 'No such board'),
      );

  void _requireCell(BoardFacts board, int row, int col) {
    if (!board.contains(row, col)) {
      throw ArgumentError('Cell $row:$col is outside ${board.rows}x${board.cols}');
    }
  }

  String _requireLabel(String label) {
    final text = label.trim();
    if (text.isEmpty) throw ArgumentError.value(label, 'label', 'Empty');
    return text;
  }

  int _indexOf(String tileId) {
    final index = _tiles.indexWhere((tile) => tile.id == tileId);
    if (index < 0) throw ArgumentError.value(tileId, 'tileId', 'No such tile');
    return index;
  }

  bool _isFree(String boardId, int row, int col) =>
      !gridOf(boardId, _tiles, _boards).containsKey((row, col));

  String _nextId() => deterministicId(circleId, 'fake-tile:${_sequence++}');

  /// A later timestamp on every call, so creation order is deterministic.
  DateTime _tick() => _epoch.add(Duration(minutes: ++_minutes));

  static String _userId(String name) => deterministicId(circleId, 'user:$name');
}

/// A [SpeechService] that records what it was asked to say and plays nothing.
class FakeSpeech implements SpeechService {
  /// With the default [speakFor] of zero, [speak] never reports speaking and
  /// starts no timer. A longer value keeps [speaking] true for that long.
  FakeSpeech({this.speakFor = Duration.zero, bool offlineVoice = true})
      : offlineVoiceReady = ValueNotifier(offlineVoice);

  /// Every text passed to [speak], oldest first.
  final List<String> spoken = [];

  final Duration speakFor;

  /// How many times [warmUp] ran.
  int warmUps = 0;

  int _utterance = 0;

  @override
  final ValueNotifier<bool> speaking = ValueNotifier(false);

  @override
  final ValueNotifier<bool> offlineVoiceReady;

  @override
  Future<void> warmUp() async {
    warmUps++;
  }

  @override
  Future<void> speak(String text) async {
    final mine = ++_utterance;
    spoken.add(text);
    if (speakFor == Duration.zero) return;
    speaking.value = true;
    await Future<void>.delayed(speakFor);
    // A later speak or stop owns the flag now.
    if (mine == _utterance) speaking.value = false;
  }

  @override
  Future<void> stop() async {
    _utterance++;
    speaking.value = false;
  }
}

/// A [SyncStatus] whose state is set by hand.
class FakeSyncStatus extends SyncStatus {
  FakeSyncStatus({
    this._state = SyncState.live,
    this._hasUnsent = false,
    this._lastMergeAt,
  });

  SyncState _state;
  bool _hasUnsent;
  DateTime? _lastMergeAt;

  /// How many times [syncNow] ran.
  int syncNowCalls = 0;

  @override
  SyncState get state => _state;

  set state(SyncState value) {
    if (value == _state) return;
    _state = value;
    notifyListeners();
  }

  @override
  bool get hasUnsent => _hasUnsent;

  set hasUnsent(bool value) {
    if (value == _hasUnsent) return;
    _hasUnsent = value;
    notifyListeners();
  }

  @override
  DateTime? get lastMergeAt => _lastMergeAt;

  set lastMergeAt(DateTime? value) {
    _lastMergeAt = value;
    notifyListeners();
  }

  /// Goes live from any state a retry can fix; the others are left alone.
  @override
  Future<void> syncNow() async {
    syncNowCalls++;
    switch (_state) {
      case SyncState.signedOut ||
            SyncState.clockSkew ||
            SyncState.needsUpdate ||
            SyncState.accessLost:
        return;
      case SyncState.offline ||
            SyncState.connecting ||
            SyncState.live ||
            SyncState.backoff:
        _state = SyncState.live;
        _hasUnsent = false;
        _lastMergeAt = DateTime.now();
        notifyListeners();
    }
  }
}
