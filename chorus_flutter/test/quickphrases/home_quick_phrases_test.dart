// Quick phrases from home: the adults' page, and the circle's phrases on
// the child's board.
import 'package:chorus_flutter/screens/home_screen.dart';
import 'package:chorus_flutter/screens/services.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_quick_phrases.dart';
import 'package:chorus_ui/features/quick_phrases_screen.dart';
import 'package:chorus_ui/talker/word_tools/word_tools.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app/fakes.dart';

void main() {
  Future<void> pumpHome(WidgetTester tester, CircleServices? services) async {
    final workspace = FakeWorkspace();
    final selected = circle();
    await pumpScreen(
      tester,
      HomeScreen(
        circles: [selected],
        selected: selected,
        onSelect: (_) {},
        store: workspace.boardStore(selected),
        sync: workspace.sync,
        speech: FakeSpeech(),
        gateway: FakeGateway(),
        readiness: CircleReadiness.ready,
        onRetryReady: () {},
        onSignOut: () {},
        services: services,
      ),
    );
  }

  testWidgets('home offers no "Quick phrases" without them', (tester) async {
    await pumpHome(tester, null);
    expect(find.text(quickPhrasesTitle), findsNothing);
  });

  testWidgets('"Quick phrases" on home opens the page with the circle\'s '
      'phrases', (tester) async {
    final book = FakeQuickPhraseBook(phrases: ['Swing please', 'Too loud']);
    await pumpHome(tester, CircleServices(userId: 'me', quickPhrases: book));
    final entry = find.text(quickPhrasesTitle);
    await tester.scrollUntilVisible(entry, 200);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.byType(QuickPhrasesScreen), findsOneWidget);
    expect(find.text('Swing please'), findsOneWidget);
  });

  testWidgets("the child's board gets the circle's phrases", (tester) async {
    final book = FakeQuickPhraseBook(phrases: ['Swing please']);
    await pumpHome(
      tester,
      CircleServices(
        userId: 'me',
        quickPhrases: book,
        wordCounts: MemorySpokenWordCounts(),
      ),
    );
    await tester.tap(find.text(openBoardLabel('Maya')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is WordToolKey && w.label == quickPhrasesLabel,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Swing please'), findsOneWidget);
  });
}
