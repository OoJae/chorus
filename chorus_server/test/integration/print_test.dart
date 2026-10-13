/// Tests for the paper backup: who may publish a board, how long the link
/// lasts, and that the printed page shows the grid and nothing a snapshot
/// could smuggle in.
library;

import 'dart:convert';
import 'dart:io';

import 'package:chorus_server/src/generated/protocol.dart';
import 'package:chorus_server/src/printing/print_page.dart';
import 'package:chorus_server/src/printing/printing_endpoint.dart';
import 'package:chorus_server/src/printing/print_routes.dart';
import 'package:chorus_shared/chorus_shared.dart'
    show colorForKey, placedKey, trayKey, universalCore36;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_offline_sync_server/serverpod_offline_sync_server.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

/// Matches a [CircleException] carrying [failure].
Matcher refusedWith(CircleFailure failure) => throwsA(
  isA<CircleException>().having((e) => e.failure, 'failure', failure),
);

/// The starter board as the client would publish it.
String starterSnapshot({String name = 'Home', String? childName = 'Ada'}) =>
    jsonEncode({
      'childName': ?childName,
      'name': name,
      'rows': 6,
      'cols': 6,
      'tiles': [
        for (final word in universalCore36)
          {
            'row': word.row,
            'col': word.col,
            'label': word.label,
            'colorKey': word.colorKey,
          },
      ],
    });

