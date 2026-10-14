/// The browser's share sheet, through the Web Share API.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// True where the browser offers `navigator.share`: phones, mostly.
bool canShareLinks() {
  try {
    return web.window.navigator.has('share');
  } catch (_) {
    return false;
  }
}

/// Opens the sheet. False when the adult closed it, or the browser refused
/// (it only shares straight after a tap).
Future<bool> shareLink(String url, String text, String title) async {
  try {
    await web.window.navigator
        .share(web.ShareData(title: title, text: text, url: url))
        .toDart;
    return true;
  } catch (_) {
    return false;
  }
}
