/// The circle's quick phrases on this device, from the server, kept on the
/// device for use offline; and this device's own word counts.
library;

import 'dart:async';
import 'dart:convert';

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_shared/chorus_shared.dart'
    show cleanQuickPhrases, countSpokenWords, defaultQuickPhrases;
import 'package:chorus_ui/contracts_quick_phrases.dart';

import '../../screens/support/circle_cache_none.dart'
    if (dart.library.io) '../../screens/support/circle_cache_io.dart'
    if (dart.library.js_interop) '../../screens/support/circle_cache_web.dart'
    as platform;

/// Reads the text kept under a name on this device; null when none.
typedef ReadText = Future<String?> Function(String name);

/// Keeps text under a name on this device.
typedef WriteText = Future<void> Function(String name, String text);

/// [QuickPhraseBook] over the server's `quickPhrase` endpoint.
///
/// What the device kept last time shows at once, the defaults when it
/// kept nothing; the server is asked once on creation. [refresh] asks the
/// server and keeps the answer; [save] needs the server and keeps what it
/// kept.
class ServerQuickPhrases extends QuickPhraseBook {
  ServerQuickPhrases({
    required this.circleId,
    required bool canEdit,
    required this._fetch,
    required this._push,
    ReadText? read,
    WriteText? write,
  }) : _editable = canEdit,
       _read = read ?? platform.readText,
       _write = write ?? platform.writeText {
    // The device's copy first; then the circle's latest, when there is a
    // connection, so the child's board has it before the panel opens.
    unawaited(_load().whenComplete(refresh));
  }

  /// The phrases of [circleSpace] through [client].
  factory ServerQuickPhrases.forClient(
    Client client, {
    required UuidValue circleSpace,
    required bool canEdit,
  }) => ServerQuickPhrases(
    circleId: circleSpace.uuid,
    canEdit: canEdit,
    fetch: () => client.quickPhrase.list(circleSpace),
    push: (phrases) => client.quickPhrase.set(circleSpace, phrases),
  );

  /// Names the phrases kept on this device.
  final String circleId;
  final bool _editable;
  final Future<List<String>> Function() _fetch;
  final Future<List<String>> Function(List<String>) _push;
  final ReadText _read;
  final WriteText _write;

  List<String> _phrases = defaultQuickPhrases;

  /// Set once the server has answered, so a slow read of the device's copy
  /// never overwrites a newer answer.
  bool _fromServer = false;

  String get _name => 'chorus_quick_phrases_$circleId';

  @override
  List<String> get phrases => _phrases;

  @override
  bool get canEdit => _editable;

  Future<void> _load() async {
    try {
      final text = await _read(_name);
      if (text == null || _fromServer) return;
      final kept = cleanQuickPhrases((jsonDecode(text) as List).cast<String>());
      if (kept.isEmpty) return;
      _phrases = List.unmodifiable(kept);
      notifyListeners();
    } catch (_) {
      // Nothing usable kept: the defaults stay.
    }
  }

  void _take(List<String> phrases) {
    final kept = cleanQuickPhrases(phrases);
    _phrases = List.unmodifiable(kept.isEmpty ? defaultQuickPhrases : kept);
    _fromServer = true;
    notifyListeners();
    unawaited(
      _write(_name, jsonEncode(_phrases)).catchError((Object _) {}),
    );
  }

  @override
  Future<void> refresh() async {
    try {
      _take(await _fetch());
    } catch (_) {
      // Offline or refused: what the device has stays.
    }
  }

  @override
  Future<void> save(List<String> phrases) async {
    if (!_editable) {
      throw StateError('A read-only partner cannot change these.');
    }
    _take(await _push(phrases));
  }
}

/// [SpokenWordCounts] kept in this device's storage, never sent anywhere.
class DeviceWordCounts implements SpokenWordCounts {
  DeviceWordCounts({required this.circleId, ReadText? read, WriteText? write})
    : _read = read ?? platform.readText,
      _write = write ?? platform.writeText {
    unawaited(_load());
  }

  /// Names the counts kept on this device.
  final String circleId;
  final ReadText _read;
  final WriteText _write;
  Map<String, int> _counts = const {};
  Timer? _saveSoon;

  String get _name => 'chorus_word_counts_$circleId';

  @override
  Map<String, int> get counts => _counts;

  Future<void> _load() async {
    try {
      final text = await _read(_name);
      if (text == null) return;
      final kept = (jsonDecode(text) as Map).map(
        (key, value) => MapEntry(key as String, (value as num).toInt()),
      );
      // Words counted before the device's copy was read are added to it.
      final merged = Map<String, int>.of(kept);
      _counts.forEach((word, n) => merged[word] = (merged[word] ?? 0) + n);
      _counts = merged;
    } catch (_) {}
  }

  @override
  void noteSaid(String text) {
    try {
      _counts = countSpokenWords(_counts, text);
    } catch (_) {
      return;
    }
    _saveSoon?.cancel();
    _saveSoon = Timer(const Duration(seconds: 2), () {
      unawaited(_write(_name, jsonEncode(_counts)).catchError((Object _) {}));
    });
  }
}
