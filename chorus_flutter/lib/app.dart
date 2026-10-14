/// The Chorus app: sign-in gate, and the real server and replica behind the
/// screens.
library;

import 'dart:async';

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_ui/contracts.dart' hide CircleRole;
import 'package:chorus_ui/onboarding/launch_reveal.dart';
import 'package:chorus_ui/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import 'client.dart';
import 'screens/onboarding_screen.dart';
import 'screens/services.dart';
import 'screens/signed_in_shell.dart';
import 'screens/support/circle_cache.dart';
import 'src/activity/w2_parts.dart';
import 'src/features/feature_wiring.dart';
import 'src/live/chorus_live_session.dart';
import 'src/live/live_settings.dart';
import 'src/local_flags.dart';
import 'src/media/cached_media_store.dart';
import 'src/media/clip_player.dart';
import 'src/media/device_media_capture.dart';
import 'src/media/media_files.dart';
import 'src/media/media_gateway.dart';
import 'src/speech/clip_tile_speaker.dart';
import 'src/speech/tts_speech_service.dart';
import 'src/suggest/server_word_suggester.dart';
import 'src/sync/chorus_session.dart';
import 'src/tabs/one_tab_gate.dart';
import 'src/tabs/tab_workspaces.dart';
import 'src/trust/trust_services.dart';

class ChorusApp extends StatefulWidget {
  const ChorusApp({super.key});

  @override
  State<ChorusApp> createState() => _ChorusAppState();
}

class _ChorusAppState extends State<ChorusApp> {
  // One voice for the whole app, warmed once.
  final SpeechService _speech = TtsSpeechService();
  late final CircleGateway _gateway = ServerCircleGateway(client);

  // Kept here as well as in the shell, to stop this tab's sync the moment
  // another tab takes over.
  late final TabWorkspaces _workspaces = TabWorkspaces(
    () => SessionWorkspace.open(client, speech: _speech),
  );

  /// The tab that had the seat refreshed the sign-in this browser keeps as
  /// it went, and the server takes only the newest: an older one still in
  /// this tab's memory would sign the adult out.
  Future<void> _rereadSignIn() => client.auth.restore();

  /// Whether a sign-in read from this device at start-up is still to be
  /// checked with the server. One made since then is fresh from it.
  bool _signInToCheck = client.auth.isAuthenticated;

  /// Checks the sign-in read at start-up with the server, once, from the tab
  /// that holds the seat. The check replaces the sign-in the browser keeps:
  /// a tab without the seat that checked would leave the one with it on an
  /// older copy, and its next refresh would sign out every tab. An invalid
  /// sign-in signs the device out; a network failure changes nothing.
  void _checkSignIn() {
    if (!_signInToCheck) return;
    _signInToCheck = false;
    unawaited(
      client.auth
          .validateAuthentication(timeout: const Duration(seconds: 5))
          .then<void>((_) {}, onError: (Object _) {}),
    );
  }

  /// What this device remembers about itself: whether the onboarding
  /// screen has been shown.
  final LocalFlags _flags = LocalFlags();

  @override
  void initState() {
    super.initState();
    // Suggested words and the circle's members, on this app's client.
    w2RemoteFor = (circle, userId) => serverW2Remote(client, circle, userId);
    client.auth.authInfoListenable.addListener(_noteSignedIn);
    _noteSignedIn();
  }

  @override
  void dispose() {
    client.auth.authInfoListenable.removeListener(_noteSignedIn);
    super.dispose();
  }

