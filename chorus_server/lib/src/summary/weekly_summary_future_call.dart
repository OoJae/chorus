import 'package:serverpod/serverpod.dart';

import 'week_summaries.dart';

/// Works out last week for every circle whose word log is on, once a week,
/// so "This week" for a finished week is read rather than worked out.
///
/// Only a shortcut: `summary.week` works the same without it, which matters
/// where the Cloud plan runs no future calls.
class WeeklySummaryFutureCall extends FutureCall {
  Future<void> storeLastWeek(Session session) async {
    await storeLastWeekForAll(session);
  }
}
