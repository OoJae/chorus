import 'dart:convert';

import 'package:chorus_client/chorus_client.dart'
    show
        CircleException,
        CircleFailure,
        ServerpodClientNetworkException,
        ViewOnlyLink;
import 'package:chorus_flutter/src/sharing/server_board_sharing.dart';
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/contracts_sharing.dart';
import 'package:chorus_ui/fakes.dart' show FakeBoardStore, FakeSyncStatus;
import 'package:flutter_test/flutter_test.dart';

const String _token = 'abcdefghijklmnopqrstuvwxyz012345';

/// The server's sharing and printing calls, recorded.
class _Server {
  final List<String> viewOnly = [];
  final List<String> copies = [];
  final List<String> withdrawn = [];
  final List<String> exportAsked = [];
  Object? down;

  final DateTime expiry = DateTime.utc(2026, 10, 21, 9);

  Future<ViewOnlyLink> publishViewOnly(String json) async {
    if (down case final error?) throw error;
    viewOnly.add(json);
    return ViewOnlyLink(
      token: _token,
      url: 'https://chorus.example/b/$_token',
      exportUrl: 'https://chorus.example/export/$_token',
      expiresAt: expiry,
    );
  }

  Future<bool> withdraw(String token) async {
    if (down case final error?) throw error;
    withdrawn.add(token);
    return true;
  }

  Future<String> publishCopy(String json) async {
    if (down case final error?) throw error;
    copies.add(json);
    return _token;
  }

  Future<String> exportUrl(String token) async {
    if (down case final error?) throw error;
    exportAsked.add(token);
    return 'https://chorus.example/export/$token';
  }
}

void main() {
  late _Server server;
  late FakeBoardStore store;
  late BoardFacts home;
  late FakeSyncStatus sync;
  var snapshots = 0;

  ServerBoardSharing sharing({Uri? pageBase}) => ServerBoardSharing(
    publishViewOnly: server.publishViewOnly,
    withdraw: server.withdraw,
    publishCopy: server.publishCopy,
    exportUrl: server.exportUrl,
    snapshot: () async {
      snapshots++;
      return (
        childName: store.childName,
        boards: store.boards,
        tiles: store.tiles,
      );
    },
    sync: sync,
    pageBase: pageBase,
  );

  setUp(() async {
    server = _Server();
    store = FakeBoardStore.seeded();
    home = store.boards.firstWhere((board) => board.isHome);
    sync = FakeSyncStatus();
    snapshots = 0;
    // A word that says more than its label, to see `speech` travel.
    await store.updateTile(
      gridOf(home.id, store.tiles, store.boards)[(0, 0)]!.id,
      speech: 'I like it',
    );
  });

  group('shareViewOnly', () {
    test('sends the snapshot this device would print, with speech, and '
        'returns the server\'s link and expiry', () async {
      final link = await sharing().shareViewOnly(home);
      expect(
        server.viewOnly.single,
        printSnapshotJson(
          childName: 'Maya',
          board: home,
          tiles: store.tiles,
          boards: store.boards,
        ),
      );
      final sent = jsonDecode(server.viewOnly.single) as Map<String, Object?>;
      expect(
        (sent['tiles']! as List).first,
        containsPair('speech', 'I like it'),
      );
      expect(link.url, Uri.parse('https://chorus.example/b/$_token'));
      expect(link.expiresAt, server.expiry);
    });

    test(
      'in the released web app the link is on the page\'s own address',
      () async {
        final link = await sharing(
          pageBase: Uri.parse('https://chorus.app/app/'),
        ).shareViewOnly(home);
        expect(link.url, Uri.parse('https://chorus.app/b/$_token'));
      },
    );

    test('uses the board as this device holds it now', () async {
      await store.renameBoard(home.id, 'Core');
      await sharing().shareViewOnly(home);
      final sent = jsonDecode(server.viewOnly.single) as Map<String, Object?>;
      expect(sent['name'], 'Core');
    });
  });

  test('withdraw sends the link\'s token', () async {
    final s = sharing();
    final link = await s.shareViewOnly(home);
    await s.withdraw(link);
    await s.withdraw(link);
    expect(server.withdrawn, [_token, _token]);
  });

  group('exportObf', () {
    test(
      'stores a copy, makes no speaking page, and links to the .obf file',
      () async {
        final url = await sharing().exportObf(home);
        expect(server.viewOnly, isEmpty);
        expect(server.copies.single, contains('"childName":"Maya"'));
        expect(server.exportAsked, [_token]);
        expect(url, Uri.parse('https://chorus.example/export/$_token'));
      },
    );

    test('in the released web app it needs no second call', () async {
      final url = await sharing(
        pageBase: Uri.parse('https://chorus.app/'),
      ).exportObf(home);
      expect(url, Uri.parse('https://chorus.app/export/$_token'));
      expect(server.exportAsked, isEmpty);
    });
  });

  group('failures are a SharingFailed with words for the adult', () {
    test('no connection', () async {
      server.down = const ServerpodClientNetworkException('no signal');
      await expectLater(
        sharing().shareViewOnly(home),
        throwsA(
          isA<SharingFailed>().having(
            (e) => e.message,
            'message',
            contains('could not reach the server'),
          ),
        ),
      );
      await expectLater(
        sharing().exportObf(home),
        throwsA(isA<SharingFailed>()),
      );
    });

    test('a partner, refused by the server', () async {
      server.down = CircleException(failure: CircleFailure.notAllowed);
      await expectLater(
        sharing().shareViewOnly(home),
        throwsA(
          isA<SharingFailed>().having(
            (e) => e.message,
            'message',
            'Only the adults who can change the board can share it.',
          ),
        ),
      );
    });

    test('offline or working offline: refused before anything is read or '
        'sent', () async {
      sync.state = SyncState.offline;
      await expectLater(
        sharing().shareViewOnly(home),
        throwsA(isA<SharingFailed>()),
      );
      await sync.setWorkingOffline(true);
      await expectLater(
        sharing().exportObf(home),
        throwsA(
          isA<SharingFailed>().having(
            (e) => e.message,
            'message',
            contains('Work offline'),
          ),
        ),
      );
      await expectLater(
        sharing().withdraw(
          SharedLink(
            url: Uri.parse('https://chorus.example/b/$_token'),
            expiresAt: server.expiry,
          ),
        ),
        throwsA(isA<SharingFailed>()),
      );
      expect(snapshots, 0);
      expect(server.viewOnly, isEmpty);
      expect(server.copies, isEmpty);
      expect(server.withdrawn, isEmpty);
    });

    test('a board that cannot be read', () async {
      final broken = ServerBoardSharing(
        publishViewOnly: server.publishViewOnly,
        withdraw: server.withdraw,
        publishCopy: server.publishCopy,
        exportUrl: server.exportUrl,
        snapshot: () async => throw StateError('closed'),
      );
      await expectLater(
        broken.shareViewOnly(home),
        throwsA(isA<SharingFailed>()),
      );
      expect(server.viewOnly, isEmpty);
    });
  });
}
