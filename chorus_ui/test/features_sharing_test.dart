import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts_sharing.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_features.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var clock = DateTime.utc(2026, 10, 14, 9);
  DateTime now() => clock;

  final store = FakeBoardStore.seeded();
  BoardFacts home() =>
      store.boards.singleWhere((board) => board.id == store.homeBoardId);

  setUp(() => clock = DateTime.utc(2026, 10, 14, 9));

  test('a view-only link lasts seven days', () async {
    final sharing = FakeBoardSharing(now: now);
    expect(sharing, isA<BoardSharing>());
    final link = await sharing.shareViewOnly(home());
    expect(link.expiresAt, DateTime.utc(2026, 10, 21, 9));
    expect(sharing.isOpen(link), isTrue);
    clock = DateTime.utc(2026, 10, 21, 9);
    expect(sharing.isOpen(link), isFalse);
  });

  test(
    'a withdrawn link stops opening, and withdrawing twice is safe',
    () async {
      final sharing = FakeBoardSharing(now: now);
      final link = await sharing.shareViewOnly(home());
      final other = await sharing.shareViewOnly(home());
      expect(other.url, isNot(link.url));
      await sharing.withdraw(link);
      await sharing.withdraw(link);
      expect(sharing.isOpen(link), isFalse);
      expect(sharing.isOpen(other), isTrue);
      expect(sharing.shared, [link, other]);
    },
  );

  test('export gives a link to an .obf file of the board', () async {
    final sharing = FakeBoardSharing(store: store, now: now);
    final url = await sharing.exportObf(home());
    expect(url.path, endsWith('.obf'));
    final obf = parseObf(sharing.exported[url]!);
    expect(obf.name, 'Home');
    expect(obfPlacements(obf).fitted, hasLength(36));
  });

  test('every call needs a connection, and says so plainly', () async {
    final sharing = FakeBoardSharing(now: now);
    final link = await sharing.shareViewOnly(home());
    sharing.online = false;
    await expectLater(
      sharing.shareViewOnly(home()),
      throwsA(isA<SharingFailed>()),
    );
    await expectLater(sharing.withdraw(link), throwsA(isA<SharingFailed>()));
    await expectLater(
      sharing.exportObf(home()),
      throwsA(
        isA<SharingFailed>().having(
          (e) => e.message,
          'message',
          allOf(contains('connection'), isNot(contains('!'))),
        ),
      ),
    );
    expect(sharing.isOpen(link), isTrue);
  });
}
