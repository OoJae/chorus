import 'dart:async';

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_flutter/src/live/chorus_live_session.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/contracts_live.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:flutter_test/flutter_test.dart';

final _space = UuidValue.fromString('6f1d2c3a-0b4e-4c5d-8e9f-a1b2c3d4e5f6');
final _dad = UuidValue.fromString('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
final _gran = UuidValue.fromString('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');
const _tile = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';

/// One stream the session opened: what the server would push down it and
/// what the session sent up it.
class _Call {
  _Call(Stream<LiveEvent> outgoing) {
    outgoing.listen(sent.add, onDone: () => closedByClient = true);
  }

  final StreamController<LiveEvent> down = StreamController<LiveEvent>();
  final List<LiveEvent> sent = [];
  bool closedByClient = false;

  List<LiveEvent> of(LiveKind kind) =>
      sent.where((event) => event.kind == kind).toList();
}

/// Stands in for `client.live.join` and counts the attempts.
class _Server {
  final List<_Call> calls = [];

  /// When true, a new stream fails straight away, like an unreachable
  /// server.
  bool refuse = false;

  _Call get last => calls.last;

  Stream<LiveEvent> join(UuidValue space, Stream<LiveEvent> outgoing) {
    final call = _Call(outgoing);
    calls.add(call);
    if (refuse) {
      call.down.addError(StateError('unreachable'));
      call.down.close();
    }
    return call.down.stream;
  }
}

/// A presence event as the server stamps it: `text` is `joined`, `here` or
/// `left`.
LiveEvent _presence(UuidValue user, String name, {String text = 'here'}) =>
    LiveEvent(
      kind: LiveKind.presence,
      fromUser: user,
      fromName: name,
      text: text,
    );

void main() {
  late _Server server;

  ChorusLiveSession open({
    SyncStatus? sync,
    bool mayShareSaid = true,
    Future<bool> Function()? load,
    Future<void> Function(bool)? save,
  }) {
    final live = ChorusLiveSession(
      join: server.join,
      circleSpace: _space,
      sync: sync,
      mayShareSaid: mayShareSaid,
      loadShareSaid: load,
      saveShareSaid: save,
    );
    return live..start();
  }

  /// Lets a stream that did not fail count as connected.
  Future<void> settle(WidgetTester tester) =>
      tester.pump(const Duration(milliseconds: 1500));

  setUp(() => server = _Server());

  group('connection', () {
    testWidgets('a stream that does not fail becomes connected', (
      tester,
    ) async {
      final live = open();
      expect(server.calls, hasLength(1));
      expect(live.connected, isFalse);
      await settle(tester);
      expect(live.connected, isTrue);
      live.dispose();
    });

    testWidgets('an event from the server connects at once', (tester) async {
      final live = open();
      server.last.down.add(_presence(_dad, 'Dad'));
      await tester.pump();
      expect(live.connected, isTrue);
      expect(live.present, ['Dad']);
      live.dispose();
    });

    testWidgets('reconnects with the shared backoff: 1, 2, 4 ... 30 seconds', (
      tester,
    ) async {
      server.refuse = true;
      final live = open();
      await tester.pump();
      expect(server.calls, hasLength(1));
      expect(live.connected, isFalse);

      // Waits of 1, 2, 4, 8, 16 seconds, then capped at 30.
      var opened = 1;
      for (final wait in const [1, 2, 4, 8, 16, 30, 30]) {
        await tester.pump(
          Duration(seconds: wait) - const Duration(milliseconds: 1),
        );
        expect(server.calls, hasLength(opened), reason: 'before ${wait}s');
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump();
        opened++;
        expect(server.calls, hasLength(opened), reason: 'after ${wait}s');
      }
      expect(live.connected, isFalse);
      live.dispose();
    });

    testWidgets('hearing from the server starts the backoff over', (
      tester,
    ) async {
      server.refuse = true;
      final live = open();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(server.calls, hasLength(3));

      // The fourth attempt gets through, then drops.
      server.refuse = false;
      await tester.pump(const Duration(seconds: 4));
      expect(server.calls, hasLength(4));
      server.last.down.add(_presence(_dad, 'Dad'));
      await tester.pump();
      expect(live.connected, isTrue);

      server.last.down.addError(StateError('dropped'));
      await tester.pump();
      expect(live.connected, isFalse);
      expect(live.present, isEmpty);

      await tester.pump(const Duration(milliseconds: 999));
      expect(server.calls, hasLength(4));
      await tester.pump(const Duration(milliseconds: 1));
      expect(server.calls, hasLength(5));
      live.dispose();
    });

    testWidgets('a stream the server ends is reopened too', (tester) async {
      final live = open();
      await settle(tester);
      await server.last.down.close();
      await tester.pump();
      expect(live.connected, isFalse);
      await tester.pump(const Duration(seconds: 1));
      expect(server.calls, hasLength(2));
      live.dispose();
    });

    testWidgets('does not connect while the device is offline', (tester) async {
      final sync = FakeSyncStatus(state: SyncState.offline);
      final live = open(sync: sync);
      await tester.pump(const Duration(minutes: 1));
      expect(server.calls, isEmpty);

      sync.state = SyncState.connecting;
      await tester.pump();
      expect(server.calls, hasLength(1));
      await settle(tester);
      expect(live.connected, isTrue);

      sync.state = SyncState.offline;
      await tester.pump();
      expect(live.connected, isFalse);
      expect(server.last.closedByClient, isTrue);
      await tester.pump(const Duration(minutes: 1));
      expect(server.calls, hasLength(1));
      live.dispose();
    });

    testWidgets('sync getting through cuts a long wait short, once', (
      tester,
    ) async {
      server.refuse = true;
      final sync = FakeSyncStatus(state: SyncState.backoff);
      final live = open(sync: sync);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(server.calls, hasLength(2));

      sync.state = SyncState.live;
      await tester.pump();
      expect(server.calls, hasLength(3));

      // More news from sync while it stays live is not another kick.
      sync.hasUnsent = true;
      await tester.pump();
      expect(server.calls, hasLength(3));
      live.dispose();
    });

    testWidgets('dispose closes the stream and stops retrying', (tester) async {
      final live = open();
      await settle(tester);
      final call = server.last;
      live.dispose();
      await tester.pump();
      expect(call.closedByClient, isTrue);
      await tester.pump(const Duration(minutes: 2));
      expect(server.calls, hasLength(1));
    });
  });

  group('pulses', () {
    testWidgets('a pulse glows, then is cleared after about 2.5 seconds', (
      tester,
    ) async {
      final live = open();
      var notified = 0;
      server.last.down.add(
        LiveEvent(
          kind: LiveKind.pulse,
          tileId: UuidValue.fromString(_tile),
          fromUser: _dad,
          fromName: 'Dad',
        ),
      );
      await tester.pump();
      live.addListener(() => notified++);
      expect(live.pulsing, {_tile});

      await tester.pump(const Duration(milliseconds: 2400));
      expect(live.pulsing, {_tile});
      await tester.pump(const Duration(milliseconds: 100));
      expect(live.pulsing, isEmpty);
      expect(notified, 1);
      expect(livePulseFor, const Duration(milliseconds: 2500));
      live.dispose();
    });

    testWidgets('a repeated pulse starts the 2.5 seconds over', (tester) async {
      final live = open();
      LiveEvent pulse() => LiveEvent(
        kind: LiveKind.pulse,
        tileId: UuidValue.fromString(_tile),
      );
      server.last.down.add(pulse());
      await tester.pump(const Duration(seconds: 2));
      server.last.down.add(pulse());
      await tester.pump(const Duration(seconds: 2));
      expect(live.pulsing, {_tile});
      await tester.pump(const Duration(milliseconds: 500));
      expect(live.pulsing, isEmpty);
      live.dispose();
    });

    testWidgets('sendPulse sends the tile and glows here as well', (
      tester,
    ) async {
      final live = open();
      await settle(tester);
      live.sendPulse(_tile.toUpperCase());
      await tester.pump();
      final sent = server.last.of(LiveKind.pulse);
      expect(sent, hasLength(1));
      expect(sent.single.tileId, UuidValue.fromString(_tile));
      expect(live.pulsing, {_tile});
      await tester.pump(livePulseFor);
      expect(live.pulsing, isEmpty);
      live.dispose();
    });

    testWidgets('sendPulse does nothing while disconnected', (tester) async {
      server.refuse = true;
      final live = open();
      await tester.pump();
      live.sendPulse(_tile);
      await tester.pump();
      expect(live.pulsing, isEmpty);
      expect(server.calls.expand((call) => call.of(LiveKind.pulse)), isEmpty);
      live.dispose();
    });

    testWidgets('sendPulse ignores an id that is not a tile id', (
      tester,
    ) async {
      final live = open();
      await settle(tester);
      live.sendPulse('not-a-uuid');
      await tester.pump();
      expect(server.last.of(LiveKind.pulse), isEmpty);
      expect(live.pulsing, isEmpty);
      live.dispose();
    });

    testWidgets('a drop clears what was glowing', (tester) async {
      final live = open();
      await settle(tester);
      live.sendPulse(_tile);
      server.last.down.addError(StateError('dropped'));
      await tester.pump();
      expect(live.pulsing, isEmpty);
      live.dispose();
    });
  });

  group('what is said', () {
    testWidgets('shareSaid is off by default and then nothing is sent', (
      tester,
    ) async {
      final live = open();
      await settle(tester);
      expect(live.shareSaid, isFalse);
      live.sendSaid('I want more');
      await tester.pump();
      expect(server.last.of(LiveKind.said), isEmpty);
      // Only presence ever went up.
      expect(
        server.last.sent.every((event) => event.kind == LiveKind.presence),
        isTrue,
      );
      expect(server.last.sent.every((event) => event.text == null), isTrue);
      live.dispose();
    });

    testWidgets('with shareSaid on the sentence is sent', (tester) async {
      final live = open();
      await settle(tester);
      live.shareSaid = true;
      live.sendSaid('  I want more ');
      live.sendSaid('   ');
      await tester.pump();
      expect(server.last.of(LiveKind.said).map((e) => e.text), ['I want more']);

      live.shareSaid = false;
      live.sendSaid('stop');
      await tester.pump();
      expect(server.last.of(LiveKind.said), hasLength(1));
      live.dispose();
    });

    testWidgets('sendSaid does nothing while disconnected', (tester) async {
      server.refuse = true;
      final live = open();
      live.shareSaid = true;
      await tester.pump();
      live.sendSaid('I want more');
      await tester.pump();
      expect(server.calls.expand((call) => call.of(LiveKind.said)), isEmpty);
      live.dispose();
    });

    testWidgets('only a guardian can turn sharing on', (tester) async {
      final saved = <bool>[];
      final live = open(
        mayShareSaid: false,
        load: () async => true,
        save: (value) async => saved.add(value),
      );
      await settle(tester);
      expect(live.shareSaid, isFalse);
      live.shareSaid = true;
      expect(live.shareSaid, isFalse);
      live.sendSaid('I want more');
      await tester.pump();
      expect(server.last.of(LiveKind.said), isEmpty);
      expect(saved, isEmpty);
      live.dispose();
    });

    testWidgets('the saved switch is restored and changes are saved', (
      tester,
    ) async {
      final saved = <bool>[];
      final live = open(
        load: () async => true,
        save: (value) async => saved.add(value),
      );
      var notified = 0;
      live.addListener(() => notified++);
      expect(live.shareSaid, isFalse);
      await tester.pump();
      expect(live.shareSaid, isTrue);
      expect(notified, 1);
      expect(saved, isEmpty);

      live.shareSaid = false;
      expect(saved, [false]);
      live.dispose();
    });

    testWidgets('a choice made before the saved value arrives wins', (
      tester,
    ) async {
      final loading = Completer<bool>();
      final live = open(load: () => loading.future);
      live.shareSaid = false;
      loading.complete(true);
      await tester.pump();
      expect(live.shareSaid, isFalse);
      live.dispose();
    });

    testWidgets('an unreadable or unwritable setting changes nothing else', (
      tester,
    ) async {
      final live = open(
        load: () async => throw StateError('unreadable'),
        save: (_) async => throw StateError('read-only'),
      );
      await tester.pump();
      expect(live.shareSaid, isFalse);
      live.shareSaid = true;
      await tester.pump();
      expect(live.shareSaid, isTrue);
      live.dispose();
    });

    testWidgets('a sentence shared by another device becomes lastSaid', (
      tester,
    ) async {
      final live = open();
      expect(live.lastSaid, isNull);
      server.last.down.add(
        LiveEvent(kind: LiveKind.said, text: 'I want more', fromName: 'Mum'),
      );
      await tester.pump();
      expect(live.lastSaid, 'I want more');
      live.dispose();
    });
  });

  group('presence', () {
    testWidgets('announces itself on connecting and every ten seconds', (
      tester,
    ) async {
      final live = open();
      await tester.pump();
      expect(server.last.of(LiveKind.presence), hasLength(1));
      expect(server.last.sent.single.text, isNull);
      await settle(tester);
      await tester.pump(const Duration(seconds: 10));
      expect(server.last.of(LiveKind.presence), hasLength(2));
      live.dispose();
    });

    testWidgets(
      'lists the others, answers a newcomer once, forgets the silent',
      (
        tester,
      ) async {
        final live = open();
        await settle(tester);
        expect(server.last.of(LiveKind.presence), hasLength(1));

        server.last.down.add(_presence(_dad, 'Dad'));
        await tester.pump();
        expect(live.present, ['Dad']);
        expect(server.last.of(LiveKind.presence), hasLength(2));

        // Known already: no answer, or two devices would talk for ever.
        server.last.down.add(_presence(_dad, 'Dad'));
        server.last.down.add(_presence(_gran, 'Gran'));
        await tester.pump();
        expect(live.present, ['Dad', 'Gran']);
        expect(server.last.of(LiveKind.presence), hasLength(3));

        // Gran keeps reporting; Dad goes quiet.
        await tester.pump(const Duration(seconds: 20));
        server.last.down.add(_presence(_gran, 'Gran'));
        await tester.pump(const Duration(seconds: 6));
        expect(live.present, ['Gran']);
        live.dispose();
      },
    );

    testWidgets("the server's words are never shown as names", (tester) async {
      final live = open();
      server.last.down.add(_presence(_dad, 'Dad', text: 'joined'));
      server.last.down.add(_presence(_gran, 'Gran'));
      server.last.down.add(LiveEvent(kind: LiveKind.presence, text: 'here'));
      await tester.pump();
      expect(live.present, ['Dad', 'Gran', 'Someone']);
      live.dispose();
    });

    testWidgets('a member who leaves is removed at once', (tester) async {
      final live = open();
      server.last.down.add(_presence(_dad, 'Dad', text: 'joined'));
      server.last.down.add(_presence(_gran, 'Gran', text: 'joined'));
      await tester.pump();
      expect(live.present, ['Dad', 'Gran']);

      var notified = 0;
      live.addListener(() => notified++);
      server.last.down.add(_presence(_dad, 'Dad', text: 'left'));
      await tester.pump();
      expect(live.present, ['Gran']);
      expect(notified, 1);

      // Leaving twice, or leaving unseen, changes nothing.
      server.last.down.add(_presence(_dad, 'Dad', text: 'left'));
      await tester.pump();
      expect(live.present, ['Gran']);
      expect(notified, 1);
      live.dispose();
    });

    testWidgets('two devices of one adult are one name, and it stays while '
        'either is joined', (tester) async {
      final live = open();
      server.last.down.add(_presence(_dad, 'Dad', text: 'joined'));
      server.last.down.add(_presence(_dad, 'Dad', text: 'joined'));
      await tester.pump();
      expect(live.present, ['Dad']);

      // One of them closes: the server sends `left`, then the other
      // device's `here`.
      server.last.down.add(_presence(_dad, 'Dad', text: 'left'));
      server.last.down.add(_presence(_dad, 'Dad'));
      await tester.pump();
      expect(live.present, ['Dad']);
      live.dispose();
    });
  });

  group('a refused stream', () {
    testWidgets('is not reopened when the server says not a member', (
      tester,
    ) async {
      final sync = FakeSyncStatus();
      final live = open(sync: sync);
      server.last.down.addError(
        CircleException(failure: CircleFailure.notAMember),
      );
      await tester.pump();
      expect(live.connected, isFalse);
      expect(live.refused, isTrue);

      await tester.pump(const Duration(minutes: 2));
      sync.state = SyncState.backoff;
      sync.state = SyncState.live;
      await tester.pump(const Duration(minutes: 2));
      expect(server.calls, hasLength(1));
      live.dispose();
    });
  });
}
