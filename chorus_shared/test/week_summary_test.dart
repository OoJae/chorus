import 'dart:convert';

import 'package:chorus_shared/chorus_shared.dart';
import 'package:test/test.dart';

void main() {
  // Monday 12 October 2026.
  final monday = DateTime.utc(2026, 10, 12);
  final lastWeek = DateTime.utc(2026, 10, 7, 10);

  TileFacts tile(
    String id,
    String label, {
    DateTime? createdAt,
    bool archived = false,
    String boardId = 'home',
  }) => TileFacts(
    id: id,
    boardId: boardId,
    cellKey: archived ? trayKey(id) : placedKey(boardId, 0, id.length),
    label: label,
    archived: archived,
    createdAt: createdAt ?? DateTime.utc(2026, 9, 1),
  );

  WordUse said(String tileId, DateTime at) =>
      WordUse(tileId: tileId, boardId: 'home', spokenAt: at);

  DateTime day(int d, [int hour = 9]) =>
      monday.add(Duration(days: d, hours: hour));

  final tiles = [
    tile('want', 'want'),
    tile('more', 'more'),
    tile('more2', 'More', boardId: 'words'),
    tile('go', 'go'),
    tile('stop', 'stop'),
    tile('juice', 'juice', createdAt: day(1)),
    tile('swing', 'swing', createdAt: day(2)),
    tile('old', 'old word', archived: true),
    tile('gone', 'gone', createdAt: day(3), archived: true),
  ];

  final uses = [
    said('want', lastWeek),
    said('want', day(0)),
    said('want', day(1)),
    said('want', day(4)),
    said('more', day(1)),
    said('more2', day(2)),
    said('more', day(3)),
    said('juice', day(2)),
    said('old', day(5)),
    said('go', lastWeek),
    // After the week, and of a tile nobody knows: both ignored.
    said('stop', day(8)),
    said('ghost', day(1)),
  ];

  late WeekSummary week;
  setUp(() => week = summarizeWeek(uses, tiles, monday));

  test('top words: most used first, ties by label, one word per label', () {
    expect(week.topWords, const [
      WordCount('more', 3),
      WordCount('want', 3),
      WordCount('juice', 1),
      WordCount('old word', 1),
    ]);
  });

  test('top words are cut to the limit', () {
    expect(summarizeWeek(uses, tiles, monday, top: 1).topWords, const [
      WordCount('more', 3),
    ]);
  });

  test('first time: spoken this week and never before', () {
    expect(week.firstTimeWords, ['juice', 'more', 'old word']);
  });

  test('added: created this week and still on a board', () {
    expect(week.addedWords, ['juice', 'swing']);
  });

  test('not used yet: on a board and never spoken by the end of the week', () {
    expect(week.notUsedYet, ['stop', 'swing']);
  });

  test('totals count only this week', () {
    expect(week.totalUses, 8);
    expect(week.wordsUsed, 4);
  });

  test('an empty log', () {
    final empty = summarizeWeek(const [], tiles, monday);
    expect(empty.topWords, isEmpty);
    expect(empty.firstTimeWords, isEmpty);
    expect(empty.totalUses, 0);
    expect(empty.notUsedYet, ['go', 'juice', 'more', 'stop', 'swing', 'want']);
  });

  test('the week starts on Monday 00:00 UTC', () {
    expect(weekStartOf(DateTime.utc(2026, 10, 14, 15)), monday);
    expect(weekStartOf(monday), monday);
    expect(weekStartOf(DateTime.utc(2026, 10, 18, 23, 59)), monday);
    expect(weekStartOf(DateTime.utc(2026, 10, 19)), DateTime.utc(2026, 10, 19));
    expect(week.weekEnd, DateTime.utc(2026, 10, 19));
  });

  test('round-trips through JSON', () {
    final json = jsonDecode(jsonEncode(week.toJson())) as Map<String, Object?>;
    final back = WeekSummary.fromJson(json);
    expect(back.weekStart, week.weekStart);
    expect(back.topWords, week.topWords);
    expect(back.firstTimeWords, week.firstTimeWords);
    expect(back.addedWords, week.addedWords);
    expect(back.notUsedYet, week.notUsedYet);
    expect(back.totalUses, week.totalUses);
    expect(back.wordsUsed, week.wordsUsed);
    expect(
      () => WeekSummary.fromJson({'weekStart': '2026-10-12T00:00:00Z'}),
      throwsFormatException,
    );
  });
}
