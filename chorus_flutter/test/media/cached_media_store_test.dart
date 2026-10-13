import 'dart:async';
import 'dart:typed_data';

import 'package:chorus_client/chorus_client.dart'
    show CircleException, CircleFailure;
import 'package:chorus_flutter/src/media/cached_media_store.dart';
import 'package:chorus_flutter/src/media/image_shrink.dart';
import 'package:chorus_flutter/src/media/media_files.dart';
import 'package:chorus_flutter/src/media/media_gateway.dart';
import 'package:chorus_flutter/src/media/media_hash.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// The circle's storage on the server, shared by every device in a test.
class FakeServer implements MediaGateway {
  bool online = true;

  /// Verified files, by hash.
  final Map<String, Uint8List> held = {};

  /// When set, every download returns these bytes instead of the real ones.
  Uint8List? tamperWith;

  /// When set, every upload is refused with this.
  Object? refuseWith;

  final List<String> uploads = [];
  final List<List<String>> urlRequests = [];
  final List<String> fetches = [];

  void _needOnline() {
    if (!online) throw StateError('offline');
  }

  @override
  Future<void> upload(
    String hash,
    Uint8List bytes, {
    required bool isAudio,
  }) async {
    _needOnline();
    final refusal = refuseWith;
    if (refusal != null) throw refusal;
    if (sha256Hex(bytes) != hash) throw StateError('does not verify');
    uploads.add(hash);
    held[hash] = bytes;
  }

  @override
  Future<Map<String, String>> downloadUrls(List<String> hashes) async {
    _needOnline();
    urlRequests.add(List.of(hashes));
    return {
      for (final hash in hashes)
        if (held.containsKey(hash)) hash: 'https://files.test/$hash',
    };
  }

  @override
  Future<Uint8List> fetch(String url) async {
    _needOnline();
    final hash = url.split('/').last;
    fetches.add(hash);
    return tamperWith ?? held[hash]!;
  }
}

Uint8List _photo([int seed = 1]) {
  final picture = img.Image(width: 900, height: 600);
  img.fill(picture, color: img.ColorRgb8(seed * 40, 120, 200));
  return img.encodePng(picture);
}

final Uint8List _clip = Uint8List.fromList([0x1A, 0x45, 0xDF, 0xA3, 5, 6, 7]);

Future<void> _wait([Duration duration = const Duration(milliseconds: 10)]) =>
    Future<void>.delayed(duration);

/// Waits until [done] is true, for at most two seconds.
Future<void> _until(bool Function() done) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!done()) {
    if (DateTime.now().isAfter(deadline)) fail('Timed out waiting.');
    await _wait(const Duration(milliseconds: 5));
  }
}

/// Live sync that an adult can pause: resuming notifies as going live.
class _Pausable extends FakeSyncStatus {
  bool _paused = false;

  @override
  bool get workingOffline => _paused;

  set paused(bool value) {
    _paused = value;
    notifyListeners();
  }
}

