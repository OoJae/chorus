/// Every Chorus screen on the in-memory fakes, with no backend: a gallery
/// for reviewing the screens in a browser or on a device.
///
/// `flutter run -t lib/main_fake.dart` here; for the web, build
/// `chorus_flutter` with `-t lib/main_gallery.dart`, which also shows the
/// app's real home screen.
///
/// Each screen opens straight from the address as well, so a screenshot
/// needs no taps: `#/talker`, `#/editor`, `#/home` and the others in
/// [GalleryPage]. `?theme=dark` or `?theme=light` picks the palette (the
/// system's otherwise), `?text=2` doubles the text and `?motion=reduced`
/// asks for reduced motion.
library;

import 'dart:async';

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';

import 'brand/mark.dart';
import 'brand/tokens.dart';
import 'contracts.dart';
import 'credits/credits_screen.dart';
import 'editor/add_word_sheet.dart';
import 'editor/editor_screen.dart';
import 'fakes.dart';
import 'fakes_features.dart';
import 'fakes_media.dart';
import 'features/features.dart';
import 'home/home.dart';
import 'onboarding/launch_reveal.dart';
import 'onboarding/onboarding_view.dart';
import 'talker/talker_screen.dart';
import 'theme.dart';
import 'widgets/sync_chip.dart';

void main() => runApp(const ChorusGallery());

/// Builds a home screen on [fakes]. The app passes its own `HomeScreen`;
/// without one the gallery composes home from this package's pieces.
typedef GalleryHomeBuilder =
    Widget Function(BuildContext context, GalleryFakes fakes);

/// The screens of the gallery, each with the address it opens from.
enum GalleryPage {
  onboarding('/onboarding', 'Launch and onboarding', Icons.waving_hand_rounded),
  home('/home', 'Home', Icons.home_rounded),
  talker('/talker', "The child's board", Icons.record_voice_over_rounded),
  editor('/editor', 'Edit words, with a clash in the tray', Icons.edit_rounded),
  addWord('/add-word', 'Add a word', Icons.add_box_rounded),
  wordLog('/word-log', 'Word log', Icons.list_alt_rounded),
  thisWeek('/this-week', 'This week', Icons.bar_chart_rounded),
  share('/share', 'Share a view-only board', Icons.link_rounded),
  export('/export', 'Export as Open Board Format', Icons.ios_share_rounded),
  credits('/credits', 'Credits', Icons.info_outline_rounded);

  const GalleryPage(this.route, this.title, this.icon);

  final String route;
  final String title;
  final IconData icon;

  static GalleryPage? forRoute(String? name) {
    for (final page in values) {
      if (page.route == name) return page;
    }
    return null;
  }
}

/// The made-up circle every gallery screen runs on: Maya's boards with one
/// free spot, a clash waiting in "Needs a home", a word log that is on with
/// a week of use, and sharing that hands out `chorus.example` links.
class GalleryFakes {
  GalleryFakes() {
    _seed();
  }

  /// The child the circle is for.
  static const String childName = 'Maya';

  /// Two free spots on the home board: (3, 5) stays free, and (4, 5) is
  /// where two adults' offline words clashed.
  final FakeMediaBoardStore store = FakeMediaBoardStore.seeded(
    leaveEmpty: const {(3, 5), (4, 5)},
  );
  final FakeSpeech speech = FakeSpeech(
    speakFor: const Duration(milliseconds: 900),
  );
  final FakeSyncStatus sync = FakeSyncStatus();
  final FakeMediaStore media = FakeMediaStore();
  final FakeMediaCapture capture = FakeMediaCapture();
  late final FakeTileSpeaker speaker = FakeTileSpeaker(
    media: media,
    speech: speech,
  );
  final FakeWordLog wordLog = FakeWordLog(enabled: true);
  late final FakeWeekSummarySource summary = FakeWeekSummarySource(
    store: store,
    log: wordLog,
  );
  late final FakeBoardSharing sharing = FakeBoardSharing(store: store);

  /// The board home shows, and the one shared and exported.
  BoardFacts get homeBoard =>
      store.boards.firstWhere((board) => board.id == store.homeBoardId);

