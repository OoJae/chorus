import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_flutter/screens/first_run_screen.dart';
import 'package:chorus_flutter/screens/signed_in_shell.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  testWidgets('offers the three ways to get a board', (tester) async {
    await pumpScreen(
      tester,
      FirstRunScreen(gateway: FakeGateway(), onCircle: (_) {}),
    );

    expect(find.text('Start a board for my child'), findsOneWidget);
    expect(find.text('Join with a code'), findsOneWidget);
    expect(find.text('Try a demo board'), findsOneWidget);
  });

  testWidgets('the demo makes a circle for Maya in one tap', (tester) async {
    final gateway = FakeGateway();
    CircleInfo? got;
    await pumpScreen(
      tester,
      FirstRunScreen(gateway: gateway, onCircle: (circle) => got = circle),
    );

    await tester.tap(find.text('Try a demo board'));
    await tester.pumpAndSettle();

    expect(gateway.created.single.$1, 'Maya');
    expect(got?.childName, 'Maya');
  });

  testWidgets('starting a board asks for both names', (tester) async {
    final gateway = FakeGateway();
    CircleInfo? got;
    await pumpScreen(
      tester,
      FirstRunScreen(gateway: gateway, onCircle: (circle) => got = circle),
    );

    await tester.tap(find.text('Start a board for my child'));
    await tester.pumpAndSettle();

    // An empty form is refused and nothing is sent.
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.text('Please fill this in'), findsNWidgets(2));
    expect(gateway.created, isEmpty);

    await tester.enterText(find.byKey(const ValueKey('first-field')), ' Ada ');
    await tester.enterText(find.byKey(const ValueKey('second-field')), 'Dad');
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(gateway.created.single, ('Ada', 'Dad'));
    expect(got?.childName, 'Ada');
  });

  testWidgets('a refused code is explained in plain words, with Retry', (
    tester,
  ) async {
    final gateway = FakeGateway()
      ..failNext = CircleException(failure: CircleFailure.inviteUsed);
    CircleInfo? got;
    await pumpScreen(
      tester,
      FirstRunScreen(gateway: gateway, onCircle: (circle) => got = circle),
    );

    await tester.tap(find.text('Join with a code'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('first-field')), 'ABC234');
    await tester.enterText(
      find.byKey(const ValueKey('second-field')),
      'Ms Lee',
    );
    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(
      find.text('That code has already been used. Ask for a new one.'),
      findsOneWidget,
    );
    expect(got, isNull);

    // Retry repeats the same answers without asking again.
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(gateway.accepted.single, ('ABC234', 'Ms Lee'));
    expect(got?.childName, 'Sam');
  });

  testWidgets('a failure that is not about the circle still offers Retry', (
    tester,
  ) async {
    final gateway = FakeGateway()..failNext = Exception('socket closed');
    await pumpScreen(
      tester,
      FirstRunScreen(gateway: gateway, onCircle: (_) {}),
    );

    await tester.tap(find.text('Try a demo board'));
    await tester.pumpAndSettle();

    expect(find.textContaining('could not reach the server'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    // The raw error never reaches the screen.
    expect(find.textContaining('socket'), findsNothing);
  });

  testWidgets('an adult with no circle lands on the first screen, and the '
      'demo takes them home with the starter board seeded', (tester) async {
    final gateway = FakeGateway();
    final workspace = FakeWorkspace();
    await pumpScreen(
      tester,
      SignedInShell(
        gateway: gateway,
        openWorkspace: () async => workspace,
        speech: FakeSpeech(),
      ),
    );
    // The opening state is a message, not a blank screen.
    expect(find.text('Opening Chorus…'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Chorus'), findsOneWidget);

    await tester.tap(find.text('Try a demo board'));
    await tester.pumpAndSettle();

    expect(find.text("Maya's board"), findsOneWidget);
    expect(find.text('Talker'), findsOneWidget);
    expect(workspace.readied, [('Maya', true)]);
  });
}
