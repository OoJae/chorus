/// Test harness for the sync scenarios: a real test server on embedded
/// Postgres, real generated clients, and one SQLite replica per device.
///
/// Circles are created and joined through the real `CircleEndpoint` over
/// HTTP, so the roles under test are the ones the app will actually get.
/// Every scenario makes its own users and circle, which is what keeps the
/// scenarios independent although the server database is never rolled back.
library;

import 'dart:async';
import 'dart:io';

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_server/src/generated/protocol.dart' as server;
import 'package:chorus_shared/chorus_shared.dart';
import 'package:path/path.dart' as p;
import 'package:serverpod/serverpod.dart' as pod;
import 'package:serverpod_database/serverpod_database.dart'
    show Column, Transaction, ValueEncoder;
// The two dialect encoders are not exported; see [_EncoderByZone].
// ignore: implementation_imports
import 'package:serverpod_database/src/adapters/postgres/value_encoder.dart';
// ignore: implementation_imports
import 'package:serverpod_database/src/adapters/sqlite/value_encoder.dart';
import 'package:serverpod_offline_sync_client/serverpod_offline_sync_client.dart';
import 'package:serverpod_offline_sync_server/serverpod_offline_sync_server.dart'
    show
        OfflineSyncInitialize,
        OfflineSyncSessionExtension,
        offlineSyncDatabaseInterceptor;
import 'package:test/test.dart';

import '../integration/test_tools/serverpod_test_tools.dart';

/// Long enough for two writes on different replicas to get different clock
/// readings, so "earlier" and "later" are unambiguous.
const Duration tick = Duration(milliseconds: 25);

/// Prints one observation in a greppable form. `docs/spike-results.md` is
/// written from these lines.
void note(String scenario, String what, Object? value) {
  // ignore: avoid_print
  print('SPIKE|$scenario|$what|$value');
}

/// Runs [body] in a group with a started test server that has the sync
/// engine configured the way the generated `Serverpod` class configures it.
///
/// The generated test tools build a plain `Serverpod`, without the sync
/// interceptor and without `initializeOfflineSync`; both are added here.
void withSyncWorld(String name, void Function(SyncWorld world) body) {
  withServerpod(
    name,
    rollbackDatabase: RollbackDatabase.disabled,
    databaseInterceptor: (session, inner) {
      // Creating the session's database just made Postgres the process-wide
      // encoder; put the zone-aware one back.
      ValueEncoder.set(const _EncoderByZone());
      return offlineSyncDatabaseInterceptor(session, inner);
    },
    (sessionBuilder, _) {
      final world = SyncWorld._(sessionBuilder);
      world._register();
      body(world);
    },
  );
}

/// The server and every replica of one test file.
class SyncWorld {
  SyncWorld._(this._sessionBuilder);

  final TestSessionBuilder _sessionBuilder;
  late final pod.Session _boot = _sessionBuilder.build();
  late Directory _dir;
  late String _template;
  var _count = 0;

  /// A server session for direct reads. Built after the engine is
  /// configured, so its database is the sync-aware one.
  late final pod.Session serverSession = _sessionBuilder.build();

  String get _url => 'http://localhost:${_boot.server.port}/';

  void _register() {
    // The bearer token is the user's UUID; anything else is not signed in.
    _boot.serverpod
      ..initializeOfflineSync(syncTables: server.syncTables)
      ..authenticationHandler = (session, token) async {
        final raw = token.startsWith('Bearer ') ? token.substring(7) : token;
        if (!pod.Uuid.isValidUUID(fromString: raw)) return null;
        return pod.AuthenticationInfo(
          raw,
          <pod.Scope>{},
          authId: const pod.Uuid().v4(),
        );
      };

    // Migrating a client database takes most of a second. It is done once,
    // and each replica opens a copy.
    setUpAll(() async {
      _dir = await Directory.systemTemp.createTemp('chorus_sync_');
      _template = p.join(_dir.path, 'template.db');
      final client = Client(_url);
      await _onReplica(() async {
        final template = await client.createSession(
          _template,
          isDebugMode: true,
        );
        await template.close();
      });
      ValueEncoder.set(const _EncoderByZone());
      client.close();
    });

    tearDownAll(() async {
      if (_syncTimes.isNotEmpty) {
        _syncTimes.sort();
        note(
          'timing',
          'syncOnce over loopback, ms (count / min / median / max)',
          '${_syncTimes.length} / ${_syncTimes.first} / '
              '${_syncTimes[_syncTimes.length ~/ 2]} / ${_syncTimes.last}',
        );
        _syncTimes.clear();
      }
      if (_dir.existsSync()) await _dir.delete(recursive: true);
    });
  }

