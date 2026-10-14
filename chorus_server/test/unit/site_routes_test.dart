/// Tests for the site's routing pieces that need no database: the landing
/// page's headers and the redirect from /app to /app/. The whole layout,
/// served by Serverpod beside the board pages, is tested in
/// `test/integration/sharing_test.dart`.
library;

import 'dart:convert';
import 'dart:io';

import 'package:chorus_server/src/web/app_route.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

void main() {
  test('Given the landing page, when its headers are read then it loads '
      'only its own files and runs nothing inline.', () {
    final csp = landingHeaders['Content-Security-Policy']!.single;
    expect(csp, contains("script-src 'self'"));
    expect(csp, contains("style-src 'self'"));
    expect(csp, isNot(contains('unsafe-inline')));
    expect(csp, contains("frame-ancestors 'none'"));
    expect(landingHeaders['Cache-Control'], ['no-cache']);
    expect(landingHeaders['X-Content-Type-Options'], ['nosniff']);
    expect(landingHeaders['Referrer-Policy'], [
      'strict-origin-when-cross-origin',
    ]);
    expect(landingHeaders['X-Robots-Tag'], isNull);
  });

  group('Given the redirect on /app in front of an app at /app/**,', () {
    late RelicServer server;
    late HttpClient client;

    setUpAll(() async {
      final app = RelicApp()
        ..use(appMount, appSlashRedirect)
        ..get('$appMount/**', (_) => Response.ok(body: Body.fromString('app')))
        ..get('/', (_) => Response.ok(body: Body.fromString('landing')));
      server = await app.serve(port: 0);
      client = HttpClient();
    });

    tearDownAll(() async {
      client.close(force: true);
      await server.close();
    });

    Future<(int, String?, String)> fetch(String path) async {
      final request = await client.get('127.0.0.1', server.port, path);
      request.followRedirects = false;
      final response = await request.close();
      return (
        response.statusCode,
        response.headers.value('location'),
        await utf8.decodeStream(response),
      );
    }

    test('when /app is asked for then it moves permanently to /app/, '
        'keeping the query.', () async {
      expect(await fetch('/app'), (301, '/app/', ''));
      final withQuery = await fetch('/app?x=1');
      expect(withQuery.$1, 301);
      expect(withQuery.$2, '/app/?x=1');
    });

    test(
      'when /app/ or a path below it is asked for then the app answers.',
      () async {
        expect(await fetch('/app/'), (200, null, 'app'));
        expect(await fetch('/app/some/route'), (200, null, 'app'));
        expect(await fetch('/'), (200, null, 'landing'));
      },
    );
  });
}
