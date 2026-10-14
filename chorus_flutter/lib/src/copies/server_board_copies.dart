/// Named board copies over the server's `boardCopy` endpoint.
library;

import 'package:chorus_client/chorus_client.dart' as api;
import 'package:chorus_shared/chorus_shared.dart' show BoardFacts;
import 'package:chorus_ui/contracts.dart' show SyncState, SyncStatus;
import 'package:chorus_ui/contracts_copies.dart';

/// The calls a [ServerBoardCopies] makes, so tests can stand in for them.
class CopyCalls {
  const CopyCalls({
    required this.take,
    required this.list,
    required this.get,
    required this.delete,
  });

  /// The calls of [client] for [circleSpace].
  factory CopyCalls.forClient(api.Client client, api.UuidValue circleSpace) =>
      CopyCalls(
        take: (board, name) => client.boardCopy.take(
          circleSpace,
          api.UuidValue.fromString(board),
          name,
        ),
        list: () => client.boardCopy.list(circleSpace),
        get: (id) => client.boardCopy.get(circleSpace, id),
        delete: (id) => client.boardCopy.delete(circleSpace, id),
      );

  final Future<api.BoardCopyInfo> Function(String boardId, String name) take;
  final Future<List<api.BoardCopyInfo>> Function() list;
  final Future<api.BoardCopyInfo?> Function(int id) get;
  final Future<bool> Function(int id) delete;
}

/// The circle's board copies, kept on the server. Every failure is a
/// [CopiesFailed] with words for the adult.
class ServerBoardCopies implements BoardCopies {
  ServerBoardCopies({
    required this._calls,
    required this.canEdit,
    this._sync,
    this.timeout = const Duration(seconds: 20),
  });

  final CopyCalls _calls;
  final SyncStatus? _sync;
  final Duration timeout;

  @override
  final bool canEdit;

  /// A copy is taken from the words the server holds, so it is refused
  /// while this device is offline or paused: words made here since would
  /// be missing from it.
  void _requireLive() {
    final sync = _sync;
    if (sync == null) return;
    if (sync.state != SyncState.live || sync.workingOffline) {
      throw const CopiesFailed(copiesOfflineMessage);
    }
    if (sync.hasUnsent) throw const CopiesFailed(copiesWaitingMessage);
  }

  Future<T> _call<T>(Future<T> Function() call) async {
    try {
      return await call().timeout(timeout);
    } catch (_) {
      throw const CopiesFailed(copiesOfflineMessage);
    }
  }

  static int _idOf(String copyId) =>
      int.tryParse(copyId) ??
      (throw const CopiesFailed('This copy could not be found.'));

  @override
  Future<BoardCopy> take(BoardFacts board, String name) async {
    if (!canEdit) {
      throw StateError('A read-only partner takes no copy.');
    }
    _requireLive();
    return copyOf(await _call(() => _calls.take(board.id, name)));
  }

  @override
  Future<List<BoardCopy>> list() async {
    final listed = await _call(_calls.list);
    return [for (final info in listed) copyOf(info)];
  }

  @override
  Future<BoardCopy?> get(String copyId) async {
    final id = _idOf(copyId);
    final info = await _call(() => _calls.get(id));
    return info == null ? null : copyOf(info);
  }

  @override
  Future<void> delete(String copyId) async {
    if (!canEdit) {
      throw StateError('A read-only partner deletes no copy.');
    }
    final id = _idOf(copyId);
    await _call(() => _calls.delete(id));
  }
}

/// [info] as the screens see it.
BoardCopy copyOf(api.BoardCopyInfo info) => BoardCopy(
  id: '${info.id}',
  boardId: info.boardId.uuid.toLowerCase(),
  boardName: info.boardName,
  rows: info.rows,
  cols: info.cols,
  name: info.name,
  takenByName: info.takenByName,
  takenAt: info.takenAt.toUtc(),
  wordCount: info.wordCount,
  words: [
    for (final word in info.words)
      CopyWordFacts(
        label: word.label,
        speech: word.speech,
        colorKey: word.colorKey,
        imageHash: word.imageHash,
        cellKey: word.cellKey,
      ),
  ],
);