  /// One new signed-in user per name, each with an empty, unsynced replica.
  Future<List<Replica>> users(List<String> names) async => [
    for (final name in names) await _open(const pod.Uuid().v7obj(), name),
  ];

  /// A second device for the user of [first]: same identity, its own
  /// database file.
  Future<Replica> secondDevice(Replica first) =>
      _open(first.userId, '${first.name} (second device)');

  Future<Replica> _open(UuidValue userId, String name) async {
    final path = p.join(_dir.path, 'replica-${++_count}.db');
    await File(_template).copy(path);
    final client = Client(_url)..authKeyProvider = _Token(userId);
    final session = await _onReplica(
      () => client.createSyncSession(
        path,
        runMigrations: false,
        persistentUserId: userId,
      ),
    );
    // Opening a client database made SQLite the process-wide encoder.
    ValueEncoder.set(const _EncoderByZone());
    addTearDown(() async {
      await _onReplica(session.close);
      client.close();
    });
    return Replica._(name, userId, client, session);
  }

  /// Creates a circle through the real endpoint with [guardian] as its
  /// guardian, invites each of [members] with their role, and syncs every
  /// replica once so each holds its membership. Returns the circle's space.
  ///
  /// With [deliver] false nobody syncs: the server knows the memberships and
  /// no replica does yet.
  Future<UuidValue> circle(
    Replica guardian, {
    Map<Replica, CircleRole> members = const {},
    bool deliver = true,
  }) async {
    final info = await guardian.client.circle.createCircle(
      'Ada',
      guardian.name,
    );
    for (final MapEntry(key: member, value: role) in members.entries) {
      final code = await guardian.client.circle.createInvite(
        info.spaceUuid,
        role,
      );
      await member.client.circle.acceptInvite(code, member.name);
    }
    if (deliver) {
      for (final replica in [guardian, ...members.keys]) {
        await replica.sync();
      }
    }
    return info.spaceUuid;
  }

  /// Inserts the starter board row (no tiles) from [author] and brings
  /// [replicas] level.
  Future<BoardFacts> emptyBoard(
    UuidValue circle,
    Replica author,
    List<Replica> replicas,
  ) async {
    final board = starterBoard(circle.uuid);
    await author.write(circle, (db, tx) async {
      await Board.db.insertRow(db, boardRow(board, circle), transaction: tx);
    });
    await converge(circle, replicas);
    return board;
  }

  /// Syncs [replicas] in order, round after round, until every replica and
  /// the server show the same rows for [circle]; then runs one more round
  /// and checks nothing moved. Returns the number of rounds it took.
  Future<int> converge(
    UuidValue circle,
    List<Replica> replicas, {
    int maxRounds = 6,
  }) async {
    Future<List<String>> states() async => [
      await serverState(circle),
      for (final replica in replicas) await replica.state(circle),
    ];

    for (var round = 1; round <= maxRounds; round++) {
      for (final replica in replicas) {
        await replica.sync();
      }
      final seen = await states();
      if (seen.toSet().length == 1) {
        for (final replica in replicas) {
          await replica.sync();
        }
        expect(
          await states(),
          everyElement(seen.first),
          reason: 'state changed again after the replicas had agreed',
        );
        return round;
      }
    }
    final seen = await states();
    fail(
      'No agreement after $maxRounds rounds.\n'
      'server:\n${seen.first}\n'
      '${[for (var i = 0; i < replicas.length; i++) '${replicas[i].name}:\n${seen[i + 1]}'].join('\n')}',
    );
  }

  /// Changes the sync role of [member] on the server only, as a guardian's
  /// request would. The member's replica learns of it at its next sync.
  Future<void> setServerRole(
    UuidValue circle,
    Replica member,
    OfflineSyncSpaceRole role,
  ) => serverSession.offlineSync.spaces.grant(
    space: circle,
    user: member.userId,
    role: role,
  );

  /// The circle's tiles as the server holds them.
  Future<List<TileFacts>> serverTiles(UuidValue circle) async {
    final rows = await server.Tile.db.find(
      serverSession,
      where: (t) => t.circleId.equals(circle),
    );
    return [
      for (final row in rows)
        TileFacts(
          id: row.id!.uuid,
          boardId: row.boardId.uuid,
          cellKey: row.cellKey,
          label: row.label,
          speech: row.speech,
          colorKey: row.colorKey,
          archived: row.archivedAt != null,
          createdBy: row.createdBy.uuid,
          createdByName: row.createdByName,
          createdAt: row.createdAt,
        ),
    ];
  }

  /// Ids of the circle's edit-log rows as the server holds them.
  Future<Set<String>> serverEditIds(UuidValue circle) async {
    final rows = await server.TileEdit.db.find(
      serverSession,
      where: (t) => t.circleId.equals(circle),
    );
    return {for (final row in rows) row.id!.uuid};
  }

