/// The word finder: an adult types a word and sees where it is, and can make
/// it glow on the child's board.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';

import '../brand/tokens.dart';
import '../contracts.dart';
import '../contracts_live.dart';
import '../features/flags/w6.dart';

/// Title of the word finder and tooltip of the buttons that open it.
const String findWordLabel = 'Find a word';

/// The search field's hint.
const String findWordHint = 'Type a word, like "eat"';

/// Shown when nothing matches.
const String findNothingMessage = 'No word like that on the boards yet.';

/// Shown under the button while the live session has no connection.
const String findNeedsConnectionMessage = 'Showing a word needs a connection.';

/// The button that makes the word glow on the child's board.
String showOnBoardLabel(String childName) => "Show on $childName's board";

/// Said once the glow is sent.
String shownMessage(String label, String childName) =>
    "'$label' is glowing on $childName's board.";

/// Said when the circle has more than one board: the child's board rings
/// the word's board tab when another board is on show.
String shownOnTabMessage(String label, String childName, String board) =>
    "'$label' is glowing. If $childName is on another board, the $board tab "
    'glows too.';

/// Opens the word finder over [context], when its flag is on.
void openWordFinder(
  BuildContext context, {
  required BoardStore store,
  LiveSession? live,
  String query = '',
}) {
  if (!wordFinderEnabled) return;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          WordFinderScreen(store: store, live: live, initialQuery: query),
    ),
  );
}

/// A search field over every board of the circle, with each result's board
/// and a small map of its grid with the word's cell lit. With [live], each
/// result offers "Show on the child's board", the same glow model mode sends.
class WordFinderScreen extends StatefulWidget {
  const WordFinderScreen({
    super.key,
    required this.store,
    this.live,
    this.initialQuery = '',
  });

  final BoardStore store;
  final LiveSession? live;

  /// What the search field starts with.
  final String initialQuery;

  @override
  State<WordFinderScreen> createState() => _WordFinderScreenState();
}

class _WordFinderScreenState extends State<WordFinderScreen> {
  late final TextEditingController _query = TextEditingController(
    text: widget.initialQuery,
  );

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _show(WordFind find) {
    final live = widget.live;
    if (live == null || !live.connected) return;
    live.sendPulse(find.tile.id);
    final child = widget.store.childName;
    final label = find.tile.label;
    final boards = widget.store.boards.where((board) => !board.archived);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            boards.length < 2
                ? shownMessage(label, child)
                : shownOnTabMessage(label, child, find.board.name),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final margin = ChorusSpace.margin(MediaQuery.sizeOf(context).width);
    final live = widget.live;
    return Scaffold(
      appBar: AppBar(title: const Text(findWordLabel)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([widget.store, _query, ?live]),
          builder: (context, _) {
            final store = widget.store;
            final found = findWords(_query.text, store.tiles, store.boards);
            final query = _query.text.trim();
            return ListView(
              padding: EdgeInsets.fromLTRB(margin, 12, margin, 24),
              children: [
                TextField(
                  controller: _query,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: findWordHint,
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                if (query.isNotEmpty && found.isEmpty)
                  Text(
                    findNothingMessage,
                    style: ChorusType.body.copyWith(color: colors.inkMuted),
                  ),
                if (live != null && !live.connected && found.isNotEmpty) ...[
                  Text(
                    findNeedsConnectionMessage,
                    style: ChorusType.body.copyWith(color: colors.inkMuted),
                  ),
                  const SizedBox(height: 8),
                ],
                for (final find in found) ...[
                  _Result(
                    find: find,
                    childName: store.childName,
                    onShow: live == null
                        ? null
                        : live.connected
                        ? () => _show(find)
                        : null,
                    showLive: live != null,
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({
    required this.find,
    required this.childName,
    required this.onShow,
    required this.showLive,
  });

  final WordFind find;
  final String childName;
  final VoidCallback? onShow;
  final bool showLive;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final tile = find.tile;
    final spoken = tile.spokenText;
    return Semantics(
      container: true,
      label:
          '${tile.label}, ${find.board.name} board, row ${find.row + 1}, '
          'column ${find.col + 1}',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(ChorusSpace.buttonRadius),
          border: Border.all(color: colors.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: GridMap(
                rows: find.board.rows,
                cols: find.board.cols,
                row: find.row,
                col: find.col,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Text(
                      tile.label,
                      style: ChorusType.label.copyWith(color: colors.ink),
                    ),
                  ),
                  if (spoken != tile.label)
                    ExcludeSemantics(
                      child: Text(
                        'Says "$spoken"',
                        style: ChorusType.body.copyWith(color: colors.inkMuted),
                      ),
                    ),
                  ExcludeSemantics(
                    child: Text(
                      '${find.board.name} board · row ${find.row + 1}, '
                      'column ${find.col + 1}',
                      style: ChorusType.body.copyWith(color: colors.inkMuted),
                    ),
                  ),
                  if (showLive) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: onShow,
                      icon: const Icon(Icons.flare_rounded),
                      label: Text(showOnBoardLabel(childName)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small map of a board's grid with one cell lit: ink on card, as adult
/// chrome is.
class GridMap extends StatelessWidget {
  const GridMap({
    super.key,
    required this.rows,
    required this.cols,
    required this.row,
    required this.col,
    this.width = 72,
  });

  final int rows;
  final int cols;
  final int row;
  final int col;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final cell = (width - (cols - 1) * 2) / cols;
    final height = rows * cell + (rows - 1) * 2;
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _GridMapPainter(
          rows: rows,
          cols: cols,
          row: row,
          col: col,
          cell: cell,
          line: colors.line,
          ink: colors.ink,
        ),
      ),
    );
  }
}

class _GridMapPainter extends CustomPainter {
  _GridMapPainter({
    required this.rows,
    required this.cols,
    required this.row,
    required this.col,
    required this.cell,
    required this.line,
    required this.ink,
  });

  final int rows;
  final int cols;
  final int row;
  final int col;
  final double cell;
  final Color line;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = line;
    final lit = Paint()..color = ink;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(c * (cell + 2), r * (cell + 2), cell, cell),
          const Radius.circular(2),
        );
        canvas.drawRRect(rect, r == row && c == col ? lit : outline);
      }
    }
  }

  @override
  bool shouldRepaint(_GridMapPainter old) =>
      old.rows != rows ||
      old.cols != cols ||
      old.row != row ||
      old.col != col ||
      old.line != line ||
      old.ink != ink;
}
