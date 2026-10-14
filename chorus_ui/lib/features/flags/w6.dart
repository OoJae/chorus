/// Feature flags of the modelling features (items 11, 12, 22 and 24).
///
/// Each entry point checks its flag, so setting one to false hides that
/// feature completely and leaves everything else as it was.
library;

/// Item 11, the word finder: "Find a word" in the editor's bar and in the
/// model-mode bar, with "Show on the child's board".
const bool wordFinderEnabled = true;

/// Item 12, modelled versus said: an adult's taps in "Show words on the
/// board" are logged as modelled, and "This week" shows "modelled 14 ·
/// said 3".
const bool modelledWordsEnabled = true;

/// Item 12, focus words of the week: up to three pinned words with a
/// modelling tip, a quiet ring on them in the editor and the tip in the
/// model-mode bar.
const bool focusWordsEnabled = true;

/// Item 12, the Thursday nudge on home: "Nobody has modelled 'help' yet
/// this week."
const bool focusNudgeEnabled = true;

/// Item 24, speech to symbols: "Listen" in the model-mode bar, where the
/// browser has speech recognition.
const bool speechToSymbolsEnabled = true;

/// Item 22, the one-page progress report: "Progress report" on "This
/// week".
const bool progressReportEnabled = true;
