/// Feature flags for hidden words and the home language (engineer W5).
///
/// Setting a flag to false hides its feature completely: every entry point
/// checks it, and the board, the editor and the app work as before.
library;

/// Item 10: an adult can hide a word from the child's board for now. The
/// word's cell stays taken and blank, nothing moves, and "Show everything"
/// on the child's board shows every hidden word until the board is left.
/// In the editor a hidden word is dimmed with an "eye off" mark, and the
/// word's sheet offers "Hide for now" and "Show on the board again".
const bool hideWordsEnabled = true;

/// Item 16: a second (home) language per circle. The word's sheet in the
/// editor offers "Second language", and a switch on the child's board
/// shows every word that has one in that language and speaks it.
const bool homeLanguageEnabled = true;
