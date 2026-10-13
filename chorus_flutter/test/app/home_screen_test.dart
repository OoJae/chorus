import 'dart:async';

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_flutter/screens/home_screen.dart';
import 'package:chorus_flutter/screens/signed_in_shell.dart';
import 'package:chorus_shared/chorus_shared.dart' show BoardFacts;
import 'package:chorus_ui/contracts.dart' show BoardStore;
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/widgets/sync_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// A circle whose board has not reached this device.
class _NoBoardYet extends FakeBoardStore {
  _NoBoardYet() : super.seeded();

  @override
  List<BoardFacts> get boards => const [];
}

void main() {
  /// Home for [selected] on fresh fakes.
  Future<FakeGateway> pumpHome(
    WidgetTester tester,
    CircleInfo selected, {
    List<CircleInfo>? circles,
    CircleReadiness readiness = CircleReadiness.ready,
    VoidCallback? onRetryReady,
    ValueChanged<CircleInfo>? onSelect,
    BoardStore? store,
  }) async {
    final gateway = FakeGateway();
    final workspace = FakeWorkspace();
    await pumpScreen(
      tester,
      HomeScreen(
        circles: circles ?? [selected],
        selected: selected,
        onSelect: onSelect ?? (_) {},
        store: store ?? workspace.boardStore(selected),
        sync: workspace.sync,
        speech: FakeSpeech(),
        gateway: gateway,
        readiness: readiness,
        onRetryReady: onRetryReady ?? () {},
        onSignOut: () {},
      ),
    );
    return gateway;
  }

  testWidgets('a guardian sees every action and the sync chip', (tester) async {
    await pumpHome(tester, circle());

    expect(find.text("Maya's board"), findsOneWidget);
    for (final label in [
      'Talker',
      'Edit board',
      'Invite someone',
      'Credits',
      'Sign out',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.byType(SyncChip), findsOneWidget);
    expect(find.text('Up to date'), findsOneWidget);
    // One circle: no switcher.
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('a partner can view but is not offered editing or inviting', (
    tester,
  ) async {
    await pumpHome(tester, circle(role: CircleRole.partner, myName: 'Gran'));

    expect(find.text('View board'), findsOneWidget);
    expect(find.text('Edit board'), findsNothing);
    expect(find.text('Invite someone'), findsNothing);
    expect(find.text('Talker'), findsOneWidget);
  });

  testWidgets('a therapist can edit but not invite', (tester) async {
    await pumpHome(tester, circle(role: CircleRole.therapist));

    expect(find.text('Edit board'), findsOneWidget);
    expect(find.text('Invite someone'), findsNothing);
  });

  testWidgets('inviting shows the code large with a copy button', (
    tester,
  ) async {
    final gateway = await pumpHome(tester, circle());

    await tester.tap(find.text('Invite someone'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Family or friend who can view'));
    await tester.pump();
    await tester.tap(find.text('Make a code'));
    await tester.pumpAndSettle();

    expect(gateway.invited, [CircleRole.partner]);
    expect(find.text('ABC234'), findsOneWidget);
    expect(find.text('Copy code'), findsOneWidget);
  });

  testWidgets('a refused invite is explained and can be retried', (
    tester,
  ) async {
    final gateway = await pumpHome(tester, circle());
    gateway.failNext = CircleException(failure: CircleFailure.notAllowed);

    await tester.tap(find.text('Invite someone'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Make a code'));
    await tester.pumpAndSettle();

    expect(find.text('Only a parent or guardian can do that.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('ABC234'), findsOneWidget);
  });

  testWidgets('with more than one circle a switcher chooses between them', (
    tester,
  ) async {
    final maya = circle();
    final sam = circle(space: samSpace, childName: 'Sam');
    CircleInfo? chosen;
    await pumpHome(
      tester,
      maya,
      circles: [maya, sam],
      onSelect: (circle) => chosen = circle,
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Sam'));
    expect(chosen?.childName, 'Sam');
  });

  testWidgets('a circle that could not be readied says so and offers Retry', (
    tester,
  ) async {
    var retries = 0;
    await pumpHome(
      tester,
      circle(),
      readiness: CircleReadiness.failed,
      onRetryReady: () => retries++,
    );

    expect(find.textContaining('could not check in'), findsOneWidget);
    // The board saved on the device still opens.
    expect(
      tester
          .widget<FilledButton>(
            find.ancestor(
              of: find.text('Talker'),
              matching: find.bySubtype<FilledButton>(),
            ),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });

  testWidgets('a ready circle with no board yet explains and offers Retry', (
    tester,
  ) async {
    var retries = 0;
    await pumpHome(
      tester,
      circle(role: CircleRole.therapist),
      store: _NoBoardYet(),
      onRetryReady: () => retries++,
    );

    expect(find.textContaining('There is no board here yet'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.ancestor(
              of: find.text('Talker'),
              matching: find.bySubtype<FilledButton>(),
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });

  group('signed-in shell', () {
    testWidgets('Retry joins the readying call still under way', (
      tester,
    ) async {
      final workspace = FakeWorkspace()..readyGate = Completer<void>();
      await pumpScreen(
        tester,
        SignedInShell(
          gateway: FakeGateway(circles: [circle()]),
          openWorkspace: () async => workspace,
          speech: FakeSpeech(),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(workspace.readied, hasLength(1));

      // The wait is given up on; the work is not.
      await tester.pump(const Duration(seconds: 46));
      expect(find.textContaining('could not check in'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(workspace.readied, hasLength(1), reason: 'no second call');
      expect(workspace.sync.syncNowCalls, 1);

      workspace.readyGate!.complete();
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('could not check in'), findsNothing);
      expect(find.textContaining('Checking for changes'), findsNothing);
    });

    testWidgets('sign out does not wait for ever on a replica that hangs', (
      tester,
    ) async {
      final gateway = FakeGateway(circles: [circle()]);
      final workspace = FakeWorkspace()..closeGate = Completer<void>();
      await pumpScreen(
        tester,
        SignedInShell(
          gateway: gateway,
          openWorkspace: () async => workspace,
          speech: FakeSpeech(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign out'));
      await tester.pump(const Duration(seconds: 4));
      expect(gateway.signOuts, 0);
      await tester.pump(const Duration(seconds: 2));
      expect(gateway.signOuts, 1);
    });

    testWidgets('remembered circles open home with no server answer', (
      tester,
    ) async {
      final gateway = FakeGateway(remembered: [circle()])
        ..failNext = Exception('offline');
      final workspace = FakeWorkspace()..failNextReady = Exception('offline');
      await pumpScreen(
        tester,
        SignedInShell(
          gateway: gateway,
          openWorkspace: () async => workspace,
          speech: FakeSpeech(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Maya's board"), findsOneWidget);
      expect(find.textContaining('could not check in'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.textContaining('could not check in'), findsNothing);
      expect(workspace.readied, [('Maya', true), ('Maya', true)]);
    });

    testWidgets('no signal and nothing remembered: an error with Retry', (
      tester,
    ) async {
      final gateway = FakeGateway(circles: [circle()])
        ..failNext = Exception('offline');
      await pumpScreen(
        tester,
        SignedInShell(
          gateway: gateway,
          openWorkspace: () async => FakeWorkspace(),
          speech: FakeSpeech(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('could not reach the server'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text("Maya's board"), findsOneWidget);
    });

    testWidgets('a replica that will not open offers Retry', (tester) async {
      var attempts = 0;
      await pumpScreen(
        tester,
        SignedInShell(
          gateway: FakeGateway(circles: [circle()]),
          openWorkspace: () async {
            if (attempts++ == 0) throw StateError('locked');
            return FakeWorkspace();
          },
          speech: FakeSpeech(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('could not open the boards'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text("Maya's board"), findsOneWidget);
    });

    testWidgets('an invited member does not seed the starter board', (
      tester,
    ) async {
      final workspace = FakeWorkspace();
      await pumpScreen(
        tester,
        SignedInShell(
          gateway: FakeGateway(circles: [circle(role: CircleRole.teacher)]),
          openWorkspace: () async => workspace,
          speech: FakeSpeech(),
        ),
      );
      await tester.pumpAndSettle();

      expect(workspace.readied, [('Maya', false)]);
    });

    testWidgets('sign out closes the replica, then signs out', (tester) async {
      final gateway = FakeGateway(circles: [circle()]);
      final workspace = FakeWorkspace();
      await pumpScreen(
        tester,
        SignedInShell(
          gateway: gateway,
          openWorkspace: () async => workspace,
          speech: FakeSpeech(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign out'));
      await tester.pump();
      await tester.pump();

      expect(workspace.closed, isTrue);
      expect(gateway.signOuts, 1);
      // While the auth state catches up the screen says what is happening.
      expect(find.text('Signing out…'), findsOneWidget);
    });
  });
}
