import 'package:serverpod/serverpod.dart';

import '../circles/membership_guard.dart';
import '../generated/protocol.dart';

/// Most words taken in one call.
const int maxWordUsesPerCall = 200;

/// How far ahead of the server's clock a word's time may be.
const Duration wordUseClockSlack = Duration(minutes: 5);

/// How old a word may be and still be logged.
const Duration wordUseMaxAge = Duration(days: 30);

/// The opt-in word log: which tile the child's board spoke, and when.
///
/// Off until a guardian turns it on for the circle. It holds tile ids,
/// board ids and times only, never a label or a sentence, and a guardian can
/// delete it all at any time.
class WordLogEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Whether [circleSpace] keeps a word log, and whether the caller may
  /// change that. Members only.
  Future<WordLogStatus> status(Session session, UuidValue circleSpace) async {
    final membership = await requireMember(session, circleSpace);
    return WordLogStatus(
      enabled: await isWordLogOn(session, circleSpace),
      canChange: membership.role == CircleRole.guardian,
    );
  }

  /// Turns the circle's word log on or off. Guardians only. Turning it off
  /// keeps what was logged; [deleteAll] removes it.
  ///
  /// Words spoken before the log was last turned on or off are not taken
  /// (see [record]), so asking for the state it is already in changes
  /// nothing, not even the time.
  Future<WordLogStatus> setEnabled(
    Session session,
    UuidValue circleSpace,
    bool enabled,
  ) async {
    await _requireGuardian(session, circleSpace);
    if (await isWordLogOn(session, circleSpace) == enabled) {
      return WordLogStatus(enabled: enabled, canChange: true);
    }
    await WordLogSetting.db.upsertRow(
      session,
      WordLogSetting(
        circleSpace: circleSpace,
        enabled: enabled,
        changedBy: callerId(session),
        changedAt: DateTime.now().toUtc(),
      ),
      conflictColumns: (t) => [t.circleSpace],
    );
    return WordLogStatus(enabled: enabled, canChange: true);
  }

  /// Adds [uses] to the log and returns how many were new. Editing roles
  /// only, and only while the log is on.
  ///
  /// All or nothing: throws [WordLogException] and keeps none of the call
  /// when the log is off (`off`), there are more than 200 (`tooMany`), a
  /// time is more than five minutes ahead or more than 30 days old
  /// (`badTime`), or a tile is not one of the circle's (`unknownTile`). A
  /// word sent twice is kept once, so a batch can safely be sent again.
  /// Words of tiles marked "never log" are dropped quietly. The board is
  /// taken from the tile as the server holds it.
  ///
  /// Words spoken before the guardian last turned the log on or off, or
  /// deleted it, are dropped quietly too. A device that was offline, or
  /// never heard that its last batch arrived, still holds words; without
  /// this, sending them after a delete would put the deleted words back.
  Future<int> record(
    Session session,
    UuidValue circleSpace,
    List<WordUseEntry> uses,
  ) => _record(session, circleSpace, uses, modelled: false);

  /// Adds words an adult tapped in "Show words on the board" (model mode)
  /// as modelled, not said, and returns how many were new. The same rules
  /// and failures as [record]: editing roles only, only while the log is
  /// on, never words of tiles marked "never log". The device leaves them
  /// out in private mode.
  Future<int> recordModelled(
    Session session,
    UuidValue circleSpace,
    List<WordUseEntry> uses,
  ) => _record(session, circleSpace, uses, modelled: true);

  Future<int> _record(
    Session session,
    UuidValue circleSpace,
    List<WordUseEntry> uses, {
    required bool modelled,
  }) async {
    await requireMember(session, circleSpace, editing: true);
    if (!await isWordLogOn(session, circleSpace)) {
      throw WordLogException(failure: WordLogFailure.off);
    }
    if (uses.length > maxWordUsesPerCall) {
      throw WordLogException(failure: WordLogFailure.tooMany);
    }
    if (uses.isEmpty) return 0;

    final now = DateTime.now().toUtc();
    final latest = now.add(wordUseClockSlack);
    final earliest = now.subtract(wordUseMaxAge);
    for (final use in uses) {
      final at = use.spokenAt.toUtc();
      if (at.isAfter(latest) || at.isBefore(earliest)) {
        throw WordLogException(failure: WordLogFailure.badTime);
      }
    }

    // The synced tile table, read as the server sees it (not as a user's
    // replica would), so it must filter on the circle itself.
    final wanted = {for (final use in uses) use.tileId};
    final tiles = await Tile.db.find(
      session,
      where: (t) => t.circleId.equals(circleSpace) & t.id.inSet(wanted),
    );
    if (tiles.length != wanted.length) {
      throw WordLogException(failure: WordLogFailure.unknownTile);
    }
    final byId = {for (final tile in tiles) tile.id!: tile};

    final rows = [
      for (final use in uses)
        if (!byId[use.tileId]!.noLog)
          WordUseRecord(
            circleSpace: circleSpace,
            tileId: use.tileId,
            // The tile's own board, as the server holds it.
            boardId: byId[use.tileId]!.boardId,
            spokenAt: use.spokenAt.toUtc(),
            receivedAt: now,
            modelled: modelled,
          ),
    ];
    if (rows.isEmpty) return 0;
    final added = await session.db.transaction((transaction) async {
      // Read again under a shared lock, held until the words are in. A
      // delete or a switch that comes now waits until this call is done
      // (and a delete then removes what it added); one already under way
      // is waited for here, and its new time read.
      final setting = await WordLogSetting.db.findFirstRow(
        session,
        where: (t) => t.circleSpace.equals(circleSpace),
        transaction: transaction,
        lockMode: LockMode.forShare,
      );
      if (setting == null || !setting.enabled) {
        throw WordLogException(failure: WordLogFailure.off);
      }
      final since = setting.changedAt;
      final kept = [
        for (final row in rows)
          if (!row.spokenAt.isBefore(since)) row,
      ];
      if (kept.isEmpty) return const <WordUseRecord>[];
      final added = await WordUseRecord.db.insert(
        session,
        kept,
        ignoreConflicts: true,
        transaction: transaction,
      );
      if (added.isNotEmpty) {
        await forgetStoredWeeks(
          session,
          circleSpace,
          since: added
              .map((row) => row.spokenAt)
              .reduce((a, b) => a.isBefore(b) ? a : b),
          transaction: transaction,
        );
      }
      return added;
    });
    return added.length;
  }

  /// Removes the circle's whole word log for good, with the weeks worked
  /// out from it. Guardians only. Returns how many words went.
  ///
  /// It also moves the log's start to now, so words a device still holds
  /// from before the delete are not taken when it sends them (see
  /// [record]).
  Future<int> deleteAll(Session session, UuidValue circleSpace) async {
    await _requireGuardian(session, circleSpace);
    return session.db.transaction((transaction) async {
      // Locked first, so a call to [record] under way finishes before the
      // words go, and one that comes later reads the new start.
      final setting = await WordLogSetting.db.findFirstRow(
        session,
        where: (t) => t.circleSpace.equals(circleSpace),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (setting != null) {
        await WordLogSetting.db.updateRow(
          session,
          setting.copyWith(
            changedBy: callerId(session),
            changedAt: DateTime.now().toUtc(),
          ),
          columns: (t) => [t.changedBy, t.changedAt],
          transaction: transaction,
        );
      }
      final gone = await WordUseRecord.db.deleteWhere(
        session,
        where: (t) => t.circleSpace.equals(circleSpace),
        transaction: transaction,
      );
      await WeeklySummary.db.deleteWhere(
        session,
        where: (t) => t.circleSpace.equals(circleSpace),
        transaction: transaction,
      );
      return gone.length;
    });
  }

  Future<void> _requireGuardian(Session session, UuidValue circleSpace) async {
    final membership = await requireMember(session, circleSpace);
    if (membership.role != CircleRole.guardian) {
      throw CircleException(failure: CircleFailure.notAllowed);
    }
  }
}

/// True when a guardian has turned [circleSpace]'s word log on.
Future<bool> isWordLogOn(Session session, UuidValue circleSpace) async {
  final setting = await WordLogSetting.db.findFirstRow(
    session,
    where: (t) => t.circleSpace.equals(circleSpace),
  );
  return setting?.enabled ?? false;
}

/// Removes the weeks worked out ahead for [circleSpace] that a word spoken
/// at [since] changes: its own week and every later one, whose "first
/// time" lists depend on it. They are worked out again when asked for.
Future<void> forgetStoredWeeks(
  Session session,
  UuidValue circleSpace, {
  required DateTime since,
  Transaction? transaction,
}) async {
  final cutoff = since.toUtc().subtract(const Duration(days: 7));
  await WeeklySummary.db.deleteWhere(
    session,
    where: (t) => t.circleSpace.equals(circleSpace) & (t.weekStart > cutoff),
    transaction: transaction,
  );
}
