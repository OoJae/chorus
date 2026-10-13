/// Retry timing for the sync supervisor.
library;

/// Delay before retry number [attempt]: [base] at attempt 0, doubling each
/// attempt, never more than [max]. A negative attempt counts as 0.
Duration backoffDelay(
  int attempt, {
  Duration base = const Duration(seconds: 1),
  Duration max = const Duration(seconds: 30),
}) {
  if (base >= max) return max;
  if (base <= Duration.zero) return Duration.zero;
  // Doubles step by step and stops at the cap, so a large attempt cannot
  // overflow.
  var delay = base;
  for (var i = 0; i < attempt; i++) {
    delay *= 2;
    if (delay >= max) return max;
  }
  return delay;
}
