/// Names for media files: the SHA-256 of their bytes, and what kind of file
/// the bytes are.
library;

import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

/// The SHA-256 of [bytes] as 64 lowercase hex characters. This is the value
/// stored in a tile's `imageHash` or `audioHash` and sent to the server.
String sha256Hex(List<int> bytes) => crypto.sha256.convert(bytes).toString();

final RegExp _sha256 = RegExp(r'^[0-9a-f]{64}$');

/// True for exactly 64 lowercase hex characters. Anything else is never
/// used as a file name or sent to the server.
bool isSha256Hex(String value) => _sha256.hasMatch(value);

/// The container a media file is in, as far as the app needs to know to
/// name it and play it.
class MediaFormat {
  const MediaFormat(this.extension, this.mimeType);

  /// File extension without the dot.
  final String extension;
  final String mimeType;

  static const jpeg = MediaFormat('jpg', 'image/jpeg');
  static const png = MediaFormat('png', 'image/png');
  static const m4a = MediaFormat('m4a', 'audio/mp4');
  static const webm = MediaFormat('webm', 'audio/webm');
  static const ogg = MediaFormat('ogg', 'audio/ogg');
  static const wav = MediaFormat('wav', 'audio/wav');
  static const unknown = MediaFormat('bin', 'application/octet-stream');

  /// Every format [sniffFormat] can report.
  static const all = [jpeg, png, m4a, webm, ogg, wav, unknown];

  @override
  String toString() => 'MediaFormat($extension)';
}

/// Reads the format from the first bytes of a file. Recorders differ by
/// platform (AAC in MP4 on phones, Opus in WebM in most browsers), and a
/// player on another device needs to be told which it is.
MediaFormat sniffFormat(Uint8List bytes) {
  bool at(int offset, List<int> magic) {
    if (bytes.length < offset + magic.length) return false;
    for (var i = 0; i < magic.length; i++) {
      if (bytes[offset + i] != magic[i]) return false;
    }
    return true;
  }

  if (at(0, const [0xFF, 0xD8, 0xFF])) return MediaFormat.jpeg;
  if (at(0, const [0x89, 0x50, 0x4E, 0x47])) return MediaFormat.png;
  // "ftyp" after the four-byte box size.
  if (at(4, const [0x66, 0x74, 0x79, 0x70])) return MediaFormat.m4a;
  // EBML header.
  if (at(0, const [0x1A, 0x45, 0xDF, 0xA3])) return MediaFormat.webm;
  if (at(0, const [0x4F, 0x67, 0x67, 0x53])) return MediaFormat.ogg;
  // "RIFF" .... "WAVE".
  if (at(0, const [0x52, 0x49, 0x46, 0x46]) &&
      at(8, const [0x57, 0x41, 0x56, 0x45])) {
    return MediaFormat.wav;
  }
  return MediaFormat.unknown;
}
