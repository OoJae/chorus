/// Feature flags of W8: picture scenes and named board copies.
///
/// Each entry point of a feature checks its flag, so setting one to false
/// hides that feature everywhere and nothing else changes.
library;

/// Picture scenes (item 17): "Scenes" on home for adults, where a family
/// photo gets spots that speak, and the "Scenes" button in the child's
/// status row, which opens the scene picker and the photo full-screen.
const bool pictureScenesEnabled = true;

/// Named board copies (item 25): "Save a copy" and "Copies" in the
/// editor's board menu, the read-only view of a copy, and "Put back",
/// which adds a missing word to "Needs a home".
const bool boardCopiesEnabled = true;