  /// Everything the server holds for [circle], as one comparable string.
  Future<String> serverState(UuidValue circle) async {
    final boards = await server.Board.db.find(
      serverSession,
      where: (t) => t.circleId.equals(circle),
    );
    return _state(
      [for (final b in boards) '${b.id!.uuid}|${b.name}'],
      await serverTiles(circle),
      await serverEditIds(circle),
    );
  }

  /// UUID of the sync space the server filed tile [id] under, or null when
  /// the server has no such tile.
  Future<String?> serverSpaceOfTile(UuidValue id) async {
    final result = await serverSession.db.unsafeQuery(
      'SELECT s."uuidSpaceId"::text FROM "tile" t '
      'JOIN "offline_sync_spaces" s ON s."id" = t."spaceId" '
      'WHERE t."id" = \'${id.uuid}\'',
    );
    return result.isEmpty ? null : result.first.first as String;
  }
}

/// One device: a signed-in client and its local database.
///
/// The database is only reachable through [local] and [write], which run the
/// work in the replica zone; see [_EncoderByZone] for why that matters.
class Replica {
  Replica._(this.name, this.userId, this.client, this._session);

  final String name;
  final UuidValue userId;
  final Client client;
  final OfflineSyncDatabaseSession _session;

  /// Runs [body] against this device's local database.
  Future<R> local<R>(
    Future<R> Function(OfflineSyncDatabaseSession db) body,
  ) => _onReplica(() => body(_session));

  /// One full sync with the server. Returns how long it took.
  Future<Duration> sync() => local((db) async {
    final watch = Stopwatch()..start();
    await client.offlineSync.syncOnce(db);
    _syncTimes.add(watch.elapsedMilliseconds);
    return watch.elapsed;
  });

  /// Runs [body] as one write into the circle's shared space, the way the
  /// app must make every write.
  Future<R> write<R>(
    UuidValue circle,
    Future<R> Function(OfflineSyncDatabaseSession db, Transaction tx) body,
  ) => local(
    (db) => db.db.transactionForUser(
      userId,
      (tx) => body(db, tx),
      spaceId: circle,
    ),
  );

  Future<List<Tile>> tileRows(UuidValue circle) => local(
    (db) => Tile.db.find(db, where: (t) => t.circleId.equals(circle)),
  );

  Future<List<TileFacts>> tiles(UuidValue circle) async => [
    for (final row in await tileRows(circle)) tileFacts(row),
  ];

  /// The raw cell key of tile [id] as this device has it.
  Future<String> cellKeyOf(UuidValue id) async =>
      (await local((db) => Tile.db.findById(db, id)))!.cellKey;

  Future<List<TileEdit>> edits(UuidValue circle) => local(
    (db) => TileEdit.db.find(db, where: (t) => t.circleId.equals(circle)),
  );

  /// Everything this replica holds for [circle], as one comparable string.
  Future<String> state(UuidValue circle) async {
    final boards = await local(
      (db) => Board.db.find(db, where: (t) => t.circleId.equals(circle)),
    );
    return _state(
      [for (final b in boards) '${b.id!.uuid}|${b.name}'],
      await tiles(circle),
      {for (final e in await edits(circle)) e.id!.uuid},
    );
  }

  /// Inserts [tile] into the circle's shared space.
  Future<Tile> insertTile(UuidValue circle, Tile tile) => write(
    circle,
    (db, tx) => Tile.db.insertRow(db, tile, transaction: tx),
  );

  /// Re-reads tile [id], applies [change] and writes it back in one
  /// transaction in the circle's space. [columns] names what changed; pass
  /// null to write the whole row, which the app must never do. [edit], if
  /// given, builds an edit-log row from the tile as it was and is inserted
  /// in the same transaction.
  Future<Tile> updateTile(
    UuidValue circle,
    UuidValue id,
    Tile Function(Tile row) change, {
    required List<Column> Function(TileTable t)? columns,
    TileEdit Function(Tile before)? edit,
  }) => write(circle, (db, tx) async {
    final before = (await Tile.db.findById(db, id, transaction: tx))!;
    if (edit != null) {
      await TileEdit.db.insertRow(db, edit(before), transaction: tx);
    }
    return Tile.db.updateRow(
      db,
      change(before),
      columns: columns,
      transaction: tx,
    );
  });

  /// A tile row authored on this device, not yet written anywhere.
  Tile newTile(
    UuidValue circle,
    BoardFacts board,
    String label, {
    String? cellKey,
    UuidValue? id,
  }) {
    final tileId = id ?? const pod.Uuid().v7obj();
    return Tile(
      id: tileId,
      circleId: circle,
      boardId: UuidValue.fromString(board.id),
      cellKey: cellKey ?? trayKey(tileId.uuid),
      label: label,
      noLog: false,
      createdBy: userId,
      createdByName: name,
      createdAt: DateTime.now().toUtc(),
    );
  }

