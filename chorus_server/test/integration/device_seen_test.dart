/// Endpoint tests for "Who is up to date": each device reports its last
/// sync, any member reads the circle's list, and nobody else does either.
library;

import 'package:chorus_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_offline_sync_server/serverpod_offline_sync_server.dart';
import 'package:test/test.dart';

import 'test_circles.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Given the device list endpoint,',
    databaseInterceptor: offlineSyncDatabaseInterceptor,
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      final circles = Circles(sessionBuilder, endpoints);
      final seen = endpoints.deviceSeen;

      test('when nobody is signed in then both methods are refused.', () async {
        final space = const Uuid().v7obj();
        await expectLater(seen.devices(sessionBuilder, space), unauthenticated);
        await expectLater(
          seen.heartbeat(
            sessionBuilder,
            space,
            'device-1',
            'Web browser',
            DateTime.now(),
          ),
          unauthenticated,
        );
      });

      test('when someone outside the circle reports or asks then they are '
          'refused and nothing is kept.', () async {
        final circle = await circles.create();
        final stranger = circles.user();
        await expectLater(
          seen.heartbeat(
            stranger.session,
            circle.space,
            'device-1',
            'Web browser',
            DateTime.now(),
          ),
          refusedWith(CircleFailure.notAMember),
        );
        await expectLater(
          seen.devices(stranger.session, circle.space),
          refusedWith(CircleFailure.notAMember),
        );
        expect(
          await seen.devices(circle.guardian.session, circle.space),
          isEmpty,
        );
      });

      test('when members report their devices then every member, a read-only '
          'partner included, sees each device with its name and times, most '
          'recently synced first.', () async {
        final circle = await circles.create();
        final teacher = await circles.member(circle, CircleRole.teacher);
        final partner = await circles.member(circle, CircleRole.partner);
        final earlier = DateTime.now().toUtc().subtract(
          const Duration(days: 3),
        );
        await seen.heartbeat(
          circle.guardian.session,
          circle.space,
          'mum-phone',
          'Android phone',
          DateTime.now(),
        );
        await seen.heartbeat(
          teacher.session,
          circle.space,
          'teacher-web',
          'Web browser',
          earlier,
        );
        await seen.heartbeat(
          partner.session,
          circle.space,
          'gran-tablet',
          'Android tablet',
          earlier.subtract(const Duration(hours: 1)),
        );

        for (final who in [circle.guardian, teacher, partner]) {
          final list = await seen.devices(who.session, circle.space);
          expect(list.map((d) => d.deviceId), [
            'mum-phone',
            'teacher-web',
            'gran-tablet',
          ]);
          expect(list.first.userName, 'Mum');
          expect(list.first.deviceLabel, 'Android phone');
          expect(list[1].userName, 'teacher');
          expect(list[1].userId, teacher.id);
          expect(
            list[1].lastSyncAt.difference(earlier).inSeconds.abs(),
            lessThan(2),
          );
        }
      });

      test('when one device reports again then it keeps one row, and a sync '
          'time in the future is taken as now.', () async {
        final circle = await circles.create();
        final old = DateTime.now().toUtc().subtract(const Duration(days: 1));
        await seen.heartbeat(
          circle.guardian.session,
          circle.space,
          'mum-phone',
          'Android phone',
          old,
        );
        await seen.heartbeat(
          circle.guardian.session,
          circle.space,
          'mum-phone',
          'Android phone',
          DateTime.now().toUtc().add(const Duration(days: 2)),
        );
        final list = await seen.devices(circle.guardian.session, circle.space);
        expect(list, hasLength(1));
        expect(
          list.single.lastSyncAt.isAfter(
            DateTime.now().toUtc().add(const Duration(minutes: 1)),
          ),
          isFalse,
        );
        expect(list.single.lastSyncAt.isAfter(old), isTrue);
      });

      test('when a device id is empty or too long then the report is '
          'refused.', () async {
        final circle = await circles.create();
        for (final id in ['', '   ', 'x' * 65]) {
          await expectLater(
            seen.heartbeat(
              circle.guardian.session,
              circle.space,
              id,
              'Web browser',
              DateTime.now(),
            ),
            refusedWith(CircleFailure.notAllowed),
          );
        }
      });
    },
  );
}
