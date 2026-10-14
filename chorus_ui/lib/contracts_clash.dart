/// "Try a clash": the practice partner as the editor sees it.
///
/// Kept apart from `contracts.dart` so the editor works exactly as before
/// without one.
library;

/// Why the practice partner did not put a word down.
enum PracticeRefusal {
  /// The server already has a word in that spot; another empty one may
  /// still work.
  cellTaken,

  /// The board or the spot has not reached the server.
  noSuchCell,

  /// The circle has had its practice words for this hour.
  tooMany,

  /// This adult may not change the board.
  notAllowed,

  /// The server could not be reached.
  unreachable,
}

/// Thrown by [ClashPartner.putWord].
class PracticeRefused implements Exception {
  const PracticeRefused(this.reason);

  final PracticeRefusal reason;

  @override
  String toString() => 'PracticeRefused(${reason.name})';
}

/// The word the practice partner put down on the server.
class PartnerWord {
  const PartnerWord({
    required this.tileId,
    required this.label,
    required this.partnerName,
  });

  final String tileId;
  final String label;

  /// How the partner is named on every device: "Practice partner".
  final String partnerName;
}

/// A second adult that lives on the server, so one adult with one device
/// can watch two words meet in one spot.
abstract class ClashPartner {
  /// Has the partner put a word into cell ([row], [col]) of [boardId] on
  /// the server, as another adult's device would. This device must not
  /// sync between this call and the adult's own word, or the partner's
  /// word arrives first and fills the spot.
  ///
  /// Throws [PracticeRefused].
  Future<PartnerWord> putWord({
    required String boardId,
    required int row,
    required int col,
  });
}
