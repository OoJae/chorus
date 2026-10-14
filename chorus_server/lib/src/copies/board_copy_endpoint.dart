import 'package:chorus_shared/chorus_shared.dart'
    show
        BoardFacts,
        TileFacts,
        copyNameProblem,
        copyWordsOf,
        maxCopiesPerCircle,
        tidyText;
import 'package:serverpod/serverpod.dart';

import '../circles/membership_guard.dart';
import '../generated/protocol.dart';

/// Named copies of a board, such as "Before the school trip".
///
/// A copy keeps the board's placed words as the server holds them when it
/// is taken. Taking, reading or deleting one never touches the board: a
/// word is put back on the adult's own device, through "Needs a home".
///
/// Each method throws [CircleException] with `notAMember` for someone
/// outside the circle, and with `notAllowed` for a read-only partner who
/// takes or deletes a copy, or for a name or board the rules refuse.
class BoardCopyEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Takes a copy of the board [boardId] called [name]. Editing roles
  /// only. Refused for a board the circle does not have in use, a name
  /// `copyNameProblem` refuses, and a circle that already keeps
  /// [maxCopiesPerCircle] copies.
  Future<BoardCopyInfo> take(
    Session session,
    UuidValue circleSpace,
    UuidValue boardId,
    String name,
  ) async {
    final membership = await requireMember(
      session,
      circleSpace,
      editing: true,
    );
    if (copyNameProblem(name) != null) {
      throw CircleException(failure: CircleFailure.notAllowed);
    }
    final kept = await BoardCopy.db.count(
      session,
      where: (t) => t.circleSpace.equals(circleSpace),
    );
    if (kept >= maxCopiesPerCircle) {
      throw CircleException(failure: CircleFailure.notAllowed);
    }

    // The synced tables, read as the server sees them (not as a user's
    // replica would), so every query filters on the circle itself.
    final board = await Board.db.findFirstRow(
      session,
      where: (t) => t.id.equals(boardId) & t.circleId.equals(circleSpace),
    );
    if (board == null || board.archivedAt != null) {
      throw CircleException(failure: CircleFailure.notAllowed);
    }
    final tiles = await Tile.db.find(
      session,
      where: (t) => t.circleId.equals(circleSpace) & t.boardId.equals(boardId),
    );
    final facts = BoardFacts(
      id: board.id!.uuid,
      name: board.name,
      rows: board.rows,
      cols: board.cols,
      isHome: board.isHome,
    );
    final words = copyWordsOf(facts.id, [
      for (final tile in tiles)
        TileFacts(
          id: tile.id!.uuid,
          boardId: tile.boardId.uuid,
          cellKey: tile.cellKey,
          label: tile.label,
          speech: tile.speech,
          colorKey: tile.colorKey,
          imageHash: tile.imageHash,
          archived: tile.archivedAt != null,
          createdAt: tile.createdAt,
        ),
    ], [facts]);

    final copy = await BoardCopy.db.insertRow(
      session,
      BoardCopy(
        circleSpace: circleSpace,
        boardId: boardId,
        boardName: board.name,
        rows: board.rows,
        cols: board.cols,
        name: tidyText(name),
        takenBy: membership.userId,
        takenByName: membership.displayName,
        takenAt: DateTime.now().toUtc(),
        words: [
          for (final word in words)
            BoardCopyWord(
              label: word.label,
              speech: word.speech,
              colorKey: word.colorKey,
              imageHash: word.imageHash,
              cellKey: word.cellKey,
            ),
        ],
      ),
    );
    return _info(copy, withWords: true);
  }

  /// The circle's copies, newest first, without their words. Members
  /// only.
  Future<List<BoardCopyInfo>> list(
    Session session,
    UuidValue circleSpace,
  ) async {
    await requireMember(session, circleSpace);
    final copies = await BoardCopy.db.find(
      session,
      where: (t) => t.circleSpace.equals(circleSpace),
      orderBy: (t) => t.id,
    );
    return [
      for (final copy in copies.reversed) _info(copy, withWords: false),
    ];
  }

  /// The copy [copyId] with its words, or null when the circle has no such
  /// copy. Members only.
  Future<BoardCopyInfo?> get(
    Session session,
    UuidValue circleSpace,
    int copyId,
  ) async {
    await requireMember(session, circleSpace);
    final copy = await BoardCopy.db.findFirstRow(
      session,
      where: (t) => t.id.equals(copyId) & t.circleSpace.equals(circleSpace),
    );
    return copy == null ? null : _info(copy, withWords: true);
  }

  /// Deletes the copy [copyId]. The board is not touched. Editing roles
  /// only. Returns false when the circle has no such copy.
  Future<bool> delete(
    Session session,
    UuidValue circleSpace,
    int copyId,
  ) async {
    await requireMember(session, circleSpace, editing: true);
    final deleted = await BoardCopy.db.deleteWhere(
      session,
      where: (t) => t.id.equals(copyId) & t.circleSpace.equals(circleSpace),
    );
    return deleted.isNotEmpty;
  }

  static BoardCopyInfo _info(BoardCopy copy, {required bool withWords}) =>
      BoardCopyInfo(
        id: copy.id!,
        boardId: copy.boardId,
        boardName: copy.boardName,
        rows: copy.rows,
        cols: copy.cols,
        name: copy.name,
        takenByName: copy.takenByName,
        takenAt: copy.takenAt,
        wordCount: copy.words.length,
        words: withWords ? copy.words : const [],
      );
}
