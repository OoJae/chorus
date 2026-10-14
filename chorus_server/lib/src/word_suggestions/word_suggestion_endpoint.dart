import 'package:serverpod/serverpod.dart';

import '../circles/membership_guard.dart';
import '../generated/protocol.dart';

/// Longest label a suggestion keeps.
const int maxSuggestedLabelLength = 40;

/// Most open suggestions one circle holds; older ones are not listed.
const int maxOpenSuggestions = 50;

/// Most suggestions one member may have waiting for an editor at once.
const int maxOpenSuggestionsPerMember = 10;

/// Most suggestions one circle may have waiting for an editor at once,
/// fewer than [maxOpenSuggestions], so every waiting one is listed.
const int maxOpenSuggestionsPerCircle = 30;

/// `source` of a suggestion made by a person in the circle.
const String suggestionFromPerson = 'person';

/// `source` of a suggestion made from a photo.
const String suggestionFromPhoto = 'photo';

/// `resolution` of a suggestion an editor put on the board.
const String suggestionAdded = 'added';

/// `resolution` of a suggestion an editor said no to.
const String suggestionDeclined = 'declined';

/// Words suggested for the board by anyone in the circle, read-only members
/// included. A suggestion never reaches the board by itself: an editor adds
/// it through the normal add path, then chooses its spot.
class WordSuggestionEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Suggests [label] (with optional [speech] and part-of-speech
  /// [colorKey]) for [circleSpace]'s board. Any member. Each text is cut to
  /// [maxSuggestedLabelLength] characters.
  ///
  /// Throws [CircleException] with `notAllowed` while the caller already
  /// has [maxOpenSuggestionsPerMember] suggestions waiting, or the circle
  /// [maxOpenSuggestionsPerCircle], so nobody can bury the others' words.
  Future<SuggestedWordInfo> suggest(
    Session session,
    UuidValue circleSpace,
    String label,
    String? speech,
    String? colorKey,
  ) async {
    final me = await requireMember(session, circleSpace);
    final text = _clean(label);
    if (text == null) {
      throw ArgumentError.value(label, 'label', 'A suggestion needs a word');
    }
    final row = await session.db.transaction((transaction) async {
      // One suggestion at a time per circle, so the caps below hold even
      // when many calls come at once.
      await Circle.db.findFirstRow(
        session,
        where: (t) => t.spaceUuid.equals(circleSpace),
        lockMode: LockMode.forUpdate,
        transaction: transaction,
      );
      final mine = await SuggestedWord.db.count(
        session,
        where: (t) =>
            t.circleSpace.equals(circleSpace) &
            t.suggestedBy.equals(me.userId) &
            t.resolvedAt.equals(null),
        transaction: transaction,
      );
      final all = await SuggestedWord.db.count(
        session,
        where: (t) =>
            t.circleSpace.equals(circleSpace) & t.resolvedAt.equals(null),
        transaction: transaction,
      );
      if (mine >= maxOpenSuggestionsPerMember ||
          all >= maxOpenSuggestionsPerCircle) {
        throw CircleException(failure: CircleFailure.notAllowed);
      }
      return SuggestedWord.db.insertRow(
        session,
        SuggestedWord(
          circleSpace: circleSpace,
          label: text,
          speech: _clean(speech),
          colorKey: _clean(colorKey),
          suggestedBy: me.userId,
          suggestedByName: me.displayName,
          source: suggestionFromPerson,
          createdAt: DateTime.now().toUtc(),
        ),
        transaction: transaction,
      );
    });
    return infoOf(row);
  }

  /// The circle's open suggestions, oldest first. Editors only.
  Future<List<SuggestedWordInfo>> list(
    Session session,
    UuidValue circleSpace,
  ) async {
    await requireMember(session, circleSpace, editing: true);
    final rows = await SuggestedWord.db.find(
      session,
      where: (t) =>
          t.circleSpace.equals(circleSpace) & t.resolvedAt.equals(null),
      orderBy: (t) => t.createdAt,
      limit: maxOpenSuggestions,
    );
    return [for (final row in rows) infoOf(row)];
  }

  /// Answers suggestion [id]: [added] when an editor put it on the board,
  /// false when they said no. Editors only. Answering twice changes
  /// nothing.
  Future<void> resolve(
    Session session,
    UuidValue circleSpace,
    int id,
    bool added,
  ) async {
    final me = await requireMember(session, circleSpace, editing: true);
    final row = await SuggestedWord.db.findFirstRow(
      session,
      where: (t) => t.id.equals(id) & t.circleSpace.equals(circleSpace),
    );
    if (row == null || row.resolvedAt != null) return;
    await SuggestedWord.db.updateRow(
      session,
      row.copyWith(
        resolvedAt: DateTime.now().toUtc(),
        resolution: added ? suggestionAdded : suggestionDeclined,
        resolvedBy: me.userId,
      ),
      columns: (t) => [t.resolvedAt, t.resolution, t.resolvedBy],
    );
  }

  static String? _clean(String? value) {
    final text = value?.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text == null || text.isEmpty) return null;
    return text.length > maxSuggestedLabelLength
        ? text.substring(0, maxSuggestedLabelLength)
        : text;
  }
}

/// [row] as editors see it.
SuggestedWordInfo infoOf(SuggestedWord row) => SuggestedWordInfo(
  id: row.id!,
  label: row.label,
  speech: row.speech,
  colorKey: row.colorKey,
  suggestedByName: row.suggestedByName,
  source: row.source,
  createdAt: row.createdAt,
);
