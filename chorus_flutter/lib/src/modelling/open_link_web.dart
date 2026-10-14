/// Opening a page in a new browser tab.
library;

import 'package:web/web.dart' as web;

bool openInNewTab(String url) {
  try {
    // With "noopener" the browser returns no window, so there is nothing to
    // check; a blocked pop-up still leaves the link in the dialog.
    web.window.open(url, '_blank', 'noopener');
    return true;
  } catch (_) {
    return false;
  }
}