  /// A row for the edit log, describing a change made on this device.
  TileEdit newEdit(
    UuidValue circle,
    UuidValue tileId,
    String prop,
    String? oldValue,
    String? newValue,
  ) => TileEdit(
    id: const pod.Uuid().v7obj(),
    circleId: circle,
    tileId: tileId,
    prop: prop,
    oldValue: oldValue,
    newValue: newValue,
    reason: 'edit',
    actorId: userId,
    actorName: name,
    editedAt: DateTime.now().toUtc(),
  );

  @override
  String toString() => name;
}

String _state(
  Iterable<String> boards,
  Iterable<TileFacts> tiles,
  Iterable<String> editIds,
) => [
  ...boards.map((b) => 'board $b').toList()..sort(),
  ...tiles
      .map(
        (t) => 'tile ${t.id}|${t.cellKey}|${t.label}|${t.speech}|${t.archived}',
      )
      .toList()
    ..sort(),
  ...editIds.map((e) => 'edit $e').toList()..sort(),
].join('\n');

/// The adapter the app will also need: a generated row as shared facts.
TileFacts tileFacts(Tile row) => TileFacts(
  id: row.id!.uuid,
  boardId: row.boardId.uuid,
  cellKey: row.cellKey,
  label: row.label,
  speech: row.speech,
  imageHash: row.imageHash,
  audioHash: row.audioHash,
  colorKey: row.colorKey,
  archived: row.archivedAt != null,
  createdBy: row.createdBy.uuid,
  createdByName: row.createdByName,
  createdAt: row.createdAt,
);

/// A generated board row for [board] in [circle].
Board boardRow(BoardFacts board, UuidValue circle) => Board(
  id: UuidValue.fromString(board.id),
  circleId: circle,
  name: board.name,
  rows: board.rows,
  cols: board.cols,
  isHome: board.isHome,
  createdAt: DateTime.now().toUtc(),
);

/// A generated tile row for the starter tile [tile] in [circle].
Tile starterTileRow(TileFacts tile, UuidValue circle) => Tile(
  id: UuidValue.fromString(tile.id),
  circleId: circle,
  boardId: UuidValue.fromString(tile.boardId),
  cellKey: tile.cellKey,
  label: tile.label,
  colorKey: tile.colorKey,
  noLog: false,
  createdBy: UuidValue.fromString(tile.createdBy),
  createdByName: tile.createdByName,
  createdAt: tile.createdAt ?? DateTime.now().toUtc(),
);

class _Token implements ClientAuthKeyProvider {
  _Token(this._userId);

  final UuidValue _userId;

  @override
  Future<String?> get authHeaderValue async => 'Bearer ${_userId.uuid}';
}

/// Duration of every sync in this test file, in milliseconds.
final _syncTimes = <int>[];

const _replicaZone = #chorusReplica;

/// Runs [body] in the zone that marks code as running "on a device".
Future<R> _onReplica<R>(Future<R> Function() body) =>
    runZoned(body, zoneValues: {_replicaZone: true});

/// Picks the SQL dialect by zone, so a Postgres server and SQLite replicas
/// can share one isolate.
///
/// `serverpod_database` keeps one process-wide [ValueEncoder] and replaces
/// it every time a `Database` is constructed: on every server request
/// (Postgres) and every client database open (SQLite). Query expressions
/// read it when they are rendered, so in one isolate each side ends up
/// rendering the other's dialect: a UUID becomes `X'..'` for Postgres or a
/// quoted string for a SQLite blob column, and lookups fail or silently
/// match nothing. A real app never sees this because its client is another
/// process. Here, replica work runs in a marked zone and this encoder is put
/// back after every construction.
class _EncoderByZone implements ValueEncoder {
  const _EncoderByZone();

  ValueEncoder get _current => Zone.current[_replicaZone] == true
      ? const SqliteValueEncoder()
      : const PostgresValueEncoder();

  @override
  String convert(
    Object? input, {
    bool escapeStrings = true,
    bool hasDefaults = false,
  }) => _current.convert(
    input,
    escapeStrings: escapeStrings,
    hasDefaults: hasDefaults,
  );

  @override
  String? tryConvert(Object? input, {bool escapeStrings = false}) =>
      _current.tryConvert(input, escapeStrings: escapeStrings);

  @override
  String encodeColumnValue(
    Column column,
    dynamic value, {
    bool hasDefaults = false,
  }) => _current.encodeColumnValue(column, value, hasDefaults: hasDefaults);

  @override
  String quoteTableName(String tableName) => _current.quoteTableName(tableName);
}