  void _seed() {
    // This device's "park" holds the spot; the teacher's "playground",
    // added offline to the same spot, waits in "Needs a home".
    unawaited(
      store.addTile(boardId: store.homeBoardId, row: 4, col: 5, label: 'park'),
    );
    store.remoteConflict(row: 4, col: 5, label: 'playground');
    // A week of words, for "This week".
    const used = {
      'want': 9,
      'more': 7,
      'I': 6,
      'go': 5,
      'help': 4,
      'stop': 3,
      'like': 2,
      'look': 1,
    };
    for (final MapEntry(key: label, value: times) in used.entries) {
      final tile = store.tiles.where((t) => t.label == label).firstOrNull;
      if (tile == null) continue;
      for (var i = 0; i < times; i++) {
        wordLog.noteSpoken(tile);
      }
    }
  }

  void dispose() {
    store.dispose();
    sync.dispose();
    wordLog.dispose();
    media.dispose();
    speech.speaking.dispose();
    speech.offlineVoiceReady.dispose();
  }
}

/// The gallery app. [home] builds the home screen; see
/// [GalleryHomeBuilder].
class ChorusGallery extends StatefulWidget {
  const ChorusGallery({
    super.key,
    this.home,
    this.initialRoute,
    this.themeMode,
  });

  final GalleryHomeBuilder? home;

  /// The page to open on, as [GalleryPage.route]; null takes it from the
  /// address.
  final String? initialRoute;

  /// The palette to start in; null takes it from `?theme=`.
  final ThemeMode? themeMode;

  @override
  State<ChorusGallery> createState() => _ChorusGalleryState();
}

class _ChorusGalleryState extends State<ChorusGallery> {
  final GalleryFakes _fakes = GalleryFakes();

  /// Light, dark or the system's, from `?theme=` and the switch on the
  /// gallery's first page.
  late final ValueNotifier<ThemeMode> _mode = ValueNotifier(
    widget.themeMode ??
        switch (Uri.base.queryParameters['theme']) {
          'dark' => ThemeMode.dark,
          'light' => ThemeMode.light,
          _ => ThemeMode.system,
        },
  );

  /// From `?text=`: the text scale every screen is shown at.
  final double? _textScale = double.tryParse(
    Uri.base.queryParameters['text'] ?? '',
  );

  /// From `?motion=reduced`.
  final bool _reduced = Uri.base.queryParameters['motion'] == 'reduced';

  @override
  void dispose() {
    _mode.dispose();
    _fakes.dispose();
    super.dispose();
  }

