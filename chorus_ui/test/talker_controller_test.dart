import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/talker/talker_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _boardId = '11111111-1111-4111-8111-111111111111';
const _home = BoardFacts(id: _boardId, name: 'Home', rows: 2, cols: 2, isHome: true);

TileFacts _tile(String id, String label, int row, int col, {String? speech}) =>
    TileFacts(
      id: id,
      boardId: _boardId,
      cellKey: placedKey(_boardId, row, col),
      label: label,
      speech: speech,
      createdAt: DateTime.utc(2026, 1, 1),
    );

/// In-memory store. `merge` stands in for a sync from another device; the
/// write methods count calls so tests can prove the talker never writes.
class _Store extends BoardStore {
  _Store(this._tiles);

  List<TileFacts> _tiles;
  List<BoardFacts> _boards = const [_home];
  int writes = 0;

  bool get listening => hasListeners;

  @override
  String get childName => 'Maya';
  @override
  String get myName => 'Mum';
  @override
  CircleRole get role => CircleRole.guardian;
  @override
  List<BoardFacts> get boards => _boards;
  @override
  List<TileFacts> get tiles => List.unmodifiable(_tiles);

  void merge(List<TileFacts> next, {BoardFacts? board}) {
    _tiles = next;
    if (board != null) _boards = [board];
    notifyListeners();
  }

  @override
  Future<bool> addTile({
    required String boardId,
    required int row,
    required int col,
    required String label,
    String? speech,
    String? colorKey,
  }) async {
    writes++;
    return true;
  }

  @override
  Future<bool> placeTile(String tileId,
      {required int row, required int col}) async {
    writes++;
    return true;
  }

  @override
  Future<void> updateTile(String tileId,
      {String? label, String? speech, String? colorKey}) async {
    writes++;
  }

  @override
  Future<void> archiveTile(String tileId) async {
    writes++;
  }
}

class _Speech implements SpeechService {
  final List<String> spoken = [];

  @override
  final ValueNotifier<bool> speaking = ValueNotifier(false);
  @override
  final ValueNotifier<bool> offlineVoiceReady = ValueNotifier(true);

  @override
  Future<void> warmUp() async {}
  @override
  Future<void> speak(String text) async => spoken.add(text);
  @override
  Future<void> stop() async {}
}

