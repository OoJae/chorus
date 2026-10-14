import 'package:chorus_shared/chorus_shared.dart'
    show cleanQuickPhrases, defaultQuickPhrases;
import 'package:serverpod/serverpod.dart';

import '../circles/membership_guard.dart';
import '../generated/protocol.dart';

/// A circle's quick phrases: the few whole sentences the child's board says
/// at once ("Stop", "Help", "I'm hurt"). Every member reads them; editing
/// roles change them. Kept on the server only, never synced: each device
/// keeps its own copy for when it is offline.
class QuickPhraseEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// The circle's phrases in order, or the defaults when it has none of its
  /// own. Members only.
  Future<List<String>> list(Session session, UuidValue circleSpace) async {
    await requireMember(session, circleSpace);
    return quickPhrasesOf(session, circleSpace);
  }

  /// Replaces the circle's phrases with [phrases], in that order, and
  /// returns what was kept: trimmed, without empties or repeats, at most
  /// `maxQuickPhrases`, each at most `maxQuickPhraseLength` long (see
  /// `cleanQuickPhrases`). An empty list puts the defaults back. Editing
  /// roles only: a read-only partner is refused with `notAllowed`.
  Future<List<String>> set(
    Session session,
    UuidValue circleSpace,
    List<String> phrases,
  ) async {
    await requireMember(session, circleSpace, editing: true);
    final kept = cleanQuickPhrases(phrases);
    await session.db.transaction((transaction) async {
      await QuickPhrase.db.deleteWhere(
        session,
        where: (t) => t.circleSpace.equals(circleSpace),
        transaction: transaction,
      );
      if (kept.isEmpty) return;
      await QuickPhrase.db.insert(session, [
        for (var i = 0; i < kept.length; i++)
          QuickPhrase(circleSpace: circleSpace, position: i, text: kept[i]),
      ], transaction: transaction);
    });
    return kept.isEmpty ? defaultQuickPhrases : kept;
  }
}

/// [circleSpace]'s phrases in order, or the defaults when it has none.
Future<List<String>> quickPhrasesOf(
  Session session,
  UuidValue circleSpace,
) async {
  final rows = await QuickPhrase.db.find(
    session,
    where: (t) => t.circleSpace.equals(circleSpace),
    orderBy: (t) => t.position,
  );
  if (rows.isEmpty) return defaultQuickPhrases;
  return [for (final row in rows) row.text];
}