  Route<void>? _route(RouteSettings settings) {
    final name = settings.name;
    if (name == '/' || name == null) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => _GalleryIndex(fakes: _fakes, mode: _mode),
      );
    }
    final page = GalleryPage.forRoute(name);
    if (page == null) return null;
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => _screen(context, page),
    );
  }

  Widget _screen(BuildContext context, GalleryPage page) {
    final fakes = _fakes;
    final store = fakes.store;
    void back() => Navigator.of(context).maybePop();
    return switch (page) {
      GalleryPage.onboarding => LaunchReveal(
        child: OnboardingView(
          speech: fakes.speech,
          onMakeBoard: back,
          onHaveOne: back,
        ),
      ),
      GalleryPage.home =>
        widget.home?.call(context, fakes) ?? _HomeStandIn(fakes: fakes),
      GalleryPage.talker => TalkerScreen(
        store: store,
        speech: fakes.speech,
        sync: fakes.sync,
        media: fakes.media,
        speaker: fakes.speaker,
        wordLog: fakes.wordLog,
        onExit: () => Navigator.of(context).pop(),
      ),
      GalleryPage.editor => _editor(fakes),
      GalleryPage.addWord => _AddWordOverEditor(
        editor: _editor(fakes),
        fakes: fakes,
      ),
      GalleryPage.wordLog => WordLogScreen(
        log: fakes.wordLog,
        childName: GalleryFakes.childName,
        summary: fakes.summary,
        store: store,
        sync: fakes.sync,
      ),
      GalleryPage.thisWeek => ThisWeekScreen(
        source: fakes.summary,
        childName: GalleryFakes.childName,
        log: fakes.wordLog,
        tiles: store.tiles,
        role: store.role,
      ),
      GalleryPage.share => ShareViewOnlyScreen(
        sharing: fakes.sharing,
        board: fakes.homeBoard,
        childName: GalleryFakes.childName,
        sync: fakes.sync,
      ),
      GalleryPage.export => ExportObfScreen(
        sharing: fakes.sharing,
        board: fakes.homeBoard,
        childName: GalleryFakes.childName,
        sync: fakes.sync,
      ),
      GalleryPage.credits => const CreditsScreen(),
    };
  }

  Widget _editor(GalleryFakes fakes) => Builder(
    builder: (context) => EditorScreen(
      store: fakes.store,
      sync: fakes.sync,
      media: fakes.media,
      capture: fakes.capture,
      speaker: fakes.speaker,
      onExport: (board) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ExportObfScreen(
            sharing: fakes.sharing,
            board: board,
            childName: GalleryFakes.childName,
            sync: fakes.sync,
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _mode,
      builder: (context, mode, _) => MaterialApp(
        title: 'Chorus gallery',
        debugShowCheckedModeBanner: false,
        theme: chorusTheme(),
        darkTheme: chorusDarkTheme(),
        themeMode: mode,
        initialRoute: widget.initialRoute,
        onGenerateRoute: _route,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          final textScale = _textScale;
          return MediaQuery(
            data: media.copyWith(
              textScaler: textScale == null
                  ? media.textScaler
                  : TextScaler.linear(textScale),
              disableAnimations: media.disableAnimations || _reduced,
            ),
            // The fake voice is silent, so say on screen what it would
            // speak.
            child: Stack(
              children: [
                ?child,
                _WouldSay(speech: _fakes.speech),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The gallery's first page: every screen, the palette, and the made-up
/// events a real circle would bring.
class _GalleryIndex extends StatefulWidget {
  const _GalleryIndex({required this.fakes, required this.mode});

  final GalleryFakes fakes;
  final ValueNotifier<ThemeMode> mode;

  @override
  State<_GalleryIndex> createState() => _GalleryIndexState();
}

class _GalleryIndexState extends State<_GalleryIndex> {
  static const List<String> _remoteWords = [
    'swing',
    'juice',
    'music',
    'outside',
    'book',
  ];
  static const List<String> _clashWords = ['bus', 'bubbles', 'grandma'];

  int _remoteCount = 0;
  int _clashCount = 0;

  FakeMediaBoardStore get _store => widget.fakes.store;

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  (int, int)? _firstFreeCell() {
    final board = widget.fakes.homeBoard;
    return emptyCells(board, _store.tiles, _store.boards).firstOrNull;
  }

  void _remoteWord() {
    final cell = _firstFreeCell();
    if (cell == null) {
      _say('The board is full. Remove a word in Edit words first.');
      return;
    }
    final word = _remoteWords[_remoteCount++ % _remoteWords.length];
    _store.remoteAdd(row: cell.$1, col: cell.$2, label: word);
    _say('Ms Lee added "$word" from another device.');
  }

  /// Another adult's offline word for a spot already taken: it arrives in
  /// "Needs a home".
  void _clash() {
    final word = _clashWords[_clashCount++ % _clashWords.length];
    _store.remoteConflict(row: 4, col: 5, label: word);
    _say('"$word" lost its spot and is waiting in Needs a home.');
  }

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final margin = ChorusSpace.margin(width);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: EdgeInsets.fromLTRB(margin, 24, margin, 32),
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: ChorusLockup(),
                ),
                const SizedBox(height: 24),
                Text(
                  'Gallery',
                  style: ChorusType.title.copyWith(color: colors.ink),
                ),
                const SizedBox(height: 8),
                Text(
                  'Every screen on made-up data. Nothing is sent anywhere, '
                  'and the voice is silent: what it would say appears at the '
                  'bottom of the screen.',
                  style: ChorusType.body.copyWith(color: colors.inkMuted),
                ),
                const SizedBox(height: 20),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: widget.mode,
                  builder: (context, mode, _) => SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                      ),
                      ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                    ],
                    selected: {mode},
                    onSelectionChanged: (chosen) =>
                        widget.mode.value = chosen.single,
                  ),
                ),
                const SizedBox(height: 16),
                for (final page in GalleryPage.values)
                  ListTile(
                    leading: Icon(page.icon),
                    title: Text(page.title),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).pushNamed(page.route),
                  ),
                const Divider(height: 33),
                Text(
                  'Make something happen',
                  style: ChorusType.headline.copyWith(color: colors.ink),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline_rounded),
                  title: const Text('A word arrives from another device'),
                  onTap: _remoteWord,
                ),
                ListTile(
                  leading: const Icon(Icons.call_split_rounded),
                  title: const Text('Another clash arrives in Needs a home'),
                  onTap: _clash,
                ),
                ListenableBuilder(
                  listenable: _store,
                  builder: (context, _) => SwitchListTile(
                    title: const Text('Signed in as a read-only partner'),
                    value: !_store.role.canEdit,
                    onChanged: (readOnly) => _store.role = readOnly
                        ? CircleRole.partner
                        : CircleRole.guardian,
                  ),
                ),
                ListenableBuilder(
                  listenable: widget.fakes.sync,
                  builder: (context, _) => SwitchListTile(
                    title: const Text('This device is offline'),
                    value: widget.fakes.sync.state == SyncState.offline,
                    onChanged: (offline) {
                      final sync = widget.fakes.sync;
                      sync.hasUnsent = offline;
                      sync.state = offline ? SyncState.offline : SyncState.live;
                      widget.fakes.wordLog.online = !offline;
                      widget.fakes.sharing.online = !offline;
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Home made from this package's pieces, as the app's `HomeScreen` makes
/// it: the board as an object, the thumb's actions and the quiet list. The
/// board flies into the child's board as in the app.
class _HomeStandIn extends StatelessWidget {
  const _HomeStandIn({required this.fakes});

  final GalleryFakes fakes;

  void _push(BuildContext context, String route) =>
      Navigator.of(context).pushNamed(route);

  void _openBoard(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final board = heroBoardOf(fakes.store);
    Navigator.of(context).push(
      BoardRoute<void>(
        reducedMotion: reduced,
        builder: (routeContext) => TalkerScreen(
          store: fakes.store,
          speech: fakes.speech,
          sync: fakes.sync,
          media: fakes.media,
          speaker: fakes.speaker,
          wordLog: fakes.wordLog,
          heroTag: board == null || reduced ? null : boardHeroTag(board.id),
          onExit: () => Navigator.of(routeContext).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = fakes.store;
    const name = GalleryFakes.childName;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final canEdit = store.role.canEdit;
        return HomeLayout(
          status: SyncChip(sync: fakes.sync),
          title: "$name's board",
          hero: (context, lean) => HomeHero(
            store: store,
            childName: name,
            media: fakes.media,
            lean: lean,
            onOpen: () => _openBoard(context),
          ),
          actions: HomeActions(
            openLabel: canEdit ? "Open $name's board" : "View $name's board",
            onOpen: () => _openBoard(context),
            editLabel: canEdit ? 'Edit words' : null,
            onEdit: () => _push(context, GalleryPage.editor.route),
          ),
          list: [
            if (canEdit)
              HomeEntry(
                icon: Icons.link_rounded,
                label: 'Share a view-only board',
                onTap: () => _push(context, GalleryPage.share.route),
              ),
            HomeEntry(
              icon: Icons.bar_chart_rounded,
              label: 'Word log and this week',
              onTap: () => _push(context, GalleryPage.wordLog.route),
            ),
            HomeEntry(
              icon: Icons.info_outline_rounded,
              label: 'Credits',
              onTap: () => _push(context, GalleryPage.credits.route),
            ),
          ],
        );
      },
    );
  }
}

/// The editor with "Add a word" open over it, for the free spot.
class _AddWordOverEditor extends StatefulWidget {
  const _AddWordOverEditor({required this.editor, required this.fakes});

  final Widget editor;
  final GalleryFakes fakes;

  @override
  State<_AddWordOverEditor> createState() => _AddWordOverEditorState();
}

class _AddWordOverEditorState extends State<_AddWordOverEditor> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final fakes = widget.fakes;
      unawaited(
        showAddWordSheet(
          context,
          store: fakes.store,
          boardId: fakes.store.homeBoardId,
          row: 3,
          col: 5,
          media: fakes.media,
          capture: fakes.capture,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.editor;
}

/// A caption at the bottom of every screen while the fake voice "speaks".
class _WouldSay extends StatelessWidget {
  const _WouldSay({required this.speech});

  final FakeSpeech speech;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: speech.speaking,
      builder: (context, speaking, _) {
        if (!speaking || speech.spoken.isEmpty) return const SizedBox.shrink();
        final colors = ChorusColors.of(context);
        return Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: IgnorePointer(
            child: SafeArea(
              child: Center(
                child: Material(
                  color: colors.ink,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Text(
                      'Says: "${speech.spoken.last}"',
                      style: ChorusType.body.copyWith(color: colors.card),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
