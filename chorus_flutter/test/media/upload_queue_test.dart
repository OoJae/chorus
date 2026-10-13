import 'dart:convert';

import 'package:chorus_flutter/src/media/upload_queue.dart';
import 'package:flutter_test/flutter_test.dart';

/// A server that can be switched off, and records every try.
class FakeUploader {
  bool online = true;

  /// Hashes that fail even when online.
  final Set<String> broken = {};

  /// Hashes whose bytes are gone from this device.
  final Set<String> gone = {};

  /// Every try, in order, successful or not.
  final List<String> tries = [];

  /// What reached the server, in order.
  final List<String> sent = [];

  Future<UploadOutcome> send(QueuedUpload upload) async {
    tries.add(upload.hash);
    await Future<void>.delayed(Duration.zero);
    if (gone.contains(upload.hash)) return UploadOutcome.dropped;
    if (!online) throw StateError('offline');
    if (broken.contains(upload.hash)) return UploadOutcome.retryLater;
    sent.add(upload.hash);
    return UploadOutcome.sent;
  }
}

/// The saved queue, as one piece of text.
class FakeNote {
  String? text;
  int saves = 0;

  Future<String?> load() async => text;

  Future<void> save(String value) async {
    saves++;
    text = value;
  }

  List<String> get hashes => text == null
      ? const []
      : [for (final item in jsonDecode(text!) as List) item['hash'] as String];
}

/// Lets timers of [duration] and the work they start run.
Future<void> _wait([Duration duration = const Duration(milliseconds: 5)]) =>
    Future<void>.delayed(duration);

