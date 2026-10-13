import 'dart:io';
import 'dart:typed_data';

import 'package:chorus_flutter/src/media/media_files.dart';
import 'package:chorus_flutter/src/media/media_files_io.dart';
import 'package:chorus_flutter/src/media/media_hash.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('chorus_media_test');
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3, 4]);
  final clip = Uint8List.fromList([0x1A, 0x45, 0xDF, 0xA3, 9, 9, 9]);

  group('IoMediaFiles', () {
    test('keeps a file under its hash and gives it back', () async {
      final files = await IoMediaFiles.open(dir);
      final hash = sha256Hex(jpeg);
      expect(files.has(hash), isFalse);
      expect(await files.read(hash), isNull);
      expect(files.pathOf(hash), isNull);

      await files.write(hash, jpeg);

      expect(files.has(hash), isTrue);
      expect(await files.read(hash), jpeg);
      expect(sha256Hex((await files.read(hash))!), hash);
    });

    test('names the file by hash, with an extension a player can go by',
        () async {
      final files = await IoMediaFiles.open(dir);
      await files.write(sha256Hex(jpeg), jpeg);
      await files.write(sha256Hex(clip), clip);

      expect(p.basename(files.pathOf(sha256Hex(jpeg))!),
          '${sha256Hex(jpeg)}.jpg');
      expect(p.basename(files.pathOf(sha256Hex(clip))!),
          '${sha256Hex(clip)}.webm');
      expect(await File(files.pathOf(sha256Hex(clip))!).readAsBytes(), clip);
    });

    test('still holds everything after the app restarts', () async {
      final first = await IoMediaFiles.open(dir);
      await first.write(sha256Hex(jpeg), jpeg);
      await first.write(sha256Hex(clip), clip);
      await first.writeNote('uploads_a', '[1]');

      final second = await IoMediaFiles.open(dir);

      expect(second.has(sha256Hex(jpeg)), isTrue);
      expect(await second.read(sha256Hex(clip)), clip);
      expect(await second.readNote('uploads_a'), '[1]');
    });

    test('writing a hash twice leaves one file', () async {
      final files = await IoMediaFiles.open(dir);
      final hash = sha256Hex(jpeg);
      await files.write(hash, jpeg);
      await files.write(hash, jpeg);

      final names = [
        await for (final entry in dir.list()) p.basename(entry.path),
      ];
      expect(names, ['$hash.jpg']);
    });

    test('refuses a name that is not a hash', () async {
      final files = await IoMediaFiles.open(dir);
      expect(() => files.write('../escape', jpeg), throwsArgumentError);
      expect(() => files.write('A' * 64, jpeg), throwsArgumentError);
    });

    test('notes and half-written files are never taken for media', () async {
      final hash = sha256Hex(jpeg);
      await File(p.join(dir.path, '$hash.jpg.part')).writeAsBytes(jpeg);
      await File(p.join(dir.path, 'stray.txt')).writeAsString('x');
      final files = await IoMediaFiles.open(dir);
      await files.writeNote('uploads/../../x', 'kept inside');

      expect(files.has(hash), isFalse);
      expect(await files.readNote('uploads/../../x'), 'kept inside');
      // The note stayed in the media directory.
      expect(await dir.list().length, 3);
      expect(await files.readNote('never written'), isNull);
    });

    test('a file removed behind the app is reported missing, not thrown',
        () async {
      final files = await IoMediaFiles.open(dir);
      final hash = sha256Hex(jpeg);
      await files.write(hash, jpeg);
      await File(files.pathOf(hash)!).delete();

      expect(await files.read(hash), isNull);
      expect(files.has(hash), isFalse);
    });

    test('a note is replaced whole', () async {
      final files = await IoMediaFiles.open(dir);
      await files.writeNote('q', 'a long first value');
      await files.writeNote('q', 'b');
      expect(await files.readNote('q'), 'b');
    });
  });

  group('MemoryMediaFiles', () {
    test('holds files and notes, and has no paths', () async {
      final files = MemoryMediaFiles();
      final hash = sha256Hex(clip);
      await files.write(hash, clip);
      await files.writeNote('q', 'text');

      expect(files.has(hash), isTrue);
      expect(await files.read(hash), clip);
      expect(files.pathOf(hash), isNull);
      expect(await files.readNote('q'), 'text');
      expect(await files.read(sha256Hex(jpeg)), isNull);
    });
  });
}
