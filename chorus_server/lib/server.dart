import 'dart:async';

import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';
import 'package:serverpod_cloud_storage/serverpod_cloud_storage.dart';

import 'src/cache_busting.dart';
import 'src/demo/demo_seed.dart';
import 'src/generated/serverpod.dart';
import 'src/jobs/scheduled_jobs.dart';
import 'src/printing/print_routes.dart';
import 'src/progress/progress_routes.dart';
import 'src/sharing/sharing_routes.dart';
import 'src/web/app_route.dart';

/// The starting point of the Serverpod server.
void run(List<String> args) async {
  // Initialize Serverpod. The generated Serverpod class is already connected
  // with your project's generated code.
  final pod = Serverpod(args);

  // Initialize authentication services for the server.
  // Token managers will be used to validate and issue authentication keys,
  // and the identity providers will be the authentication options available for users.
  pod.initializeAuthServices(
    tokenManagerBuilders: [
      // Use JWT for authentication keys towards the server.
      JwtConfigFromPasswords(),
    ],
    identityProviderBuilders: [
      // Configure the email identity provider for email/password authentication.
      // The default setup works with Serverpod Cloud without configuration. In
      // development the verification codes are logged to the console, and in
      // staging and production they are sent through the Serverpod Cloud email
      // service. If you want to use a custom provider for sending emails, use
      // `EmailIdpConfigFromPasswords`.
      ServerpodCloudEmailIdpConfig(
        appDisplayName: 'chorus',
      ),
    ],
  );

  // Serve all files in the web/static relative directory under /web.
  // These are used by the default web page.
  pod.webServer.addRoute(
    StaticRoute.withCacheBusting(cacheBustingConfig),
    cacheBustingConfig.mountPrefix,
  );

  // The landing page at /, and the Flutter web app with its config at /app.
  registerSiteRoutes(pod);

  // Configure cloud storage.
  // This setup works with Serverpod Cloud without extra configuration.
  // If you want to use a custom provider for cloud storage, replace these
  // with your preferred provider.
  pod.addCloudStorage(
    await ServerpodCloudProvider.private(
      fallback: () => DatabaseCloudStorage('private'),
    ),
  );
  pod.addCloudStorage(
    await ServerpodCloudProvider.public(
      fallback: () => DatabaseCloudStorage('public'),
    ),
  );

  // The printable page of a published board.
  registerPrintRoutes(pod);

  // The view-only board and the .obf export.
  registerSharingRoutes(pod);

  // The one-page progress report (counts only).
  registerProgressRoutes(pod);

  // Start the server.
  await pod.start();

  // Demo accounts and their circle, once the database is up.
  scheduleDemoSeed(pod);

  // The weekly summary and the daily cleanup, where future calls run.
  unawaited(scheduleJobs(pod));
}