void main() {
  late FakeServer server;

  CachedMediaStore device(
    MediaFiles files, {
    SyncStatus? sync,
    String queue = 'user_circle',
    Duration retryBase = const Duration(milliseconds: 30),
  }) {
    final store = CachedMediaStore(
      files: Future.value(files),
      gateway: server,
      queueName: queue,
      sync: sync,
      // The real shrinking, without the isolate hop.
      shrink: (bytes) async => shrinkToJpeg(bytes),
      retryBase: retryBase,
      retryMax: const Duration(milliseconds: 120),
    );
    addTearDown(store.dispose);
    return store;
  }

  setUp(() => server = FakeServer());

  group('adding with no connection', () {
    test('a photo is shrunk, kept locally and usable at once', () async {
      server.online = false;
      final files = MemoryMediaFiles();
      final store = device(files);

      final hash = await store.addImage(_photo());

      expect(isSha256Hex(hash), isTrue);
      final kept = (await files.read(hash))!;
      expect(sha256Hex(kept), hash);
      expect(sniffFormat(kept), MediaFormat.jpeg);
      final decoded = img.decodeJpg(kept)!;
      expect((decoded.width, decoded.height), (512, 341));
      expect(store.imageFor(hash), isNotNull);
      expect(store.pendingUploads, 1);
      expect(server.uploads, isEmpty);
    });

    test('a clip is kept as recorded and reported as on this device',
        () async {
      server.online = false;
      final files = MemoryMediaFiles();
      final store = device(files);

      final hash = await store.addAudio(_clip);

      expect(hash, sha256Hex(_clip));
      expect(store.hasAudio(hash), isTrue);
      expect(await store.clipBytes(hash), _clip);
      expect(store.pendingUploads, 1);
    });

    test('an oversized or empty clip, or a non-picture, is refused',
        () async {
      final store = device(MemoryMediaFiles());

      expect(() => store.addAudio(Uint8List(0)), throwsArgumentError);
      expect(() => store.addAudio(Uint8List(maxClipBytes + 1)),
          throwsArgumentError);
      expect(() => store.addImage(Uint8List.fromList(const [1, 2, 3])),
          throwsFormatException);
      await _wait();
      expect(store.pendingUploads, 0);
    });

    test('the same photo added twice is one file and one upload', () async {
      server.online = false;
      final store = device(MemoryMediaFiles());

      final first = await store.addImage(_photo());
      final second = await store.addImage(_photo());

      expect(second, first);
      expect(store.pendingUploads, 1);
    });
  });

  group('working offline', () {
    test('nothing is sent or fetched until sync is switched back on',
        () async {
      // The server is reachable: only the adult's switch holds things back.
      final sync = _Pausable()..paused = true;
      final other = device(MemoryMediaFiles(), queue: 'other_circle');
      final theirs = await other.addAudio(_clip);
      await _until(() => other.pendingUploads == 0);
      server.uploads.clear();

      final store = device(MemoryMediaFiles(), sync: sync);
      final image = await store.addImage(_photo());
      expect(store.imageFor(image), isNotNull);
      expect(store.hasAudio(theirs), isFalse);
      store.imageFor(theirs);
      // Several retry delays pass (30 ms doubling to 120 ms).
      await _wait(const Duration(milliseconds: 500));
      expect(store.pendingUploads, 1);
      expect(server.uploads, isEmpty);
      expect(server.urlRequests, isEmpty);
      expect(server.fetches, isEmpty);

      sync.paused = false;
      await _until(() => store.pendingUploads == 0);
      await _until(() => server.fetches.isNotEmpty);
      expect(server.uploads, [image]);
      expect(server.fetches, [theirs]);
    });
  });

  group('uploading', () {
    test('files go up when the connection returns, oldest first', () async {
      server.online = false;
      final sync = FakeSyncStatus(state: SyncState.offline);
      final store =
          device(MemoryMediaFiles(), sync: sync, retryBase: const Duration(seconds: 30));
      final image = await store.addImage(_photo());
      final clip = await store.addAudio(_clip);
      await _wait();
      expect(store.pendingUploads, 2);

      var notified = 0;
      store.addListener(() => notified++);
      server.online = true;
      sync.state = SyncState.live;
      await _until(() => store.pendingUploads == 0);

      expect(server.uploads, [image, clip]);
      expect(sha256Hex(server.held[image]!), image);
      expect(notified, greaterThanOrEqualTo(2));
    });

    test('a file the server refuses for good leaves the queue, and stays '
        'on this device', () async {
      server.refuseWith = CircleException(failure: CircleFailure.notAllowed);
      final store = device(MemoryMediaFiles());
      final hash = await store.addAudio(_clip);
      await _until(() => store.pendingUploads == 0);
      expect(server.uploads, isEmpty);
      expect(store.hasAudio(hash), isTrue);
    });

    test('any other refusal is tried again', () async {
      server.refuseWith = CircleException(failure: CircleFailure.notAMember);
      final store = device(MemoryMediaFiles());
      await store.addAudio(_clip);
      await _wait(const Duration(milliseconds: 100));
      expect(store.pendingUploads, 1);
      server.refuseWith = null;
      await _until(() => store.pendingUploads == 0);
      expect(server.uploads, hasLength(1));
    });

    test('retries by itself with no nudge', () async {
      server.online = false;
      final store = device(MemoryMediaFiles());
      await store.addAudio(_clip);
      await _wait();
      expect(store.pendingUploads, 1);

      server.online = true;
      await _until(() => store.pendingUploads == 0);
      expect(server.uploads, [sha256Hex(_clip)]);
    });

    test('unsent files survive a restart of the app', () async {
      server.online = false;
      final files = MemoryMediaFiles();
      final first = device(files);
      final hash = await first.addImage(_photo());
      await _wait();
      first.dispose();

      server.online = true;
      final second = device(files);
      await _until(() => server.uploads.isNotEmpty);

      expect(server.uploads, [hash]);
      await _until(() => second.pendingUploads == 0);
    });

    test('each circle has its own queue', () async {
      server.online = false;
      final files = MemoryMediaFiles();
      final one = device(files, queue: 'user_one');
      await one.addAudio(_clip);
      await _wait();

      final other = device(files, queue: 'user_two');
      await other.ready;
      await _wait();

      expect(one.pendingUploads, 1);
      expect(other.pendingUploads, 0);
    });
  });

  group('another device', () {
    /// Puts a photo and a clip on the server from a first device.
    Future<(String, String)> seedServer() async {
      final author = device(MemoryMediaFiles(), queue: 'author');
      final image = await author.addImage(_photo());
      final clip = await author.addAudio(_clip);
      await _until(() => author.pendingUploads == 0);
      return (image, clip);
    }

    test('shows nothing at first, then fetches, verifies and caches',
        () async {
      final (image, clip) = await seedServer();
      final files = MemoryMediaFiles();
      final store = device(files);
      await store.ready;
      var notified = 0;
      store.addListener(() => notified++);

      // The board is drawn: every tile asks in the same frame.
      expect(store.imageFor(image), isNull);
      expect(store.hasAudio(clip), isFalse);
      expect(store.imageFor(image), isNull);

      await _until(() => store.hasAudio(clip) && store.imageFor(image) != null);

      expect(server.urlRequests.last, unorderedEquals([image, clip]),
          reason: 'one request for the whole board');
      expect(sha256Hex((await files.read(image))!), image);
      expect(await store.clipBytes(clip), _clip);
      expect(notified, greaterThanOrEqualTo(2));
      expect(store.missing, isEmpty);
      expect(store.pendingUploads, 0, reason: 'a fetched file is not re-sent');
    });

    test('a fetched file is not fetched again', () async {
      final (image, _) = await seedServer();
      final store = device(MemoryMediaFiles());
      await store.ready;
      store.imageFor(image);
      await _until(() => store.imageFor(image) != null);
      final fetchesSoFar = server.fetches.length;

      store.imageFor(image);
      store.imageFor(image);
      await _wait(const Duration(milliseconds: 80));

      expect(server.fetches.length, fetchesSoFar);
    });

    test('bytes that do not match the hash are thrown away', () async {
      final (image, _) = await seedServer();
      server.tamperWith = Uint8List.fromList(const [6, 6, 6]);
      final files = MemoryMediaFiles();
      final store = device(files);
      await store.ready;

      store.imageFor(image);
      await _until(() => server.fetches.isNotEmpty);
      await _wait();

      expect(files.has(image), isFalse);
      expect(store.imageFor(image), isNull);
      expect(store.missing, {image});

      // The honest bytes are accepted on a later try.
      server.tamperWith = null;
      await _until(() => store.imageFor(image) != null);
      expect(files.has(image), isTrue);
    });

    test('with no connection it keeps the label, then catches up', () async {
      final (image, clip) = await seedServer();
      server.online = false;
      final sync = FakeSyncStatus(state: SyncState.offline);
      final store =
          device(MemoryMediaFiles(), sync: sync, retryBase: const Duration(seconds: 30));
      await store.ready;

      expect(store.imageFor(image), isNull);
      expect(store.hasAudio(clip), isFalse);
      await _wait(const Duration(milliseconds: 80));
      expect(store.imageFor(image), isNull);
      expect(store.missing, {image, clip});

      server.online = true;
      sync.state = SyncState.live;
      await _until(() => store.hasAudio(clip) && store.imageFor(image) != null);
    });

    test('a hash the server does not hold yet is asked for again later',
        () async {
      final store = device(MemoryMediaFiles());
      await store.ready;
      final hash = sha256Hex(_clip);

      expect(store.hasAudio(hash), isFalse);
      await _until(() => server.urlRequests.isNotEmpty);
      expect(server.fetches, isEmpty);

      // Its author comes online and uploads it.
      server.held[hash] = _clip;
      await _until(() => store.hasAudio(hash));
    });

    test('a cached photo shows after a restart with no connection',
        () async {
      final (image, _) = await seedServer();
      final files = MemoryMediaFiles();
      final first = device(files);
      await first.ready;
      first.imageFor(image);
      await _until(() => first.imageFor(image) != null);
      first.dispose();

      server.online = false;
      final requestsSoFar = server.urlRequests.length;
      final second = device(files);
      await second.ready;
      second.imageFor(image);
      await _until(() => second.imageFor(image) != null);

      expect(server.urlRequests.length, requestsSoFar);
    });
  });

  group('what is never used as a name or sent', () {
    test('a null or malformed hash is ignored', () async {
      final store = device(MemoryMediaFiles());
      await store.ready;

      expect(store.imageFor(null), isNull);
      expect(store.hasAudio(null), isFalse);
      expect(store.imageFor('../../etc/passwd'), isNull);
      expect(store.hasAudio('A' * 64), isFalse);
      expect(await store.clipBytes('nope'), isNull);
      await _wait(const Duration(milliseconds: 80));

      expect(server.urlRequests, isEmpty);
      expect(store.missing, isEmpty);
    });
  });

  test('asks before the files are open are answered once they are',
      () async {
    final opening = Completer<MediaFiles>();
    final files = MemoryMediaFiles();
    final hash = sha256Hex(_clip);
    await files.write(hash, _clip);
    final store = CachedMediaStore(
      files: opening.future,
      gateway: server,
      queueName: 'late',
    );
    addTearDown(store.dispose);
    var notified = 0;
    store.addListener(() => notified++);

    expect(store.hasAudio(hash), isFalse);
    opening.complete(files);
    await store.ready;

    expect(notified, 1, reason: 'tiles are told to ask again');
    expect(store.hasAudio(hash), isTrue);
    expect(server.urlRequests, isEmpty);
  });

  test('nothing is notified or fetched after dispose', () async {
    final store = device(MemoryMediaFiles());
    await store.ready;
    store.hasAudio(sha256Hex(_clip));
    store.dispose();
    await _wait(const Duration(milliseconds: 80));

    expect(server.urlRequests, isEmpty);
    expect(() => store.addAudio(_clip), throwsStateError);
  });
}
