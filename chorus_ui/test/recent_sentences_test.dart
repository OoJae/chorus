// "Recent" keeps one list for each child's circle, and a sign-out forgets
// them all.
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/talker/recent_sentences.dart';
import 'package:chorus_ui/talker/talker_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(RecentSentences.clearAll);

  test('one child\'s sentences never show on another child\'s board', () {
    RecentSentences.useCircle('maya');
    RecentSentences.session.add('I feel sick');
    RecentSentences.useCircle('sam');
    expect(RecentSentences.session.sentences, isEmpty);
    RecentSentences.session.add('more juice');
    RecentSentences.useCircle('maya');
    expect(RecentSentences.session.sentences, ['I feel sick']);
  });

  test('a sign-out forgets every circle\'s list', () {
    RecentSentences.useCircle('maya');
    final maya = RecentSentences.session..add('I feel sick');
    RecentSentences.useCircle('sam');
    RecentSentences.session.add('more juice');
    RecentSentences.clearAll();
    expect(maya.sentences, isEmpty, reason: 'an open list is emptied too');
    expect(RecentSentences.session.sentences, isEmpty);
    RecentSentences.useCircle('maya');
    expect(RecentSentences.session.sentences, isEmpty);
    RecentSentences.useCircle('sam');
    expect(RecentSentences.session.sentences, isEmpty);
  });

  test('"Say it again" says what the board said, not only the labels', () {
    RecentSentences.useCircle('maya');
    const toilet = TileFacts(
      id: 't',
      boardId: 'b',
      cellKey: 'b:0:0',
      label: 'toilet',
      speech: 'I need the toilet',
    );
    const now = TileFacts(
      id: 'n',
      boardId: 'b',
      cellKey: 'b:0:1',
      label: 'now',
    );
    noteSentenceSpoken([toilet, now]);
    final recent = RecentSentences.session;
    expect(recent.sentences, ['toilet now'], reason: 'listed as it reads');
    expect(recent.spokenOf('toilet now'), 'I need the toilet now');
    // A sentence whose words say their labels is said as listed.
    recent.add('want more');
    expect(recent.spokenOf('want more'), 'want more');
  });
}
