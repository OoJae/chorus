/// Endpoint tests for media: who may upload and download, that identical
/// bytes are stored once, the size caps, and that nothing is handed out
/// before the server has checked the bytes against their hash.
library;

import 'dart:typed_data';

import 'package:chorus_server/src/generated/protocol.dart';
import 'package:chorus_server/src/media/media_files.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_offline_sync_server/serverpod_offline_sync_server.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

/// Matches a [CircleException] carrying [failure].
Matcher refusedWith(CircleFailure failure) => throwsA(
  isA<CircleException>().having((e) => e.failure, 'failure', failure),
);

/// [length] bytes that differ for each [seed].
Uint8List bytesOf(int seed, [int length = 2048]) =>
    Uint8List.fromList(List.generate(length, (i) => (i * 31 + seed) % 256));

String hashOf(Uint8List bytes) => crypto.sha256.convert(bytes).toString();

void main() {
  withServerpod(
    'Given the media endpoint,',
    // The generated test tools build a plain Serverpod; the circle endpoint
    // needs the sync engine wired in the way the generated class does it.
    databaseInterceptor: offlineSyncDatabaseInterceptor,
    (sessionBuilder, endpoints) {
      final session = sessionBuilder.build();
      session.serverpod.initializeOfflineSync(syncTables: syncTables);

      /// A session builder signed in as a new user.
      TestSessionBuilder user() => sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          const Uuid().v7obj().uuid,
          {},
        ),
      );

      /// A new circle; returns its space and its guardian.
      Future<(UuidValue, TestSessionBuilder)> circle() async {
        final guardian = user();
        final info = await endpoints.circle.createCircle(
          guardian,
          'Ada',
          'Mum',
        );
        return (info.spaceUuid, guardian);
      }

      /// A new member of [space] with [role].
      Future<TestSessionBuilder> member(
        UuidValue space,
        TestSessionBuilder guardian,
        CircleRole role,
      ) async {
        final who = user();
        final code = await endpoints.circle.createInvite(guardian, space, role);
        await endpoints.circle.acceptInvite(who, code, role.name);
        return who;
      }

      /// Does what the client's uploader does with a ticket in local
      /// development: leaves [bytes] at [path], not yet verified.
      Future<void> upload(String path, Uint8List bytes) =>
          (session.serverpod.storage[mediaStorageId]! as DatabaseCloudStorage)
              .storeUnverifiedFile(
                session: session,
                path: path,
                byteData: ByteData.sublistView(bytes),
              );

      Future<MediaObject?> record(UuidValue space, String sha256) =>
          findMedia(session, space, sha256);

      test('when nobody is signed in then every method is refused.', () async {
        final space = const Uuid().v7obj();
        final hash = hashOf(bytesOf(1));
        final unauthenticated = throwsA(
          isA<ServerpodUnauthenticatedException>(),
        );
        await expectLater(
          endpoints.media.requestUpload(
            sessionBuilder,
            space,
            hash,
            MediaKind.image,
            10,
          ),
          unauthenticated,
        );
        await expectLater(
          endpoints.media.confirmUpload(sessionBuilder, space, hash),
          unauthenticated,
        );
        await expectLater(
          endpoints.media.downloadUrls(sessionBuilder, space, [hash]),
          unauthenticated,
        );
      });

      test('when a guardian uploads a photo then it is filed under the '
          'circle and its hash, and only handed out once confirmed.', () async {
        final (space, guardian) = await circle();
        final bytes = bytesOf(2);
        final hash = hashOf(bytes);

        final ticket = await endpoints.media.requestUpload(
          guardian,
          space,
          hash,
          MediaKind.image,
          bytes.length,
        );

        expect(ticket.path, 'media/${space.uuid}/$hash');
        expect(ticket.uploadDescription, isNotNull);
        expect((await record(space, hash))!.verifiedAt, isNull);
        // Nothing uploaded yet: nothing to confirm, nothing to download.
        expect(
          await endpoints.media.confirmUpload(guardian, space, hash),
          isFalse,
        );
        expect(
          await endpoints.media.downloadUrls(guardian, space, [hash]),
          isEmpty,
        );

        await upload(ticket.path, bytes);
        // Uploaded but unconfirmed is still not handed out.
        expect(
          await endpoints.media.downloadUrls(guardian, space, [hash]),
          isEmpty,
        );

        expect(
          await endpoints.media.confirmUpload(guardian, space, hash),
          isTrue,
        );
        final stored = (await record(space, hash))!;
        expect(stored.verifiedAt, isNotNull);
        expect(stored.kind, MediaKind.image);
        expect(stored.bytes, bytes.length);
        final urls = await endpoints.media.downloadUrls(guardian, space, [
          hash,
          hashOf(bytesOf(99)),
          'not a hash',
        ]);
        expect(urls.keys, [hash]);
        expect(Uri.parse(urls[hash]!).hasScheme, isTrue);
        // Confirming again is harmless.
        expect(
          await endpoints.media.confirmUpload(guardian, space, hash),
          isTrue,
        );
      });

      test('when the same bytes are offered again then there is nothing to '
          'upload and only one file is kept.', () async {
        final (space, guardian) = await circle();
        final teacher = await member(space, guardian, CircleRole.teacher);
        final bytes = bytesOf(3);
        final hash = hashOf(bytes);
        final first = await endpoints.media.requestUpload(
          guardian,
          space,
          hash,
          MediaKind.image,
          bytes.length,
        );
        await upload(first.path, bytes);
        await endpoints.media.confirmUpload(guardian, space, hash);

        final again = await endpoints.media.requestUpload(
          guardian,
          space,
          hash,
          MediaKind.image,
          bytes.length,
        );
        final byTeacher = await endpoints.media.requestUpload(
          teacher,
          space,
          hash,
          MediaKind.image,
          bytes.length,
        );

        expect(again.uploadDescription, isNull);
        expect(again.path, first.path);
        expect(byTeacher.uploadDescription, isNull);
        expect(
          await MediaObject.db.count(
            session,
            where: (t) => t.circleSpace.equals(space),
          ),
          1,
        );
      });

      test('when an upload arrived but was never confirmed then asking '
          'again settles it instead of uploading twice.', () async {
        final (space, guardian) = await circle();
        final bytes = bytesOf(4);
        final hash = hashOf(bytes);
        final first = await endpoints.media.requestUpload(
          guardian,
          space,
          hash,
          MediaKind.audio,
          bytes.length,
        );
        await upload(first.path, bytes);

        final again = await endpoints.media.requestUpload(
          guardian,
          space,
          hash,
          MediaKind.audio,
          bytes.length,
        );

        expect(again.uploadDescription, isNull);
        expect((await record(space, hash))!.verifiedAt, isNotNull);
      });

      test('when the uploaded bytes do not match the hash then the file is '
          'refused and removed, and the right bytes can follow.', () async {
        final (space, guardian) = await circle();
        final bytes = bytesOf(5);
        final hash = hashOf(bytes);
        final ticket = await endpoints.media.requestUpload(
          guardian,
          space,
          hash,
          MediaKind.image,
          bytes.length,
        );
        await upload(ticket.path, bytesOf(6));

        expect(
          await endpoints.media.confirmUpload(guardian, space, hash),
          isFalse,
        );
        expect((await record(space, hash))!.verifiedAt, isNull);
        expect(
          await endpoints.media.downloadUrls(guardian, space, [hash]),
          isEmpty,
        );
        expect(
          await session.storage.fileExists(
            storageId: mediaStorageId,
            path: ticket.path,
          ),
          isFalse,
        );

        final retry = await endpoints.media.requestUpload(
          guardian,
          space,
          hash,
          MediaKind.image,
          bytes.length,
        );
        expect(retry.uploadDescription, isNotNull);
        await upload(retry.path, bytes);
        expect(
          await endpoints.media.confirmUpload(guardian, space, hash),
          isTrue,
        );
      });

      test('when a file is over its cap then the request is refused: images '
          '400 KB, audio 600 KB, and never empty.', () async {
        final (space, guardian) = await circle();
        final hash = hashOf(bytesOf(7));
        Future<UploadTicket> ask(MediaKind kind, int bytes) =>
            endpoints.media.requestUpload(guardian, space, hash, kind, bytes);

        await expectLater(
          ask(MediaKind.image, 400 * 1024 + 1),
          refusedWith(CircleFailure.notAllowed),
        );
        await expectLater(
          ask(MediaKind.audio, 600 * 1024 + 1),
          refusedWith(CircleFailure.notAllowed),
        );
        await expectLater(
          ask(MediaKind.image, 0),
          refusedWith(CircleFailure.notAllowed),
        );
        await expectLater(
          ask(MediaKind.image, -1),
          refusedWith(CircleFailure.notAllowed),
        );
        expect(await record(space, hash), isNull);

        expect(
          (await ask(MediaKind.image, 400 * 1024)).uploadDescription,
          isNotNull,
        );
        // 500 KB is too much for a picture but fine for a voice clip.
        expect(
          (await ask(MediaKind.audio, 500 * 1024)).uploadDescription,
          isNotNull,
        );
      });

      test('when more bytes arrive than the cap allows then confirming '
          'refuses them whatever size was declared.', () async {
        final (space, guardian) = await circle();
        final bytes = bytesOf(8, 400 * 1024 + 1);
        final hash = hashOf(bytes);
        final ticket = await endpoints.media.requestUpload(
          guardian,
          space,
          hash,
          MediaKind.image,
          1000,
        );
        await upload(ticket.path, bytes);

        expect(
          await endpoints.media.confirmUpload(guardian, space, hash),
          isFalse,
        );
        expect((await record(space, hash))!.verifiedAt, isNull);
      });

      test('when the hash is not a lowercase SHA-256 then nothing is '
          'recorded.', () async {
        final (space, guardian) = await circle();
        final good = hashOf(bytesOf(9));
        for (final bad in [
          good.toUpperCase(),
          good.substring(1),
          '${good}0',
          '../${good.substring(3)}',
          '',
        ]) {
          await expectLater(
            endpoints.media.requestUpload(
              guardian,
              space,
              bad,
              MediaKind.image,
              10,
            ),
            refusedWith(CircleFailure.notAllowed),
            reason: bad,
          );
          expect(
            await endpoints.media.confirmUpload(guardian, space, bad),
            isFalse,
          );
        }
        expect(
          await MediaObject.db.count(
            session,
            where: (t) => t.circleSpace.equals(space),
          ),
          0,
        );
      });

      test('when a therapist or teacher uploads then it is allowed, and a '
          'read-only partner may download but not upload.', () async {
        final (space, guardian) = await circle();
        final therapist = await member(space, guardian, CircleRole.therapist);
        final teacher = await member(space, guardian, CircleRole.teacher);
        final partner = await member(space, guardian, CircleRole.partner);
        final bytes = bytesOf(10);
        final hash = hashOf(bytes);

        final ticket = await endpoints.media.requestUpload(
          therapist,
          space,
          hash,
          MediaKind.audio,
          bytes.length,
        );
        await upload(ticket.path, bytes);
        expect(
          await endpoints.media.confirmUpload(teacher, space, hash),
          isTrue,
        );

        await expectLater(
          endpoints.media.requestUpload(
            partner,
            space,
            hashOf(bytesOf(11)),
            MediaKind.image,
            10,
          ),
          refusedWith(CircleFailure.notAllowed),
        );
        await expectLater(
          endpoints.media.confirmUpload(partner, space, hash),
          refusedWith(CircleFailure.notAllowed),
        );
        expect(
          (await endpoints.media.downloadUrls(partner, space, [hash])).keys,
          [hash],
        );
      });

      test('when someone outside the circle asks then every method is '
          'refused, even for a hash the circle holds.', () async {
        final (space, guardian) = await circle();
        final stranger = user();
        final bytes = bytesOf(12);
        final hash = hashOf(bytes);
        final ticket = await endpoints.media.requestUpload(
          guardian,
          space,
          hash,
          MediaKind.image,
          bytes.length,
        );
        await upload(ticket.path, bytes);
        await endpoints.media.confirmUpload(guardian, space, hash);

        await expectLater(
          endpoints.media.requestUpload(
            stranger,
            space,
            hash,
            MediaKind.image,
            bytes.length,
          ),
          refusedWith(CircleFailure.notAMember),
        );
        await expectLater(
          endpoints.media.confirmUpload(stranger, space, hash),
          refusedWith(CircleFailure.notAMember),
        );
        await expectLater(
          endpoints.media.downloadUrls(stranger, space, [hash]),
          refusedWith(CircleFailure.notAMember),
        );
      });

      test('when another circle asks for the same hash then it learns '
          'nothing: no link, and its own upload is still wanted.', () async {
        final (space, guardian) = await circle();
        final (otherSpace, otherGuardian) = await circle();
        final bytes = bytesOf(13);
        final hash = hashOf(bytes);
        final ticket = await endpoints.media.requestUpload(
          guardian,
          space,
          hash,
          MediaKind.image,
          bytes.length,
        );
        await upload(ticket.path, bytes);
        await endpoints.media.confirmUpload(guardian, space, hash);

        expect(
          await endpoints.media.downloadUrls(otherGuardian, otherSpace, [hash]),
          isEmpty,
        );
        final theirs = await endpoints.media.requestUpload(
          otherGuardian,
          otherSpace,
          hash,
          MediaKind.image,
          bytes.length,
        );
        expect(theirs.uploadDescription, isNotNull);
        expect(theirs.path, isNot(ticket.path));
        expect(theirs.path, contains(otherSpace.uuid));
        // Confirming in the other circle does not borrow the first's bytes.
        expect(
          await endpoints.media.confirmUpload(otherGuardian, otherSpace, hash),
          isFalse,
        );
      });

      test('when the server reads a verified file for its own use then it '
          'gets the bytes, and nothing for an unverified one.', () async {
        final (space, guardian) = await circle();
        final bytes = bytesOf(14);
        final hash = hashOf(bytes);
        final ticket = await endpoints.media.requestUpload(
          guardian,
          space,
          hash,
          MediaKind.image,
          bytes.length,
        );
        await upload(ticket.path, bytes);

        expect(await readVerifiedMedia(session, space, hash), isNull);
        await endpoints.media.confirmUpload(guardian, space, hash);

        final read = await readVerifiedMedia(session, space, hash);
        expect(Uint8List.sublistView(read!), bytes);
        expect(
          await readVerifiedMedia(session, const Uuid().v7obj(), hash),
          isNull,
        );
      });
    },
  );
}
