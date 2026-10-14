// This device's settings kept on the device, and the circle's voice kept
// here and sent to the circle.
import 'dart:convert';

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_flutter/src/device/local_device_settings.dart';
import 'package:chorus_flutter/src/speech/chosen_voice.dart';
import 'package:chorus_flutter/src/voice/server_voice_choice.dart';
import 'package:chorus_ui/contracts_device.dart';
import 'package:chorus_ui/contracts_voice.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalDeviceSettings', () {
    test('reads what was kept, and keeps what is saved', () async {
      final files = <String, String>{
        deviceSettingsFile: jsonEncode(
          const DeviceSettings(keyguard: true).toJson(),
        ),
      };
      final store = LocalDeviceSettings(
        read: (name) async => files[name],
        write: (name, text) async => files[name] = text,
      );
      await store.loaded;
      expect(store.settings.keyguard, isTrue);
      await store.save(
        store.settings.copyWith(holdTime: const Duration(seconds: 1)),
      );
      final again = LocalDeviceSettings(read: (name) async => files[name]);
      await again.loaded;
      expect(again.settings.holdTime, const Duration(seconds: 1));
      expect(again.settings.keyguard, isTrue);
    });

    test('storage that refuses gives the defaults and never throws', () async {
      final store = LocalDeviceSettings(
        read: (_) async => throw StateError('blocked'),
        write: (_, _) async => throw StateError('blocked'),
      );
      await store.loaded;
      expect(store.settings, const DeviceSettings());
      await store.save(const DeviceSettings(keyguard: true));
      expect(store.settings.keyguard, isTrue);
    });
  });

  group('ServerVoiceChoice', () {
    late Map<String, String> files;
    late List<VoicePrefs> sent;
    late VoiceSetting onServer;
    late bool online;

    setUp(() {
      files = {};
      sent = [];
      online = true;
      onServer = VoiceSetting(rate: 0.9, pitch: 1.0);
    });

    ServerVoiceChoice make({bool canChange = true}) => ServerVoiceChoice(
      canChange: canChange,
      fetch: () async {
        if (!online) throw Exception('offline');
        return onServer;
      },
      send: (prefs) async {
        if (!online) throw Exception('offline');
        sent.add(prefs);
        onServer = VoiceSetting(
          voiceName: prefs.voiceName,
          rate: prefs.rate,
          pitch: prefs.pitch,
        );
        return onServer;
      },
      speech: FakeSpeech(),
      cacheName: 'voice.json',
      read: (name) async => files[name],
      write: (name, text) async => files[name] = text,
    );

    test('takes the circle voice from the server and keeps it here', () async {
      onServer = VoiceSetting(voiceName: 'Samantha', rate: 1.2, pitch: 0.8);
      final voice = make();
      await voice.ready;
      expect(voice.prefs.voiceName, 'Samantha');
      expect(voice.prefs.rate, 1.2);
      online = false;
      final later = make();
      await later.ready;
      expect(later.prefs.pitch, 0.8);
    });

    test('a choice made offline is used at once and sent later', () async {
      online = false;
      final voice = make();
      await voice.ready;
      await voice.choose(const VoicePrefs(rate: 0.7));
      expect(voice.prefs.rate, 0.7);
      expect(sent, isEmpty);
      online = true;
      final later = make();
      await later.ready;
      expect(sent.single.rate, 0.7);
      expect(later.prefs.rate, 0.7);
    });

    test('a read-only partner cannot change it', () async {
      final voice = make(canChange: false);
      await voice.ready;
      expect(() => voice.choose(const VoicePrefs(rate: 1.2)), throwsStateError);
    });

    test('Try it speaks the words', () async {
      final speech = FakeSpeech();
      final voice = ServerVoiceChoice(
        canChange: true,
        fetch: () async => onServer,
        send: (_) async => onServer,
        speech: speech,
        cacheName: 'voice.json',
        read: (_) async => null,
        write: (_, _) async {},
      );
      await voice.ready;
      await voice.tryIt('I want juice');
      expect(speech.spoken, ['I want juice']);
    });
  });

  group('ChosenVoice', () {
    test('speed is a share of each engine\'s normal', () {
      expect(ChosenVoice.engineRate(0.9, web: true), 0.9);
      expect(ChosenVoice.engineRate(0.9, web: false), closeTo(0.45, 1e-9));
    });
  });
}
