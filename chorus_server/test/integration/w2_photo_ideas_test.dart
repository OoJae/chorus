/// Endpoint tests for several ideas from one photo: across word types, a
/// colour key each, cached for a day, and gentle failure. The model is a
/// fake; no network.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:chorus_server/src/generated/protocol.dart';
import 'package:chorus_server/src/suggest/suggest_service.dart';
import 'package:chorus_server/src/suggest/vision_transport.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'suggest_endpoint_test.dart'
    show FakeTransport, failsWith, pngBytes, said;
import 'test_tools/serverpod_test_tools.dart';

VisionReply ideasReply(List<Map<String, Object?>> ideas) =>
    said(jsonEncode({'ideas': ideas}));

final park = ideasReply([
  {
    'label': 'Swing',
    'speech': 'swing',
    'colorKey': 'noun',
    'properName': false,
  },
  {'label': 'push', 'speech': 'push', 'colorKey': 'verb', 'properName': false},
  {
    'label': 'high',
    'speech': 'high',
    'colorKey': 'descriptor',
    'properName': false,
  },
  {
    'label': 'swing',
    'speech': 'swing',
    'colorKey': 'noun',
    'properName': false,
  },
  {'label': 'go', 'speech': 'go', 'colorKey': 'adverb', 'properName': false},
]);

void main() {
  test('parseIdeas keeps 3 to 6 distinct words with known colour keys', () {
    final ideas = parseIdeas(park.body);
    expect(ideas.map((i) => i.label), ['swing', 'push', 'high', 'go']);
    expect(ideas.map((i) => i.colorKey), [
      'noun',
      'verb',
      'descriptor',
      'noun',
    ]);
  });

  test('parseIdeas refuses fewer than three words', () {
    expect(
      () => parseIdeas(
        ideasReply([
          {
            'label': 'a',
            'speech': 'a',
            'colorKey': 'noun',
            'properName': false,
          },
        ]).body,
      ),
      failsWith(SuggestFailure.unreadable),
    );
  });

  withServerpod('Given ideas from a photo,', (sessionBuilder, endpoints) {
    final session = sessionBuilder.build();
    const hash =
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

    tearDown(() => suggestSettingsOverride = null);

    FakeTransport use(List<Object> replies, {DateTime Function()? now}) {
      final transport = FakeTransport(replies);
      suggestSettingsOverride = SuggestSettings(
        apiKey: 'test-key',
        transport: transport,
        retryDelay: Duration.zero,
        now: now,
      );
      return transport;
    }

    Future<(UuidValue, TestSessionBuilder)> member(CircleRole role) async {
      final id = const Uuid().v7obj();
      final circle = const Uuid().v7obj();
      await Membership.db.insertRow(
        session,
        Membership(
          circleSpace: circle,
          userId: id,
          role: role,
          displayName: 'Sam',
          joinedAt: DateTime.now().toUtc(),
        ),
      );
      return (
        circle,
        sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            id.uuid,
            {},
          ),
        ),
      );
    }

    Future<void> photo(UuidValue space) async {
      final path = 'media/${space.uuid}/$hash';
      await session.storage.storeFile(
        storageId: mediaStorageId,
        path: path,
        byteData: ByteData.sublistView(Uint8List.fromList(pngBytes)),
      );
      await MediaObject.db.insertRow(
        session,
        MediaObject(
          circleSpace: space,
          sha256: hash,
          kind: MediaKind.image,
          path: path,
          bytes: pngBytes.length,
          createdBy: const Uuid().v7obj(),
          verifiedAt: DateTime.now().toUtc(),
        ),
      );
    }

    test(
      'an editor gets ideas, and asking again within a day is cached',
      () async {
        final transport = use([park]);
        final (space, guardian) = await member(CircleRole.guardian);
        await photo(space);
        final first = await endpoints.suggest.ideasFromPhoto(
          guardian,
          space,
          hash,
          'en',
        );
        expect(first.map((i) => i.label), ['swing', 'push', 'high', 'go']);
        final again = await endpoints.suggest.ideasFromPhoto(
          guardian,
          space,
          hash,
          'en',
        );
        expect(again.map((i) => i.label), ['swing', 'push', 'high', 'go']);
        expect(transport.sent, hasLength(1));
        final system = transport.sent.single.body['system'] as String;
        expect(system, contains('between 3 and 6'));
      },
    );

    test('a cached answer older than a day is asked again', () async {
      var now = DateTime.now().toUtc();
      final transport = use([park, park], now: () => now);
      final (space, guardian) = await member(CircleRole.teacher);
      await photo(space);
      await endpoints.suggest.ideasFromPhoto(guardian, space, hash, 'en');
      now = now.add(const Duration(days: 1, minutes: 1));
      await endpoints.suggest.ideasFromPhoto(guardian, space, hash, 'en');
      expect(transport.sent, hasLength(2));
    });

    test('a read-only partner is refused', () async {
      use([park]);
      final (space, partner) = await member(CircleRole.partner);
      await photo(space);
      await expectLater(
        endpoints.suggest.ideasFromPhoto(partner, space, hash, 'en'),
        throwsA(isA<CircleException>()),
      );
    });

    test('a failed call is a SuggestException, never a crash', () async {
      use([StateError('timeout')]);
      final (space, guardian) = await member(CircleRole.guardian);
      await photo(space);
      await expectLater(
        endpoints.suggest.ideasFromPhoto(guardian, space, hash, 'en'),
        failsWith(SuggestFailure.failed),
      );
    });
  });
}
