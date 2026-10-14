import 'dart:convert';

import 'package:chorus_shared/chorus_shared.dart';
import 'package:test/test.dart';

void main() {
  WordUse use(int n) => WordUse(
    tileId: 'tile-$n',
    boardId: 'home',
    spokenAt: DateTime.utc(2026, 10, 14).add(Duration(seconds: n)),
  );

  group('WordUse', () {
    test('keeps the time in UTC', () {
      final local = DateTime(2026, 10, 14, 9, 30);
      final u = WordUse(tileId: 't', boardId: 'b', spokenAt: local);
      expect(u.spokenAt.isUtc, isTrue);
      expect(u.spokenAt, local.toUtc());
    });

    test('round-trips through JSON', () {
      final u = use(7);
      final json = jsonDecode(jsonEncode(u.toJson())) as Map<String, Object?>;
      expect(json, {
        'tileId': 'tile-7',
        'boardId': 'home',
        'spokenAt': '2026-10-14T00:00:07.000Z',
      });
      expect(WordUse.fromJson(json), u);
    });

    test('refuses JSON missing a field', () {
      for (final bad in <Map<String, Object?>>[
        {'boardId': 'b', 'spokenAt': '2026-10-14T00:00:00Z'},
        {'tileId': 't', 'spokenAt': '2026-10-14T00:00:00Z'},
        {'tileId': 't', 'boardId': 'b'},
        {'tileId': '', 'boardId': 'b', 'spokenAt': '2026-10-14T00:00:00Z'},
        {'tileId': 't', 'boardId': 'b', 'spokenAt': 'yesterday'},
      ]) {
        expect(
          () => WordUse.fromJson(bad),
          throwsFormatException,
          reason: '$bad',
        );
      }
    });
  });

  group('queue', () {
    test('caps at 2,000, dropping the oldest first', () {
      expect(wordLogQueueCap, 2000);
      final full = [for (var i = 0; i < 2000; i++) use(i)];
      final next = enqueueWordUses(full, [use(2000), use(2001)]);
      expect(next, hasLength(2000));
      expect(next.first, use(2));
      expect(next.last, use(2001));
    });

    test('adds at the end below the cap', () {
      expect(enqueueWordUses([use(0)], [use(1)]), [use(0), use(1)]);
    });

    test('sends the oldest 200 at a time', () {
      expect(wordLogBatchSize, 200);
      final queue = [for (var i = 0; i < 450; i++) use(i)];
      final batch = nextWordUseBatch(queue);
      expect(batch, hasLength(200));
      expect(batch.first, use(0));
      expect(batch.last, use(199));
      expect(nextWordUseBatch(queue.sublist(400)), hasLength(50));
    });

    test('drops what was sent, and only that', () {
      final queue = [for (var i = 0; i < 5; i++) use(i)];
      expect(afterWordUsesSent(queue, 2), [use(2), use(3), use(4)]);
      expect(afterWordUsesSent(queue, 9), isEmpty);
      expect(afterWordUsesSent(queue, -1), queue);
    });

    test('survives being written down and read back', () {
      final queue = [use(0), use(1)];
      expect(decodeWordUses(encodeWordUses(queue)), queue);
    });

    test('a damaged entry is skipped, not the whole queue', () {
      final text = jsonEncode([
        use(0).toJson(),
        {'tileId': 'broken'},
        'nonsense',
        use(1).toJson(),
      ]);
      expect(decodeWordUses(text), [use(0), use(1)]);
      expect(decodeWordUses('not json'), isEmpty);
      expect(decodeWordUses('{}'), isEmpty);
    });
  });
}
