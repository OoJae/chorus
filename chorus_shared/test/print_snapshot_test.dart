import 'dart:convert';

import 'package:chorus_shared/chorus_shared.dart';
import 'package:test/test.dart';

void main() {
  const circle = '6f1d2c3a-0b4e-4c5d-8e9f-a1b2c3d4e5f6';
  final home = starterBoard(circle);
  final starter = starterTiles(
    circleId: circle,
    createdBy: '11111111-2222-4333-8444-555555555555',
    createdByName: 'Mum',
    createdAt: DateTime.utc(2026, 10, 13),
  );

  Map<String, dynamic> snapshot(List<TileFacts> tiles) =>
      jsonDecode(
            printSnapshotJson(
              childName: 'Maya',
              board: home,
              tiles: tiles,
              boards: [home],
            ),
          )
          as Map<String, dynamic>;

  test('the starter board prints all 36 words in their cells', () {
    final json = snapshot(starter);
    expect(json['childName'], 'Maya');
    expect(json['name'], home.name);
    expect(json['rows'], 6);
    expect(json['cols'], 6);
    final tiles = (json['tiles'] as List).cast<Map<String, dynamic>>();
    expect(tiles, hasLength(36));
    expect(tiles.first, {
      'row': 0,
      'col': 0,
      'label': 'like',
      'colorKey': 'verb',
    });
    for (final word in universalCore36) {
      expect(
        tiles.where((t) => t['row'] == word.row && t['col'] == word.col).single,
        containsPair('label', word.label),
      );
    }
  });

  test('archived, tray and contested words are left off the page', () {
    final archived = starter[0].copyWith(
      archived: true,
      cellKey: trayKey(starter[0].id),
    );
    final waiting = TileFacts(
      id: '22222222-2222-4333-8444-555555555555',
      boardId: home.id,
      cellKey: trayKey('22222222-2222-4333-8444-555555555555'),
      label: 'juice',
    );
    final contested = TileFacts(
      id: '33333333-2222-4333-8444-555555555555',
      boardId: home.id,
      cellKey:
          '${placedKey(home.id, 0, 1)}__conflict__'
          '33333333-2222-4333-8444-555555555555',
      label: 'snack',
    );
    final json = snapshot([archived, ...starter.skip(1), waiting, contested]);
    final labels = [for (final t in json['tiles'] as List) (t as Map)['label']];
    expect(labels, hasLength(35));
    expect(labels, isNot(contains('like')));
    expect(labels, isNot(contains('juice')));
    expect(labels, isNot(contains('snack')));
  });

  test('a word with no colour and nothing private is sent', () {
    final plain = TileFacts(
      id: '44444444-2222-4333-8444-555555555555',
      boardId: home.id,
      cellKey: placedKey(home.id, 0, 0),
      label: 'Grandma',
      speech: 'Nana',
      imageHash: 'a' * 64,
      audioHash: 'b' * 64,
      createdByName: 'Mum',
    );
    final json = snapshot([plain]);
    expect(json['tiles'], [
      {'row': 0, 'col': 0, 'label': 'Grandma'},
    ]);
    expect(jsonEncode(json), isNot(contains('Mum')));
  });

  test('the home board is the one printed, never an archived one', () {
    const old = BoardFacts(
      id: 'b1',
      name: 'Old',
      rows: 2,
      cols: 2,
      isHome: true,
      archived: true,
    );
    const second = BoardFacts(id: 'b2', name: 'Second', rows: 2, cols: 2);
    expect(boardToPrint([old, second, home]), home);
    expect(boardToPrint([old, second]), second);
    expect(boardToPrint([old]), isNull);
  });
}
