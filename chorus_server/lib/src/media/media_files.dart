/// Where a circle's media files live in storage, the limits on them, and the
/// one check that makes a stored file trustworthy.
///
/// A file is named by the SHA-256 of its bytes and filed under its circle, so
/// the same picture is stored once per circle and a hash from one circle
/// says nothing about another's files.
library;

import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Media is never public: files are reached only through short-lived links.
const String mediaStorageId = 'private';

/// Largest image the server takes, in bytes.
const int maxImageBytes = 400 * 1024;

/// Largest voice clip the server takes, in bytes.
const int maxAudioBytes = 600 * 1024;

/// How long an upload ticket stays usable.
const Duration uploadTicketLifetime = Duration(minutes: 10);

/// How long a download link stays usable.
const Duration downloadLinkLifetime = Duration(minutes: 5);

/// Most hashes one `downloadUrls` call answers; the rest are ignored.
const int maxHashesPerCall = 200;

final RegExp _sha256Hex = RegExp(r'^[0-9a-f]{64}$');

/// True when [value] is a SHA-256 as lowercase hex, the only form stored.
bool isSha256Hex(String value) => _sha256Hex.hasMatch(value);

/// Size cap for a file of [kind], in bytes.
int maxBytesFor(MediaKind kind) => switch (kind) {
  MediaKind.image => maxImageBytes,
  MediaKind.audio => maxAudioBytes,
};

/// Path in private storage of the circle's file with hash [sha256].
///
/// Built only from server-checked values. Throws [ArgumentError] when
/// [sha256] is not lowercase hex, so a caller's text can never shape a path.
String mediaPath(UuidValue circleSpace, String sha256) {
  if (!isSha256Hex(sha256)) {
    throw ArgumentError.value(sha256, 'sha256', 'not a lowercase SHA-256');
  }
  return 'media/${circleSpace.uuid.toLowerCase()}/$sha256';
}

/// Lowercase hex SHA-256 of [data].
String sha256Of(ByteData data) => crypto.sha256
    .convert(
      Uint8List.sublistView(data),
    )
    .toString();

/// The circle's record for [sha256], or null when there is none.
Future<MediaObject?> findMedia(
  Session session,
  UuidValue circleSpace,
  String sha256,
) => MediaObject.db.findFirstRow(
  session,
  where: (t) => t.circleSpace.equals(circleSpace) & t.sha256.equals(sha256),
);

/// The bytes of the circle's verified file with hash [sha256], or null when
/// the circle has no such verified file.
///
/// For server-side readers such as the word suggestion. The caller must have
/// checked membership first.
Future<ByteData?> readVerifiedMedia(
  Session session,
  UuidValue circleSpace,
  String sha256,
) async {
  if (!isSha256Hex(sha256)) return null;
  final object = await findMedia(session, circleSpace, sha256);
  if (object == null || object.verifiedAt == null) return null;
  try {
    return await session.storage.retrieveFile(
      storageId: mediaStorageId,
      path: object.path,
    );
  } on CloudStorageFileNotFoundException {
    return null;
  }
}

/// Checks the stored bytes of [object] against its hash and size cap, and
/// stamps `verifiedAt` when they match.
///
/// Returns false when nothing was uploaded, or when the bytes are too large
/// or hash to something else; a wrong file is deleted so the upload can be
/// tried again. Already verified files return true without being re-read.
Future<bool> verifyStoredMedia(Session session, MediaObject object) async {
  if (object.verifiedAt != null) return true;
  final storage = session.storage;
  final path = object.path;
  try {
    // False only means "no upload was waiting": an earlier confirm may have
    // got this far and then failed, so the bytes are checked either way.
    await storage.verifyUpload(storageId: mediaStorageId, path: path);
    final stat = await storage.statFile(storageId: mediaStorageId, path: path);
    var matches = stat.size > 0 && stat.size <= maxBytesFor(object.kind);
    if (matches) {
      final data = await storage.retrieveFile(
        storageId: mediaStorageId,
        path: path,
      );
      matches = sha256Of(data) == object.sha256;
    }
    if (!matches) {
      await storage.deleteFile(storageId: mediaStorageId, path: path);
      return false;
    }
    await MediaObject.db.updateRow(
      session,
      object.copyWith(bytes: stat.size, verifiedAt: DateTime.now().toUtc()),
      columns: (t) => [t.bytes, t.verifiedAt],
    );
    return true;
  } on CloudStorageFileNotFoundException {
    return false;
  }
}
