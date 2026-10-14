// Several ideas for one photo: the shrunk photo is uploaded once, the ideas
// come back as plain word ideas, and every failure is an empty list.
import 'dart:typed_data';

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_flutter/src/media/media_hash.dart';
import 'package:chorus_flutter/src/suggest/server_word_suggester.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final photo = Uint8List.fromList([1, 2, 3]);
  final shrunk = Uint8List.fromList([9, 9, 9, 9]);

  ServerWordSuggester make(
    Future<List<WordSuggestion>> Function(String hash, String locale) ideas, {
    List<String>? uploads,
    Duration timeout = const Duration(seconds: 5),
  }) {
    final made = ServerWordSuggester(
      upload: (hash, bytes) async => uploads?.add(hash),
      suggest: (hash, locale) async => throw StateError('one word'),
      ideas: ideas,
      shrink: (bytes) async => shrunk,
      timeout: timeout,
    );
    addTearDown(made.dispose);
    return made;
  }

  WordSuggestion w(String label, String key) => WordSuggestion(
    label: label,
    speech: label,
    colorKey: key,
    alternatives: [],
  );

  test('uploads under the hash and returns the ideas', () async {
    final uploads = <String>[];
    final asked = <String>[];
    final ideas = await make((hash, locale) async {
      asked.add(hash);
      return [w(' swing ', 'noun'), w('push', 'verb'), w('', 'noun')];
    }, uploads: uploads).ideasFromPhoto(photo);
    expect(uploads, [sha256Hex(shrunk)]);
    expect(asked, [sha256Hex(shrunk)]);
    expect(ideas.map((i) => (i.label, i.colorKey)), [
      ('swing', 'noun'),
      ('push', 'verb'),
    ]);
  });

  test('a failure or a timeout is an empty list', () async {
    expect(
      await make(
        (h, l) async => throw StateError('down'),
      ).ideasFromPhoto(photo),
      isEmpty,
    );
    expect(
      await make(
        (h, l) =>
            Future.delayed(const Duration(seconds: 1), () => [w('a', 'noun')]),
        timeout: const Duration(milliseconds: 10),
      ).ideasFromPhoto(photo),
      isEmpty,
    );
  });

  test('not set up turns the offer off', () async {
    final s = make(
      (h, l) async =>
          throw SuggestException(failure: SuggestFailure.notConfigured),
    );
    expect(await s.ideasFromPhoto(photo), isEmpty);
    expect(s.available.value, isFalse);
  });
}
