/// Handing a link to the system's share sheet, where Chorus can reach one.
library;

import 'share_link_none.dart'
    if (dart.library.js_interop) 'share_link_web.dart'
    as platform;

/// Opens the share sheet for [url], with [text] and [title] beside it.
/// Completes with false when the adult closed it without sharing.
typedef ShareLink = Future<bool> Function(Uri url, String text, String title);

/// The device's share sheet, or null where Chorus has none to open: in a
/// browser without the Web Share API (most desktop browsers), and in the
/// installed app, which carries no share plugin. The screens then offer
/// Copy alone.
ShareLink? systemShareLink() => platform.canShareLinks() ? _share : null;

Future<bool> _share(Uri url, String text, String title) =>
    platform.shareLink(url.toString(), text, title);
