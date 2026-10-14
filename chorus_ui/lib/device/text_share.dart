/// Handing text to the system's share sheet, or saving it as a file,
/// where the platform offers it. Everywhere else the screens copy instead.
library;

import 'text_share_none.dart'
    if (dart.library.js_interop) 'text_share_web.dart'
    as platform;

/// Opens the share sheet for [text]. Completes with true once it was shared
/// and false when the adult closed the sheet.
typedef ShareText = Future<bool> Function(String text);

/// Saves [text] as a file called [fileName]. Completes with false when it
/// could not be saved.
typedef SaveTextFile = Future<bool> Function(String fileName, String text);

/// The device's share sheet, or null where there is none to open: most
/// desktop browsers, and the installed app, which carries no share plugin.
ShareText? systemShareText() =>
    platform.canShareText() ? platform.shareText : null;

/// A file download, or null where Chorus cannot save a file (the installed
/// app, which has no file plugin).
SaveTextFile? systemSaveTextFile() =>
    platform.canSaveFiles() ? platform.saveTextFile : null;
