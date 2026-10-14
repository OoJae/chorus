/// Feature flags for the content features: pictures on every starter word,
/// and ready-made boards. Set one to false to hide that feature completely;
/// nothing else depends on it.
library;

/// Pictures on all 36 starter words. When false, the 13 words that gained a
/// picture with this feature (the five from Mulberry Symbols and the eight
/// drawn for Chorus) show as text again in the app, as before; the other 23
/// keep theirs. The paper copy and the view-only page draw from the server's
/// own symbol list, which this flag does not reach.
const bool coreSymbolsEnabled = true;

/// "Add a ready-made board" in the editor's board menu: six bundled Open
/// Board Format boards (Food, People, Places, Feelings, Actions, Describing
/// words), each added through the same import as "Import a board (.obf)".
/// When false, the menu item is not offered.
const bool readyMadeBoardsEnabled = true;
