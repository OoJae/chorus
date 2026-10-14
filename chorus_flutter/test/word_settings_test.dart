// Hidden words and the second language over the server (W5): kept on the
// device so the child's board works offline, sent while sync is live, and
// asked for again when sync comes back.
import 'package:chorus_client/chorus_client.dart' hide CircleRole;
import 'package:chorus_flutter/src/speech/tts_speech_service.dart';
import 'package:chorus_flutter/src/wordsettings/server_word_settings.dart';
import 'package:chorus_flutter/src/wordsettings/word_settings_storage.dart';
import 'package:chorus_ui/contracts.dart' show SyncState;
import 'package:chorus_ui/contracts_language.dart';
import 'package:chorus_ui/fakes.dart' show FakeSyncStatus;
import 'package:flutter_test/flutter_test.dart';

/// The server's hidden words, in memory.
class _HiddenServer {
  final Set<String> hidden = {};
  int sets = 0;
  bool down = false;
  bool refuse = false;

  Future<List<String>> list() async {
    if (down) throw StateError('no network');
    return hidden.toList();
  }

  Future<void> set(String tileId, bool value) async {
    if (down) throw StateError('no network');
    if (refuse) throw CircleException(failure: CircleFailure.notAllowed);
    sets++;
    value ? hidden.add(tileId) : hidden.remove(tileId);
  }
}

/// The server's second language, in memory.
class _LanguageServer {
  HomeLanguage? language;
  final Map<String, Map<String, WordInLanguage>> words = {};
  bool down = false;

  Future<HomeLanguage?> get() async {
    if (down) throw StateError('no network');
    return language;
  }

  Future<void> setLanguage(HomeLanguage? value) async {
    if (down) throw StateError('no network');
    language = value;
  }

  Future<List<WordInLanguage>> list(String code) async {
    if (down) throw StateError('no network');
    return (words[code] ?? {}).values.toList();
  }

  Future<void> setWord(String code, WordInLanguage word) async {
    if (down) throw StateError('no network');
    final byTile = words.putIfAbsent(code, () => {});
    word.label.isEmpty
        ? byTile.remove(word.tileId)
        : byTile[word.tileId] = word;
  }
}

const _yoruba = HomeLanguage(code: 'yo', name: 'Yoruba');

