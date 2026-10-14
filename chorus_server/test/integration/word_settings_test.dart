/// Endpoint tests for hidden words and the second language: members read,
/// editing roles write, a partner and a stranger are refused, and each
/// circle sees only its own rows.
library;

import 'package:chorus_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_offline_sync_server/serverpod_offline_sync_server.dart';
import 'package:test/test.dart';

import 'test_circles.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Given the hidden words and home language endpoints,',
    databaseInterceptor: offlineSyncDatabaseInterceptor,
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      final circles = Circles(sessionBuilder, endpoints);
      final hidden = endpoints.hiddenWords;
      final language = endpoints.homeLanguage;

      test('when nobody is signed in then every method is refused.', () async {
        final space = const Uuid().v7obj();
        final tile = const Uuid().v7obj();
        await expectLater(hidden.list(sessionBuilder, space), unauthenticated);
        await expectLater(
          hidden.setHidden(sessionBuilder, space, tile, true),
          unauthenticated,
        );
        await expectLater(
          language.getLanguage(sessionBuilder, space),
          unauthenticated,
        );
        await expectLater(
          language.listTranslations(sessionBuilder, space, 'yo'),
          unauthenticated,
        );
      });

      test(
        'when an editor hides a word then every member lists it, and showing '
        'it again takes it off the list.',
        () async {
          final circle = await circles.create();
          final teacher = await circles.member(circle, CircleRole.teacher);
          final partner = await circles.member(circle, CircleRole.partner);
          final tiles = await circles.addTiles(circle, ['more', 'go']);
          final more = tiles.first.id!;

          await hidden.setHidden(teacher.session, circle.space, more, true);
          // Twice is the same as once.
          await hidden.setHidden(teacher.session, circle.space, more, true);
          expect(await hidden.list(partner.session, circle.space), [more]);
          expect(await hidden.list(circle.guardian.session, circle.space), [
            more,
          ]);

          await hidden.setHidden(
            circle.guardian.session,
            circle.space,
            more,
            false,
          );
          expect(await hidden.list(partner.session, circle.space), isEmpty);
        },
      );

      test(
        'when a partner or a stranger hides a word then it is refused.',
        () async {
          final circle = await circles.create();
          final partner = await circles.member(circle, CircleRole.partner);
          final stranger = circles.user();
          final tile = const Uuid().v7obj();
          await expectLater(
            hidden.setHidden(partner.session, circle.space, tile, true),
            refusedWith(CircleFailure.notAllowed),
          );
          await expectLater(
            hidden.setHidden(stranger.session, circle.space, tile, true),
            refusedWith(CircleFailure.notAMember),
          );
          await expectLater(
            hidden.list(stranger.session, circle.space),
            refusedWith(CircleFailure.notAMember),
          );
          expect(await hidden.list(partner.session, circle.space), isEmpty);
        },
      );

      test(
        'when two circles hide words then each lists only its own.',
        () async {
          final first = await circles.create();
          final second = await circles.create(child: 'Sam');
          final a = const Uuid().v7obj();
          final b = const Uuid().v7obj();
          await hidden.setHidden(first.guardian.session, first.space, a, true);
          await hidden.setHidden(
            second.guardian.session,
            second.space,
            b,
            true,
          );
          expect(await hidden.list(first.guardian.session, first.space), [a]);
          expect(await hidden.list(second.guardian.session, second.space), [b]);
        },
      );

      test(
        'when an editor sets a second language then members read it, and '
        'null clears it.',
        () async {
          final circle = await circles.create();
          final therapist = await circles.member(circle, CircleRole.therapist);
          final partner = await circles.member(circle, CircleRole.partner);
          expect(
            await language.getLanguage(partner.session, circle.space),
            isNull,
          );

          await language.setLanguage(
            therapist.session,
            circle.space,
            SecondLanguage(code: 'yo', name: ' Yoruba '),
          );
          final got = await language.getLanguage(partner.session, circle.space);
          expect(got?.code, 'yo');
          expect(got?.name, 'Yoruba');

          await language.setLanguage(
            circle.guardian.session,
            circle.space,
            SecondLanguage(code: 'es', name: 'Spanish'),
          );
          expect(
            (await language.getLanguage(partner.session, circle.space))?.code,
            'es',
          );

          await language.setLanguage(therapist.session, circle.space, null);
          expect(
            await language.getLanguage(partner.session, circle.space),
            isNull,
          );
        },
      );

      test(
        'when a partner sets a language or a word then it is refused.',
        () async {
          final circle = await circles.create();
          final partner = await circles.member(circle, CircleRole.partner);
          await expectLater(
            language.setLanguage(
              partner.session,
              circle.space,
              SecondLanguage(code: 'yo', name: 'Yoruba'),
            ),
            refusedWith(CircleFailure.notAllowed),
          );
          await expectLater(
            language.setTranslation(
              partner.session,
              circle.space,
              WordTranslation(
                tileId: const Uuid().v7obj(),
                languageCode: 'yo',
                label: 'omi',
              ),
            ),
            refusedWith(CircleFailure.notAllowed),
          );
        },
      );

      test('when a language is blank then it is refused.', () async {
        final circle = await circles.create();
        await expectLater(
          language.setLanguage(
            circle.guardian.session,
            circle.space,
            SecondLanguage(code: ' ', name: 'Yoruba'),
          ),
          throwsA(isA<WordSettingsException>()),
        );
      });

      test(
        'when an editor sets a word in a language then it is listed for that '
        'language only, a new label replaces it and an empty one removes it.',
        () async {
          final circle = await circles.create();
          final teacher = await circles.member(circle, CircleRole.teacher);
          final partner = await circles.member(circle, CircleRole.partner);
          final tiles = await circles.addTiles(circle, ['water']);
          final water = tiles.single.id!;

          await language.setTranslation(
            teacher.session,
            circle.space,
            WordTranslation(
              tileId: water,
              languageCode: 'yo',
              label: 'omi',
              speech: 'omi',
            ),
          );
          await language.setTranslation(
            teacher.session,
            circle.space,
            WordTranslation(tileId: water, languageCode: 'es', label: 'agua'),
          );
          var yo = await language.listTranslations(
            partner.session,
            circle.space,
            'yo',
          );
          expect(yo.single.label, 'omi');
          expect(yo.single.speech, 'omi');
          expect(yo.single.tileId, water);

          await language.setTranslation(
            circle.guardian.session,
            circle.space,
            WordTranslation(
              tileId: water,
              languageCode: 'yo',
              label: 'omi tutu',
            ),
          );
          yo = await language.listTranslations(
            partner.session,
            circle.space,
            'yo',
          );
          expect(yo.single.label, 'omi tutu');
          expect(yo.single.speech, isNull);

          await language.setTranslation(
            circle.guardian.session,
            circle.space,
            WordTranslation(tileId: water, languageCode: 'yo', label: ''),
          );
          expect(
            await language.listTranslations(
              partner.session,
              circle.space,
              'yo',
            ),
            isEmpty,
          );
          final es = await language.listTranslations(
            partner.session,
            circle.space,
            'es',
          );
          expect(es.single.label, 'agua');
        },
      );

      test('when a word is too long then it is refused.', () async {
        final circle = await circles.create();
        await expectLater(
          language.setTranslation(
            circle.guardian.session,
            circle.space,
            WordTranslation(
              tileId: const Uuid().v7obj(),
              languageCode: 'yo',
              label: 'a' * 81,
            ),
          ),
          throwsA(isA<WordSettingsException>()),
        );
      });
    },
  );
}
