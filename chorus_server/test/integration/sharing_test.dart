/// Tests for the view-only board and the .obf export: who may share, how
/// long a link lasts, that withdrawing works, that the page speaks without
/// loading anything, and that the file reads back as the same board.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' show pow;

import 'package:chorus_server/src/generated/protocol.dart';
import 'package:chorus_server/src/obf/obf_export.dart';
import 'package:chorus_server/src/printing/print_page.dart';
import 'package:chorus_server/src/printing/print_routes.dart';
import 'package:chorus_server/src/sharing/sharing_endpoint.dart';
import 'package:chorus_server/src/sharing/sharing_routes.dart';
import 'package:chorus_server/src/sharing/view_only_page.dart';
import 'package:chorus_server/src/web/app_route.dart';
import 'package:chorus_shared/chorus_shared.dart'
    show parseObf, symbolSvgFor, universalCore36;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_offline_sync_server/serverpod_offline_sync_server.dart';
import 'package:test/test.dart';

import 'test_circles.dart';
import 'test_tools/serverpod_test_tools.dart';

/// The starter board as the client would publish it, with one tile that
/// says something other than its label.
String snapshot({String? childName = 'Maya', String name = 'Home'}) =>
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
            if (word.label == 'he') 'speech': 'Grandad',
            'colorKey': word.colorKey,
          },
      ],
    });

/// [html] with the SVG namespace declarations taken out: they name the
/// format and are never fetched.
String withoutNamespaces(String html) =>
    html.replaceAll(RegExp(r'xmlns(:\w+)?="[^"]*"'), '');

