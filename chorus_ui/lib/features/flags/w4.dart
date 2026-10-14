/// Feature flags of the talker's word tools: word endings, quick phrases
/// and the keyboard. Each switches its feature off completely: with a flag
/// false, the key on the child's board and every page behind it are gone,
/// and nothing else changes.
library;

/// The "word endings" key beside the sentence strip: plural, -ing, -ed,
/// -s and 's on the last word of the sentence.
const bool w4WordEndings = true;

/// The "quick phrases" key on the child's board, its full-screen panel,
/// and the "Quick phrases" page adults reach from home.
const bool w4QuickPhrases = true;

/// The keyboard key on the child's board and its full-screen keyboard
/// with word prediction.
const bool w4Keyboard = true;

/// True when any of the word tools is on, so the talker draws their keys.
const bool w4AnyWordTool = w4WordEndings || w4QuickPhrases || w4Keyboard;

/// Whether the word tool keys also show on a phone (the talker's narrow
/// and short layouts). There the strip's row and the status row are
/// already at the widths the board's layout promises (the strip keeps
/// nearly the whole width of an upright phone), so the keys would take
/// that width from the sentence. Off: on a phone the tools are reached by
/// holding the sentence strip for half a second instead. Turning this on
/// is a layout decision; `talker_layout_test.dart` would need new widths.
const bool w4WordToolsOnPhones = false;
