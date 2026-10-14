import 'dart:async';
import 'dart:io';

import 'package:serverpod/serverpod.dart';

import 'routes/app_config_route.dart';

/// Where the Flutter web app lives. The landing page has the root.
const String appMount = '/app';

/// Where the landing page's own files (styles, script, fonts) are served.
const String landingMount = '/landing';

/// The landing page's headers: public and cacheable for a short while, and
/// allowed to load nothing but its own files. Unlike the board pages it may
/// be indexed and may send a referrer.
final Headers landingHeaders = Headers.build((h) {
  h['Cache-Control'] = ['no-cache'];
  h['Referrer-Policy'] = ['strict-origin-when-cross-origin'];
  h['X-Content-Type-Options'] = ['nosniff'];
  h['Content-Security-Policy'] = [landingContentSecurityPolicy];
});

/// Everything the landing page loads comes from this server; nothing runs
/// inline.
const String landingContentSecurityPolicy =
    "default-src 'none'; script-src 'self'; style-src 'self'; "
    "font-src 'self'; img-src 'self' data:; media-src 'self'; "
    "connect-src 'self'; manifest-src 'self'; base-uri 'none'; "
    "form-action 'none'; frame-ancestors 'none'";

/// Adds the site to the web server: the landing page at `/`, its files at
/// [landingMount], and the Flutter web app with its config at [appMount].
///
/// [landingDir] and [appDir] default to `web/landing` and `web/app`. When
/// the app has not been built, [appMount] serves a page saying so. Call
/// before the server starts.
void registerSiteRoutes(
  Serverpod pod, {
  Directory? landingDir,
  Directory? appDir,
}) {
  final web = pod.webServer;
  final landing =
      landingDir ?? Directory(Uri(path: 'web/landing').toFilePath());
  final app = appDir ?? Directory(Uri(path: 'web/app').toFilePath());

  web.addRoute(LandingRoute(File('${landing.path}/index.html')), '/');
  web.addRoute(
    StaticRoute.directory(
      landing,
      cacheControlFactory: StaticRoute.public(
        maxAge: const Duration(minutes: 5),
      ),
    ),
    '$landingMount/**',
  );

  // The app reads its server's address from here, relative to its base
  // href. The build also ships a static assets/assets/config.json that
  // points at localhost; this literal route hides it.
  web.addRoute(
    AppConfigRoute(apiConfig: pod.config.apiServer),
    '$appMount/assets/assets/config.json',
  );

  // The manifest's scope is /app/, so /app goes to /app/.
  web.addMiddleware(appSlashRedirect, appMount);

  if (app.existsSync()) {
    web.addRoute(
      FlutterRoute(
        app,
        // If building the Flutter app with WASM, set the below parameter to
        // true and add the --wasm flag to the flutter build command.
        enableWasmHeaders: false,
      ),
      appMount,
    );
  } else {
    // The app has not been built: say so under its address.
    final buildPage = StaticRoute.file(
      File(Uri(path: 'web/pages/build_flutter_app.html').toFilePath()),
    );
    web.addRoute(buildPage, appMount);
    web.addRoute(buildPage, '$appMount/**');
  }
}

/// Sends `/app` to `/app/`, keeping the query. Relic routes both to the
/// same node, so this looks at the path as the browser sent it.
Handler appSlashRedirect(Handler next) => (Request request) {
  if (request.url.path == appMount) {
    final query = request.url.query;
    return Response.movedPermanently(
      Uri(path: '$appMount/', query: query.isEmpty ? null : query),
    );
  }
  return next(request);
};

/// Serves the landing page with its own headers, for GET and HEAD.
class LandingRoute extends Route {
  LandingRoute(this.page) : super(methods: {Method.get, Method.head});

  /// The page, `web/landing/index.html`.
  final File page;

  @override
  Future<Result> handleCall(Session session, Request request) async {
    if (!await page.exists()) return Response.notFound();
    return Response.ok(
      body: Body.fromString(await page.readAsString(), mimeType: MimeType.html),
      headers: landingHeaders,
    );
  }
}