void main() {
  group('Given a view-only page,', () {
    final until = DateTime.utc(2026, 10, 21, 9);
    String render(String json) =>
        renderViewOnlyPage(PrintBoard.parse(json), expiresAt: until);

    test('when it is the starter board then every word is a laminated tile '
        'that says itself, with its symbol, under a strip and two '
        'buttons.', () {
      final html = render(snapshot());

      expect(
        '<button type="button" class="tile'.allMatches(html),
        hasLength(36),
      );
      expect(
        html,
        contains(
          '<button type="button" class="tile c-verb" data-say="like">'
          '<span class="label">like</span></button>',
        ),
      );
      expect(
        html,
        contains(
          '<button type="button" class="tile c-verb" data-say="want">'
          '<span class="sym" aria-hidden="true">${symbolSvgFor('want')}',
        ),
      );
      expect(html, contains('data-say="Grandad"><span class="label">he<'));
      expect(html, contains('<div id="strip" class="strip"'));
      expect(
        html,
        contains('<button type="button" id="speak" class="act">Speak</button>'),
      );
      expect(
        html,
        contains('<button type="button" id="clear" class="act">Clear</button>'),
      );
      expect(html, contains('<h1>Maya&#39;s board</h1>'));
      // Card, laminated fill and its 3 px darker edge, ink labels.
      expect(html, contains('--card:#f6f2ea'));
      expect(html, contains('.c-verb{--fill:#c7efb2;--edge:#7db863}'));
      expect(html, contains('box-shadow:0 3px 0 var(--edge)'));
      expect(html, contains('color:#15171a'));
      expect(html, contains('font-family:system-ui'));
    });

    test('when it is opened then the footer names the child, the last day '
        'and the credits.', () {
      final html = render(snapshot());

      expect(
        html,
        contains(
          'A view-only copy of Maya&#39;s board, shared from Chorus. It '
          'stops working on 21 October 2026.',
        ),
      );
      expect(html, contains(escapeHtml(boardCredit)));
      expect(
        render(snapshot(childName: null)),
        contains('A view-only copy of this board, shared from Chorus.'),
      );
    });

    test('when it speaks then it uses the browser\'s own voice in en-US, '
        'cancelling first and waiting for the engine to go quiet.', () {
      final html = render(snapshot());

      expect(html, contains('window.speechSynthesis'));
      expect(html, contains("u.lang = 'en-US'"));
      expect(
        html.indexOf('synth.cancel()'),
        lessThan(html.indexOf('synth.speak(u)')),
      );
      expect(html, contains('setTimeout(go, 10)'));
      expect(html, contains('waits < 30'));
    });

    test('when it chooses a voice then only voices on the device are '
        'considered, so no tapped word goes to a speech service.', () {
      final html = render(snapshot());

      expect(html, contains('return v.localService !== false;'));
      // Every pass reads the one list, filtered to the device's voices.
      expect(
        html,
        contains(
          'var list = Array.prototype.filter.call(synth.getVoices() || [], '
          'onDevice);',
        ),
      );
      expect('synth.getVoices()'.allMatches(html), hasLength(1));
      // With none of its own, no voice is set and the browser's default
      // speaks.
      expect(html, contains('if (voice) u.voice = voice;'));
    });

    test('when it is opened then it loads nothing, stores nothing and moves '
        'only on the press and the new word\'s fade.', () {
      final html = withoutNamespaces(render(snapshot()));

      expect(html, isNot(contains('http')));
      expect(html, isNot(contains('//')));
      expect(html, isNot(matches(RegExp(r'\b(src|href|action)\s*='))));
      expect(html, isNot(contains('url(')));
      expect(html, isNot(contains('@import')));
      expect(html, isNot(contains('fetch(')));
      expect(html, isNot(contains('XMLHttpRequest')));
      expect(html, isNot(contains('Storage')));
      expect(html, isNot(contains('cookie')));
      expect(html, isNot(contains('<form')));
      // The board stays still: the press and the strip's fade, nothing else.
      expect('@keyframes'.allMatches(html), hasLength(1));
      expect(html, contains('@keyframes land{from{opacity:0}to{opacity:1}}'));
      expect(html, contains('animation:land 200ms'));
      expect(html, contains('.tile:active{transform:translateY(2px)'));
      expect(html, isNot(contains('rotate')));
      expect(html, isNot(contains('perspective')));
      expect(html, contains('@media (prefers-reduced-motion:reduce)'));
    });

    test('when the reader\'s device is dark then the page is slate with '
        'dimmer fills, and labels stay ink.', () {
      final html = render(snapshot());
      final dark = html.substring(
        html.indexOf('@media (prefers-color-scheme:dark)'),
      );

      expect(dark, contains('--card:#101214'));
      expect(dark, contains('.c-verb{--fill:#a9d993;--edge:#5f9a48}'));
      expect(dark, contains('.c-negation{--fill:#efb88e;--edge:#b76a3d}'));
      expect(html, contains('<meta name="color-scheme" content="light dark">'));
      expect(html, contains('.tile{--fill:#ffffff;--edge:#a9a8a3;'));
      expect(darkTileColours.keys, printColours.keys);
      expect(tileEdges.keys, printColours.keys);
    });

    test('when a label is drawn on any fill, light or dark, then the ink is '
        'at least 9:1 against it, as on the app\'s tiles.', () {
      // WCAG relative luminance of `#rrggbb`.
      double luminance(String hex) {
        double channel(int at) {
          final c = int.parse(hex.substring(at, at + 2), radix: 16) / 255;
          return c <= 0.03928
              ? c / 12.92
              : pow((c + 0.055) / 1.055, 2.4).toDouble();
        }

        return 0.2126 * channel(1) + 0.7152 * channel(3) + 0.0722 * channel(5);
      }

      final ink = luminance('#15171a');
      for (final fill in [
        ...printColours.values,
        for (final (fill, _) in darkTileColours.values) fill,
      ]) {
        expect(
          (luminance(fill) + 0.05) / (ink + 0.05),
          greaterThan(9),
          reason: fill,
        );
      }
    });

    test('when it lays out the board then it keeps the board\'s grid, fits '
        'the screen, and gives every label the one size its longest word '
        'fits.', () {
      final html = render(snapshot());

      expect(html, contains('grid-template-columns:repeat(6,minmax(0,1fr))'));
      expect(html, contains('(100vh - 220px) * 1.000'));
      // "different" is the longest starter word: 9 letters.
      expect(html, contains('var(--tw) / 5.58'));
      final short = render(
        jsonEncode({
          'rows': 2,
          'cols': 3,
          'tiles': [
            {'row': 0, 'col': 0, 'label': 'go'},
          ],
        }),
      );
      expect(short, contains('grid-template-columns:repeat(3,minmax(0,1fr))'));
      expect(short, contains('(100vh - 220px) * 1.500'));
      expect(short, contains('var(--tw) / 2.48'));
      expect('class="empty"'.allMatches(short), hasLength(5));
    });

    test('when text carries markup then it is shown and said as text.', () {
      final html = render(
        jsonEncode({
          'childName': '<img src=x onerror=alert(1)>',
          'name': '</title><script>alert(2)</script>',
          'rows': 1,
          'cols': 2,
          'tiles': [
            {
              'row': 0,
              'col': 0,
              'label': '<script>alert(3)</script>',
              'speech': '"><img src=x onerror=alert(4)>',
              'colorKey': 'verb',
            },
            {
              'row': 0,
              'col': 1,
              'label': 'x',
              'colorKey': '}body{background:red',
            },
          ],
        }),
      );

      expect('<script'.allMatches(html), hasLength(1));
      expect(html, isNot(contains('<img')));
      expect(html, isNot(contains('background:red')));
      expect(html, contains('data-say="&quot;&gt;&lt;img src=x onerror'));
      expect(html, contains('&lt;script&gt;alert(3)&lt;&#47;script&gt;'));
      expect('<title>'.allMatches(html), hasLength(1));
    });
  });

  test('Given a board name, when it names the .obf file then the plain name '
      'is safe for every browser and the full one is kept too.', () {
    expect(
      obfContentDisposition('Home'),
      'attachment; filename="Home.obf"; filename*=UTF-8\'\'Home.obf',
    );
    expect(
      obfContentDisposition('Snacks "and" drinks/ü'),
      startsWith('attachment; filename="Snacks _and_ drinks__.obf"; '),
    );
    expect(
      obfContentDisposition('Snacks "and" drinks/ü'),
      endsWith("filename*=UTF-8''Snacks%20%22and%22%20drinks%2F%C3%BC.obf"),
    );
    expect(obfContentDisposition('ü'), contains('filename="board.obf"'));
  });

  test('Given a path, when the app fallback looks at it then only the '
      "server's own pages keep their 404.", () {
    for (final own in [
      '/b/${'A' * 43}',
      '/print/x',
      '/export/${'A' * 43}',
    ]) {
      expect(isOwnPagePath(own), isTrue, reason: own);
    }
    for (final app in [
      '/',
      '/b',
      '/b/',
      '/b/x/y',
      '/home',
      '/bb/x',
      '/main.dart.js',
    ]) {
      expect(isOwnPagePath(app), isFalse, reason: app);
    }
  });

  withServerpod(
    'Given the sharing endpoint,',
    databaseInterceptor: offlineSyncDatabaseInterceptor,
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      final circles = Circles(sessionBuilder, endpoints);
      final session = circles.session;
      final sharing = endpoints.sharing;

      Future<SharedSnapshot> stored(String token) async =>
          (await SharedSnapshot.db.findFirstRow(
            session,
            where: (t) => t.token.equals(token),
          ))!;

      Future<void> expire(String token) async {
        await SharedSnapshot.db.updateRow(
          session,
          (await stored(token)).copyWith(
            expiresAt: DateTime.now().toUtc().subtract(
              const Duration(seconds: 1),
            ),
          ),
          columns: (t) => [t.expiresAt],
        );
      }

      test('when nobody is signed in then every method is refused.', () async {
        final space = const Uuid().v7obj();
        await expectLater(
          sharing.publishViewOnly(sessionBuilder, space, snapshot()),
          unauthenticated,
        );
        await expectLater(
          sharing.withdraw(sessionBuilder, space, 'A' * 43),
          unauthenticated,
        );
        await expectLater(
          sharing.exportUrl(sessionBuilder, 'A' * 43),
          unauthenticated,
        );
      });

      test('when a guardian shares the board then the link opens a page that '
          'speaks for 7 days, and its file is beside it.', () async {
        final circle = await circles.create();

        final link = await sharing.publishViewOnly(
          circle.guardian.session,
          circle.space,
          snapshot(),
        );

        expect(isPrintToken(link.token), isTrue);
        final url = Uri.parse(link.url);
        expect(url.host, 'localhost');
        expect(url.path, '/b/${link.token}');
        expect(Uri.parse(link.exportUrl).path, '/export/${link.token}');
        final row = await stored(link.token);
        expect(row.kind, SnapshotKind.viewOnly);
        expect(row.circleSpace, circle.space);
        expect(row.createdBy, circle.guardian.id);
        expect(row.expiresAt.difference(row.createdAt), viewOnlyLinkLifetime);
        expect(viewOnlyLinkLifetime, const Duration(days: 7));
        expect(link.expiresAt, row.expiresAt);

        final response = await viewOnlyResponse(session, link.token);
        expect(response.statusCode, 200);
        expect(response.body.bodyType?.mimeType, MimeType.html);
        final html = await response.readAsString();
        expect('class="tile'.allMatches(html), hasLength(36));
        expect(html, contains('Maya&#39;s board'));
        expect(html, contains(printDate(row.expiresAt)));
        final csp = response.headers['content-security-policy']!.single;
        expect(csp, contains("default-src 'none'"));
        expect(csp, contains("style-src 'unsafe-inline'"));
        expect(csp, contains("script-src 'unsafe-inline'"));
        expect(csp, contains('img-src data:'));
        expect(csp, isNot(contains('connect-src')));
        expect(response.headers['cache-control']!.single, contains('no-store'));
        expect(response.headers['set-cookie'], isNull);
      });

      test('when a therapist or a teacher shares then it is allowed, and a '
          'partner and a stranger are refused.', () async {
        final circle = await circles.create();
        for (final role in [CircleRole.therapist, CircleRole.teacher]) {
          final member = await circles.member(circle, role);
          expect(
            (await sharing.publishViewOnly(
              member.session,
              circle.space,
              snapshot(),
            )).token,
            isNotEmpty,
          );
        }
        final partner = await circles.member(circle, CircleRole.partner);
        await expectLater(
          sharing.publishViewOnly(partner.session, circle.space, snapshot()),
          refusedWith(CircleFailure.notAllowed),
        );
        await expectLater(
          sharing.publishViewOnly(
            circles.user().session,
            circle.space,
            snapshot(),
          ),
          refusedWith(CircleFailure.notAMember),
        );
        expect(
          await SharedSnapshot.db.count(
            session,
            where: (t) => t.circleSpace.equals(circle.space),
          ),
          2,
        );
      });

      test('when the snapshot is too large or cannot be laid out then '
          'nothing is stored.', () async {
        final circle = await circles.create();
        final huge = jsonEncode({
          'rows': 6,
          'cols': 6,
          'tiles': <Object>[],
          'padding': 'x' * maxSnapshotBytes,
        });
        for (final bad in [huge, 'not json', '{"tiles":[]}']) {
          await expectLater(
            sharing.publishViewOnly(circle.guardian.session, circle.space, bad),
            refusedWith(CircleFailure.notAllowed),
          );
        }
        expect(
          await SharedSnapshot.db.count(
            session,
            where: (t) => t.circleSpace.equals(circle.space),
          ),
          0,
        );
      });

      test('when the token never existed, is malformed or belongs to a '
          'paper copy then the page is not found (404).', () async {
        final circle = await circles.create();
        final paper = await endpoints.printing.publishBoard(
          circle.guardian.session,
          circle.space,
          snapshot(),
        );

        for (final bad in [
          'A' * 43,
          '',
          'short',
          '${'A' * 43}x',
          "' OR 1=1 --",
          paper,
        ]) {
          final response = await viewOnlyResponse(session, bad);
          expect(response.statusCode, sharedUnknownStatus, reason: bad);
          expect(sharedUnknownStatus, 404);
          final html = await response.readAsString();
          expect(html, contains('This board is not here'));
          expect(html, isNot(contains('like')));
          expect(html, isNot(contains('<script')));
        }
      });

      test('when the link has expired then the page is gone (410), and the '
          'next share or the daily sweep removes it.', () async {
        final circle = await circles.create();
        final link = await sharing.publishViewOnly(
          circle.guardian.session,
          circle.space,
          snapshot(),
        );
        await expire(link.token);

        final response = await viewOnlyResponse(session, link.token);
        expect(response.statusCode, sharedGoneStatus);
        expect(sharedGoneStatus, 410);
        final html = await response.readAsString();
        expect(html, contains('This board is no longer shared'));
        expect(html, isNot(contains('like')));

        await sharing.publishViewOnly(
          circle.guardian.session,
          circle.space,
          snapshot(),
        );
        expect(
          await SharedSnapshot.db.count(
            session,
            where: (t) => t.token.equals(link.token),
          ),
          0,
        );
        expect(
          (await viewOnlyResponse(session, link.token)).statusCode,
          sharedUnknownStatus,
        );
      });

      test('when an adult withdraws a link then the page and its file are '
          'gone (410) at once, and withdrawing again changes '
          'nothing.', () async {
        final circle = await circles.create();
        final teacher = await circles.member(circle, CircleRole.teacher);
        final link = await sharing.publishViewOnly(
          circle.guardian.session,
          circle.space,
          snapshot(),
        );
        expect((await viewOnlyResponse(session, link.token)).statusCode, 200);

        expect(
          await sharing.withdraw(teacher.session, circle.space, link.token),
          isTrue,
        );

        expect(
          (await viewOnlyResponse(session, link.token)).statusCode,
          sharedGoneStatus,
        );
        expect(
          (await obfExportResponse(session, link.token)).statusCode,
          sharedGoneStatus,
        );
        expect(
          await sharing.withdraw(
            circle.guardian.session,
            circle.space,
            link.token,
          ),
          isFalse,
        );
      });

      test('when someone without the right withdraws then the link keeps '
          'working.', () async {
        final circle = await circles.create();
        final other = await circles.create();
        final partner = await circles.member(circle, CircleRole.partner);
        final link = await sharing.publishViewOnly(
          circle.guardian.session,
          circle.space,
          snapshot(),
        );

        await expectLater(
          sharing.withdraw(partner.session, circle.space, link.token),
          refusedWith(CircleFailure.notAllowed),
        );
        await expectLater(
          sharing.withdraw(circles.user().session, circle.space, link.token),
          refusedWith(CircleFailure.notAMember),
        );
        // Another circle's guardian cannot reach it through their own circle.
        expect(
          await sharing.withdraw(
            other.guardian.session,
            other.space,
            link.token,
          ),
          isFalse,
        );
        await expectLater(
          sharing.withdraw(
            circle.guardian.session,
            circle.space,
            'not-a-token',
          ),
          refusedWith(CircleFailure.notAllowed),
        );
        expect((await viewOnlyResponse(session, link.token)).statusCode, 200);
      });

      test('when a board is exported then the file is Open Board Format that '
          'reads back as the same grid, words, speech and colours.', () async {
        final circle = await circles.create();
        final link = await sharing.publishViewOnly(
          circle.guardian.session,
          circle.space,
          snapshot(),
        );
        final paper = await endpoints.printing.publishBoard(
          circle.guardian.session,
          circle.space,
          snapshot(name: 'Kitchen'),
        );

        final response = await obfExportResponse(session, link.token);
        expect(response.statusCode, 200);
        expect(response.body.bodyType?.mimeType, MimeType.json);
        expect(
          response.headers['content-disposition']!.single,
          startsWith('attachment; filename="Home.obf"'),
        );
        expect(response.headers['cache-control']!.single, contains('no-store'));
        final body = await response.readAsString();
        final board = parseObf(body);
        expect(board.name, 'Home');
        expect((board.rows, board.columns), (6, 6));
        String? labelAt(int row, int col) =>
            board.button(board.order[row][col]!)!.label;
        for (final word in universalCore36) {
          expect(labelAt(word.row, word.col), word.label);
        }
        final he = board.button(board.order[2][1]!)!;
        expect(he.vocalization, 'Grandad');
        expect(
          board.button(board.order[0][0]!)!.backgroundColor,
          'rgb(199, 239, 178)',
        );
        expect((jsonDecode(body) as Map)['format'], 'open-board-0.1');
        // The same link gives the same file.
        expect(
          await (await obfExportResponse(session, link.token)).readAsString(),
          body,
        );

        final fromPaper = await obfExportResponse(session, paper);
        expect(fromPaper.statusCode, 200);
        expect(parseObf(await fromPaper.readAsString()).name, 'Kitchen');
        expect(
          await sharing.exportUrl(circle.guardian.session, paper),
          endsWith('/export/$paper'),
        );
      });

      test('when an export link is unknown or has expired then it is 404 '
          'or 410.', () async {
        final circle = await circles.create();
        final link = await sharing.publishViewOnly(
          circle.guardian.session,
          circle.space,
          snapshot(),
        );
        await expire(link.token);

        expect(
          (await obfExportResponse(session, 'A' * 43)).statusCode,
          sharedUnknownStatus,
        );
        expect(
          (await obfExportResponse(session, 'nope')).statusCode,
          sharedUnknownStatus,
        );
        expect(
          (await obfExportResponse(session, link.token)).statusCode,
          sharedGoneStatus,
        );
      });

      test('when the web server serves the app beside these pages then a '
          "page's 404 and 410 reach the browser, and the app's own routes "
          'still open the app.', () async {
        final app = await Directory.systemTemp.createTemp('chorus_app');
        addTearDown(() => app.delete(recursive: true));
        await File('${app.path}/index.html').writeAsString('the chorus app');
        await File('${app.path}/main.dart.js').writeAsString('// js');

        final pod = session.serverpod;
        final web = pod.webServer;
        registerPrintRoutes(pod);
        registerSharingRoutes(pod);
        web.addRoute(AppRoute(app, enableWasmHeaders: false), '/');
        expect(await web.start(), isTrue);
        addTearDown(web.stop);
        final client = HttpClient();
        addTearDown(() => client.close(force: true));
        Future<(int, String, HttpHeaders)> fetch(String path) async {
          final request = await client.get('localhost', web.port!, path);
          final response = await request.close();
          return (
            response.statusCode,
            await utf8.decodeStream(response),
            response.headers,
          );
        }

        final circle = await circles.create();
        final live = await sharing.publishViewOnly(
          circle.guardian.session,
          circle.space,
          snapshot(),
        );
        final gone = await sharing.publishViewOnly(
          circle.guardian.session,
          circle.space,
          snapshot(),
        );
        await sharing.withdraw(
          circle.guardian.session,
          circle.space,
          gone.token,
        );

        final page = await fetch('/b/${live.token}');
        expect(page.$1, 200);
        expect(page.$2, contains('class="tile'));
        expect(
          page.$3.value('content-security-policy'),
          contains('script-src'),
        );

        final unknown = await fetch('/b/${'A' * 43}');
        expect(unknown.$1, 404);
        expect(unknown.$2, contains('This board is not here'));
        expect(unknown.$2, isNot(contains('the chorus app')));

        final withdrawn = await fetch('/b/${gone.token}');
        expect(withdrawn.$1, 410);
        expect(withdrawn.$2, contains('no longer shared'));

        final file = await fetch('/export/${live.token}');
        expect(file.$1, 200);
        expect(file.$3.contentType?.mimeType, 'application/json');
        expect(parseObf(file.$2).name, 'Home');
        expect((await fetch('/export/${'A' * 43}')).$1, 404);

        expect((await fetch('/print/${'A' * 43}')).$1, printMissingStatus);

        expect(await fetch('/'), isA<(int, String, HttpHeaders)>());
        expect((await fetch('/')).$2, 'the chorus app');
        expect((await fetch('/main.dart.js')).$2, '// js');
        final route = await fetch('/some/app/route');
        expect(route.$1, 200);
        expect(route.$2, 'the chorus app');
        expect((await fetch('/b/x/y')).$2, 'the chorus app');
      });
    },
  );
}
