/// Switches for the talker access features (engineer W3). Setting one to
/// false hides that feature everywhere, and nothing else changes.
library;

/// Item 7, touch settings: hold time, ignore repeat taps and select on
/// release, in "This device" under "Touch", applied to every word on the
/// child's board.
const bool touchSettingsEnabled = true;

/// Item 8, switch access: one- and two-switch scanning with space and
/// enter, and the spoken preview, in "This device" under "Switch access".
/// (Each tile's screen-reader label is its spoken word whatever this says.)
const bool switchAccessEnabled = true;

/// Item 13, voice choice: the circle's voice, speed and pitch, in "This
/// device" under "Voice", on every device and on the view-only page.
const bool voiceChoiceEnabled = true;

/// Item 19, keyguard mode: the grid's fixed geometry and the keyguard
/// template, in "This device" under "Keyguard".
const bool keyguardEnabled = true;

/// Item 20, share a sentence and "Recent" sentences, in the child's status
/// row.
const bool shareSentenceEnabled = true;

/// Whether "This device" has anything to show: home offers it only then.
const bool deviceSettingsEnabled =
    touchSettingsEnabled ||
    switchAccessEnabled ||
    voiceChoiceEnabled ||
    keyguardEnabled;
