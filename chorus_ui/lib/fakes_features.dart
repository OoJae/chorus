/// In-memory stand-ins for the word log, "This week" and board sharing.
///
/// They let the feature screens run and be tested with no server. Each
/// keeps its contract's rules: the log records nothing unless it is on and
/// not private, only a guardian may change it, and sharing needs a
/// connection.
library;

import 'package:chorus_shared/chorus_shared.dart';

import 'contracts.dart';
import 'contracts_sharing.dart';
import 'contracts_wordlog.dart';

/// A [WordLog] held in memory.
///
/// [online] stands in for the connection: while it is on, every use is
/// sent at once and lands in [kept] (the server's log); while it is off,
/// uses wait in the queue under the shared queue rules and are sent when it
/// comes back.
class FakeWordLog extends WordLog {
  FakeWordLog({
    this._role = CircleRole.guardian,
    this._enabled = false,
    this._online = true,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  CircleRole _role;
  bool _enabled;
  bool _online;
  bool _private = false;
  final DateTime Function() _now;
  List<WordUse> _queue = const [];

  /// The uses the server holds, oldest first.
  final List<WordUse> kept = [];

  /// How many times [deleteAll] removed the log.
  int deletions = 0;

  @override
  bool get enabled => _enabled;

  @override
  bool get private => _private;

  @override
  bool get canChange => _role == CircleRole.guardian;

  @override
  int get pending => _queue.length;

  /// The uses waiting on this device, oldest first.
  List<WordUse> get queued => List.unmodifiable(_queue);

  CircleRole get role => _role;

  /// Switches the signed-in adult's role.
  set role(CircleRole value) {
    if (value == _role) return;
    _role = value;
    notifyListeners();
  }

  bool get online => _online;

  /// The connection came or went. Coming back sends what was waiting.
  set online(bool value) {
    if (value == _online) return;
    _online = value;
    if (value) _send();
    notifyListeners();
  }

  @override
  void noteSpoken(TileFacts tile) {
    if (!_enabled || _private) return;
    try {
      _queue = enqueueWordUses(_queue, [
        WordUse(tileId: tile.id, boardId: tile.boardId, spokenAt: _now()),
      ]);
      if (_online) _send();
      notifyListeners();
    } catch (_) {
      // The child's tap must never fail because of the log.
    }
  }

  @override
  Future<void> setEnabled(bool value) async {
    _requireGuardian();
    if (value == _enabled) return;
    _enabled = value;
    notifyListeners();
  }

  @override
  void setPrivate(bool value) {
    if (value == _private) return;
    _private = value;
    notifyListeners();
  }

  @override
  Future<void> deleteAll() async {
    _requireGuardian();
    if (!_online) {
      throw StateError(
        'The word log could not be deleted with no connection. Nothing was '
        'removed.',
      );
    }
    kept.clear();
    _queue = const [];
    deletions++;
    notifyListeners();
  }

  /// Sends the queue in batches, as the real sender does.
  void _send() {
    while (_queue.isNotEmpty) {
      final batch = nextWordUseBatch(_queue);
      kept.addAll(batch);
      _queue = afterWordUsesSent(_queue, batch.length);
    }
  }

  void _requireGuardian() {
    if (!canChange) {
      throw StateError('Only a guardian can change the word log.');
    }
  }
}

/// A [WeekSummarySource] that sums [log]'s kept uses against [store]'s
/// tiles, as the server sums its rows.
class FakeWeekSummarySource implements WeekSummarySource {
  FakeWeekSummarySource({
    required this.store,
    required this.log,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final BoardStore store;
  final FakeWordLog log;
  final DateTime Function() _now;

  /// How many times [thisWeek] was asked.
  int asked = 0;

  @override
  Future<WeekSummary?> thisWeek() async {
    asked++;
    if (!log.online || !log.enabled) return null;
    if (store.role != CircleRole.guardian &&
        store.role != CircleRole.therapist) {
      return null;
    }
    return summarizeWeek(log.kept, store.tiles, weekStartOf(_now()));
  }
}

/// A [BoardSharing] that hands out `chorus.example` links and remembers
/// them. Given a [store], it also keeps each export's OBF text, so an
/// export can be imported again.
class FakeBoardSharing implements BoardSharing {
  FakeBoardSharing({this.store, this.online = true, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final BoardStore? store;
  final DateTime Function() _now;

  /// False stands in for no connection: every call then throws.
  bool online;

  int _sequence = 0;
  final List<SharedLink> _open = [];

  /// Every link handed out, oldest first, withdrawn ones included.
  final List<SharedLink> shared = [];

  /// The OBF text of each export, by its link. Empty without a [store].
  final Map<Uri, String> exported = {};

  /// True while [link] would still open: not withdrawn and not expired.
  bool isOpen(SharedLink link) =>
      _open.contains(link) && _now().toUtc().isBefore(link.expiresAt);

  @override
  Future<SharedLink> shareViewOnly(BoardFacts board) async {
    _requireOnline();
    final link = SharedLink(
      url: Uri.parse('https://chorus.example/b/view-${_sequence++}'),
      expiresAt: _now().toUtc().add(viewOnlyLinkLasts),
    );
    _open.add(link);
    shared.add(link);
    return link;
  }

  @override
  Future<void> withdraw(SharedLink link) async {
    _requireOnline();
    _open.remove(link);
  }

  @override
  Future<Uri> exportObf(BoardFacts board) async {
    _requireOnline();
    final url = Uri.parse(
      'https://chorus.example/export/board-${_sequence++}.obf',
    );
    final tiles = store?.tiles;
    if (tiles != null) exported[url] = obfJsonOf(board, tiles);
    return url;
  }

  void _requireOnline() {
    if (!online) {
      throw const SharingFailed(
        'This needs a connection. Try again when the device is online.',
      );
    }
  }
}
