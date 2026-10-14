import 'dart:async';

import 'package:chorus_flutter/src/speech/tts_speech_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The platform half of flutter_tts, answering on its method channel.
///
/// As a browser it follows flutter_tts_web.dart at 4.2.5: a stop only asks
/// the browser to cancel, the plugin hears that the word has ended on a
/// later turn, and until then it drops any word handed to it. As a phone it
/// follows the Android plugin, where a stop frees the engine at once.
class FakeEngine {
  FakeEngine(this._messenger, {this.browser = true}) {
    _messenger.setMockMethodCallHandler(_channel, _handle);
  }

  static const MethodChannel _channel = MethodChannel('flutter_tts');

  /// How long the engine takes to report that a word started or was cut
  /// off. An odd number, so a report never falls due together with one of
  /// the service's ten-millisecond waits.
  static const Duration lag = Duration(milliseconds: 23);

  final TestDefaultBinaryMessenger _messenger;
  final bool browser;

  /// Every call the service made, oldest first, as 'method argument'.
  final List<String> calls = [];

  /// The words that were really said, and the voice each was said with.
  final List<String> said = [];
  final List<String?> saidWith = [];

  /// What getVoices answers. An error is thrown instead.
  Object? voices = const <Object?>[];

  /// When set, getVoices answers only once it completes.
  Completer<void>? voicesGate;

  /// When false, the engine never reports that a cut-off word has stopped.
  bool reportsCancel = true;

  /// The voice and language the next word is said with.
  String? voice;
  String? spokenLanguage;

  /// The plugin's own idea of whether a word is being said.
  bool _busy = false;
  bool _cancelling = false;
  Completer<Object?>? _done;

  void dispose() => _messenger.setMockMethodCallHandler(_channel, null);

  int count(String method) =>
      calls.where((c) => c == method || c.startsWith('$method ')).length;

  /// The word being said comes to its end.
  void finish() {
    _busy = false;
    _done?.complete(1);
    _done = null;
    _send('speak.onComplete');
  }

  Future<Object?> _handle(MethodCall call) async {
    final argument = call.arguments;
    calls.add(argument == null ? call.method : '${call.method} $argument');
    switch (call.method) {
      case 'speak':
        return _speak(argument is Map ? '${argument['text']}' : '$argument');
      case 'stop':
        _stop();
      case 'getVoices':
        await voicesGate?.future;
        final answer = voices;
        if (answer is Error) throw answer;
        return answer;
      case 'setLanguage':
        _setLanguage('$argument');
      case 'setVoice':
        _setVoice(argument as Map);
    }
    return 1;
  }

  Future<Object?> _speak(String text) {
    if (_busy) {
      // The phone answers "not spoken". The browser says nothing at all,
      // and only answers when the word it is busy with ends.
      if (!browser) return Future.value(0);
      return (_done = Completer<Object?>()).future;
    }
    final done = _done = Completer<Object?>();
    said.add(text);
    saidWith.add(voice);
    if (browser) {
      // The plugin counts the word as playing only once the browser says
      // it has started.
      Timer(lag, () {
        _busy = true;
        _send('speak.onStart');
      });
    } else {
      _busy = true;
      Timer(lag, () => _send('speak.onStart'));
    }
    return done.future;
  }

  void _stop() {
    if (!browser) {
      if (!_busy) return;
      _busy = false;
      Timer(lag, () => _send('speak.onCancel'));
      return;
    }
    // Before the word has started the plugin thinks nothing is playing and
    // asks the browser for nothing.
    if (!_busy || _cancelling || !reportsCancel) return;
    _cancelling = true;
    Timer(lag, () {
      _cancelling = false;
      _busy = false;
      // As the plugin does: the cut-off word's speak call is never answered.
      _done = null;
      _send('speak.onError', 'interrupted');
    });
  }

  /// The plugin takes the first voice listed for the language, and does
  /// nothing when there is none.
  void _setLanguage(String language) {
    if (!browser) return;
    for (final listed in _listed) {
      final locale = '${listed['locale']}';
      if (!locale.toLowerCase().startsWith(language.toLowerCase())) continue;
      voice = '${listed['name']}';
      spokenLanguage = locale;
      return;
    }
  }

  /// The plugin takes a voice only when name and locale both match one it
  /// lists, and leaves the language alone.
  void _setVoice(Map<Object?, Object?> wanted) {
    for (final listed in _listed) {
      if (listed['name'] == wanted['name'] &&
          listed['locale'] == wanted['locale']) {
        voice = '${listed['name']}';
      }
    }
  }

  Iterable<Map<Object?, Object?>> get _listed {
    final all = voices;
    return all is List ? all.whereType<Map<Object?, Object?>>() : const [];
  }