  /// Someone signed in on this device has passed its first start, even on
  /// a version without onboarding: signing out leads to sign-in.
  void _noteSignedIn() {
    if (client.auth.authInfoListenable.value == null) return;
    if (_flags.known(LocalFlag.seenOnboarding) ?? false) return;
    unawaited(_flags.write(LocalFlag.seenOnboarding, true));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chorus',
      debugShowCheckedModeBanner: false,
      theme: chorusTheme(),
      darkTheme: chorusDarkTheme(),
      themeMode: ThemeMode.system,
      // After the system splash, the chorus reveal, once per cold start,
      // over whatever opens underneath: the board is not kept waiting.
      builder: (context, child) =>
          LaunchReveal(child: child ?? const SizedBox.shrink()),
      home: ValueListenableBuilder(
        valueListenable: client.auth.authInfoListenable,
        builder: (context, authInfo, _) {
          // First start: onboarding; every later signed-out start, signing
          // out included: sign-in.
          if (authInfo == null) {
            return SignedOutStart(speech: _speech, flags: _flags);
          }
          // In a browser only one tab runs the signed-in app: every tab
          // shares the one database on this device.
          return OneTabGate(
            onTaken: _workspaces.closeAll,
            afterTakeOver: _rereadSignIn,
            onHeld: _checkSignIn,
            // Keyed by user: signing in as someone else starts from scratch,
            // with that user's own database file.
            child: SignedInShell(
              key: ValueKey(authInfo.authUserId),
              gateway: _gateway,
              openWorkspace: _workspaces.open,
              speech: _speech,
            ),
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
  SessionWorkspace._(this._client, this._session, this._speech);

  final Client _client;
  final ChorusSession _session;
  final SpeechService _speech;

  /// How long sync waits for the first board to be read before starting
  /// anyway (a signed-in device with no boards yet has nothing to read).
  static const _localFirst = Duration(milliseconds: 1500);

  /// How long a paper copy may take before the adult is told it failed.
  static const _publishTimeout = Duration(seconds: 30);

  bool _syncStarted = false;
  Timer? _startTimer;

  // One player for the board and one capture (with its own player, for
  // previews) for the whole session. Both are made empty and touch the
  // device only on first use.
  final DeviceClipPlayer _clipPlayer = DeviceClipPlayer();
  final DeviceMediaCapture _capture = DeviceMediaCapture();

  /// The media store, speaker and suggester of each circle opened so far.
  final Map<UuidValue, _CircleParts> _parts = {};

  /// Opens the user's replica. Sync starts once the first board has been
  /// read from this device, or after [_localFirst]: in the browser the
  /// database has a single connection, and a sync that starts first holds it
  /// for as long as the network takes, with the board unreadable meanwhile.
  ///
  /// [speech] is the app's voice, used for a word with no recording on this
  /// device.
  static Future<SessionWorkspace> open(
    Client client, {
    required SpeechService speech,
  }) async {
    final session = await ChorusSession.open(client);
    final workspace = SessionWorkspace._(client, session, speech);
    workspace._startTimer = Timer(_localFirst, workspace._startSync);
    return workspace;
  }

  /// Sync keeps itself going from here; with no signal it simply waits. A
  /// failed first connection is the supervisor's to show and retry.
  void _startSync() {
    if (_syncStarted) return;
    _syncStarted = true;
    _startTimer?.cancel();
    unawaited(
      Future<void>.sync(
        () => _session.sync.start(),
      ).then<void>((_) {}, onError: (Object _) {}),
    );
  }

  @override
  SyncStatus get sync => _session.sync;

  @override
  Future<void> ensureCircleReady(
    CircleInfo circle, {
    bool seedIfEmpty = false,
  }) => _session.ensureCircleReady(circle, seedIfEmpty: seedIfEmpty);

  @override
  BoardStore boardStore(CircleInfo circle) {
    final store = _session.boardStore(circle);
    if (!_syncStarted) unawaited(store.refresh().whenComplete(_startSync));
    return store;
  }

  @override
  CircleServices servicesFor(CircleInfo circle) {
    final space = circle.spaceUuid;
    final parts = _parts[space] ??= _CircleParts.open(
      _client,
      space: space,
      userId: _session.userId,
      sync: sync,
      speech: _speech,
      clipPlayer: _clipPlayer,
    );
    parts.trust ??= TrustParts.open(
      _client,
      space: space,
      sync: sync,
      replica: _session.replica,
    );
    return parts.services[circle.myRole] ??= _servicesFor(circle, parts);
  }

  CircleServices _servicesFor(CircleInfo circle, _CircleParts parts) {
    final space = circle.spaceUuid;
    final me = _session.userId.uuid;
    final canEdit = circle.myRole != CircleRole.partner;
    final isGuardian = circle.myRole == CircleRole.guardian;
    final features = parts.featuresFor(
      circle.myRole,
      () => openCircleFeatures(
        _client,
        circle: circle,
        userId: me,
        sync: sync,
        openStore: () => _session.boardStore(circle),
      ),
    );
    return CircleServices(
      userId: me,
      media: parts.media,
      speaker: parts.speaker,
      // A partner sees photos and hears clips but adds none.
      capture: canEdit ? _capture : null,
      suggester: canEdit ? parts.suggester : null,
      live: ({required bool forTalker}) {
        // Only the child's board shares what is said, and only when a
        // guardian turned it on for this device.
        final sharing = forTalker && isGuardian;
        return ChorusLiveSession.forClient(
          _client,
          circleSpace: space,
          sync: sync,
          mayShareSaid: sharing,
          loadShareSaid: sharing ? () => readShareSaid(me, space.uuid) : null,
          saveShareSaid: sharing
              ? (value) => writeShareSaid(me, space.uuid, value)
              : null,
        );
      },
      publishBoard: (boardJson) => _publish(space, boardJson),
      wordLog: features?.wordLog,
      summary: features?.summary,
      sharing: features?.sharing,
      boards: features?.boards,
      trust: parts.trust?.services(canEdit: canEdit),
    );
  }

  /// Stores the snapshot and works out where its page is. In the released
  /// web app the page is on the server the app itself came from; anywhere
  /// else the app only knows the API server, so it asks.
  Future<String> _publish(UuidValue space, String boardJson) async {
    final token = await _client.printing
        .publishBoard(space, boardJson)
        .timeout(_publishTimeout);
    if (kIsWeb && kReleaseMode) {
      return Uri.base.resolve('/print/$token').toString();
    }
    return _client.printing.pageUrl(token).timeout(_publishTimeout);
  }

  @override
  Future<void> close() async {
    _startTimer?.cancel();
    _syncStarted = true;
    for (final parts in _parts.values) {
      parts.dispose();
    }
    _parts.clear();
    unawaited(_capture.dispose().then<void>((_) {}, onError: (Object _) {}));
    unawaited(_clipPlayer.dispose().then<void>((_) {}, onError: (Object _) {}));
    try {
      await Future<void>.sync(() => _session.sync.stop());
    } finally {
      await _session.close();
    }
  }
}

/// The long-lived parts of one circle: they hold files, timers and a
/// listener on sync, so they are made once and disposed with the workspace.
class _CircleParts {
  _CircleParts._(this.media, this.speaker, this.suggester);

  factory _CircleParts.open(
    Client client, {
    required UuidValue space,
    required UuidValue userId,
    required SyncStatus sync,
    required SpeechService speech,
    required ClipPlayer clipPlayer,
  }) {
    final gateway = ServerMediaGateway(client, space);
    final media = CachedMediaStore(
      files: openMediaFiles(),
      gateway: gateway,
      // One queue per adult and circle, so a second account on this device
      // never sends the first one's files.
      queueName: '${userId.uuid}_${space.uuid}',
      sync: sync,
    );
    return _CircleParts._(
      media,
      ClipTileSpeaker(speech: speech, clips: media, player: clipPlayer),
      ServerWordSuggester.forClient(
        client,
        circleSpace: space,
        upload: (hash, bytes) => gateway.upload(hash, bytes, isAudio: false),
        sync: sync,
        locale: PlatformDispatcher.instance.locale.toLanguageTag(),
      ),
    );
  }

  final CachedMediaStore media;
  final ClipTileSpeaker speaker;
  final ServerWordSuggester suggester;

  /// "Try a clash", "Who is up to date" and "Under the hood".
  TrustParts? trust;

  /// The services handed out, by the adult's role when they were asked for.
  final Map<CircleRole, CircleServices> services = {};

  /// The word log, "This week", sharing and board management, for the
  /// adult's role now. One set per circle: see [FeatureSlot].
  final FeatureSlot<CircleFeatures> _features = FeatureSlot(
    (features) => features.dispose(),
  );

  /// The features for [role], made with [open] the first time and again
  /// when the adult's role changed. Null when they could not be made: the
  /// board works without them.
  CircleFeatures? featuresFor(CircleRole role, CircleFeatures Function() open) {
    final before = _features.role;
    if (before != null && before != role) {
      // The services of the old role hold the features about to go.
      services.removeWhere((other, _) => other != role);
    }
    return _features.forRole(role, open);
  }

  void dispose() {
    trust?.dispose();
    _features.dispose();
    suggester.dispose();
    media.dispose();
  }
}