void main() {
  final want = _tile('a', 'want', 0, 0);
  final more = _tile('b', 'more', 0, 1, speech: 'more please');
  final go = _tile('c', 'go', 1, 0);

  late _Store store;
  late _Speech speech;
  late TalkerController talker;

  /// [quiet] zero makes the touch condition always pass, so each test
  /// isolates the condition it is about.
  void start({Duration quiet = Duration.zero}) {
    store = _Store([want, more]);
    speech = _Speech();
    talker = TalkerController(store: store, speech: speech, quiet: quiet);
    addTearDown(talker.dispose);
  }

  test('takes the first snapshot immediately', () {
    start();
    expect(talker.snapshot, isNotNull);
    expect(talker.snapshot!.board.id, _boardId);
    expect(talker.snapshot!.cells[(0, 0)]?.id, 'a');
    expect(talker.snapshot!.cells[(0, 1)]?.id, 'b');
    expect(talker.snapshot!.cells[(1, 0)], isNull);
    expect(talker.waitingCount, 0);
    expect(talker.needsAdult, isFalse);
  });

  test('tap adds to the strip and speaks the spoken text', () {
    start();
    var notified = 0;
    talker.addListener(() => notified++);
    talker.tapTile(want);
    talker.tapTile(more);
    expect(talker.strip.map((t) => t.id), ['a', 'b']);
    expect(speech.spoken, ['want', 'more please']);
    expect(notified, 2);
  });

  test('speakStrip speaks the whole sentence; backspace and clear edit it',
      () async {
    start();
    await talker.speakStrip();
    expect(speech.spoken, isEmpty);

    talker.tapTile(want);
    talker.tapTile(more);
    speech.spoken.clear();
    await talker.speakStrip();
    expect(speech.spoken, ['want more please']);

    talker.backspace();
    expect(talker.strip.map((t) => t.id), ['a']);
    talker.clearStrip();
    expect(talker.strip, isEmpty);
    talker.backspace();
    expect(talker.strip, isEmpty);
  });

  test('a merged word appears at once when the child is idle', () {
    start();
    store.merge([want, more, go]);
    expect(talker.snapshot!.cells[(1, 0)]?.id, 'c');
    expect(talker.waitingCount, 0);
  });

  test('a merged word waits while the strip has words in it', () {
    start();
    talker.tapTile(want);
    store.merge([want, more, go]);
    expect(talker.snapshot!.cells[(1, 0)], isNull);
    expect(talker.waitingCount, 1);
    expect(talker.needsAdult, isFalse);
    expect(talker.checkSafePoint(), isFalse);

    talker.clearStrip();
    expect(talker.checkSafePoint(), isTrue);
    expect(talker.snapshot!.cells[(1, 0)]?.id, 'c');
    expect(talker.waitingCount, 0);
  });

  test('a merged word waits while speech is playing', () {
    start();
    speech.speaking.value = true;
    store.merge([want, more, go]);
    expect(talker.snapshot!.cells[(1, 0)], isNull);
    expect(talker.waitingCount, 1);

    speech.speaking.value = false;
    expect(talker.checkSafePoint(), isTrue);
    expect(talker.snapshot!.cells[(1, 0)]?.id, 'c');
  });

  test('a merged word waits until the board has been quiet long enough', () {
    start(quiet: const Duration(hours: 1));
    store.merge([want, more, go]);
    expect(talker.checkSafePoint(), isFalse);
    expect(talker.snapshot!.cells[(1, 0)], isNull);
    expect(talker.waitingCount, 1);
  });

  test('a content edit to a visible tile is applied in place', () {
    start();
    store.merge([want.copyWith(label: 'I want'), more]);
    expect(talker.snapshot!.cells[(0, 0)]?.id, 'a');
    expect(talker.snapshot!.cells[(0, 0)]?.label, 'I want');
    expect(talker.waitingCount, 0);
  });

  test('a different tile in an occupied cell waits for an adult', () {
    start();
    final stop = _tile('d', 'stop', 0, 0);
    store.merge([want.copyWith(archived: true), more, stop]);
    expect(talker.needsAdult, isTrue);
    expect(talker.waitingCount, greaterThan(0));
    talker.checkSafePoint();
    expect(talker.snapshot!.cells[(0, 0)]?.id, isNot('d'));
    expect(talker.snapshot!.cells[(0, 1)]?.id, 'b');

    talker.applyAdultChanges();
    expect(talker.snapshot!.cells[(0, 0)]?.id, 'd');
    expect(talker.needsAdult, isFalse);
    expect(talker.waitingCount, 0);
  });

  test('a moved tile stays where the child knows it until an adult confirms',
      () {
    start();
    store.merge([
      want.copyWith(cellKey: placedKey(_boardId, 1, 1)),
      more,
      go,
    ]);
    expect(talker.needsAdult, isTrue);
    // The unrelated new word is applied; the move is not.
    expect(talker.snapshot!.cells[(1, 0)]?.id, 'c');
    expect(talker.snapshot!.cells[(0, 0)]?.id, 'a');
    expect(talker.snapshot!.cells[(1, 1)], isNull);
    expect(talker.waitingCount, greaterThan(0));

    talker.applyAdultChanges();
    expect(talker.snapshot!.cells[(0, 0)], isNull);
    expect(talker.snapshot!.cells[(1, 1)]?.id, 'a');
    expect(talker.waitingCount, 0);
  });

  test('a resized board waits for an adult even with no tile changes', () {
    start();
    const grown =
        BoardFacts(id: _boardId, name: 'Home', rows: 3, cols: 2, isHome: true);
    store.merge([want, more], board: grown);
    expect(talker.needsAdult, isTrue);
    expect(talker.waitingCount, 1);
    expect(talker.snapshot!.board.rows, 2);

    // A word in the new row is not shown either: the grid is still 2x2.
    final up = _tile('e', 'up', 2, 0);
    store.merge([want, more, up], board: grown);
    talker.checkSafePoint();
    expect(talker.needsAdult, isTrue);
    expect(talker.waitingCount, greaterThan(0));
    expect(talker.snapshot!.board.rows, 2);

    talker.applyAdultChanges();
    expect(talker.snapshot!.board.rows, 3);
    expect(talker.snapshot!.cells[(2, 0)]?.id, 'e');
    expect(talker.needsAdult, isFalse);
    expect(talker.waitingCount, 0);
  });

  test('nothing swaps while a finger is down', () {
    start();
    talker.touchDown();
    store.merge([want, more, go]);
    expect(talker.checkSafePoint(), isFalse);
    expect(talker.snapshot!.cells[(1, 0)], isNull);
    expect(talker.waitingCount, 1);

    talker.touchUp();
    // An unmatched lift must not leave the count negative.
    talker.touchUp();
    expect(talker.checkSafePoint(), isTrue);
    expect(talker.snapshot!.cells[(1, 0)]?.id, 'c');
  });

  test('never writes to the store', () async {
    start();
    talker.tapTile(want);
    await talker.speakStrip();
    talker.backspace();
    talker.clearStrip();
    store.merge([want, more, go]);
    talker.checkSafePoint();
    talker.applyAdultChanges();
    expect(store.writes, 0);
  });

  testWidgets('the timer applies a waiting change once it is safe',
      (tester) async {
    final store = _Store([want, more]);
    final speech = _Speech();
    final talker =
        TalkerController(store: store, speech: speech, quiet: Duration.zero);
    speech.speaking.value = true;
    store.merge([want, more, go]);
    await tester.pump(const Duration(seconds: 1));
    expect(talker.snapshot!.cells[(1, 0)], isNull);

    speech.speaking.value = false;
    await tester.pump(const Duration(seconds: 1));
    expect(talker.snapshot!.cells[(1, 0)]?.id, 'c');
    expect(talker.waitingCount, 0);
    talker.dispose();
  });

  test('stops listening after dispose', () {
    final store = _Store([want, more]);
    final talker = TalkerController(
        store: store, speech: _Speech(), quiet: Duration.zero);
    talker.dispose();
    store.merge([want, more, go]);
    expect(store.listening, isFalse);
  });
}
