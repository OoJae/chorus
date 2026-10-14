import 'package:serverpod/serverpod.dart';

import '../circles/membership_guard.dart';
import '../generated/protocol.dart';
import 'week_summaries.dart';

/// "This week": what the word log says about one week, for the adults who
/// plan the child's words.
class SummaryEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// The week from Monday 00:00 UTC of the week [weekStart] falls in (this
  /// week when null) for [circleSpace]: most used words, words used for the
  /// first time, words added, words not used yet, and the totals. Guardians
  /// and therapists only.
  ///
  /// A week the weekly job already worked out is read as stored; any other
  /// is worked out now, so nothing depends on the job running. Throws
  /// [CircleException] with `notAllowed` for teachers and partners.
  Future<WeekReport> week(
    Session session,
    UuidValue circleSpace, [
    DateTime? weekStart,
  ]) async {
    final membership = await requireMember(session, circleSpace);
    if (membership.role != CircleRole.guardian &&
        membership.role != CircleRole.therapist) {
      throw CircleException(failure: CircleFailure.notAllowed);
    }
    return weekReport(session, circleSpace, weekStart ?? DateTime.now());
  }
}
