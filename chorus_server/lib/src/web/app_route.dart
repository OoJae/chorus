import 'package:serverpod/serverpod.dart';

/// The pages the server renders itself, one token deep: the paper copy, the
/// view-only board and the .obf export.
final RegExp _ownPage = RegExp(r'^/(b|print|export)/[^/]+$');

/// True when [path] is one of the server's own pages.
bool isOwnPagePath(String path) => _ownPage.hasMatch(path);

/// Answers with [fallback] in place of any 404, except a 404 from one of the
/// server's own pages, which reaches the browser as it is: a mistyped link
/// to a shared board gets its own "not here" page, not the app's start page.
Middleware appFallback(Route fallback) =>
    (Handler next) => (Request request) async {
      final result = await next(request);
      if (result is Response &&
          result.statusCode == 404 &&
          !isOwnPagePath(request.url.path)) {
        return fallback.asHandler(request);
      }
      return result;
    };

/// [FlutterRoute] with [appFallback] in place of its own fallback.
///
/// Serverpod attaches a Flutter route's fallback at the root of the web
/// server, where it wraps every route, the server's own pages included.
/// This keeps the app's behaviour for every other path: files from the
/// build, and the start page for anything else, so the app's own routes
/// still open.
class AppRoute extends FlutterRoute {
  AppRoute(super.directory, {super.enableWasmHeaders});

  @override
  void injectIn(RelicRouter router) {
    final subRouter = Router<Handler>();
    if (enableWasmHeaders) {
      subRouter.use('/', const WasmHeadersMiddleware().call);
    }
    subRouter.use(
      '/',
      appFallback(
        StaticRoute.file(
          indexFile,
          cacheControlFactory: StaticRoute.privateNoCache(),
        ),
      ),
    );
    StaticRoute.directory(
      directory,
      cacheBustingConfig: cacheBustingConfig,
      cacheControlFactory: cacheControlFactory,
    ).injectIn(subRouter);
    router.attach('/', subRouter);
  }
}
