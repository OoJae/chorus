/// The browser's share sheet (the Web Share API) and a download, through
/// the SDK's own JavaScript interop, as this package has no `package:web`.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('navigator')
external JSObject get _navigator;

@JS('document')
external JSObject get _document;

/// True where the browser offers `navigator.share`: phones, mostly.
bool canShareText() {
  try {
    return _navigator.has('share');
  } catch (_) {
    return false;
  }
}

/// Opens the sheet. False when the adult closed it, or the browser refused
/// (it only shares straight after a tap).
Future<bool> shareText(String text) async {
  try {
    final data = JSObject()..setProperty('text'.toJS, text.toJS);
    final shared = _navigator.callMethod<JSPromise<JSAny?>>('share'.toJS, data);
    await shared.toDart;
    return true;
  } catch (_) {
    return false;
  }
}

bool canSaveFiles() => true;

/// Downloads [text] as [fileName], through a link the page clicks itself.
Future<bool> saveTextFile(String fileName, String text) async {
  try {
    final link = _document.callMethod<JSObject>('createElement'.toJS, 'a'.toJS)
      ..setProperty(
        'href'.toJS,
        'data:image/svg+xml;charset=utf-8,${Uri.encodeComponent(text)}'.toJS,
      )
      ..setProperty('download'.toJS, fileName.toJS);
    link.callMethod<JSAny?>('click'.toJS);
    return true;
  } catch (_) {
    return false;
  }
}
