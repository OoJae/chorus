/// Endpoint tests for the live session: who may join, what is relayed to
/// whom, what the server stamps, and presence.
library;

import 'dart:async';

import 'package:chorus_server/src/generated/protocol.dart';
import 'package:chorus_server/src/live/live_endpoint.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

/// One joined device: what it sends and everything it has received.
class Device {
  Device(Stream<LiveEvent> Function(Stream<LiveEvent>) join) {
    _subscription = join(_outgoing.stream).listen(
      (event) {
        received.add(event);
        _changed.add(null);
      },
      onError: (Object error) {
        errors.add(error);
        _changed.add(null);
      },
      onDone: () {
        done = true;
        _changed.add(null);
      },
    );
  }

  final _outgoing = StreamController<LiveEvent>();
  final _changed = StreamController<void>.broadcast();
  late final StreamSubscription<LiveEvent> _subscription;
  final received = <LiveEvent>[];
  final errors = <Object>[];
  var done = false;

  void send(LiveEvent event) => _outgoing.add(event);

  /// Waits until [test] holds for what has been received so far.
  Future<void> until(bool Function() test) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!test()) {
      final left = deadline.difference(DateTime.now());
      if (left.isNegative) fail('Timed out. Received: $received $errors');
      await _changed.stream.first.timeout(left, onTimeout: () {});
    }
  }

  /// The first event of [kind] carrying [text], once it has arrived.
  Future<LiveEvent> next(LiveKind kind, {String? text, String? from}) async {
    bool matches(LiveEvent e) =>
        e.kind == kind &&
        (text == null || e.text == text) &&
        (from == null || e.fromName == from);
    await until(() => received.any(matches));
    return received.firstWhere(matches);
  }

  Future<void> leave() async {
    await _subscription.cancel();
    // Not awaited: a stream nobody listened to never finishes closing.
    unawaited(_outgoing.close());
  }
}

