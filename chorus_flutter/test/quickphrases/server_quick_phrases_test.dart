// The quick phrases a device keeps for use offline, and its own word
// counts.
import 'dart:convert';

import 'package:chorus_flutter/src/quickphrases/server_quick_phrases.dart';
import 'package:chorus_shared/chorus_shared.dart' show defaultQuickPhrases;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, String> disk;
  Future<String?> read(String name) async => disk[name];
  Future<void> write(String name, String text) async => disk[name] = text;

  setUp(() => disk = {});

  ServerQuickPhrases book({
    bool canEdit = true,
    Future<List<String>> Function()? fetch,
    Future<List<String>> Function(List<String>)? push,
  }) => ServerQuickPhrases(
    circleId: 'c1',
    canEdit: canEdit,
    fetch: fetch ?? () async => throw StateError('offline'),
    push: push ?? (p) async => throw StateError('offline'),
    read: read,
    write: write,
  );

  group('ServerQuickPhrases', () {
    test('shows the defaults while nothing is kept', () async {
      final phrases = book();
      await pumpEventQueue();
      expect(phrases.phrases, defaultQuickPhrases);
      await phrases.refresh();
      expect(phrases.phrases, defaultQuickPhrases, reason: 'offline');
    });

    test("keeps the server's list on the device for next time", () async {
      final online = book(fetch: () async => ['Swing', 'Snack']);
      await online.refresh();
      expect(online.phrases, ['Swing', 'Snack']);
      await pumpEventQueue();
      expect(jsonDecode(disk['chorus_quick_phrases_c1']!), ['Swing', 'Snack']);

      // Offline next time: what the device kept shows.
      final offline = book();
      await pumpEventQueue();
      expect(offline.phrases, ['Swing', 'Snack']);
    });

    test('saves through the server and keeps what it kept', () async {
      List<String>? sent;
      final phrases = book(
        push: (p) async {
          sent = p;
          return ['Stop', 'More'];
        },
      );
      var told = 0;
      phrases.addListener(() => told++);
      await phrases.save(['Stop', 'More', '']);
      expect(sent, ['Stop', 'More', '']);
      expect(phrases.phrases, ['Stop', 'More']);
      expect(told, greaterThan(0));
    });

    test('a failed save throws and changes nothing', () async {
      final phrases = book();
      await expectLater(phrases.save(['Mine']), throwsA(isA<StateError>()));
      expect(phrases.phrases, defaultQuickPhrases);
    });

    test('a read-only partner cannot save', () async {
      var calls = 0;
      final phrases = book(
        canEdit: false,
        push: (p) async {
          calls++;
          return p;
        },
      );
      expect(phrases.canEdit, isFalse);
      await expectLater(phrases.save(['Mine']), throwsA(isA<StateError>()));
      expect(calls, 0);
    });

    test('a broken copy on the device is ignored', () async {
      disk['chorus_quick_phrases_c1'] = 'not json';
      final phrases = book();
      await pumpEventQueue();
      expect(phrases.phrases, defaultQuickPhrases);
    });
  });

  group('DeviceWordCounts', () {
    test('counts words and keeps them on the device', () async {
      await (() async {
        final counts = DeviceWordCounts(
          circleId: 'c1',
          read: read,
          write: write,
        );
        await pumpEventQueue();
        counts.noteSaid('I want juice');
        counts.noteSaid('juice');
        expect(counts.counts, {'i': 1, 'want': 1, 'juice': 2});
      })();
      // Saved a little later, in one write.
      await Future<void>.delayed(const Duration(seconds: 3));
      expect(jsonDecode(disk['chorus_word_counts_c1']!), {
        'i': 1,
        'want': 1,
        'juice': 2,
      });

      final again = DeviceWordCounts(circleId: 'c1', read: read, write: write);
      await pumpEventQueue();
      expect(again.counts['juice'], 2);
    });
  });
}
