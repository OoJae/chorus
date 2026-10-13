/// Makes any picked photo small enough to sync to every device in the
/// circle and to sit on a tile.
library;

import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Longest side of a stored picture, in pixels.
const int maxImageSide = 512;

/// Upper limit for a stored picture, in bytes.
const int maxImageBytes = 400 * 1000;

/// Decodes [bytes], turns the picture the way the camera held it, scales it
/// so neither side is over [maxSide] and re-encodes it as a JPEG no larger
/// than [maxBytes]. A picture that is already small is still re-encoded, so
/// location and camera details in the original never leave the device.
///
/// Pure Dart, so it gives the same bytes on a phone, a desktop and in a
/// browser. Throws [FormatException] for bytes that are not a picture.
Uint8List shrinkToJpeg(
  Uint8List bytes, {
  int maxSide = maxImageSide,
  int maxBytes = maxImageBytes,
}) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    decoded = null;
  }
  if (decoded == null) {
    throw const FormatException('The file is not a picture.');
  }
  var picture = img.bakeOrientation(decoded);
  if (picture.width > maxSide || picture.height > maxSide) {
    picture = picture.width >= picture.height
        ? img.copyResize(picture,
            width: maxSide, interpolation: img.Interpolation.average)
        : img.copyResize(picture,
            height: maxSide, interpolation: img.Interpolation.average);
  }
  // JPEG has no transparency: put see-through pixels on white, not black.
  if (picture.numChannels == 4 || picture.hasPalette) {
    final flat = img.Image(width: picture.width, height: picture.height);
    img.fill(flat, color: img.ColorRgb8(255, 255, 255));
    picture = img.compositeImage(flat, picture.convert(numChannels: 4));
  }
  // 512 pixels at quality 82 is far below the limit for any real photo;
  // the loop is the guarantee, not the usual path.
  Uint8List encoded = img.encodeJpg(picture, quality: 82);
  for (var quality = 70; encoded.length > maxBytes && quality >= 30; quality -= 20) {
    encoded = img.encodeJpg(picture, quality: quality);
  }
  if (encoded.length > maxBytes) {
    throw const FormatException('The picture could not be made small enough.');
  }
  return encoded;
}
