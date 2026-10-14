/// Feature flags of the activity feed, the tray in plain words, suggested
/// words and circle members (agent W2). Setting one to false hides that
/// feature completely; nothing else depends on it.
library;

/// "What changed": the activity feed with one-tap Undo, its home entry and
/// the "Since you last looked" banner.
const bool activityFeedEnabled = true;

/// "Needs a home" in plain words: a word parked because two adults filled
/// the same spot offline shows both words, both adults and both times.
const bool plainTrayEnabled = true;

/// "Suggest a word": read-only members suggest, editors add or decline at
/// the top of "Needs a home".
const bool suggestWordEnabled = true;

/// "People in this circle", with "Remove from circle" for a guardian.
const bool circleMembersEnabled = true;
