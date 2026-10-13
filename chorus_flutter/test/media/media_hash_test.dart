import 'dart:convert';
import 'dart:typed_data';

import 'package:chorus_flutter/src/media/media_hash.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sha256Hex', () {
    test('matches the published test vectors', () {
      expect(
        sha256Hex(const []),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
      expect(
        sha256Hex(utf8.encode('abc')),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('is what isSha256Hex accepts', () {
      expect(isSha256Hex(sha256Hex(const [1, 2, 3])), isTrue);
    });
  });

  group('isSha256Hex', () {
    test('refuses anything that could not be a file name for a hash', () {
      final good = 'a' * 64;
      expect(isSha256Hex(good), isTrue);
      expect(isSha256Hex('A' * 64), isFalse, reason: 'uppercase');
      expect(isSha256Hex('a' * 63), isFalse);
      expect(isSha256Hex('a' * 65), isFalse);
      expect(isSha256Hex('${'a' * 62}/.'), isFalse);
      expect(isSha256Hex('../${'a' * 61}'), isFalse);
      expect(isSha256Hex('$good\n'), isFalse);
      expect(isSha256Hex(''), isFalse);
    });
  });

  group('sniffFormat', () {
    Uint8List bytes(List<int> head) =>
        Uint8List.fromList([...head, ...List.filled(16, 0)]);

    test('tells the formats the app records and stores apart', () {
      expect(sniffFormat(bytes(const [0xFF, 0xD8, 0xFF, 0xE0])),
          MediaFormat.jpeg);
      expect(sniffFormat(bytes(const [0x89, 0x50, 0x4E, 0x47])),
          MediaFormat.png);
      expect(
        sniffFormat(bytes([0, 0, 0, 0x1C, ...ascii.encode('ftypM4A ')])),
        MediaFormat.m4a,
      );
      expect(sniffFormat(bytes(const [0x1A, 0x45, 0xDF, 0xA3])),
          MediaFormat.webm);
      expect(sniffFormat(bytes(ascii.encode('OggS'))), MediaFormat.ogg);
      expect(
        sniffFormat(bytes([...ascii.encode('RIFF'), 0, 0, 0, 0, ...ascii.encode('WAVE')])),
        MediaFormat.wav,
      );
    });

    test('anything else, however short, is unknown', () {
      expect(sniffFormat(Uint8List(0)), MediaFormat.unknown);
      expect(sniffFormat(Uint8List.fromList(const [0xFF])), MediaFormat.unknown);
      expect(sniffFormat(bytes(ascii.encode('RIFF'))), MediaFormat.unknown);
    });
  });
}
