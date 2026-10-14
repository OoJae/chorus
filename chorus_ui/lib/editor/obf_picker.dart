/// Picking an Open Board Format (.obf) file to import.
library;

import 'obf_picker_none.dart'
    if (dart.library.js_interop) 'obf_picker_web.dart'
    as platform;

/// A file the adult picked: its [name] and its text.
class PickedFile {
  const PickedFile({required this.name, required this.text});

  final String name;
  final String text;
}

/// Asks the adult for a file and completes with it, or with null when they
/// cancelled. Throws [PickedFileTooLarge] for a file too large to be a
/// board, and a [FormatException] for one that is not text.
typedef ObfFilePicker = Future<PickedFile?> Function();

/// The largest file read as a board. An .obf board of 36 words is a few
/// kilobytes; boards with embedded pictures are larger, and are still read
/// for their words.
const int maxObfFileBytes = 8 * 1024 * 1024;

/// Thrown for a file larger than [maxObfFileBytes].
class PickedFileTooLarge implements Exception {
  const PickedFileTooLarge();

  @override
  String toString() => 'PickedFileTooLarge';
}

/// The platform's file picker, or null where there is none without a new
/// dependency.
///
/// In the browser it is an `<input type="file">`. The Android app has no
/// file picker that can open an .obf file (the photo picker opens pictures
/// only), so there import is offered in the browser only.
ObfFilePicker? get platformObfPicker => platform.obfPicker;
