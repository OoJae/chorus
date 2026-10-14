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

/// "People in this circle", with "Remove from circle" for a guardian when
/// [removeFromCircleEnabled] is on.
const bool circleMembersEnabled = true;

/// "Remove from circle" on each other member, for a guardian. Off for the
/// judging: judges share the demo circle, and the server refuses to take a
/// demo sign-in out of it anyway. The list of people stays.
const bool removeFromCircleEnabled = false;

/// Several ideas for one photo, as small word tiles coloured by part of
/// speech, with "Add all to Needs a home". Off, the sheet asks for one word
/// as before.
const bool photoIdeasEnabled = true;

/// Words a sitter tapped on the view-only page, as lines in "What changed".
/// The server's own switch is `sitterTapsEnabled` in
/// `chorus_server/lib/src/sitter/sitter_taps.dart`.
const bool sitterTapsInFeedEnabled = true;