  void _send(String method, [Object? argument]) {
    unawaited(
      _messenger.handlePlatformMessage(
        _channel.name,
        _channel.codec.encodeMethodCall(MethodCall(method, argument)),
        null,
      ),
    );
  }
}

Map<String, String> _voice(String name, String locale) => {
  'name': name,
  'locale': locale,
};

/// A phone's voice as the Android plugin lists it.
Map<String, String> _phoneVoice({
  String locale = 'en-US',
  bool needsNetwork = false,
  String features = '',
}) => {
  'name': 'en-us-x-sfg-${needsNetwork ? 'network' : 'local'}',
  'locale': locale,
  'network_required': needsNetwork ? '1' : '0',
  'features': features,
};

/// What Chrome lists on a Mac whose own voice is Swedish.
final List<Map<String, String>> _swedishMac = [
  _voice('Alva', 'sv-SE'),
  _voice('Albert', 'en-US'),
  _voice('Alice', 'it-IT'),
  _voice('Daniel', 'en-GB'),
  _voice('Samantha', 'en-US'),
  _voice('Google US English', 'en-US'),
];

const Duration _aMoment = Duration(milliseconds: 100);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  FakeEngine engineFor(WidgetTester tester, {bool browser = true}) {
    final engine = FakeEngine(
      tester.binding.defaultBinaryMessenger,
      browser: browser,
    );
    addTearDown(engine.dispose);
    return engine;
  }

  test('with no speech engine every call is quiet', () async {
    final speech = TtsSpeechService();

    await speech.warmUp();
    await speech.speak('more');
    await speech.stop();
    // A second warm-up is allowed and tries again.
    await speech.warmUp();

    expect(speech.speaking.value, isFalse);
    expect(speech.offlineVoiceReady.value, isFalse);
  });

  test('with no speech engine a browser is quiet too', () async {
    final speech = TtsSpeechService(web: true);

    await speech.speak('more');
    await speech.stop();

    expect(speech.speaking.value, isFalse);
    expect(speech.offlineVoiceReady.value, isFalse);
  });

  group('in a browser', () {
    testWidgets('a word tapped while another is sounding is spoken', (
      tester,
    ) async {
      final engine = engineFor(tester);
      final speech = TtsSpeechService(web: true);
      await speech.warmUp();

      unawaited(speech.speak('I'));
      await tester.pump(_aMoment);
      expect(speech.speaking.value, isTrue);

      unawaited(speech.speak('want'));
      await tester.pump(_aMoment);

      expect(engine.said, ['I', 'want']);
      expect(speech.speaking.value, isTrue);

      engine.finish();
      await tester.pump();
      expect(speech.speaking.value, isFalse);
    });

    testWidgets('three quick taps end with the third word spoken', (
      tester,
    ) async {
      final engine = engineFor(tester);
      final speech = TtsSpeechService(web: true);
      await speech.warmUp();

      for (final word in ['I', 'want', 'more']) {
        unawaited(speech.speak(word));
        await tester.pump(const Duration(milliseconds: 250));
      }

      expect(engine.said, ['I', 'want', 'more']);
    });

    testWidgets('three taps a tenth of a second apart are all spoken', (
      tester,
    ) async {
      final engine = engineFor(tester);
      final speech = TtsSpeechService(web: true);
      await speech.warmUp();

      for (final word in ['I', 'want', 'more']) {
        unawaited(speech.speak(word));
        await tester.pump(_aMoment);
      }

      expect(engine.said, ['I', 'want', 'more']);
    });

    testWidgets('a word tapped while nothing sounds is spoken at once', (
      tester,
    ) async {
      final engine = engineFor(tester);
      final speech = TtsSpeechService(web: true);
      await speech.warmUp();

      unawaited(speech.speak('I'));
      // No time passes: the word goes out in the same turn as the tap.
      await tester.pump();
      expect(engine.said, ['I']);

      await tester.pump(_aMoment);
      engine.finish();
      await tester.pump();
      unawaited(speech.speak('want'));
      await tester.pump();
      expect(engine.said, ['I', 'want']);

      await tester.pump(_aMoment);
    });

    testWidgets('the sentence asked for while a word sounds is spoken', (
      tester,
    ) async {
      final engine = engineFor(tester);
      final speech = TtsSpeechService(web: true);
      await speech.warmUp();

      unawaited(speech.speak('more'));
      await tester.pump(_aMoment);
      unawaited(speech.speak('I want more'));
      await tester.pump(_aMoment);

      expect(engine.said, ['more', 'I want more']);
    });

    testWidgets('a word overtaken while it waits is never spoken', (
      tester,
    ) async {
      // With the voice chosen on the first word, only the wait itself can
      // hold the later ones back.
      final engine = engineFor(tester)..voices = _swedishMac;
      final speech = TtsSpeechService(web: true);
      await speech.warmUp();

      unawaited(speech.speak('I'));
      await tester.pump(_aMoment);
      unawaited(speech.speak('want'));
      // "want" is still waiting for "I" to go quiet.
      await tester.pump(const Duration(milliseconds: 5));
      unawaited(speech.speak('more'));
      await tester.pump(_aMoment);

      expect(engine.said, ['I', 'more']);
      expect(engine.count('speak'), 2);
    });

    testWidgets('a stop while a word waits leaves it unspoken', (tester) async {
      final engine = engineFor(tester)..voices = _swedishMac;
      final speech = TtsSpeechService(web: true);
      await speech.warmUp();

      unawaited(speech.speak('I'));
      await tester.pump(_aMoment);
      unawaited(speech.speak('want'));
      await tester.pump(const Duration(milliseconds: 5));
      await speech.stop();
      await tester.pump(_aMoment);

      expect(engine.said, ['I']);
      expect(engine.count('speak'), 1);
      expect(speech.speaking.value, isFalse);
    });

    testWidgets('a word overtaken while the voice is chosen is never spoken', (
      tester,
    ) async {
      final engine = engineFor(tester);
      final speech = TtsSpeechService(web: true);
      await speech.warmUp();
      engine
        ..voices = _swedishMac
        ..voicesGate = Completer<void>();

      unawaited(speech.speak('I'));
      await tester.pump();
      // "I" is still waiting for the voice list when "want" is tapped.
      unawaited(speech.speak('want'));
      await tester.pump();
      engine.voicesGate!.complete();
      await tester.pump(_aMoment);

      expect(engine.said, ['want']);
      expect(engine.saidWith, ['Samantha']);
    });

    testWidgets('a word right after a stop is spoken', (tester) async {
      final engine = engineFor(tester);
      final speech = TtsSpeechService(web: true);
      await speech.warmUp();

      unawaited(speech.speak('I'));
      await tester.pump(_aMoment);
      // The stop clears the flag the screens see before the engine is quiet.
      await speech.stop();
      expect(speech.speaking.value, isFalse);
      unawaited(speech.speak('want'));
      await tester.pump(_aMoment);

      expect(engine.said, ['I', 'want']);
    });

    testWidgets('an engine that never reports holds a word 300 ms at most', (
      tester,
    ) async {
      final engine = engineFor(tester)..reportsCancel = false;
      final speech = TtsSpeechService(web: true);
      await speech.warmUp();

      unawaited(speech.speak('I'));
      await tester.pump(_aMoment);
      unawaited(speech.speak('want'));
      await tester.pump(const Duration(milliseconds: 295));
      expect(engine.calls, isNot(contains('speak want')));

      await tester.pump(const Duration(milliseconds: 10));
      expect(engine.calls.last, 'speak want');
    });

    testWidgets('voices that load late still give an everyday English voice', (
      tester,
    ) async {
      final engine = engineFor(tester);
      final speech = TtsSpeechService(web: true);
      // Chrome and Edge list nothing the first time they are asked.
      await speech.warmUp();
      expect(engine.voice, isNull);
      engine.voices = _swedishMac;

      unawaited(speech.speak('want'));
      await tester.pump(_aMoment);

      expect(engine.saidWith, ['Samantha']);
      expect(engine.spokenLanguage, 'en-US');
    });

    testWidgets('the voice is chosen once', (tester) async {
      final engine = engineFor(tester)..voices = _swedishMac;
      final speech = TtsSpeechService(web: true);
      await speech.warmUp();

      for (final word in ['I', 'want']) {
        unawaited(speech.speak(word));
        await tester.pump(_aMoment);
        engine.finish();
        await tester.pump();
      }

      expect(engine.saidWith, ['Samantha', 'Samantha']);
      expect(engine.count('getVoices'), 1);
      expect(engine.count('setVoice'), 1);
    });

    testWidgets('while no voices are listed each word looks again', (
      tester,
    ) async {
      final engine = engineFor(tester);
      final speech = TtsSpeechService(web: true);
      await speech.warmUp();

      unawaited(speech.speak('I'));
      await tester.pump(_aMoment);
      engine.finish();
      await tester.pump();
      engine.voices = _swedishMac;
      unawaited(speech.speak('want'));
      await tester.pump(_aMoment);

      expect(engine.said, ['I', 'want']);
      expect(engine.saidWith, [null, 'Samantha']);
    });

    testWidgets('a voice on the machine is preferred to an online one', (
      tester,
    ) async {
      final engine = engineFor(tester)
        ..voices = [
          _voice('Microsoft Bengt - Swedish (Sweden)', 'sv-SE'),
          _voice('Google US English', 'en-US'),
          _voice('Microsoft Zira - English (United States)', 'en-US'),
        ];
      final speech = TtsSpeechService(web: true);
      await speech.warmUp();

      unawaited(speech.speak('want'));
      await tester.pump(_aMoment);

      expect(engine.saidWith, ['Microsoft Zira - English (United States)']);
    });

    testWidgets('with no everyday voice the language still picks one, once', (
      tester,
    ) async {
      final engine = engineFor(tester);
      final speech = TtsSpeechService(web: true);
      await speech.warmUp();
      engine.voices = [_voice('Alva', 'sv-SE'), _voice('Albert', 'en-US')];

      for (final word in ['I', 'want']) {
        unawaited(speech.speak(word));
        await tester.pump(_aMoment);
        engine.finish();
        await tester.pump();
      }

      expect(engine.saidWith, ['Albert', 'Albert']);
      expect(engine.count('getVoices'), 1);
      expect(engine.count('setVoice'), 0);
    });

    testWidgets('an online voice is never chosen, even an everyday one', (
      tester,
    ) async {
      const google = 'Google US English';
      const aria = 'Microsoft Aria Online (Natural) - English (United States)';
      final engine = engineFor(tester)
        ..voices = [
          _voice(google, 'en-US'),
          _voice(aria, 'en-US'),
          _voice('Fred', 'en-US'),
        ];
      final speech = TtsSpeechService(
        web: true,
        onlineVoices: () => {google, aria},
      );
      await speech.warmUp();

      unawaited(speech.speak('want'));
      await tester.pump(_aMoment);

      expect(engine.saidWith, ['Fred']);
    });

    testWidgets('with only online voices for the language, an English voice '
        'on the device speaks', (tester) async {
      const google = 'Google US English';
      final engine = engineFor(tester)
        ..voices = [
          _voice('Alva', 'sv-SE'),
          _voice(google, 'en-US'),
          _voice('Daniel', 'en-GB'),
        ];
      final speech = TtsSpeechService(
        web: true,
        onlineVoices: () => {google},
      );
      await speech.warmUp();

      unawaited(speech.speak('want'));
      await tester.pump(_aMoment);

      expect(engine.saidWith, ['Daniel']);
      expect(engine.spokenLanguage, 'en-US');
    });

    testWidgets('a browser that cannot list its voices still speaks', (
      tester,
    ) async {
      final engine = engineFor(tester)..voices = StateError('no voices');
      final speech = TtsSpeechService(web: true);
      await speech.warmUp();

      unawaited(speech.speak('want'));
      await tester.pump(_aMoment);

      expect(engine.said, ['want']);
    });
  });

  group('on a phone', () {
    testWidgets('a new word follows the stop with no wait', (tester) async {
      final engine = engineFor(tester, browser: false);
      final speech = TtsSpeechService();
      await speech.warmUp();

      unawaited(speech.speak('I'));
      await tester.pump(_aMoment);
      unawaited(speech.speak('want'));
      // No time passes: the phone's engine is free as soon as it is stopped.
      await tester.pump();

      expect(engine.said, ['I', 'want']);
      // The voice is left as warm-up set it.
      expect(engine.count('setLanguage'), 1);
      expect(engine.count('getVoices'), 1);
      expect(engine.count('setVoice'), 0);

      await tester.pump(_aMoment);
    });

    testWidgets('an installed voice that needs no network is ready', (
      tester,
    ) async {
      engineFor(tester, browser: false).voices = [
        _phoneVoice(needsNetwork: true),
        _phoneVoice(features: 'networkTimeoutMs\tnetworkRetriesCount'),
      ];
      final speech = TtsSpeechService();

      await speech.warmUp();

      expect(speech.offlineVoiceReady.value, isTrue);
    });

    testWidgets('a voice that is listed but not downloaded is not ready', (
      tester,
    ) async {
      engineFor(tester, browser: false).voices = [
        _phoneVoice(features: 'notInstalled'),
        _phoneVoice(features: 'networkTimeoutMs\tnotInstalled'),
        _phoneVoice(needsNetwork: true),
      ];
      final speech = TtsSpeechService();

      await speech.warmUp();

      expect(speech.offlineVoiceReady.value, isFalse);
    });

    testWidgets('one downloaded voice among those that are not is enough', (
      tester,
    ) async {
      engineFor(tester, browser: false).voices = [
        _phoneVoice(features: 'notInstalled'),
        _phoneVoice(locale: 'sv-SE'),
        _phoneVoice(locale: 'en-GB'),
      ];
      final speech = TtsSpeechService();

      await speech.warmUp();

      expect(speech.offlineVoiceReady.value, isTrue);
    });

    testWidgets('a voice list that cannot be read is trusted', (tester) async {
      engineFor(tester, browser: false).voices = null;
      final speech = TtsSpeechService();

      await speech.warmUp();

      expect(speech.offlineVoiceReady.value, isTrue);
    });
  });
}