void main() {
  group('ServerHiddenWords', () {
    late _HiddenServer server;
    late MemoryWordSettingsStorage storage;
    late FakeSyncStatus sync;

    ServerHiddenWords open() => ServerHiddenWords(
      list: server.list,
      set: server.set,
      storage: storage,
      sync: sync,
    );

    setUp(() {
      server = _HiddenServer();
      storage = MemoryWordSettingsStorage();
      sync = FakeSyncStatus();
    });

    test('reads the server, and a hidden word is sent', () async {
      server.hidden.add('a');
      final words = open();
      addTearDown(words.dispose);
      await words.ready;
      expect(words.hiddenIds, {'a'});

      await words.setHidden('b', true);
      expect(words.hiddenIds, {'a', 'b'});
      await words.tick();
      expect(server.hidden, {'a', 'b'});
      expect(words.pending, isEmpty);
    });

    test('offline a change shows at once, is kept, and is sent when sync is '
        'back', () async {
      sync.state = SyncState.offline;
      final words = open();
      await words.ready;
      await words.setHidden('a', true);
      expect(words.hiddenIds, {'a'});
      expect(server.sets, 0);
      words.dispose();

      // A restart with no network: still hidden, from this device.
      final again = open();
      addTearDown(again.dispose);
      await again.ready;
      expect(again.hiddenIds, {'a'});

      sync.state = SyncState.live;
      await Future<void>.delayed(Duration.zero);
      await again.tick();
      expect(server.hidden, {'a'});
      expect(again.pending, isEmpty);
    });

    test('a failed send is kept for the next try', () async {
      final words = open();
      addTearDown(words.dispose);
      await words.ready;
      server.down = true;
      await words.setHidden('a', true);
      await words.tick();
      expect(words.pending, {'a': true});
      server.down = false;
      await words.tick();
      expect(server.hidden, {'a'});
    });

    test('a word shown again elsewhere comes back here', () async {
      server.hidden.add('a');
      final words = open();
      addTearDown(words.dispose);
      await words.ready;
      server.hidden.clear();
      await words.tick();
      expect(words.hiddenIds, isEmpty);
    });

    test('a partner may not hide, and a refused change is dropped', () async {
      final partner = ServerHiddenWords(
        list: server.list,
        set: server.set,
        storage: storage,
        sync: sync,
        canChange: false,
      );
      addTearDown(partner.dispose);
      expect(() => partner.setHidden('a', true), throwsStateError);

      server.refuse = true;
      final words = open();
      addTearDown(words.dispose);
      await words.ready;
      await words.setHidden('a', true);
      await words.tick();
      expect(words.canChange, isFalse);
      expect(words.hiddenIds, isEmpty);
    });
  });

  group('ServerHomeLanguages', () {
    late _LanguageServer server;
    late MemoryWordSettingsStorage storage;
    late FakeSyncStatus sync;

    ServerHomeLanguages open() => ServerHomeLanguages(
      getLanguage: server.get,
      setLanguage: server.setLanguage,
      listWords: server.list,
      setWord: server.setWord,
      storage: storage,
      sync: sync,
    );

    setUp(() {
      server = _LanguageServer();
      storage = MemoryWordSettingsStorage();
      sync = FakeSyncStatus();
    });

    test('reads the language and its words', () async {
      server.language = _yoruba;
      server.words['yo'] = {
        'a': const WordInLanguage(tileId: 'a', label: 'omi'),
      };
      final languages = open();
      addTearDown(languages.dispose);
      await languages.ready;
      expect(languages.language, _yoruba);
      expect(languages.wordFor('a')?.label, 'omi');
      expect(languages.wordFor('b'), isNull);
    });

    test('offline a language and a word show at once, survive a restart, and '
        'are sent in order when sync is back', () async {
      sync.state = SyncState.offline;
      final languages = open();
      await languages.ready;
      await languages.setLanguage(_yoruba);
      await languages.setWord('a', label: 'omi', speech: 'omi o');
      expect(languages.language, _yoruba);
      expect(languages.wordFor('a')?.spokenText, 'omi o');
      languages.dispose();

      final again = open();
      addTearDown(again.dispose);
      await again.ready;
      expect(again.wordFor('a')?.label, 'omi');
      expect(again.pendingCount, 2);

      sync.state = SyncState.live;
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      await again.tick();
      expect(server.language, _yoruba);
      expect(server.words['yo']?['a']?.label, 'omi');
      expect(again.pendingCount, 0);
      expect(again.wordFor('a')?.label, 'omi');
    });

    test('an empty word removes it', () async {
      server.language = _yoruba;
      server.words['yo'] = {
        'a': const WordInLanguage(tileId: 'a', label: 'omi'),
      };
      final languages = open();
      addTearDown(languages.dispose);
      await languages.ready;
      await languages.setWord('a', label: '');
      expect(languages.wordFor('a'), isNull);
      await languages.tick();
      expect(server.words['yo'], isEmpty);
    });

    test('a word needs a language first', () async {
      final languages = open();
      addTearDown(languages.dispose);
      await languages.ready;
      expect(() => languages.setWord('a', label: 'omi'), throwsStateError);
    });
  });

  group('TtsSpeechService.voiceForLanguage', () {
    final voices = <Object?>[
      {'name': 'Samantha', 'locale': 'en-US'},
      {'name': 'Google español', 'locale': 'es-US'},
      {'name': 'Monica', 'locale': 'es-ES'},
      {'name': 'Thomas', 'locale': 'fr-FR', 'features': 'notInstalled'},
    ];

    test('picks a voice of the language on the device', () {
      expect(
        TtsSpeechService.voiceForLanguage(voices, 'es-ES', const {}),
        {'name': 'Monica', 'locale': 'es-ES'},
      );
      expect(
        TtsSpeechService.voiceForLanguage(voices, 'es', const {})?['locale'],
        'es-US',
      );
    });

    test('never an online voice or one not downloaded, and none for a '
        'language the device lacks', () {
      expect(
        TtsSpeechService.voiceForLanguage(voices, 'es', {'Google español'}),
        {'name': 'Monica', 'locale': 'es-ES'},
      );
      expect(TtsSpeechService.voiceForLanguage(voices, 'fr', const {}), isNull);
      expect(TtsSpeechService.voiceForLanguage(voices, 'yo', const {}), isNull);
    });
  });
}
