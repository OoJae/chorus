import 'package:chorus_shared/chorus_shared.dart' show weekStartOf;
import 'package:serverpod/serverpod.dart';

import '../circles/membership_guard.dart';
import '../generated/protocol.dart';
import 'focus_words.dart';

/// Focus words of the week: up to three words a guardian or therapist pins,
/// each with a one-line modelling tip, and the Thursday nudge when one has
/// not been modelled yet. Adults only see them; the child's board stays
/// calm.
class FocusEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// This week's focus words of [circleSpace], oldest pin first. Members.
  Future<List<FocusWordInfo>> words(
    Session session,
    UuidValue circleSpace,
  ) async {
    await requireMember(session, circleSpace);
    return [
      for (final pin in await focusWordsOf(
        session,
        circleSpace,
        DateTime.now(),
      ))
        FocusWordInfo(
          tileId: pin.tileId,
          tip: pin.tip,
          weekStart: pin.weekStart,
        ),
    ];
  }

  /// Replaces this week's focus words of [circleSpace] with [pins] (their
  /// `weekStart` is ignored) and returns them as kept. Guardians and
  /// therapists only.
  ///
  /// Throws [CircleException] with `notAllowed` for another role, more than
  /// three words, the same word twice, a tip over 120 characters, or a
  /// word that is not on one of the circle's boards.
  Future<List<FocusWordInfo>> setWords(
    Session session,
    UuidValue circleSpace,
    List<FocusWordInfo> pins,
  ) async {
    final membership = await requireMember(session, circleSpace);
    if (membership.role != CircleRole.guardian &&
        membership.role != CircleRole.therapist) {
      throw CircleException(failure: CircleFailure.notAllowed);
    }
    final ids = {for (final pin in pins) pin.tileId};
    if (pins.length > maxFocusWords || ids.length != pins.length) {
      throw CircleException(failure: CircleFailure.notAllowed);
    }
    final tips = [for (final pin in pins) pin.tip.trim()];
    if (tips.any((tip) => tip.length > maxFocusTipLength)) {
      throw CircleException(failure: CircleFailure.notAllowed);
    }
    if (ids.isNotEmpty) {
      // The synced tile table, read as the server sees it: filter on the
      // circle itself.
      final tiles = await Tile.db.find(
        session,
        where: (t) =>
            t.circleId.equals(circleSpace) &
            t.id.inSet(ids) &
            t.archivedAt.equals(null),
      );
      if (tiles.length != ids.length) {
        throw CircleException(failure: CircleFailure.notAllowed);
      }
    }
    final now = DateTime.now().toUtc();
    final week = weekStartOf(now);
    final me = callerId(session);
    await session.db.transaction((transaction) async {
      await FocusWord.db.deleteWhere(
        session,
        where: (t) =>
            t.circleSpace.equals(circleSpace) & t.weekStart.equals(week),
        transaction: transaction,
      );
      await FocusWord.db.insert(
        session,
        [
          for (final (i, pin) in pins.indexed)
            FocusWord(
              circleSpace: circleSpace,
              tileId: pin.tileId,
              tip: tips[i],
              weekStart: week,
              pinnedBy: me,
              // In the order given, so the list reads back the same.
              pinnedAt: now.add(Duration(microseconds: i)),
            ),
        ],
        transaction: transaction,
      );
    });
    return [
      for (final (i, pin) in pins.indexed)
        FocusWordInfo(tileId: pin.tileId, tip: tips[i], weekStart: week),
    ];
  }

  /// This week's nudge for [circleSpace]: a focus word nobody had modelled
  /// by Thursday and still has not, or null. Members.
  Future<FocusNudgeInfo?> nudge(Session session, UuidValue circleSpace) async {
    await requireMember(session, circleSpace);
    return nudgeFor(session, circleSpace);
  }
}
