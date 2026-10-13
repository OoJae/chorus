/// Circle cache storage on the web: the browser's local storage.
///
/// A browser may refuse storage (private windows, blocked site data). Both
/// calls then throw, and the cache treats that as nothing saved.
library;

import 'dart:js_interop';

@JS('localStorage.getItem')
external JSString? _getItem(JSString key);

@JS('localStorage.setItem')
external void _setItem(JSString key, JSString value);

Future<String?> readText(String name) async => _getItem(name.toJS)?.toDart;

Future<void> writeText(String name, String text) async =>
    _setItem(name.toJS, text.toJS);
