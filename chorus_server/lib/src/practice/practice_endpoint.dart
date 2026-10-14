import 'package:chorus_shared/chorus_shared.dart' show CellKey, PlacedCell;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_offline_sync_server/serverpod_offline_sync_server.dart';

import '../circles/membership_guard.dart';
import '../generated/protocol.dart';

/// "Try a clash": a practice partner that puts a word into one cell of the
/// circle's board, so one adult with one device can watch two offline
/// claims on the same cell both survive.
///
/// The partner is a member of the circle's sync space and nothing else: it
/// has no account and no [Membership], so it never appears in the circle's
/// list of adults and can never sign in. Its id is derived from the circle,
/// so every circle has exactly one partner and every word it writes carries
/// the same author.
class PracticeEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// How the partner is named on every device.
  static const String partnerName = 'Practice partner';

  /// The most words the partner adds to one circle in one hour. Judges
  /// share the demo circle, so it is roomy enough for many of them.
  static const int hourlyLimit = 30;

  /// What the partner puts down, in this order: the first one not already
  /// on the board.
  static const List<({String label, String colorKey})> words = [
    (label: 'bubbles', colorKey: 'noun'),
    (label: 'swing', colorKey: 'noun'),
    (label: 'puzzle', colorKey: 'noun'),
    (label: 'slide', colorKey: 'noun'),
    (label: 'music', colorKey: 'noun'),
    (label: 'paint', colorKey: 'noun'),
  ];

  /// The name the partner's id is derived from, with the circle's space id
  /// as the namespace.
  static const String _partnerSeed = 'chorus-practice-partner';

  /// The practice partner of [circleSpace]: a UUID v5, the same on every
  /// call and different for every circle.
  static UuidValue partnerOf(UuidValue circleSpace) =>
      UuidValue.fromString(const Uuid().v5(circleSpace.uuid, _partnerSeed));

  /// Has the practice partner put a word into [cellKey] of board [boardId]
  /// in [circleSpace], on the server, as another adult's device would.
  /// Editing roles only.
  ///
  /// Throws [PracticeException] with `cellTaken` when the server already
  /// holds a word there (the caller picks another empty cell), `noSuchCell`
  /// when the board or cell is not in the circle, and `tooMany` after
  /// [hourlyLimit] words in the last hour.
  Future<PracticeWord> partnerWord(
    Session session,
    UuidValue circleSpace,
    UuidValue boardId,
    String cellKey,
  ) async {
    await requireMember(session, circleSpace, editing: true);
    final cell = CellKey.parse(cellKey);
    if (cell is! PlacedCell || cell.boardId != boardId.uuid) {
      throw PracticeException(failure: PracticeFailure.noSuchCell);
    }
    final db = session.db;
    if (db is! OfflineSyncDatabase) {
      throw StateError('The sync engine is not set up on this server.');
    }

    // transactionForUser checks only the sync space's membership row, so
    // that is all the partner is given: no account, no circle membership.
    final partner = partnerOf(circleSpace);
    final spaces = session.offlineSync.spaces;
    final role = await spaces.roleOf(user: partner, space: circleSpace);
    if (role != OfflineSyncSpaceRole.readWrite) {
      await spaces.grant(
        space: circleSpace,
        user: partner,
        role: OfflineSyncSpaceRole.readWrite,
      );
    }

    try {
      return await db.transactionForUser(partner, (tx) async {
        final board = await Board.db.findFirstRow(
          session,
          where: (t) => t.id.equals(boardId) & t.circleId.equals(circleSpace),
          transaction: tx,
        );
        if (board == null ||
            board.archivedAt != null ||
            cell.row < 0 ||
            cell.col < 0 ||
            cell.row >= board.rows ||
            cell.col >= board.cols) {
          throw PracticeException(failure: PracticeFailure.noSuchCell);
        }

        final now = DateTime.now().toUtc();
        final recent = await Tile.db.count(
          session,
          where: (t) =>
              t.circleId.equals(circleSpace) &
              t.createdBy.equals(partner) &
              (t.createdAt > now.subtract(const Duration(hours: 1))),
          transaction: tx,
        );
        if (recent >= hourlyLimit) {
          throw PracticeException(failure: PracticeFailure.tooMany);
        }

        final taken = await Tile.db.findFirstRow(
          session,
          where: (t) =>
              t.circleId.equals(circleSpace) & t.cellKey.equals(cellKey),
          transaction: tx,
        );
        if (taken != null) {
          throw PracticeException(failure: PracticeFailure.cellTaken);
        }

        final onBoard = await Tile.db.find(
          session,
          where: (t) =>
              t.circleId.equals(circleSpace) &
              t.boardId.equals(boardId) &
              t.archivedAt.equals(null),
          transaction: tx,
        );
        final word = pickWord({
          for (final tile in onBoard) tile.label.trim().toLowerCase(),
        });
        final tile = await Tile.db.insertRow(
          session,
          Tile(
            id: const Uuid().v7obj(),
            circleId: circleSpace,
            boardId: boardId,
            cellKey: cellKey,
            label: word.label,
            colorKey: word.colorKey,
            noLog: false,
            createdBy: partner,
            createdByName: partnerName,
            createdAt: now,
          ),
          transaction: tx,
        );
        // Its first values as `add` edits, as a device logs a word added by
        // hand, so "What changed" shows who added it.
        for (final (prop, value) in [
          ('label', word.label),
          ('cellKey', cellKey),
          ('colorKey', word.colorKey),
        ]) {
          await TileEdit.db.insertRow(
            session,
            TileEdit(
              circleId: circleSpace,
              tileId: tile.id!,
              prop: prop,
              oldValue: null,
              newValue: value,
              baseEditId: null,
              reason: 'add',
              actorId: partner,
              actorName: partnerName,
              editedAt: now,
            ),
            transaction: tx,
          );
        }
        return PracticeWord(
          tileId: tile.id!,
          label: tile.label,
          cellKey: tile.cellKey,
          partnerName: partnerName,
        );
      }, spaceId: circleSpace);
    } on DatabaseUniqueViolationException {
      // Another device's word reached the cell between the check and the
      // insert.
      throw PracticeException(failure: PracticeFailure.cellTaken);
    }
  }

  /// The first of [words] whose label is not in [labels] (lowercase), or
  /// the first of them when the board has every one.
  static ({String label, String colorKey}) pickWord(Set<String> labels) =>
      words.where((w) => !labels.contains(w.label)).firstOrNull ?? words.first;
}
