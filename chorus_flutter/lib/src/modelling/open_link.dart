/// Opening a page in a new browser tab, where Chorus runs in a browser.
library;

import 'open_link_none.dart'
    if (dart.library.js_interop) 'open_link_web.dart'
    as platform;

/// Opens [url] in a new tab. False where there is no browser to open it in
/// (the installed app), and the screen shows the link to copy instead.
bool openInNewTab(String url) => platform.openInNewTab(url);
