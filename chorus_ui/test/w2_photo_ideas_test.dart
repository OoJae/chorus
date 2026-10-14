// Photo ideas as small word tiles: a tap fills the form, and "Add all to
// Needs a home" puts them in the tray without taking a spot.
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts_photo_ideas.dart';
import 'package:chorus_ui/editor/photo_ideas_strip.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features_harness.dart';

void main() {
  const ideas = [
    WordIdea(label: 'swing', colorKey: 'noun'),
    WordIdea(label: 'push', colorKey: 'verb'),
    WordIdea(label: 'high', colorKey: 'descriptor'),
  ];

  testWidgets('a tap uses the idea; Add all is offered', (tester) async {
    setScreen(tester, const Size(400, 800));
    WordIdea? used;
    var all = 0;
    await tester.pumpWidget(
      featureApp(
        Scaffold(
          body: PhotoIdeasStrip(
            ideas: ideas,
            onUse: (idea) => used = idea,
            onAddAll: () => all++,
          ),
        ),
      ),
    );
    expect(find.text(photoIdeasIntro), findsOneWidget);
    await tester.tap(find.text('push'));
    expect(used?.label, 'push');
    await tester.tap(find.text(addAllToTrayLabel));
    expect(all, 1);
  });

  test(
    'Add all puts every idea in the tray and moves no placed word',
    () async {
      final store = FakeBoardStore.seeded();
      final before = gridOf(store.homeBoardId, store.tiles, store.boards);
      final added = await addIdeasToTray(store, store.homeBoardId, ideas);
      expect(added, 3);
      final tray = trayOf(store.tiles, store.boards).map((e) => e.tile.label);
      expect(tray, containsAll(['swing', 'push', 'high']));
      expect(gridOf(store.homeBoardId, store.tiles, store.boards), before);
    },
  );

  test('the tray line counts the words', () {
    expect(ideasInTrayMessage(1), contains('1 word waits'));
    expect(ideasInTrayMessage(3), contains('3 words wait'));
  });
}