void main() {
  late FakeUploader server;
  late FakeNote note;
  late int changes;

  MediaUploadQueue queue({
    Duration retryBase = const Duration(milliseconds: 40),
    Duration retryMax = const Duration(milliseconds: 160),
  }) {
    final made = MediaUploadQueue(
      send: server.send,
      load: note.load,
      save: note.save,
      onChanged: () => changes++,
      retryBase: retryBase,
      retryMax: retryMax,
    );
    addTearDown(made.dispose);
    return made;
  }

  setUp(() {
    server = FakeUploader();
    note = FakeNote();
    changes = 0;
  });

  test('sends files in the order they were added', () async {
    final q = queue();
    await q.start();
    q.add('a', isAudio: false, bytes: 10);
    q.add('b', isAudio: true, bytes: 20);
    q.add('c', isAudio: false, bytes: 30);
    expect(q.length, 3);

    await _wait();

    expect(server.sent, ['a', 'b', 'c']);
    expect(q.length, 0);
    await q.saved;
    expect(note.hashes, isEmpty);
  });

  test('with no connection everything waits, in order, and is saved',
      () async {
    server.online = false;
    final q = queue();
    await q.start();
    q.add('a', isAudio: false, bytes: 10);
    q.add('b', isAudio: true, bytes: 20);
    await _wait();

    expect(server.sent, isEmpty);
    expect(q.hashes, ['a', 'b']);
    await q.saved;
    expect(note.hashes, ['a', 'b']);
    expect(q.retryDelay, const Duration(milliseconds: 40));
  });

  test('retries by itself once the connection is back', () async {
    server.online = false;
    final q = queue();
    await q.start();
    q.add('a', isAudio: false, bytes: 10);
    q.add('b', isAudio: false, bytes: 10);
    await _wait();
    expect(server.tries, ['a', 'b']);

    server.online = true;
    await _wait(const Duration(milliseconds: 80));

    expect(server.sent, ['a', 'b']);
    expect(q.length, 0);
    expect(q.retryDelay, isNull);
  });

  test('the wait doubles after each failed pass, up to the limit', () async {
    server.online = false;
    final q = queue(
      retryBase: const Duration(milliseconds: 20),
      retryMax: const Duration(milliseconds: 70),
    );
    await q.start();
    q.add('a', isAudio: false, bytes: 10);
    final delays = <Duration?>[];
    for (var pass = 1; pass <= 4; pass++) {
      // Wait for pass number [pass] to have tried and failed.
      while (server.tries.length < pass) {
        await _wait(const Duration(milliseconds: 2));
      }
      await _wait(const Duration(milliseconds: 2));
      delays.add(q.retryDelay);
    }

    expect(delays, const [
      Duration(milliseconds: 20),
      Duration(milliseconds: 40),
      Duration(milliseconds: 70),
      Duration(milliseconds: 70),
    ]);
  });

  test('kick retries at once and does not wait out the delay', () async {
    server.online = false;
    final q = queue(
      retryBase: const Duration(seconds: 30),
      retryMax: const Duration(minutes: 5),
    );
    await q.start();
    q.add('a', isAudio: false, bytes: 10);
    await _wait();
    expect(q.length, 1);

    server.online = true;
    q.kick();
    await _wait();

    expect(server.sent, ['a']);
    expect(q.length, 0);
  });

  test('a file that keeps failing does not hold up the ones behind it',
      () async {
    server.broken.add('a');
    final q = queue();
    await q.start();
    q.add('a', isAudio: false, bytes: 10);
    q.add('b', isAudio: false, bytes: 10);
    q.add('c', isAudio: false, bytes: 10);
    await _wait();

    expect(server.sent, ['b', 'c']);
    expect(q.hashes, ['a']);

    // Later it works, and it is tried first because it is the oldest.
    server.broken.clear();
    q.add('d', isAudio: false, bytes: 10);
    await _wait();
    expect(server.sent, ['b', 'c', 'a', 'd']);
  });

  test('each pass tries each file once', () async {
    server.online = false;
    final q = queue(retryBase: const Duration(seconds: 30));
    await q.start();
    q.add('a', isAudio: false, bytes: 10);
    q.add('b', isAudio: false, bytes: 10);
    await _wait(const Duration(milliseconds: 30));

    expect(server.tries, ['a', 'b']);
  });

  test('a file added while a pass is running is sent in that pass',
      () async {
    final q = queue();
    await q.start();
    q.add('a', isAudio: false, bytes: 10);
    // The pass is now inside the first send.
    q.add('b', isAudio: false, bytes: 10);
    q.kick();
    await _wait();

    expect(server.tries, ['a', 'b']);
    expect(server.sent, ['a', 'b']);
  });

  test('the same hash is queued once', () async {
    server.online = false;
    final q = queue();
    await q.start();
    q.add('a', isAudio: false, bytes: 10);
    q.add('a', isAudio: false, bytes: 10);

    expect(q.length, 1);
  });

  test('what an earlier run left unsent is sent first after a restart',
      () async {
    server.online = false;
    final first = queue();
    await first.start();
    first.add('a', isAudio: false, bytes: 10);
    first.add('b', isAudio: true, bytes: 20);
    await _wait();
    await first.saved;
    first.dispose();
    server.tries.clear();

    server.online = true;
    final second = queue();
    // Added before the saved queue has been read.
    second.add('c', isAudio: false, bytes: 30);
    expect(server.tries, isEmpty, reason: 'nothing is sent before start');
    await second.start();
    await _wait();

    expect(server.sent, ['a', 'b', 'c']);
    await second.saved;
    expect(note.hashes, isEmpty);
  });

  test('a file whose bytes are gone leaves the queue', () async {
    server.gone.add('a');
    final q = queue();
    await q.start();
    q.add('a', isAudio: false, bytes: 10);
    q.add('b', isAudio: false, bytes: 10);
    await _wait();

    expect(server.sent, ['b']);
    expect(q.length, 0);
  });

  test('an unreadable saved queue is treated as empty', () async {
    note.text = '{not json';
    final q = queue();
    await q.start();
    q.add('a', isAudio: false, bytes: 10);
    await _wait();

    expect(server.sent, ['a']);

    note.text = jsonEncode([
      {'hash': 'ok', 'audio': false, 'bytes': 1},
      {'hash': 7},
      'junk',
    ]);
    final next = queue();
    await next.start();
    await _wait();
    expect(server.sent, ['a', 'ok']);
  });

  test('tells its listener each time the count changes', () async {
    final q = queue();
    await q.start();
    q.add('a', isAudio: false, bytes: 10);
    expect(changes, 1);
    await _wait();
    expect(changes, 2);
  });

  test('after dispose nothing more is sent, and the queue stays saved',
      () async {
    server.online = false;
    final q = queue(retryBase: const Duration(milliseconds: 10));
    await q.start();
    q.add('a', isAudio: false, bytes: 10);
    await _wait();
    await q.saved;
    q.dispose();
    final triesAtDispose = server.tries.length;

    server.online = true;
    q.kick();
    q.add('b', isAudio: false, bytes: 10);
    await _wait(const Duration(milliseconds: 40));

    expect(server.tries.length, triesAtDispose);
    expect(note.hashes, ['a']);
  });
}
