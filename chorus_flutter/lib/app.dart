/// The Chorus app: sign-in gate, and the real server and replica behind the
/// screens.
library;

import 'dart:async';

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_ui/contracts.dart' hide CircleRole;
import 'package:chorus_ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import 'client.dart';
import 'screens/services.dart';
import 'screens/sign_in_screen.dart';
import 'screens/signed_in_shell.dart';
import 'screens/support/circle_cache.dart';
import 'src/speech/tts_speech_service.dart';
import 'src/sync/chorus_session.dart';

class ChorusApp extends StatefulWidget {
  const ChorusApp({super.key});

  @override
  State<ChorusApp> createState() => _ChorusAppState();
}

class _ChorusAppState extends State<ChorusApp> {
  // One voice for the whole app, warmed once.
  final SpeechService _speech = TtsSpeechService();
  late final CircleGateway _gateway = ServerCircleGateway(client);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chorus',
      debugShowCheckedModeBanner: false,
      theme: chorusTheme(),
      home: ValueListenableBuilder(
        valueListenable: client.auth.authInfoListenable,
        builder: (context, authInfo, _) {
          if (authInfo == null) return const SignInScreen();
          // Keyed by user: signing in as someone else starts from scratch,
          // with that user's own database file.
          return SignedInShell(
            key: ValueKey(authInfo.authUserId),
            gateway: _gateway,
            openWorkspace: () => SessionWorkspace.open(client),
            speech: _speech,
          );
        },
      ),
    );
  }
}

/// [CircleGateway] on the generated client, remembering the circle list on
/// this device after every successful call.
class ServerCircleGateway implements CircleGateway {
  ServerCircleGateway(this._client);

  final Client _client;

  String? get _userId => _client.auth.authInfo?.authUserId.uuid;

  @override
  Future<List<CircleInfo>> myCircles() async {
    final circles = await _client.circle.myCircles();
    final userId = _userId;
    if (userId != null) await writeCircleCache(userId, circles);
    return circles;
  }

  @override
  Future<List<CircleInfo>> rememberedCircles() async {
    final userId = _userId;
    return userId == null ? const [] : readCircleCache(userId);
  }

  @override
  Future<CircleInfo> createCircle({
    required String childName,
    required String displayName,
  }) async {
    final circle = await _client.circle.createCircle(childName, displayName);
    await _remember(circle);
    return circle;
  }

  @override
  Future<CircleInfo> acceptInvite({
    required String code,
    required String displayName,
  }) async {
    final circle = await _client.circle.acceptInvite(code, displayName);
    await _remember(circle);
    return circle;
  }

  @override
  Future<String> createInvite(CircleInfo circle, CircleRole role) =>
      _client.circle.createInvite(circle.spaceUuid, role);

  @override
  Future<void> signOut() async {
    await _client.auth.signOutDevice();
  }

  /// Adds [circle] to the remembered list, so it is there on the next start
  /// even if the app closes before the list is fetched again.
  Future<void> _remember(CircleInfo circle) async {
    final userId = _userId;
    if (userId == null) return;
    final known = await readCircleCache(userId);
    await writeCircleCache(userId, [
      for (final other in known)
        if (other.spaceUuid != circle.spaceUuid) other,
      circle,
    ]);
  }
}

/// [Workspace] on the signed-in user's [ChorusSession].
class SessionWorkspace implements Workspace {
  SessionWorkspace._(this._session);

  final ChorusSession _session;

  /// Opens the user's replica and starts sync. Sync keeps itself going from
  /// here; with no signal it simply waits.
  static Future<SessionWorkspace> open(Client client) async {
    final session = await ChorusSession.open(client);
    // Written to compile whether start() is synchronous or returns a future;
    // a failed first connection is the supervisor's to show and retry.
    unawaited(
      Future<void>.sync(
        () => session.sync.start(),
      ).then<void>((_) {}, onError: (Object _) {}),
    );
    return SessionWorkspace._(session);
  }

  @override
  SyncStatus get sync => _session.sync;

  @override
  Future<void> ensureCircleReady(
    CircleInfo circle, {
    bool seedIfEmpty = false,
  }) => _session.ensureCircleReady(circle, seedIfEmpty: seedIfEmpty);

  @override
  BoardStore boardStore(CircleInfo circle) => _session.boardStore(circle);

  @override
  Future<void> close() async {
    try {
      await Future<void>.sync(() => _session.sync.stop());
    } finally {
      await _session.close();
    }
  }
}