/// Lets relayed events and their answers settle.
Future<void> settle() async {
  for (var i = 0; i < 5; i++) {
    await flushEventQueue();
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  withServerpod('Given the live endpoint,', (sessionBuilder, endpoints) {
    final session = sessionBuilder.build();
    final devices = <Device>[];

    tearDown(() async {
      for (final device in devices) {
        await device.leave();
      }
      devices.clear();
      await settle();
    });

    TestSessionBuilder signedIn(UuidValue id) => sessionBuilder.copyWith(
      authentication: AuthenticationOverride.authenticationInfo(id.uuid, {}),
    );

    /// Adds a member named [name] to [space] and returns their id.
    Future<UuidValue> member(
      UuidValue space,
      String name, [
      CircleRole role = CircleRole.guardian,
    ]) async {
      final id = const Uuid().v7obj();
      await Membership.db.insertRow(
        session,
        Membership(
          circleSpace: space,
          userId: id,
          role: role,
          displayName: name,
          joinedAt: DateTime.now().toUtc(),
        ),
      );
      return id;
    }

    /// Joins [space] as [who] and waits until the server has let them in.
    Future<Device> join(UuidValue space, UuidValue who) async {
      final device = Device(
        (outgoing) => endpoints.live.join(signedIn(who), space, outgoing),
      );
      devices.add(device);
      await settle();
      return device;
    }

    test('when nobody is signed in then joining is refused.', () async {
      final device = Device(
        (outgoing) =>
            endpoints.live.join(sessionBuilder, const Uuid().v7obj(), outgoing),
      );
      devices.add(device);
      await device.until(() => device.errors.isNotEmpty);
      expect(device.errors.single, isA<ServerpodUnauthenticatedException>());
    });

    test('when someone outside the circle joins then they are refused and '
        'the members hear nothing.', () async {
      final space = const Uuid().v7obj();
      final mum = await join(space, await member(space, 'Mum'));
      final strangerId = await member(const Uuid().v7obj(), 'Stranger');

      final stranger = Device(
        (outgoing) =>
            endpoints.live.join(signedIn(strangerId), space, outgoing),
      );
      devices.add(stranger);
      await stranger.until(() => stranger.errors.isNotEmpty);

      expect(
        stranger.errors.single,
        isA<CircleException>().having(
          (e) => e.failure,
          'failure',
          CircleFailure.notAMember,
        ),
      );
      stranger.send(LiveEvent(kind: LiveKind.said, text: 'hello'));
      await settle();
      expect(mum.received, isEmpty);
      expect(stranger.received, isEmpty);
    });

    test('when a second member joins then each learns the other is '
        'present.', () async {
      final space = const Uuid().v7obj();
      final mumId = await member(space, 'Mum');
      final mum = await join(space, mumId);
      expect(mum.received, isEmpty, reason: 'nobody else is here yet');

      final teacherId = await member(space, 'Ms Ade', CircleRole.teacher);
      final teacher = await join(space, teacherId);

      final joined = await mum.next(LiveKind.presence, text: presenceJoined);
      expect(joined.fromUser, teacherId);
      expect(joined.fromName, 'Ms Ade');
      final here = await teacher.next(LiveKind.presence, text: presenceHere);
      expect(here.fromUser, mumId);
      expect(here.fromName, 'Mum');
      await settle();
      expect(
        teacher.received.where((e) => e.text == presenceJoined),
        isEmpty,
        reason: 'nobody is told about their own arrival',
      );
    });

    test('when a member sends a pulse then the others get it stamped by '
        'the server, and the sender gets no echo.', () async {
      final space = const Uuid().v7obj();
      final mumId = await member(space, 'Mum');
      final mum = await join(space, mumId);
      final partner = await join(
        space,
        await member(space, 'Grandad', CircleRole.partner),
      );
      final tile = const Uuid().v7obj();
      final before = DateTime.now().toUtc();

      mum.send(
        LiveEvent(
          kind: LiveKind.pulse,
          tileId: tile,
          text: 'smuggled',
          fromUser: const Uuid().v7obj(),
          fromName: 'Somebody else',
          at: DateTime.utc(1999),
        ),
      );

      final pulse = await partner.next(LiveKind.pulse);
      expect(pulse.tileId, tile);
      expect(pulse.text, isNull);
      expect(pulse.fromUser, mumId);
      expect(pulse.fromName, 'Mum');
      expect(
        pulse.at.isBefore(before.subtract(const Duration(seconds: 1))),
        isFalse,
      );
      await settle();
      expect(mum.received.where((e) => e.kind == LiveKind.pulse), isEmpty);
    });

    test('when a read-only partner sends a pulse then it is relayed '
        'too.', () async {
      final space = const Uuid().v7obj();
      final mum = await join(space, await member(space, 'Mum'));
      final partner = await join(
        space,
        await member(space, 'Grandad', CircleRole.partner),
      );

      partner.send(
        LiveEvent(kind: LiveKind.pulse, tileId: const Uuid().v7obj()),
      );

      expect((await mum.next(LiveKind.pulse)).fromName, 'Grandad');
    });

    test('when a device sends what was said then it is relayed as sent, '
        'and nothing is relayed when it sends nothing.', () async {
      final space = const Uuid().v7obj();
      final talker = await join(space, await member(space, 'Mum'));
      final teacher = await join(
        space,
        await member(space, 'Ms Ade', CircleRole.teacher),
      );

      await settle();
      expect(teacher.received.where((e) => e.kind == LiveKind.said), isEmpty);

      talker.send(LiveEvent(kind: LiveKind.said, text: ' I want more '));
      final said = await teacher.next(LiveKind.said);
      expect(said.text, 'I want more');
      expect(said.tileId, isNull);
      expect(said.fromName, 'Mum');

      talker.send(LiveEvent(kind: LiveKind.said, text: '   '));
      talker.send(LiveEvent(kind: LiveKind.said));
      talker.send(LiveEvent(kind: LiveKind.pulse));
      talker.send(LiveEvent(kind: LiveKind.said, text: 'x' * 2000));
      await teacher.until(
        () => teacher.received.where((e) => e.kind == LiveKind.said).length > 1,
      );
      await settle();
      final all = teacher.received.where((e) => e.kind != LiveKind.presence);
      expect(all, hasLength(2), reason: 'empty events are dropped');
      expect(all.last.text, hasLength(maxSaidLength));
    });

    test('when two devices share one account then each still gets the '
        "other's events.", () async {
      final space = const Uuid().v7obj();
      final mumId = await member(space, 'Mum');
      final laptop = await join(space, mumId);
      final talker = await join(space, mumId);
      final tile = const Uuid().v7obj();

      laptop.send(LiveEvent(kind: LiveKind.pulse, tileId: tile));

      expect((await talker.next(LiveKind.pulse)).tileId, tile);
      await settle();
      expect(laptop.received.where((e) => e.kind == LiveKind.pulse), isEmpty);
    });

    test('when events are sent in one circle then another circle hears '
        'nothing.', () async {
      final space = const Uuid().v7obj();
      final other = const Uuid().v7obj();
      final mum = await join(space, await member(space, 'Mum'));
      final teacher = await join(space, await member(space, 'Ms Ade'));
      final elsewhere = await join(other, await member(other, 'Dad'));

      mum.send(LiveEvent(kind: LiveKind.said, text: 'hello'));
      await teacher.next(LiveKind.said);
      await settle();

      expect(elsewhere.received, isEmpty);
    });

    test('when a member leaves then the others are told, and a client '
        'cannot fake someone leaving.', () async {
      final space = const Uuid().v7obj();
      final mum = await join(space, await member(space, 'Mum'));
      final teacherId = await member(space, 'Ms Ade', CircleRole.teacher);
      final teacher = await join(space, teacherId);

      teacher.send(LiveEvent(kind: LiveKind.presence, text: presenceLeft));
      await mum.next(LiveKind.presence, text: presenceHere, from: 'Ms Ade');
      expect(mum.received.where((e) => e.text == presenceLeft), isEmpty);

      await teacher.leave();

      final left = await mum.next(LiveKind.presence, text: presenceLeft);
      expect(left.fromUser, teacherId);
      expect(left.fromName, 'Ms Ade');

      // Nothing reaches a device that has left.
      final count = teacher.received.length;
      mum.send(LiveEvent(kind: LiveKind.said, text: 'bye'));
      await settle();
      expect(teacher.received, hasLength(count));
    });

    test('when one of two devices of the same member leaves then the '
        'other says it is still here.', () async {
      final space = const Uuid().v7obj();
      final mumId = await member(space, 'Mum');
      final teacher = await join(space, await member(space, 'Ms Ade'));
      final laptop = await join(space, mumId);
      final talker = await join(space, mumId);
      await settle();
      teacher.received.clear();

      await laptop.leave();

      await teacher.next(LiveKind.presence, text: presenceLeft, from: 'Mum');
      await teacher.next(LiveKind.presence, text: presenceHere, from: 'Mum');
      final order = teacher.received.map((e) => e.text).toList();
      expect(
        order.indexOf(presenceLeft),
        lessThan(order.lastIndexOf(presenceHere)),
      );
      expect(talker.done, isFalse);
    });
  });
}
