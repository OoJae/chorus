// Home's entries for "What changed", "Suggest a word" and "People in this
// circle", on fakes for the server parts.
import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_flutter/screens/home_screen.dart';
import 'package:chorus_flutter/screens/services.dart';
import 'package:chorus_flutter/src/activity/w2_parts.dart';
import 'package:chorus_ui/activity/activity_screen.dart';
import 'package:chorus_ui/activity/activity_text.dart';
import 'package:chorus_ui/activity/members_screen.dart';
import 'package:chorus_ui/contracts.dart' show BoardStore;
import 'package:chorus_ui/contracts_activity.dart';
import 'package:chorus_ui/contracts_edits.dart' show EditFacts;
import 'package:chorus_ui/editor/word_suggestions_tray.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_activity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late FakeWordSuggestions suggestions;
  late FakeCircleMembers members;

  setUp(() {
    suggestions = FakeWordSuggestions();
    members = FakeCircleMembers([
      const CircleMember(userId: 'a', name: 'Mum', roleName: 'Guardian'),
    ]);
    w2RemoteFor = (circle, userId) =>
        (suggestions: suggestions, members: members, sitterTaps: null);
    final looks = <String, String>{};
    w2LooksStorage = (
      read: (name) async => looks[name],
      write: (name, text) async => looks[name] = text,
    );
  });

  tearDown(() {
    w2RemoteFor = null;
    w2LooksStorage = null;
  });

  Future<void> pumpHome(
    WidgetTester tester,
    CircleInfo selected,
    String userId, {
    BoardStore? store,
  }) async {
    final workspace = FakeWorkspace();
    await pumpScreen(
      tester,
      HomeScreen(
        circles: [selected],
        selected: selected,
        onSelect: (_) {},
        store: store ?? workspace.boardStore(selected),
        sync: workspace.sync,
        speech: FakeSpeech(),
        gateway: FakeGateway(),
        readiness: CircleReadiness.ready,
        onRetryReady: () {},
        onSignOut: () {},
        services: CircleServices(userId: userId),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a guardian gets What changed and the people in the circle', (
    tester,
  ) async {
    await pumpHome(tester, circle(), 'w2-guardian');
    await tester.ensureVisible(find.text(activityTitle));
    expect(find.text(activityTitle), findsOneWidget);
    expect(find.text(membersTitle), findsOneWidget);
    expect(find.text(suggestWordLabel), findsNothing);

    await tester.tap(find.text(activityTitle));
    await tester.pumpAndSettle();
    expect(find.byType(ActivityScreen), findsOneWidget);
  });

  testWidgets('a read-only partner suggests a word from home', (tester) async {
    await pumpHome(
      tester,
      circle(role: CircleRole.partner, myName: 'Gran'),
      'w2-partner',
    );
    await tester.ensureVisible(find.text(suggestWordLabel));
    await tester.tap(find.text(suggestWordLabel));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'swing');
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(suggestions.suggested, ['swing']);
  });

  testWidgets('without a server only What changed is offered', (
    tester,
  ) async {
    w2RemoteFor = null;
    await pumpHome(tester, circle(), 'w2-alone');
    await tester.ensureVisible(find.text(activityTitle));
    expect(find.text(activityTitle), findsOneWidget);
    expect(find.text(membersTitle), findsNothing);
  });

  testWidgets('the banner counts changes not yet looked at, and opens the '
      'feed', (tester) async {
    final store = FakeActivityStore.seeded();
    final cup = store.tiles.first;
    EditFacts rename(String id) => EditFacts(
      id: id,
      tileId: cup.id,
      prop: 'label',
      oldValue: 'a',
      newValue: cup.label,
      reason: 'edit',
      actorId: 'r',
      actorName: 'Ms Rivera',
      editedAt: DateTime.now().toUtc(),
    );
    await pumpHome(tester, circle(), 'w2-banner', store: store);
    expect(find.text(sinceLastLookedText(1)), findsNothing);
    // The next change home hears of shows the banner.
    store.edits = [rename('e1')];
    await tester.pumpAndSettle();
    expect(find.text(sinceLastLookedText(1)), findsOneWidget);
    await tester.tap(find.text(sinceLastLookedAction));
    await tester.pumpAndSettle();
    expect(find.byType(ActivityScreen), findsOneWidget);
  });

  test('role names are plain', () {
    expect(roleNameOf(CircleRole.partner), 'Partner (view only)');
    expect(roleNameOf(CircleRole.guardian), 'Guardian');
  });
}
