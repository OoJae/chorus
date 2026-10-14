/// Which of a browser's voices live on a server rather than on the device.
library;

import 'online_voices_stub.dart'
    if (dart.library.js_interop) 'online_voices_web.dart'
    as platform;

/// The names of the browser's voices that are not on this device, such as
/// Chrome's "Google US English" or Edge's "Online" voices. Such a voice sends
/// each word it says to a speech service, and is silent with no network.
///
/// Empty outside a browser, and wherever the list cannot be read.
Set<String> onlineVoiceNames() => platform.onlineVoiceNames();
