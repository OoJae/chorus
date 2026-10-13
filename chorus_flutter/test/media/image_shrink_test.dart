import 'dart:math';
import 'dart:typed_data';

import 'package:chorus_flutter/src/media/image_shrink.dart';
import 'package:chorus_flutter/src/media/media_hash.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// A picture where every pixel is random: the worst case for a JPEG.
img.Image _noise(int width, int height) {
  final random = Random(7);
  final picture = img.Image(width: width, height: height);
  for (final pixel in picture) {
    pixel
      ..r = random.nextInt(256)
      ..g = random.nextInt(256)
      ..b = random.nextInt(256);
  }
  return picture;
}

void main() {
  test('a wide photo comes out 512 on the long side, as a small JPEG', () {
    final source = img.encodeJpg(_noise(1600, 900), quality: 95);

    final out = shrinkToJpeg(source);

    expect(sniffFormat(out), MediaFormat.jpeg);
    expect(out.length, lessThanOrEqualTo(maxImageBytes));
    final decoded = img.decodeJpg(out)!;
    expect(decoded.width, 512);
    expect(decoded.height, 288);
  });

  test('a tall photo is limited by its height', () {
    final out = shrinkToJpeg(img.encodePng(_noise(300, 1200)));

    final decoded = img.decodeJpg(out)!;
    expect(decoded.height, 512);
    expect(decoded.width, 128);
  });

  test('a small picture keeps its size but is still re-encoded', () {
    final source = img.encodePng(_noise(40, 30));

    final out = shrinkToJpeg(source);

    expect(sniffFormat(out), MediaFormat.jpeg);
    final decoded = img.decodeJpg(out)!;
    expect((decoded.width, decoded.height), (40, 30));
  });

  test('the same photo always gives the same bytes, so the same hash', () {
    final source = img.encodeJpg(_noise(800, 800));
    expect(sha256Hex(shrinkToJpeg(source)), sha256Hex(shrinkToJpeg(source)));
  });

  test('quality drops until the picture fits the byte limit', () {
    final source = img.encodePng(_noise(512, 512));
    final usual = shrinkToJpeg(source);
    final limit = usual.length - 1;

    final tighter = shrinkToJpeg(source, maxBytes: limit);

    expect(tighter.length, lessThanOrEqualTo(limit));
    expect(sniffFormat(tighter), MediaFormat.jpeg);
  });

  test('see-through pixels land on white', () {
    final picture = img.Image(width: 8, height: 8, numChannels: 4);
    final out = shrinkToJpeg(img.encodePng(picture));

    final pixel = img.decodeJpg(out)!.getPixel(4, 4);
    expect(pixel.r, greaterThan(240));
    expect(pixel.g, greaterThan(240));
    expect(pixel.b, greaterThan(240));
  });

  test('bytes that are not a picture are refused', () {
    expect(() => shrinkToJpeg(Uint8List.fromList(List.filled(64, 3))),
        throwsFormatException);
    expect(() => shrinkToJpeg(Uint8List(0)), throwsFormatException);
  });

  test('a picture that cannot fit is refused rather than stored too big', () {
    expect(() => shrinkToJpeg(img.encodePng(_noise(512, 512)), maxBytes: 100),
        throwsFormatException);
  });
}
