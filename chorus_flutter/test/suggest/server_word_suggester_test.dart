import 'dart:async';
import 'dart:typed_data';

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_flutter/src/media/media_hash.dart';
import 'package:chorus_flutter/src/suggest/server_word_suggester.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final photo = Uint8List.fromList([1, 2, 3]);
  final shrunk = Uint8List.fromList([9, 9, 9, 9]);

  late List<(String, Uint8List)> uploads;
  late List<(String, String)> asked;
  late Object? uploadFails;
  late FutureOr<WordSuggestion> Function() answer;

  ServerWordSuggester suggester({
    SyncStatus? sync,
    Duration timeout = const Duration(seconds: 5),
  }) {
    final made = ServerWordSuggester(
      upload: (hash, bytes) async {
        final error = uploadFails;
        if (error != null) throw error;
        uploads.add((hash, bytes));
      },
      suggest: (hash, locale) async {
        asked.add((hash, locale));
        return answer();
      },
      sync: sync,
      shrink: (bytes) async => shrunk,
      locale: 'en-GB',
      timeout: timeout,
    );
    addTearDown(made.dispose);
    return made;
  }

  setUp(() {
    uploads = [];
    asked = [];
    uploadFails = null;
    answer = () => WordSuggestion(
      label: ' juice ',
      speech: 'juice',
      colorKey: 'noun',
      alternatives: ['drink', 'juice', ' ', 'cup'],
    );
  });

  test('uploads the shrunk photo under its hash, then asks about that '
      'hash', () async {
    final idea = await suggester().fromPhoto(photo);

    final hash = sha256Hex(shrunk);
    expect(uploads, [(hash, shrunk)]);
    expect(asked, [(hash, 'en-GB')]);
    expect(idea!.label, 'juice');
    // Speech that only repeats the word is left empty.
    expect(idea.speech, '');
    expect(idea.colorKey, 'noun');
    expect(idea.alternatives, ['drink', 'cup']);
  });

  test('is available only while sync is live', () async {
    final sync = FakeSyncStatus(state: SyncState.offline);
    final made = suggester(sync: sync);
    expect(made.available.value, isFalse);
    // Not available: nothing leaves the device.
    expect(await made.fromPhoto(photo), isNull);
    expect(uploads, isEmpty);

    sync.state = SyncState.live;
    expect(made.available.value, isTrue);
    sync.state = SyncState.backoff;
    expect(made.available.value, isFalse);
  });

  test('every refusal is a quiet null', () async {
    final made = suggester();
    for (final failure in [
      SuggestFailure.overBudget,
      SuggestFailure.unreadable,
      SuggestFailure.failed,
    ]) {
      answer = () => throw SuggestException(failure: failure);
      expect(await made.fromPhoto(photo), isNull, reason: '$failure');
      // Worth offering again later.
      expect(made.available.value, isTrue, reason: '$failure');
    }
  });

  test('"not set up" also withdraws the offer for good', () async {
    final sync = FakeSyncStatus();
    final made = suggester(sync: sync);
    answer = () =>
        throw SuggestException(failure: SuggestFailure.notConfigured);
    expect(await made.fromPhoto(photo), isNull);
    expect(made.available.value, isFalse);

    sync.state = SyncState.backoff;
    sync.state = SyncState.live;
    expect(made.available.value, isFalse);
  });

  test('a failed upload, a network error, a blank answer and a timeout are '
      'null too', () async {
    final made = suggester(timeout: const Duration(milliseconds: 20));

    uploadFails = StateError('offline');
    expect(await made.fromPhoto(photo), isNull);
    expect(asked, isEmpty);
    uploadFails = null;

    answer = () => throw const ServerpodClientNetworkException('down');
    expect(await made.fromPhoto(photo), isNull);

    answer = () =>
        WordSuggestion(label: ' ', speech: '', colorKey: '', alternatives: []);
    expect(await made.fromPhoto(photo), isNull);

    answer = () => Completer<WordSuggestion>().future;
    expect(await made.fromPhoto(photo), isNull);
    expect(made.available.value, isTrue);
  });
}
