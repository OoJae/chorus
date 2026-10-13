import 'package:serverpod/serverpod.dart';

import '../circles/membership_guard.dart';
import '../generated/protocol.dart';
import 'media_files.dart';

/// Family photos and recorded voices, stored privately per circle.
///
/// A file is named by the SHA-256 of its bytes, so the same picture is stored
/// once and a tile only carries the hash. Bytes go straight to private
/// storage with a ticket; nothing is handed out until the server has checked
/// them against the hash.
class MediaEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Asks to upload a file of [bytes] bytes whose content hashes to [sha256]
  /// (lowercase hex). Editing roles only.
  ///
  /// The ticket's `uploadDescription` is null when the circle already holds
  /// verified bytes for this hash; the caller then skips the upload.
  ///
  /// Throws [CircleException] with `notAllowed` when the hash is not a
  /// lowercase SHA-256, or [bytes] is zero or over the cap for [kind]
  /// (images 400 KB, audio 600 KB).
  Future<UploadTicket> requestUpload(
    Session session,
    UuidValue circleSpace,
    String sha256,
    MediaKind kind,
    int bytes,
  ) async {
    await requireMember(session, circleSpace, editing: true);
    if (!isSha256Hex(sha256) || bytes <= 0 || bytes > maxBytesFor(kind)) {
      throw CircleException(failure: CircleFailure.notAllowed);
    }
    final path = mediaPath(circleSpace, sha256);

    // An upload that arrived but was never confirmed is settled first: it
    // either turns out to be the file, or it is removed to make room.
    final known = await findMedia(session, circleSpace, sha256);
    if (known != null && await verifyStoredMedia(session, known)) {
      return UploadTicket(path: path);
    }

    // The record is only (re)written while unverified, so a file verified a
    // moment ago by someone else is left alone.
    final recorded = await MediaObject.db.upsertRow(
      session,
      MediaObject(
        circleSpace: circleSpace,
        sha256: sha256,
        kind: kind,
        path: path,
        bytes: bytes,
        createdBy: callerId(session),
      ),
      conflictColumns: (t) => [t.circleSpace, t.sha256],
      updateColumns: (t) => [t.kind, t.bytes, t.createdBy],
      updateWhere: (t) => t.verifiedAt.equals(null),
    );
    if (recorded == null) {
      return UploadTicket(path: path);
    }

    return UploadTicket(
      path: path,
      uploadDescription: await _uploadDescription(session, path, bytes, kind),
    );
  }

  /// Checks the uploaded bytes against [sha256] and marks the file verified.
  /// Editing roles only. Returns false when the upload is missing or does not
  /// match its hash.
  Future<bool> confirmUpload(
    Session session,
    UuidValue circleSpace,
    String sha256,
  ) async {
    await requireMember(session, circleSpace, editing: true);
    if (!isSha256Hex(sha256)) return false;
    final object = await findMedia(session, circleSpace, sha256);
    if (object == null) return false;
    return verifyStoredMedia(session, object);
  }

  /// Short-lived download links, keyed by hash, for those of [hashes] that
  /// are verified files of this circle. Unknown hashes are left out.
  Future<Map<String, String>> downloadUrls(
    Session session,
    UuidValue circleSpace,
    List<String> hashes,
  ) async {
    await requireMember(session, circleSpace);
    final wanted = hashes.where(isSha256Hex).take(maxHashesPerCall).toSet();
    if (wanted.isEmpty) return {};

    final objects = await MediaObject.db.find(
      session,
      where: (t) =>
          t.circleSpace.equals(circleSpace) &
          t.sha256.inSet(wanted) &
          t.verifiedAt.notEquals(null),
    );
    final urls = <String, String>{};
    for (final object in objects) {
      try {
        final url = await session.storage.temporaryDownloadUrl(
          storageId: mediaStorageId,
          path: object.path,
          options: const TemporaryDownloadUrlOptions(
            expirationDuration: downloadLinkLifetime,
            // Never served as a page, whatever the bytes claim to be.
            contentType: 'application/octet-stream',
          ),
        );
        urls[object.sha256] = url.toString();
      } on CloudStorageFileNotFoundException {
        // Recorded but gone from storage: left out like an unknown hash.
      }
    }
    return urls;
  }

  /// Upload instructions for exactly [bytes] bytes at [path].
  ///
  /// Asks storage to refuse a second write to the same path, so a ticket
  /// issued earlier cannot replace bytes that have since been verified.
  /// Storage that cannot promise that still gets the upload.
  Future<String> _uploadDescription(
    Session session,
    String path,
    int bytes,
    MediaKind kind,
  ) async {
    UploadOptions options({required bool preventOverwrite}) => UploadOptions(
      expirationDuration: uploadTicketLifetime,
      maxFileSize: maxBytesFor(kind),
      contentLength: bytes,
      preventOverwrite: preventOverwrite,
    );
    try {
      return await session.storage.createUploadDescription(
        storageId: mediaStorageId,
        path: path,
        options: options(preventOverwrite: true),
      );
    } on CloudStorageUnsupportedOperationException {
      return session.storage.createUploadDescription(
        storageId: mediaStorageId,
        path: path,
        options: options(preventOverwrite: false),
      );
    }
  }
}
