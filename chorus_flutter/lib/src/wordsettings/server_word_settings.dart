/// Hidden words and the circle's second language over the server, kept on
/// this device so the child's board shows them with no network.
///
/// Both work the same way: what the server last said and the changes made
/// here that it has not confirmed are kept on the device; a change shows
/// here at once and is sent while sync is live; the server is asked again
/// every [_Cached.refreshEvery] while live, and whenever sync comes back.
library;

import 'dart:async';
import 'dart:convert';

import 'package:chorus_client/chorus_client.dart' hide CircleRole;
import 'package:chorus_ui/contracts.dart'
    show CircleRole, SyncState, SyncStatus;
import 'package:chorus_ui/contracts_hidden.dart';
import 'package:chorus_ui/contracts_language.dart';
import 'package:flutter/foundation.dart';

import 'word_settings_storage.dart';

/// The timers, sync listener and saving both settings share.
mixin _Cached on ChangeNotifier {
  SyncStatus? get _sync;
  WordSettingsStorage get _storage;

  /// How often the server is asked again while sync is live.
  Duration get refreshEvery;

  /// Longest wait for one server call.
  Duration get callTimeout;

  Timer? _timer;
  bool _disposed = false;
  bool _wasOnline = false;
  bool _busy = false;
  bool _again = false;
  late final Future<void> _loading;

  /// Completes once what this device kept has been read.
  @visibleForTesting
  Future<void> get ready => _loading;

  /// Sync is live and not paused. With no supervisor (a test) the server is
  /// taken to be there.
  bool get _online {
    final sync = _sync;
    return sync == null ||
        (sync.state == SyncState.live && !sync.workingOffline);
  }

  void _start() {
    _sync?.addListener(_onSync);
    _wasOnline = _online;
    _loading = _load().then((_) => _tick());
    _timer = Timer.periodic(refreshEvery, (_) => unawaited(_tick()));
  }

  void _onSync() {
    final online = _online;
    if (online && !_wasOnline) unawaited(_tick());
    _wasOnline = online;
  }

  /// Sends what waits, then asks the server. Never throws.
  @visibleForTesting
  Future<void> tick() => _tick();

  Future<void> _tick() async {
    if (_disposed || !_online) return;
    if (_busy) {
      // A change made while one is being sent goes out right after it.
      _again = true;
      return;
    }
    _busy = true;
    try {
      do {
        _again = false;
        await _flush();
        if (!_disposed) await _refresh();
      } while (_again && !_disposed && _online);
    } catch (_) {
      // Tried again on the next tick.
    } finally {
      _busy = false;
    }
  }

  Future<void> _load();
  Future<void> _flush();
  Future<void> _refresh();
  Map<String, Object?> _toJson();

  void _save() {
    if (_disposed) return;
    unawaited(
      _storage
          .write(_key, jsonEncode(_toJson()))
          .then<void>((_) {}, onError: (Object _) {}),
    );
  }

  String get _key;

  Future<Map<String, Object?>?> _read() async {
    try {
      final text = await _storage.read(_key);
      if (text == null) return null;
      final json = jsonDecode(text);
      return json is Map<String, Object?> ? json : null;
    } catch (_) {
      return null;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _stop() {
    _disposed = true;
    _timer?.cancel();
    _sync?.removeListener(_onSync);
  }
}

/// [HiddenWords] over the server's hidden words endpoint.
class ServerHiddenWords extends HiddenWords with _Cached {
  ServerHiddenWords({
    required this._list,
    required this._set,
    required this._storage,
    this._sync,
    this._canChange = true,
    this.refreshEvery = const Duration(seconds: 30),
    this.callTimeout = const Duration(seconds: 20),
  }) {
    _start();
  }

  /// The hidden words the app uses for [circleSpace], kept under [userId].
  factory ServerHiddenWords.forClient(
    Client client, {
    required UuidValue circleSpace,
    required String userId,
    required CircleRole role,
    SyncStatus? sync,
  }) => ServerHiddenWords(
    list: () async => [
      for (final id in await client.hiddenWords.list(circleSpace)) id.uuid,
    ],
    set: (tileId, hidden) => client.hiddenWords.setHidden(
      circleSpace,
      UuidValue.withValidation(tileId),
      hidden,
    ),
    storage: DeviceWordSettingsStorage(
      userId: userId,
      circleId: circleSpace.uuid,
    ),
    sync: sync,
    canChange: role != CircleRole.partner,
  );

  final Future<List<String>> Function() _list;
  final Future<void> Function(String tileId, bool hidden) _set;
  @override
  final WordSettingsStorage _storage;
  @override
  final SyncStatus? _sync;
  bool _canChange;

  @override
  final Duration refreshEvery;
  @override
  final Duration callTimeout;

  /// As the server last said.
  Set<String> _server = {};

  /// Changes made here the server has not confirmed, by tile id.
  final Map<String, bool> _pending = {};

  @override
  String get _key => 'hidden.json';

  @override
  Set<String> get hiddenIds => {
    for (final id in _server)
      if (_pending[id] != false) id,
    for (final entry in _pending.entries)
      if (entry.value) entry.key,
  };

  @override
  bool get canChange => _canChange;

  /// Changes waiting for the server.
  @visibleForTesting
  Map<String, bool> get pending => Map.unmodifiable(_pending);

  @override
  Future<void> setHidden(String tileId, bool hidden) async {
    if (!_canChange) throw StateError('Only an editor can hide words.');
    final before = hiddenIds;
    _pending[tileId] = hidden;
    _save();
    if (!setEquals(before, hiddenIds)) _notify();
    unawaited(_tick());
  }

  @override
  Future<void> _load() async {
    final json = await _read();
    if (json == null || _disposed) return;
    final server = json['server'];
    final pending = json['pending'];
    if (server is List) _server = {for (final id in server) '$id'};
    if (pending is Map) {
      for (final entry in pending.entries) {
        // Changes made here before the file was read win.
        _pending.putIfAbsent('${entry.key}', () => entry.value == true);
      }
    }
    _notify();
  }

  @override
  Future<void> _flush() async {
    for (final entry in _pending.entries.toList()) {
      if (_disposed) return;
      try {
        await _set(entry.key, entry.value).timeout(callTimeout);
      } on FormatException {
        // Not a tile id the server could ever take.
        _pending.remove(entry.key);
        _save();
        continue;
      } on CircleException {
        // No longer an editor: what waits will never be taken.
        _canChange = false;
        _pending.clear();
        _save();
        _notify();
        return;
      }
      if (entry.value) {
        _server.add(entry.key);
      } else {
        _server.remove(entry.key);
      }
      // A newer change to the same word still waits.
      if (_pending[entry.key] == entry.value) _pending.remove(entry.key);
      _save();
    }
  }

  @override
  Future<void> _refresh() async {
    final ids = await _list().timeout(callTimeout);
    if (_disposed) return;
    final before = hiddenIds;
    _server = ids.toSet();
    _save();
    if (!setEquals(before, hiddenIds)) _notify();
  }

  @override
  Map<String, Object?> _toJson() => {
    'server': _server.toList(),
    'pending': _pending,
  };

  @override
  void dispose() {
    _stop();
    super.dispose();
  }
}

/// [HomeLanguages] over the server's home language endpoint.
class ServerHomeLanguages extends HomeLanguages with _Cached {
  ServerHomeLanguages({
    required this._getLanguage,
    required this._setLanguage,
    required this._listWords,
    required this._setWord,
    required this._storage,
    this._sync,
    this._canChange = true,
    this.refreshEvery = const Duration(seconds: 30),
    this.callTimeout = const Duration(seconds: 20),
  }) {
    _start();
  }

  /// The second language the app uses for [circleSpace], kept under
  /// [userId].
  factory ServerHomeLanguages.forClient(
    Client client, {
    required UuidValue circleSpace,
    required String userId,
    required CircleRole role,
    SyncStatus? sync,
  }) => ServerHomeLanguages(
    getLanguage: () async {
      final got = await client.homeLanguage.getLanguage(circleSpace);
      return got == null ? null : HomeLanguage(code: got.code, name: got.name);
    },
    setLanguage: (language) => client.homeLanguage.setLanguage(
      circleSpace,
      language == null
          ? null
          : SecondLanguage(code: language.code, name: language.name),
    ),
    listWords: (code) async => [
      for (final word in await client.homeLanguage.listTranslations(
        circleSpace,
        code,
      ))
        WordInLanguage(
          tileId: word.tileId.uuid,
          label: word.label,
          speech: word.speech,
        ),
    ],
    setWord: (code, word) => client.homeLanguage.setTranslation(
      circleSpace,
      WordTranslation(
        tileId: UuidValue.withValidation(word.tileId),
        languageCode: code,
        label: word.label,
        speech: word.speech,
      ),
    ),
    storage: DeviceWordSettingsStorage(
      userId: userId,
      circleId: circleSpace.uuid,
    ),
    sync: sync,
    canChange: role != CircleRole.partner,
  );

  final Future<HomeLanguage?> Function() _getLanguage;
  final Future<void> Function(HomeLanguage? language) _setLanguage;
  final Future<List<WordInLanguage>> Function(String code) _listWords;
  final Future<void> Function(String code, WordInLanguage word) _setWord;
  @override
  final WordSettingsStorage _storage;
  @override
  final SyncStatus? _sync;
  bool _canChange;

  @override
  final Duration refreshEvery;
  @override
  final Duration callTimeout;

  /// As the server last said.
  HomeLanguage? _serverLanguage;

  /// Words by language code, then tile id, as the server last said.
  final Map<String, Map<String, WordInLanguage>> _serverWords = {};

  /// Changes made here the server has not confirmed, oldest first.
  final List<_Change> _pending = [];

  @override
  String get _key => 'language.json';

  @override
  bool get canChange => _canChange;

  /// Changes waiting for the server.
  @visibleForTesting
  int get pendingCount => _pending.length;

  @override
  HomeLanguage? get language {
    for (final change in _pending.reversed) {
      if (change.isLanguage) return change.language;
    }
    return _serverLanguage;
  }

  @override
  WordInLanguage? wordFor(String tileId) {
    final code = language?.code;
    if (code == null) return null;
    for (final change in _pending.reversed) {
      final word = change.word;
      if (word != null && change.code == code && word.tileId == tileId) {
        return word.label.trim().isEmpty ? null : word;
      }
    }
    return _serverWords[code]?[tileId];
  }

  @override
  Future<void> setLanguage(HomeLanguage? language) async {
    if (!_canChange) throw StateError('Only an editor can set the language.');
    if (this.language == language) return;
    _pending.add(_Change.language(language));
    _save();
    _notify();
    unawaited(_tick());
  }

  @override
  Future<void> setWord(
    String tileId, {
    required String label,
    String? speech,
  }) async {
    final code = language?.code;
    if (!_canChange || code == null) {
      throw StateError('Choose a language first.');
    }
    final said = speech?.trim();
    _pending.add(
      _Change.word(
        code,
        WordInLanguage(
          tileId: tileId,
          label: label.trim(),
          speech: (said == null || said.isEmpty) ? null : said,
        ),
      ),
    );
    _save();
    _notify();
    unawaited(_tick());
  }

  @override
  Future<void> _load() async {
    final json = await _read();
    if (json == null || _disposed) return;
    final language = json['language'];
    if (language is Map) _serverLanguage = _languageFrom(language);
    final words = json['words'];
    if (words is Map) {
      for (final byCode in words.entries) {
        final tiles = byCode.value;
        if (tiles is! Map) continue;
        _serverWords['${byCode.key}'] = {
          for (final tile in tiles.entries)
            if (tile.value is Map)
              '${tile.key}': _wordFrom('${tile.key}', tile.value as Map),
        };
      }
    }
    final pending = json['pending'];
    if (pending is List) {
      _pending.insertAll(0, [
        for (final change in pending)
          if (change is Map) ?_Change.fromJson(change),
      ]);
    }
    _notify();
  }

  @override
  Future<void> _flush() async {
    while (_pending.isNotEmpty && !_disposed) {
      final change = _pending.first;
      try {
        final word = change.word;
        if (word != null) {
          await _setWord(change.code!, word).timeout(callTimeout);
          final words = _serverWords.putIfAbsent(change.code!, () => {});
          if (word.label.trim().isEmpty) {
            words.remove(word.tileId);
          } else {
            words[word.tileId] = word;
          }
        } else {
          await _setLanguage(change.language).timeout(callTimeout);
          _serverLanguage = change.language;
        }
      } on CircleException {
        _canChange = false;
        _pending.clear();
        _save();
        _notify();
        return;
      } on WordSettingsException {
        // The server will never take this one.
      }
      _pending.remove(change);
      _save();
    }
  }

  @override
  Future<void> _refresh() async {
    final language = await _getLanguage().timeout(callTimeout);
    if (_disposed) return;
    final words = language == null
        ? null
        : await _listWords(language.code).timeout(callTimeout);
    if (_disposed) return;
    _serverLanguage = language;
    if (language != null && words != null) {
      _serverWords[language.code] = {
        for (final word in words) word.tileId: word,
      };
    }
    _save();
    _notify();
  }

  @override
  Map<String, Object?> _toJson() => {
    'language': _languageJson(_serverLanguage),
    'words': {
      for (final byCode in _serverWords.entries)
        byCode.key: {
          for (final word in byCode.value.values)
            word.tileId: {'label': word.label, 'speech': word.speech},
        },
    },
    'pending': [for (final change in _pending) change.toJson()],
  };

  @override
  void dispose() {
    _stop();
    super.dispose();
  }
}

Map<String, Object?>? _languageJson(HomeLanguage? language) =>
    language == null ? null : {'code': language.code, 'name': language.name};

HomeLanguage? _languageFrom(Map<Object?, Object?> json) {
  final code = json['code'];
  final name = json['name'];
  if (code is! String || name is! String) return null;
  return HomeLanguage(code: code, name: name);
}

WordInLanguage _wordFrom(String tileId, Map<Object?, Object?> json) =>
    WordInLanguage(
      tileId: tileId,
      label: '${json['label'] ?? ''}',
      speech: json['speech'] is String ? json['speech'] as String : null,
    );

/// One change waiting for the server: the language, or one word in [code].
class _Change {
  _Change.language(this.language) : isLanguage = true, code = null, word = null;
  _Change.word(this.code, this.word) : isLanguage = false, language = null;

  final bool isLanguage;
  final HomeLanguage? language;
  final String? code;
  final WordInLanguage? word;

  static _Change? fromJson(Map<Object?, Object?> json) {
    if (json['kind'] == 'language') {
      final language = json['language'];
      return _Change.language(language is Map ? _languageFrom(language) : null);
    }
    final code = json['code'];
    final tile = json['tile'];
    if (json['kind'] != 'word' || code is! String || tile is! String) {
      return null;
    }
    return _Change.word(code, _wordFrom(tile, json));
  }

  Map<String, Object?> toJson() => isLanguage
      ? {'kind': 'language', 'language': _languageJson(language)}
      : {
          'kind': 'word',
          'code': code,
          'tile': word!.tileId,
          'label': word!.label,
          'speech': word!.speech,
        };
}
