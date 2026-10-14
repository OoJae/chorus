/// Switches for the clash practice and trust features. Setting one to
/// false hides that feature everywhere: every entry point checks it, and
/// nothing else depends on the feature being there.
library;

/// "Try a clash" in the editor's board menu, with its guide, the glowing
/// spot and the practice partner on the server.
const bool tryAClashEnabled = true;

/// The status chip says "Everyone's up to date" and "2 changes waiting to
/// send" instead of "Up to date" and "Sending changes".
const bool trustChipWordsEnabled = true;

/// "Who is up to date" on home: each member's devices and when they last
/// synced, with the heartbeat each device sends after a sync.
const bool whoIsUpToDateEnabled = true;

/// The quiet line on home and in the editor naming who else is looking at
/// the board right now.
const bool presenceLineEnabled = true;

/// "Under the hood" on home: what the replica on this device holds, for
/// the curious. Read-only.
const bool underTheHoodEnabled = true;
