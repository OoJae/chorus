/// Small in-memory stand-ins for the server and the replica.
library;

import 'dart:async';

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_flutter/screens/services.dart';
import 'package:chorus_ui/contracts.dart' as ui;
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final UuidValue mayaSpace = UuidValue.fromString(
  '6f1d2c3a-0b4e-4c5d-8e9f-a1b2c3d4e5f6',
);
final UuidValue samSpace = UuidValue.fromString(
  '11111111-2222-4333-8444-555555555555',
);
final UuidValue _me = UuidValue.fromString(
  'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
);

CircleInfo circle({
  UuidValue? space,
  String childName = 'Maya',
  CircleRole role = CircleRole.guardian,
  String myName = 'Mum',
}) => CircleInfo(
  spaceUuid: space ?? mayaSpace,
  childName: childName,
  myRole: role,
  myDisplayName: myName,
  members: [MemberInfo(userId: _me, displayName: myName, role: role)],
);

/// A [CircleGateway] that answers from fields and records what was asked.
class FakeGateway implements CircleGateway {
  FakeGateway({List<CircleInfo>? circles, List<CircleInfo>? remembered})
    : circles = circles ?? [],
      remembered = remembered ?? [];

  /// What the "server" holds.
  final List<CircleInfo> circles;

  /// What this "device" saved last time.
  final List<CircleInfo> remembered;

  /// Thrown once by the next call that reaches the server, then cleared.
  Object? failNext;

  final List<(String, String)> created = [];
  final List<(String, String)> accepted = [];
  final List<CircleRole> invited = [];
  int signOuts = 0;

  void _maybeFail() {
    final error = failNext;
    failNext = null;
    if (error != null) throw error;
  }

  @override
  Future<List<CircleInfo>> myCircles() async {
    _maybeFail();
    return List.of(circles);
  }

  @override
  Future<List<CircleInfo>> rememberedCircles() async => List.of(remembered);

  @override
  Future<CircleInfo> createCircle({
    required String childName,
    required String displayName,
  }) async {
    _maybeFail();
    created.add((childName, displayName));
    final made = circle(childName: childName, myName: displayName);
    circles.add(made);
    return made;
  }

  @override
  Future<CircleInfo> acceptInvite({
    required String code,
    required String displayName,
  }) async {
    _maybeFail();
    accepted.add((code, displayName));
    final joined = circle(
      space: samSpace,
      childName: 'Sam',
      role: CircleRole.therapist,
      myName: displayName,
    );
    circles.add(joined);
    return joined;
  }

  @override
  Future<String> createInvite(CircleInfo circle, CircleRole role) async {
    _maybeFail();
    invited.add(role);
    return 'ABC234';
  }

  @override
  Future<void> signOut() async {
    signOuts++;
  }
}

/// A [Workspace] over the screens' own in-memory board store.
class FakeWorkspace implements Workspace {
  @override
  final FakeSyncStatus sync = FakeSyncStatus();

  /// (child's name, seedIfEmpty) for every [ensureCircleReady] call.
  final List<(String, bool)> readied = [];

  /// Thrown once by the next [ensureCircleReady], then cleared.
  Object? failNextReady;

  /// When set, [ensureCircleReady] waits for it before finishing.
  Completer<void>? readyGate;

  /// When set, [close] waits for it before finishing.
  Completer<void>? closeGate;

  bool closed = false;

  @override
  Future<void> ensureCircleReady(
    CircleInfo circle, {
    bool seedIfEmpty = false,
  }) async {
    readied.add((circle.childName, seedIfEmpty));
    final error = failNextReady;
    failNextReady = null;
    if (error != null) throw error;
    await readyGate?.future;
  }

  @override
  ui.BoardStore boardStore(CircleInfo circle) => FakeBoardStore.seeded(
    childName: circle.childName,
    myName: circle.myDisplayName,
    role: circle.myRole == CircleRole.partner
        ? ui.CircleRole.partner
        : ui.CircleRole.guardian,
  );

  @override
  Future<void> close() async {
    closed = true;
    await closeGate?.future;
  }
}

/// Pumps [child] in the app's theme on a surface tall enough that every
/// action on a screen is laid out.
Future<void> pumpScreen(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: chorusTheme(), home: child));
}
