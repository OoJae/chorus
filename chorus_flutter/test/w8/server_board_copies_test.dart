// Named board copies over stand-in server calls: what the screens get, and
// every failure in words for the adult.
import 'package:chorus_client/chorus_client.dart' as api;
import 'package:chorus_flutter/src/copies/server_board_copies.dart';
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart' show SyncState;
import 'package:chorus_ui/contracts_copies.dart';
import 'package:chorus_ui/fakes.dart' show FakeSyncStatus;
import 'package:flutter_test/flutter_test.dart';

final api.UuidValue boardId = api.UuidValue.fromString(
  '0199e0c4-0000-7000-8000-000000000001',
);

api.BoardCopyInfo info(int id, {List<api.BoardCopyWord> words = const []}) =>
    api.BoardCopyInfo(
      id: id,
      boardId: boardId,
      boardName: 'Home',
      rows: 6,
      cols: 6,
      name: 'Before the school trip',
      takenByName: 'Mum',
      takenAt: DateTime.utc(2026, 10, 14, 9),
      wordCount: words.length,
      words: words,
    );

void main() {
  late FakeSyncStatus sync;
  bool up = true;
  final taken = <(String, String)>[];

  CopyCalls calls() => CopyCalls(
    take: (board, name) async {
      if (!up) throw const api.ServerpodClientNetworkException('down');
      taken.add((board, name));
      return info(
        3,
        words: [
          api.BoardCopyWord(
            label: 'eat',
            colorKey: 'verb',
            cellKey: placedKey(boardId.uuid, 0, 1),
          ),
        ],
      );
    },
    list: () async {
      if (!up) throw const api.ServerpodClientNetworkException('down');
      return [info(3), info(2)];
    },
    get: (id) async => id == 3 ? info(3) : null,
    delete: (id) async => true,
  );

  setUp(() {
    sync = FakeSyncStatus();
    up = true;
    taken.clear();
  });

  const board = BoardFacts(id: 'b', name: 'Home', rows: 6, cols: 6);

  test('a copy is taken of the board named, and arrives as the screens see '
      'it', () async {
    final copies = ServerBoardCopies(calls: calls(), canEdit: true, sync: sync);
    final copy = await copies.take(
      BoardFacts(id: boardId.uuid, name: 'Home', rows: 6, cols: 6),
      'Before the school trip',
    );
    expect(taken.single, (boardId.uuid, 'Before the school trip'));
    expect(copy.id, '3');
    expect(copy.boardId, boardId.uuid);
    expect(copy.takenByName, 'Mum');
    expect(copy.words.single.label, 'eat');
    expect(copy.words.single.cell, PlacedCell(boardId.uuid, 0, 1));
    expect((await copies.list()).map((c) => c.id), ['3', '2']);
    expect((await copies.get('3'))!.name, 'Before the school trip');
    expect(await copies.get('9'), isNull);
    await copies.delete('3');
  });

  test(
    'with no connection, or while paused, it fails in plain words',
    () async {
      final copies = ServerBoardCopies(
        calls: calls(),
        canEdit: true,
        sync: sync,
      );
      up = false;
      await expectLater(copies.list(), throwsA(isA<CopiesFailed>()));
      up = true;
      sync.state = SyncState.offline;
      await expectLater(copies.take(board, 'x'), throwsA(isA<CopiesFailed>()));
      sync.state = SyncState.live;
      sync.hasUnsent = true;
      await expectLater(
        copies.take(board, 'x'),
        throwsA(
          isA<CopiesFailed>().having(
            (f) => f.message,
            'message',
            copiesWaitingMessage,
          ),
        ),
      );
      expect(taken, isEmpty);
      expect(copiesOfflineMessage, isNot(contains('error')));
    },
  );

  test('a read-only partner may look but not take or delete', () async {
    final copies = ServerBoardCopies(
      calls: calls(),
      canEdit: false,
      sync: sync,
    );
    expect(await copies.list(), hasLength(2));
    expect(() => copies.take(board, 'x'), throwsStateError);
    expect(() => copies.delete('3'), throwsStateError);
  });
}
