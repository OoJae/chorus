// A picture scene's photo is kept larger than a tile's picture, and still
// under the server's limit for a picture.
import 'dart:typed_data';

import 'package:chorus_flutter/src/media/cached_media_store.dart';
import 'package:chorus_flutter/src/media/image_shrink.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('a wide photo is kept 1280 pixels wide as a JPEG under the limit', () {
    final picture = img.Image(width: 2000, height: 1000);
    for (var x = 0; x < 2000; x += 1) {
      for (var y = 0; y < 1000; y += 7) {
        picture.setPixelRgb(x, y, x % 256, y % 256, (x * y) % 256);
      }
    }
    final png = Uint8List.fromList(img.encodePng(picture));

    final kept = shrinkSceneJpeg(png);
    final decoded = img.decodeJpg(kept)!;
    expect(decoded.width, maxSceneImageSide);
    expect(decoded.height, 640);
    expect(kept.length, lessThanOrEqualTo(maxImageBytes));
    // A tile's picture stays small.
    expect(img.decodeJpg(shrinkToJpeg(png))!.width, maxImageSide);
  });

  test('bytes that are not a picture are refused', () {
    expect(
      () => shrinkSceneJpeg(Uint8List.fromList([1, 2, 3])),
      throwsFormatException,
    );
  });
}
