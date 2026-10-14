/// The circle's voice over the server's `voice` endpoint, kept on this
/// device so it works offline.
library;

import 'dart:async';
import 'dart:convert';

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_ui/contracts.dart'
    show SpeechService, SyncState, SyncStatus;
import 'package:chorus_ui/contracts_voice.dart';

import '../../screens/support/circle_cache_none.dart'
    if (dart.library.io) '../../screens/support/circle_cache_io.dart'
    if (dart.library.js_interop) '../../screens/support/circle_cache_web.dart'
    as platform;
import '../speech/tts_speech_service.dart';

/// Where the voice of [circleSpace] is kept on this device.
String voiceCacheFile(String circleSpace) => 'chorus_voice_$circleSpace.json';

/// The circle's [VoicePrefs] on this device.
///
/// It starts from what this device kept, then asks the server (unless the
/// adult chose "Work offline"). A choice is used here at once, kept here,
/// and sent; one that could not be sent is kept as waiting and sent at the
/// next [refresh].
class ServerVoiceChoice extends VoiceChoice {
  ServerVoiceChoice({
    required this.canChange,
    required this._fetch,
    required this._send,
    required this._speech,
    required this._cacheName,
    this._sync,
    Future<String?> Function(String name)? read,
    Future<void> Function(String name, String text)? write,
    this.timeout = const Duration(seconds: 15),
  }) : _read = read ?? platform.readText,
       _write = write ?? platform.writeText {
    _ready = _start();
    _wasLive = _sync?.state == SyncState.live;
    _sync?.addListener(_onSync);
  }

  /// Back online: send what waits and read the latest, once per return.
  bool _wasLive = false;

  void _onSync() {
    final live = _sync?.state == SyncState.live;
    if (live && !_wasLive) unawaited(refresh());
    _wasLive = live;
  }

  /// The choice the app uses for [circleSpace]. Read-only partners hear it
  /// and cannot change it.
  factory ServerVoiceChoice.forClient(
    Client client, {
    required UuidValue circleSpace,
    required bool canChange,
    required SpeechService speech,
    SyncStatus? sync,
  }) => ServerVoiceChoice(
    canChange: canChange,
    fetch: () => client.voice.getVoice(circleSpace),
    send: (prefs) => client.voice.setVoice(
      circleSpace,
      prefs.voiceName,
      prefs.rate,
      prefs.pitch,
    ),
    speech: speech,
    cacheName: voiceCacheFile(circleSpace.uuid),
    sync: sync,
  );

  @override
  final bool canChange;

  final Future<VoiceSetting> Function() _fetch;
  final Future<VoiceSetting> Function(VoicePrefs prefs) _send;
  final SpeechService _speech;
  final String _cacheName;
  final SyncStatus? _sync;
  final Future<String?> Function(String name) _read;
  final Future<void> Function(String name, String text) _write;

  /// Longest wait for the server.
  final Duration timeout;

  VoicePrefs _prefs = const VoicePrefs();

  /// A choice made here that the server has not taken yet.
  bool _waiting = false;
  bool _disposed = false;
  late final Future<void> _ready;

  /// Completes once the kept voice is read and the server asked once.
  Future<void> get ready => _ready;

  @override
  VoicePrefs get prefs => _prefs;

  Future<void> _start() async {
    try {
      final text = await _read(_cacheName);
      if (text != null) {
        final json = jsonDecode(text);
        _set(VoicePrefs.fromJson(json));
        _waiting = json is Map && json['waiting'] == true;
      } else {
        apply();
      }
    } catch (_) {
      apply();
    }
    await refresh();
  }

  /// Hands the voice to the device's speech.
  void apply() {
    final speech = _speech;
    if (speech is TtsSpeechService) speech.useVoice(_prefs);
  }

  void _set(VoicePrefs prefs) {
    _prefs = prefs;
    apply();
    if (!_disposed) notifyListeners();
  }

  Future<void> _keep() async {
    try {
      await _write(
        _cacheName,
        jsonEncode({..._prefs.toJson(), 'waiting': _waiting}),
      );
    } catch (_) {}
  }

  /// Sends a waiting choice, then reads the circle's. Never throws; with no
  /// network the kept voice stays.
  @override
  Future<void> refresh() async {
    if (_sync?.workingOffline ?? false) return;
    try {
      if (_waiting && canChange) {
        await _send(_prefs).timeout(timeout);
        _waiting = false;
        await _keep();
        return;
      }
      final setting = await _fetch().timeout(timeout);
      final read = VoicePrefs(
        voiceName: setting.voiceName,
        rate: setting.rate,
        pitch: setting.pitch,
      );
      if (read != _prefs) _set(read);
      await _keep();
    } catch (_) {
      // Offline or refused: the kept voice stays.
    }
  }

  @override
  Future<List<String>> voiceNames() async {
    final speech = _speech;
    if (speech is! TtsSpeechService) return const [];
    return speech.deviceVoiceNames();
  }

  @override
  Future<void> choose(VoicePrefs prefs) async {
    if (!canChange) throw StateError('A read-only member cannot change it.');
    _set(prefs);
    _waiting = true;
    await _keep();
    if (_sync?.workingOffline ?? false) return;
    try {
      await _send(prefs).timeout(timeout);
      _waiting = false;
      await _keep();
    } on CircleException {
      rethrow;
    } catch (_) {
      // No network: sent at the next refresh.
    }
  }

  @override
  Future<void> tryIt(String text) => _speech.speak(text);

  @override
  void dispose() {
    _disposed = true;
    _sync?.removeListener(_onSync);
    super.dispose();
  }
}
