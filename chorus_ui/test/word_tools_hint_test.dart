// On a phone the word tools have no key of their own, so the adult screens
// say how to reach them: hold the sentence strip.
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/editor/editor_screen.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/features/flags/w4.dart';
import 'package:chorus_ui/features/quick_phrases_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features_harness.dart';

void main() {
  for (final role in [CircleRole.guardian, CircleRole.partner]) {
    for (final size in featureSizes) {
      testWidgets('the editor tells a ${role.name} how a phone reaches the '
          'word tools at ${size.width.toInt()}x${size.height.toInt()}', (
        tester,
      ) async {
        setScreen(tester, size);
        final store = FakeBoardStore.seeded()..role = role;
        await tester.pumpWidget(
          featureApp(EditorScreen(store: store, sync: FakeSyncStatus())),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        final hint = find.text(wordToolsOnPhoneHint(store.childName));
        if (!w4AnyWordTool || w4WordToolsOnPhones) {
          expect(hint, findsNothing);
          return;
        }
        // On a phone it sits under the board, on the page that scrolls.
        final page = find.byType(ListView);
        if (page.evaluate().isNotEmpty) {
          await tester.scrollUntilVisible(
            hint,
            200,
            scrollable: find
                .descendant(of: page, matching: find.byType(Scrollable))
                .first,
          );
        }
        expect(hint, findsOneWidget);
      });
    }
  }

  test('the hint and the quick phrases page name the hold', () {
    expect(wordToolsOnPhoneHint('Maya'), contains('hold the sentence strip'));
    expect(wordToolsOnPhoneHint('Maya'), contains('word endings'));
    expect(wordToolsOnPhoneHint('Maya'), contains('quick phrases'));
    expect(wordToolsOnPhoneHint('Maya'), contains('keyboard'));
    expect(quickPhrasesIntro, contains('holding the sentence strip'));
  });
}
