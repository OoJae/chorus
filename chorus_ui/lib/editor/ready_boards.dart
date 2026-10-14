/// Ready-made boards, so an adult never has to start from a blank board:
/// six Open Board Format files bundled with the app, each added through the
/// same import as "Import a board (.obf)".
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../brand/tokens.dart';
import '../contracts.dart';
import '../contracts_boards.dart';
import '../features/flags/w7.dart';
import 'board_actions.dart';
import 'obf_picker.dart';

/// The editor's board-menu item, and the title of the picker it opens.
const String readyBoardsLabel = 'Add a ready-made board';

/// The board menu's value for [readyBoardsLabel].
const String readyBoardsMenuValue = 'ready-made';

/// Under the picker's title.
const String readyBoardsIntro =
    'Each has 24 words a young child uses often. It is added as a new board, '
    'and you can change any word on it.';

/// Whether the board menu offers [readyBoardsLabel]: only to an adult who
/// can add boards, and only while the feature is on.
bool offerReadyBoards({required bool canAddBoards}) =>
    readyMadeBoardsEnabled && canAddBoards;

/// One bundled board.
class ReadyBoard {
  const ReadyBoard({
    required this.name,
    required this.asset,
    required this.sample,
    required this.icon,
  });

  /// The name shown in the picker, the same as the name in the file.
  final String name;

  /// The file, relative to this package.
  final String asset;

  /// A few of its words, shown under the name.
  final String sample;

  final IconData icon;
}

/// The six ready-made boards, in the order the picker shows them.
const List<ReadyBoard> readyBoards = [
  ReadyBoard(
    name: 'Food',
    asset: 'assets/boards/food.obf',
    sample: 'eat, drink, apple, milk, pasta',
    icon: Icons.restaurant_rounded,
  ),
  ReadyBoard(
    name: 'People',
    asset: 'assets/boards/people.obf',
    sample: 'mum, dad, friend, teacher, we',
    icon: Icons.people_alt_rounded,
  ),
  ReadyBoard(
    name: 'Places',
    asset: 'assets/boards/places.obf',
    sample: 'home, school, park, shop, outside',
    icon: Icons.place_rounded,
  ),
  ReadyBoard(
    name: 'Feelings',
    asset: 'assets/boards/feelings.obf',
    sample: 'happy, sad, tired, scared, calm',
    icon: Icons.mood_rounded,
  ),
  ReadyBoard(
    name: 'Actions',
    asset: 'assets/boards/actions.obf',
    sample: 'play, sleep, jump, read, wash',
    icon: Icons.directions_run_rounded,
  ),
  ReadyBoard(
    name: 'Describing words',
    asset: 'assets/boards/describing.obf',
    sample: 'big, little, hot, cold, fast',
    icon: Icons.palette_rounded,
  ),
];

/// Reads [board]'s file. The app bundles this package's files under
/// `packages/chorus_ui/`; this package's own tests and `main_fake.dart` run
/// it as the app, under its own path, so both are tried.
Future<String> loadReadyBoard(ReadyBoard board, {AssetBundle? bundle}) async {
  final from = bundle ?? rootBundle;
  try {
    return await from.loadString('packages/chorus_ui/${board.asset}');
  } on Object {
    return from.loadString(board.asset);
  }
}

/// How [addReadyBoardFrom] reads a board's file when it is given no
/// loader: [loadReadyBoard]. Tests swap in files read ahead, because an
/// asset read does not finish inside a widget test's fake clock.
@visibleForTesting
Future<String> Function(ReadyBoard board) readyBoardLoader = loadReadyBoard;

/// Asks which ready-made board to add, then adds it through the import
/// ([importBoardFrom]), which names it, places its words and says how many
/// are on it. Completes with the new board's id, or null when nothing was
/// added.
Future<String?> addReadyBoardFrom(
  BuildContext context, {
  required BoardStore store,
  required BoardManager manager,
  Future<String> Function(ReadyBoard board)? load,
}) async {
  if (!readyMadeBoardsEnabled) return null;
  final chosen = await showModalBottomSheet<ReadyBoard>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => const ReadyBoardPicker(),
  );
  if (chosen == null || !context.mounted) return null;
  final read = load ?? readyBoardLoader;
  return importBoardFrom(
    context,
    store: store,
    manager: manager,
    pick: () async =>
        PickedFile(name: '${chosen.name}.obf', text: await read(chosen)),
  );
}

/// The list of ready-made boards. Choosing one closes the sheet with it.
class ReadyBoardPicker extends StatelessWidget {
  const ReadyBoardPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Semantics(
                  header: true,
                  child: Text(
                    readyBoardsLabel,
                    style: ChorusType.headline.copyWith(color: colors.ink),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  readyBoardsIntro,
                  style: ChorusType.body.copyWith(color: colors.inkMuted),
                ),
              ),
              for (final board in readyBoards)
                ListTile(
                  key: ValueKey('ready-board-${board.asset}'),
                  leading: Icon(board.icon, color: colors.ink),
                  title: Text(board.name),
                  subtitle: Text('${board.sample} and more'),
                  onTap: () => Navigator.of(context).pop(board),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
