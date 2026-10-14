/// Endpoint tests for the circle's voice: who may read and change it, the
/// limits it is kept within, and the view-only page speaking with it.
library;

import 'dart:convert';

import 'package:chorus_server/src/generated/protocol.dart';
import 'package:chorus_server/src/sharing/sharing_routes.dart';
import 'package:chorus_server/src/sharing/view_only_page.dart';
import 'package:chorus_server/src/voice/circle_voices.dart';
import 'package:serverpod_offline_sync_server/serverpod_offline_sync_server.dart';
import 'package:test/test.dart';

import 'test_circles.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Given the voice endpoint,',
    databaseInterceptor: offlineSyncDatabaseInterceptor,
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      final circles = Circles(sessionBuilder, endpoints);

      test('a circle nobody has chosen for speaks with the defaults', () async {
        final circle = await circles.create();
        final voice = await endpoints.voice.getVoice(
          circle.guardian.session,
          circle.space,
        );
        expect(voice.voiceName, isNull);
        expect(voice.rate, defaultVoiceRate);
        expect(voice.pitch, defaultVoicePitch);
        expect(voice.changedAt, isNull);
      });

      test('a guardian chooses it and every member reads it', () async {
        final circle = await circles.create();
        final partner = await circles.member(circle, CircleRole.partner);
        await endpoints.voice.setVoice(
          circle.guardian.session,
          circle.space,
          'Samantha',
          1.2,
          1.25,
        );
        final read = await endpoints.voice.getVoice(
          partner.session,
          circle.space,
        );
        expect(read.voiceName, 'Samantha');
        expect(read.rate, 1.2);
        expect(read.pitch, 1.25);
        expect(read.changedAt, isNotNull);
      });

      test('a second choice replaces the first, one row per circle', () async {
        final circle = await circles.create();
        final therapist = await circles.member(circle, CircleRole.therapist);
        await endpoints.voice.setVoice(
          circle.guardian.session,
          circle.space,
          'Samantha',
          1.0,
          1.0,
        );
        final second = await endpoints.voice.setVoice(
          therapist.session,
          circle.space,
          null,
          0.7,
          0.8,
        );
        expect(second.voiceName, isNull);
        final rows = await CircleVoice.db.find(
          circles.session,
          where: (t) => t.circleSpace.equals(circle.space),
        );
        expect(rows, hasLength(1));
        expect(rows.single.rate, 0.7);
        expect(rows.single.changedBy, therapist.id);
      });

      test('speed and pitch are kept within what engines accept', () async {
        final circle = await circles.create();
        final saved = await endpoints.voice.setVoice(
          circle.guardian.session,
          circle.space,
          '   ',
          9,
          0.01,
        );
        expect(saved.voiceName, isNull);
        expect(saved.rate, maxVoiceRate);
        expect(saved.pitch, minVoicePitch);
      });

      test('a read-only partner may not change it', () async {
        final circle = await circles.create();
        final partner = await circles.member(circle, CircleRole.partner);
        await expectLater(
          endpoints.voice.setVoice(
            partner.session,
            circle.space,
            null,
            1,
            1,
          ),
          refusedWith(CircleFailure.notAllowed),
        );
      });

      test(
        'someone outside the circle can neither read nor change it',
        () async {
          final circle = await circles.create();
          final stranger = circles.user();
          await expectLater(
            endpoints.voice.getVoice(stranger.session, circle.space),
            refusedWith(CircleFailure.notAMember),
          );
          await expectLater(
            endpoints.voice.setVoice(
              stranger.session,
              circle.space,
              null,
              1,
              1,
            ),
            refusedWith(CircleFailure.notAMember),
          );
        },
      );

      test(
        'the view-only page speaks with the circle\'s speed and pitch',
        () async {
          final circle = await circles.create();
          final board = jsonEncode({
            'childName': 'Maya',
            'name': 'Home',
            'rows': 1,
            'cols': 1,
            'tiles': [
              {'row': 0, 'col': 0, 'label': 'go', 'colorKey': 'verb'},
            ],
          });
          final link = await endpoints.sharing.publishViewOnly(
            circle.guardian.session,
            circle.space,
            board,
          );
          Future<String> page() async => (await viewOnlyResponse(
            circles.session,
            link.token,
          )).readAsString();
          expect(await page(), contains('{rate: 0.9, pitch: 1.0}'));
          await endpoints.voice.setVoice(
            circle.guardian.session,
            circle.space,
            'Samantha',
            1.2,
            0.8,
          );
          final html = await page();
          expect(html, contains('{rate: 1.2, pitch: 0.8}'));
        },
      );

      test('nobody signed out reaches it', () async {
        final circle = await circles.create();
        await expectLater(
          endpoints.voice.getVoice(sessionBuilder, circle.space),
          unauthenticated,
        );
      });
    },
  );

  group('The view-only page', () {
    test('speaks at the speed and pitch it is given', () {
      expect(
        viewOnlyVoiceScript(rate: 1.2, pitch: 0.8),
        'window.chorusVoice = {rate: 1.2, pitch: 0.8};\n',
      );
    });

    test('keeps the numbers within limits', () {
      expect(
        viewOnlyVoiceScript(rate: double.nan, pitch: 7),
        'window.chorusVoice = {rate: 1.0, pitch: 2.0};\n',
      );
    });
  });
}
