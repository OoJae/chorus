// The ready-made boards as the app bundles them from chorus_ui: found under
// packages/chorus_ui/, the path a phone or a browser loads them from.
// chorus_ui's own tests run that package as the app, where its files have
// other names, so only these tests see what the app loads.
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/editor/ready_boards.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every ready-made board is in the app under the package path, and '
      'reads as 24 words', () async {
    expect(readyBoards, hasLength(6));
    for (final board in readyBoards) {
      final text = await rootBundle.loadString(
        'packages/chorus_ui/${board.asset}',
      );
      expect(await loadReadyBoard(board), text, reason: board.name);
      final parsed = parseObf(text);
      expect(parsed.name, board.name);
      final (:fitted, :leftOver) = obfPlacements(parsed);
      expect(fitted, hasLength(24), reason: board.name);
      expect(leftOver, isEmpty, reason: board.name);
    }
  });
}
