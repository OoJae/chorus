/// Endpoint tests for picture scenes: every member lists them, only editing
/// roles make and change them, spots must lie on the photo, and nothing
/// leaks between circles.
library;

import 'package:chorus_server/src/generated/protocol.dart';
import 'package:chorus_server/src/scenes/scene_endpoint.dart';
import 'package:chorus_shared/chorus_shared.dart' show maxSpotsPerScene;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_offline_sync_server/serverpod_offline_sync_server.dart';
import 'package:test/test.dart';

import 'test_circles.dart';
import 'test_tools/serverpod_test_tools.dart';

final String photo = 'a' * 64;

SceneSpotInfo spot(
  String label, {
  double x = 0.1,
  double y = 0.1,
  double width = 0.3,
  double height = 0.3,
  String? speech,
}) => SceneSpotInfo(
  x: x,
  y: y,
  width: width,
  height: height,
  label: label,
  speech: speech,
);

void main() {
  withServerpod(
    'Given the scene endpoint,',
    databaseInterceptor: offlineSyncDatabaseInterceptor,
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      final circles = Circles(sessionBuilder, endpoints);
      final scenes = endpoints.scene;

      test('when nobody is signed in then every method is refused.', () async {
        final space = const Uuid().v7obj();
        await expectLater(scenes.list(sessionBuilder, space), unauthenticated);
        await expectLater(
          scenes.create(sessionBuilder, space, 'Park', photo),
          unauthenticated,
        );
        await expectLater(
          scenes.rename(sessionBuilder, space, 1, 'Park'),
          unauthenticated,
        );
        await expectLater(
          scenes.archive(sessionBuilder, space, 1),
          unauthenticated,
        );
        await expectLater(
          scenes.setSpots(sessionBuilder, space, 1, []),
          unauthenticated,
        );
      });

      test('when a guardian makes a scene and draws its spots then every '
          'member lists it, spots in the order drawn.', () async {
        final circle = await circles.create();
        final mum = circle.guardian.session;
        final made = await scenes.create(mum, circle.space, '  At  the park ', photo);
        expect(made.name, 'At the park');
        expect(made.imageHash, photo);
        expect(made.spots, isEmpty);

        final drawn = await scenes.setSpots(mum, circle.space, made.id, [
          spot('Grandma', speech: 'Grandma Rose'),
          spot('dog', x: 0.6, y: 0.5, width: 0.2, height: 0.4),
        ]);
        expect(drawn.spots.map((s) => s.label), ['Grandma', 'dog']);
        expect(drawn.spots.first.speech, 'Grandma Rose');

        final partner = await circles.member(circle, CircleRole.partner);
        final listed = await scenes.list(partner.session, circle.space);
        expect(listed, hasLength(1));
        expect(listed.single.id, made.id);
        expect(listed.single.spots.map((s) => s.label), ['Grandma', 'dog']);
        expect(listed.single.spots[1].x, 0.6);
        expect(listed.single.spots[1].height, 0.4);
      });

      test('when spots are set again then they replace the old ones, and an '
          'empty list clears them.', () async {
        final circle = await circles.create();
        final mum = circle.guardian.session;
        final made = await scenes.create(mum, circle.space, 'Kitchen', photo);
        await scenes.setSpots(mum, circle.space, made.id, [
          spot('cup'),
          spot('fridge'),
        ]);
        await scenes.setSpots(mum, circle.space, made.id, [spot('table')]);
        expect(
          (await scenes.list(mum, circle.space)).single.spots.map(
            (s) => s.label,
          ),
          ['table'],
        );
        await scenes.setSpots(mum, circle.space, made.id, []);
        expect((await scenes.list(mum, circle.space)).single.spots, isEmpty);
      });

      test('when a scene is renamed or archived then the list follows, and '
          'an archived scene can no longer be changed.', () async {
        final circle = await circles.create();
        final mum = circle.guardian.session;
        final made = await scenes.create(mum, circle.space, 'Kitchen', photo);
        final renamed = await scenes.rename(
          mum,
          circle.space,
          made.id,
          'Our kitchen',
        );
        expect(renamed.name, 'Our kitchen');
        expect((await scenes.list(mum, circle.space)).single.name, 'Our kitchen');

        expect(await scenes.archive(mum, circle.space, made.id), isTrue);
        expect(await scenes.archive(mum, circle.space, made.id), isFalse);
        expect(await scenes.list(mum, circle.space), isEmpty);
        await expectLater(
          scenes.rename(mum, circle.space, made.id, 'Again'),
          refusedWith(CircleFailure.notAllowed),
        );
        await expectLater(
          scenes.setSpots(mum, circle.space, made.id, [spot('cup')]),
          refusedWith(CircleFailure.notAllowed),
        );
      });

      test('when a therapist or teacher edits then it is allowed; a partner '
          'and a stranger are refused.', () async {
        final circle = await circles.create();
        for (final role in [CircleRole.therapist, CircleRole.teacher]) {
          final member = await circles.member(circle, role);
          final made = await scenes.create(
            member.session,
            circle.space,
            'By ${role.name}',
            photo,
          );
          await scenes.setSpots(member.session, circle.space, made.id, [
            spot('ball'),
          ]);
        }
        final made = (await scenes.list(
          circle.guardian.session,
          circle.space,
        )).first;
        final partner = await circles.member(circle, CircleRole.partner);
        await expectLater(
          scenes.create(partner.session, circle.space, 'Mine', photo),
          refusedWith(CircleFailure.notAllowed),
        );
        await expectLater(
          scenes.rename(partner.session, circle.space, made.id, 'Mine'),
          refusedWith(CircleFailure.notAllowed),
        );
        await expectLater(
          scenes.archive(partner.session, circle.space, made.id),
          refusedWith(CircleFailure.notAllowed),
        );
        await expectLater(
          scenes.setSpots(partner.session, circle.space, made.id, []),
          refusedWith(CircleFailure.notAllowed),
        );
        final stranger = circles.user();
        await expectLater(
          scenes.list(stranger.session, circle.space),
          refusedWith(CircleFailure.notAMember),
        );
        await expectLater(
          scenes.create(stranger.session, circle.space, 'Mine', photo),
          refusedWith(CircleFailure.notAMember),
        );
      });

      test('when a scene of another circle is named then it is refused and '
          'left alone.', () async {
        final ours = await circles.create();
        final theirs = await circles.create(child: 'Sam');
        final made = await scenes.create(
          theirs.guardian.session,
          theirs.space,
          'Theirs',
          photo,
        );
        final mum = ours.guardian.session;
        await expectLater(
          scenes.rename(mum, ours.space, made.id, 'Ours'),
          refusedWith(CircleFailure.notAllowed),
        );
        await expectLater(
          scenes.setSpots(mum, ours.space, made.id, [spot('x')]),
          refusedWith(CircleFailure.notAllowed),
        );
        await expectLater(
          scenes.archive(mum, ours.space, made.id),
          refusedWith(CircleFailure.notAllowed),
        );
        expect(await scenes.list(mum, ours.space), isEmpty);
        final still = await scenes.list(theirs.guardian.session, theirs.space);
        expect(still.single.name, 'Theirs');
      });

      test('when a name, photo or spot breaks the rules then nothing is '
          'kept.', () async {
        final circle = await circles.create();
        final mum = circle.guardian.session;
        await expectLater(
          scenes.create(mum, circle.space, ' ', photo),
          refusedWith(CircleFailure.notAllowed),
        );
        await expectLater(
          scenes.create(mum, circle.space, 'Park', 'not-a-hash'),
          refusedWith(CircleFailure.notAllowed),
        );
        final made = await scenes.create(mum, circle.space, 'Park', photo);
        await scenes.setSpots(mum, circle.space, made.id, [spot('swing')]);
        for (final bad in [
          [spot('off', x: 0.9, width: 0.3)],
          [spot('tiny', width: 0.001)],
          [spot('neg', x: -0.2)],
          [spot(' ')],
          [spot('long' * 10)],
          [for (var i = 0; i <= maxSpotsPerScene; i++) spot('w$i')],
        ]) {
          await expectLater(
            scenes.setSpots(mum, circle.space, made.id, bad),
            refusedWith(CircleFailure.notAllowed),
            reason: bad.first.label,
          );
        }
        expect(
          (await scenes.list(mum, circle.space)).single.spots.single.label,
          'swing',
        );
        expect(maxScenesPerCircle, 50);
      });
    },
  );
}