void main() {
  group('Given a snapshot,', () {
    final saved = DateTime.utc(2026, 10, 13, 9);
    String page(String json) => renderPrintPage(
      PrintBoard.parse(json),
      savedAt: saved,
      expiresAt: saved.add(const Duration(days: 30)),
    );

    test('when it is the starter board then every word is in its cell with '
        'its colour, under the credit line.', () {
      final html = page(starterSnapshot());

      expect(html, contains('<h1>Ada: Home</h1>'));
      expect('<tr>'.allMatches(html), hasLength(6));
      expect('<td'.allMatches(html), hasLength(36));
      expect(html, contains('<td class="c-verb">like</td>'));
      expect(html, contains('<td class="c-negation">not</td>'));
      expect(html, contains('<td class="c-pronoun">I</td>'));
      // First row in board order.
      expect(
        html,
        contains(
          '<tr><td class="c-verb">like</td><td class="c-verb">want</td>',
        ),
      );
      expect(html, contains('Universal Core'));
      expect(html, contains('Center for Literacy and Disability Studies'));
      expect(html, contains('UNC-Chapel Hill'));
      expect(html, contains('CC BY-SA 4.0'));
      expect(html, contains('13 October 2026'));
      expect(html, contains('12 November 2026'));
      expect(html, contains('@media print'));
      expect(html, contains('print-color-adjust:exact'));
      expect(html, isNot(contains('<script')));
    });

    test('when the colours are compared with the app then they are the '
        'same.', () {
      expect(printColours.keys, colorForKey.keys);
      for (final MapEntry(:key, :value) in colorForKey.entries) {
        final rgb = (value & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
        expect(printColours[key], '#$rgb', reason: key);
      }
    });

    test('when text carries markup then it is printed as text.', () {
      const attack = '<script>alert(1)</script>';
      final html = page(
        jsonEncode({
          'childName': '"><img src=x onerror=alert(2)>',
          'name': '</title><script>alert(3)</script>',
          'rows': 1,
          'cols': 3,
          'tiles': [
            {'row': 0, 'col': 0, 'label': attack, 'colorKey': 'verb'},
            {
              'row': 0,
              'col': 1,
              'label': "Tom & 'Jerry'",
              'colorKey': 'verb" onclick="alert(4)',
            },
            {
              'row': 0,
              'col': 2,
              'label': 'x',
              'colorKey': '}body{background:url(//evil.example)',
            },
          ],
        }),
      );

      expect(html, isNot(contains('<script')));
      expect(html, isNot(contains('<img')));
      expect(html, isNot(contains('onclick')));
      expect(html, isNot(contains('evil.example')));
      expect(html, contains('&lt;script&gt;alert(1)&lt;&#47;script&gt;'));
      expect(html, contains('Tom &amp; &#39;Jerry&#39;'));
      expect(html, contains('&quot;&gt;&lt;img src=x onerror=alert(2)&gt;'));
      // A colour key that is not one of ours picks no class at all.
      expect('class="c-verb"'.allMatches(html), hasLength(1));
      expect('<title>'.allMatches(html), hasLength(1));
      expect('</title>'.allMatches(html), hasLength(1));
    });

    test('when tiles give cell keys then placed ones are printed and tray, '
        'contested, archived and out-of-grid ones are not.', () {
      const board = '0198c0de-0000-7000-8000-000000000001';
      const tile = '0198c0de-0000-7000-8000-000000000002';
      final parsed = PrintBoard.parse(
        jsonEncode({
          'board': {'name': 'Snacks', 'rows': 2, 'cols': 2},
          'tiles': [
            {'cellKey': placedKey(board, 1, 0), 'label': 'apple'},
            {'cellKey': placedKey(board, 1, 0), 'label': 'second claim'},
            {'cellKey': trayKey(tile), 'label': 'waiting'},
            {
              'cellKey': '${placedKey(board, 0, 0)}__conflict__$tile',
              'label': 'contested',
            },
            {
              'cellKey': placedKey(board, 0, 1),
              'label': 'gone',
              'archived': true,
            },
            {'cellKey': placedKey(board, 5, 5), 'label': 'outside'},
            {'row': -1, 'col': 0, 'label': 'negative'},
            {'row': 0, 'col': 1, 'label': '   '},
            {'row': 0, 'col': 1},
            'not a tile',
          ],
        }),
      );

      expect(parsed.name, 'Snacks');
      expect(parsed.childName, isNull);
      expect(parsed.cells.keys, [(1, 0)]);
      expect(parsed.cells[(1, 0)]!.label, 'apple');
      final html = renderPrintPage(parsed, savedAt: saved, expiresAt: saved);
      expect('<td class="empty"></td>'.allMatches(html), hasLength(3));
      expect(html, contains('<td>apple</td>'));
    });

    test('when it cannot be laid out then reading it fails.', () {
      for (final bad in [
        'not json',
        '[]',
        '"text"',
        '{}',
        '{"rows":6,"cols":6}',
        '{"rows":0,"cols":6,"tiles":[]}',
        '{"rows":6,"cols":13,"tiles":[]}',
        '{"rows":"6","cols":6,"tiles":[]}',
        '{"rows":6,"cols":6,"tiles":{}}',
      ]) {
        expect(
          () => PrintBoard.parse(bad),
          throwsFormatException,
          reason: bad,
        );
      }
    });

    test('when a label is very long or has line breaks then it is cut and '
        'flattened.', () {
      final parsed = PrintBoard.parse(
        jsonEncode({
          'rows': 1,
          'cols': 2,
          'tiles': [
            {'row': 0, 'col': 0, 'label': 'x' * 500},
            {'row': 0, 'col': 1, 'label': 'two\nlines\u0000'},
          ],
        }),
      );

      expect(parsed.name, 'Board');
      expect(parsed.cells[(0, 0)]!.label, 'x' * 80);
      expect(parsed.cells[(0, 1)]!.label, 'two lines');
    });
  });

  withServerpod(
    'Given the printing endpoint,',
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

      Future<SharedSnapshot> stored(String token) async =>
          (await SharedSnapshot.db.findFirstRow(
            session,
            where: (t) => t.token.equals(token),
          ))!;

      test('when nobody is signed in then publishing is refused.', () async {
        await expectLater(
          endpoints.printing.publishBoard(
            sessionBuilder,
            const Uuid().v7obj(),
            starterSnapshot(),
          ),
          throwsA(isA<ServerpodUnauthenticatedException>()),
        );
      });

      test('when a member publishes a board then the link shows it and '
          'lasts 30 days.', () async {
        final (space, guardian) = await circle();

        final token = await endpoints.printing.publishBoard(
          guardian,
          space,
          starterSnapshot(),
        );

        expect(token, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
        expect(isPrintToken(token), isTrue);
        final snapshot = await stored(token);
        expect(snapshot.circleSpace, space);
        expect(
          snapshot.expiresAt.difference(snapshot.createdAt),
          const Duration(days: 30),
        );

        final response = await printResponse(session, token);
        expect(response.statusCode, 200);
        expect(response.body.bodyType?.mimeType, MimeType.html);
        final html = await response.readAsString();
        expect(html, contains('<h1>Ada: Home</h1>'));
        expect(html, contains('<td class="c-verb">finished</td>'));
        expect(html, contains('CC BY-SA 4.0'));
        expect(
          response.headers['content-security-policy']!.single,
          contains("default-src 'none'"),
        );
        expect(response.headers['cache-control']!.single, contains('no-store'));
      });

      test('when the app asks where a page is then it gets the web '
          "server's public address, and nothing for text that is not a "
          'token.', () async {
        final (space, guardian) = await circle();
        final token = await endpoints.printing.publishBoard(
          guardian,
          space,
          starterSnapshot(),
        );

        final url = Uri.parse(
          await endpoints.printing.pageUrl(guardian, token),
        );
        expect(url.path, '/print/$token');
        expect(url.host, 'localhost');
        await expectLater(
          endpoints.printing.pageUrl(guardian, 'not-a-token'),
          refusedWith(CircleFailure.notAllowed),
        );
        await expectLater(
          endpoints.printing.pageUrl(sessionBuilder, token),
          throwsA(isA<ServerpodUnauthenticatedException>()),
        );
      });

      test('when the public address uses the usual port then the link '
          'leaves it out.', () {
        final token = 'A' * 43;
        expect(
          printPageUrl(
            ServerConfig(
              port: 8082,
              publicScheme: 'https',
              publicHost: 'chorus.example',
              publicPort: 443,
            ),
            token,
          ),
          'https://chorus.example/print/$token',
        );
        expect(
          printPageUrl(
            ServerConfig(
              port: 8082,
              publicScheme: 'http',
              publicHost: 'localhost',
              publicPort: 8082,
            ),
            token,
          ),
          'http://localhost:8082/print/$token',
        );
        expect(printPageUrl(null, token), '/print/$token');
      });

      test('when two boards are published then each gets its own '
          'token.', () async {
        final (space, guardian) = await circle();

        final first = await endpoints.printing.publishBoard(
          guardian,
          space,
          starterSnapshot(),
        );
        final second = await endpoints.printing.publishBoard(
          guardian,
          space,
          starterSnapshot(name: 'Snacks'),
        );

        expect(second, isNot(first));
        expect(
          await (await printResponse(session, second)).readAsString(),
          contains('Ada: Snacks'),
        );
      });

      test('when a read-only partner publishes then it is allowed, and a '
          'stranger is refused.', () async {
        final (space, guardian) = await circle();
        final partner = user();
        final code = await endpoints.circle.createInvite(
          guardian,
          space,
          CircleRole.partner,
        );
        await endpoints.circle.acceptInvite(partner, code, 'Gran');

        expect(
          await endpoints.printing.publishBoard(
            partner,
            space,
            starterSnapshot(),
          ),
          isNotEmpty,
        );
        await expectLater(
          endpoints.printing.publishBoard(user(), space, starterSnapshot()),
          refusedWith(CircleFailure.notAMember),
        );
        expect(
          await SharedSnapshot.db.count(
            session,
            where: (t) => t.circleSpace.equals(space),
          ),
          1,
        );
      });

      test('when the snapshot is too large or cannot be laid out then '
          'nothing is stored.', () async {
        final (space, guardian) = await circle();
        final huge = jsonEncode({
          'rows': 6,
          'cols': 6,
          'tiles': <Object>[],
          'padding': 'x' * maxSnapshotBytes,
        });
        // Under the cap in characters, over it in bytes.
        final wide = jsonEncode({
          'rows': 6,
          'cols': 6,
          'tiles': <Object>[],
          'padding': 'é' * (maxSnapshotBytes ~/ 2 + 1),
        });

        for (final bad in [huge, wide, 'not json', '[]', '{"tiles":[]}']) {
          await expectLater(
            endpoints.printing.publishBoard(guardian, space, bad),
            refusedWith(CircleFailure.notAllowed),
          );
        }
        expect(
          await SharedSnapshot.db.count(
            session,
            where: (t) => t.circleSpace.equals(space),
          ),
          0,
        );
      });

      test('when the token is unknown or malformed then the page is not '
          'found, with nothing of the app in it.', () async {
        final (space, guardian) = await circle();
        final token = await endpoints.printing.publishBoard(
          guardian,
          space,
          starterSnapshot(),
        );
        final flipped = token.startsWith('A')
            ? 'B${token.substring(1)}'
            : 'A${token.substring(1)}';

        for (final bad in [
          flipped,
          '',
          'short',
          '${token}x',
          "' OR 1=1 --",
          '<script>alert(1)</script>',
        ]) {
          final response = await printResponse(session, bad);
          expect(response.statusCode, printMissingStatus, reason: bad);
          final html = await response.readAsString();
          expect(html, contains('This board is not here'));
          expect(html, isNot(contains('like')));
          expect(html, isNot(contains('<script')));
        }
        expect(printMissingStatus, anyOf(404, 410));
      });

      test('when the web server is asked for /print/<token> then the route '
          'answers, and other paths are not its business.', () async {
        final web = session.serverpod.webServer;
        registerPrintRoutes(session.serverpod);
        expect(await web.start(), isTrue);
        addTearDown(web.stop);
        final client = HttpClient();
        addTearDown(() => client.close(force: true));
        Future<(int, String)> fetch(String path) async {
          final request = await client.get('localhost', web.port!, path);
          final response = await request.close();
          return (response.statusCode, await utf8.decodeStream(response));
        }

        // A request over HTTP is outside this test's transaction, so only
        // the answer for a token that does not exist can be checked here.
        final (status, body) = await fetch('/print/${'A' * 43}');
        expect(status, printMissingStatus);
        expect(body, contains('This board is not here'));
        expect((await fetch('/print')).$1, 404);
        expect((await fetch('/print/${'A' * 43}/more')).$1, 404);
      });

      test('when the link has expired then the page is gone, exactly as if '
          'it never existed.', () async {
        final (space, guardian) = await circle();
        final token = await endpoints.printing.publishBoard(
          guardian,
          space,
          starterSnapshot(),
        );
        final snapshot = await stored(token);
        await SharedSnapshot.db.updateRow(
          session,
          snapshot.copyWith(
            expiresAt: DateTime.now().toUtc().subtract(
              const Duration(seconds: 1),
            ),
          ),
          columns: (t) => [t.expiresAt],
        );

        final expired = await printResponse(session, token);
        final unknown = await printResponse(session, 'A' * 43);

        expect(expired.statusCode, printMissingStatus);
        expect(expired.statusCode, unknown.statusCode);
        expect(await expired.readAsString(), await unknown.readAsString());

        // The next publish sweeps the expired row away.
        await endpoints.printing.publishBoard(
          guardian,
          space,
          starterSnapshot(),
        );
        expect(
          await SharedSnapshot.db.count(
            session,
            where: (t) => t.token.equals(token),
          ),
          0,
        );
      });
    },
  );
}
