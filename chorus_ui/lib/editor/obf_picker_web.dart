/// The browser's file picker: an `<input type="file">`, reached through the
/// SDK's own JavaScript interop, as this package has no `package:web`.
library;

import 'dart:async';
import 'dart:js_interop';

import 'obf_picker.dart';

/// The browser always has one.
ObfFilePicker? get obfPicker => _pick;

@JS('document')
external _Document get _document;

extension type _Document._(JSObject _) implements JSObject {
  external _Input createElement(String tagName);
  external _Node? get body;
}

extension type _Node._(JSObject _) implements JSObject {
  external void appendChild(_Node child);
}

extension type _Input._(JSObject _) implements _Node {
  external set type(String value);
  external set accept(String value);
  external _Style get style;
  external _FileList? get files;
  external void click();
  external void remove();
  external void addEventListener(String type, JSFunction listener);
}

extension type _Style._(JSObject _) implements JSObject {
  external set display(String value);
}

extension type _FileList._(JSObject _) implements JSObject {
  external int get length;
  external _File? item(int index);
}

extension type _File._(JSObject _) implements JSObject {
  external String get name;
  external double get size;
  external JSPromise<JSString> text();
}

Future<PickedFile?> _pick() {
  final picked = Completer<PickedFile?>();
  final input = _document.createElement('input')
    ..type = 'file'
    ..accept = '.obf,.json,application/json';
  input.style.display = 'none';
  // Some browsers open the picker only for an input that is in the page.
  _document.body?.appendChild(input);

  void finish(FutureOr<PickedFile?> Function() read) {
    if (picked.isCompleted) return;
    input.remove();
    Future.sync(read).then(
      (file) {
        if (!picked.isCompleted) picked.complete(file);
      },
      onError: (Object error, StackTrace stack) {
        if (!picked.isCompleted) picked.completeError(error, stack);
      },
    );
  }

  input.addEventListener(
    'change',
    ((JSAny? _) {
      finish(() async {
        final files = input.files;
        final file = (files == null || files.length == 0)
            ? null
            : files.item(0);
        if (file == null) return null;
        if (file.size > maxObfFileBytes) throw const PickedFileTooLarge();
        try {
          final text = await file.text().toDart;
          return PickedFile(name: file.name, text: text.toDart);
        } catch (_) {
          throw const FormatException('The file could not be read as text.');
        }
      });
    }).toJS,
  );
  // Closing the picker without a file. Browsers without the event leave
  // the future waiting, which only means nothing is imported.
  input.addEventListener(
    'cancel',
    ((JSAny? _) {
      finish(() => null);
    }).toJS,
  );
  input.click();
  return picked.future;
}
