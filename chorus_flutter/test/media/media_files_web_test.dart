@TestOn('browser')
library;

import 'dart:typed_data';

import 'package:chorus_flutter/src/media/media_files.dart';
import 'package:chorus_flutter/src/media/media_hash.dart';
import 'package:flutter_test/flutter_test.dart';

/// Run with `flutter test --platform chrome test/media/media_files_web_test.dart`.
/// Skipped by the ordinary test run, which has no browser.
void main() {
  test('the browser keeps files and notes in IndexedDB', () async {
    final files = await openMediaFiles();
    expect(files, isNot(isA<MemoryMediaFiles>()));
    final clip = Uint8List.fromList(
        [0x1A, 0x45, 0xDF, 0xA3, DateTime.now().millisecond % 256]);
    final hash = sha256Hex(clip);

    await files.write(hash, clip);
    await files.writeNote('uploads_test', '["x"]');

    expect(files.has(hash), isTrue);
    expect(await files.read(hash), clip);
    expect(files.pathOf(hash), isNull);
    expect(await files.readNote('uploads_test'), '["x"]');
    expect(await files.readNote('never written'), isNull);
    expect(await files.read('f' * 64), isNull);
  });
}
