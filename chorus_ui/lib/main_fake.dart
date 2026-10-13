/// Runs every Chorus screen on the in-memory fakes, with no backend:
/// `flutter run -t lib/main_fake.dart`.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';

import 'contracts.dart';
import 'credits/credits_screen.dart';
import 'editor/editor_screen.dart';
import 'fakes.dart';
import 'talker/talker_screen.dart';
import 'theme.dart';

void main() => runApp(const ChorusFakeApp());

/// Words the debug buttons hand out, in turn.
const List<String> _remoteWords = ['swing', 'juice', 'music', 'outside', 'book'];
const List<(String, String)> _clashWords = [
  ('park', 'playground'),
  ('grandma', 'bus'),
  ('snack', 'bubbles'),
];

class ChorusFakeApp extends StatefulWidget {
  const ChorusFakeApp({super.key});

  @override
  State<ChorusFakeApp> createState() => _ChorusFakeAppState();
}

class _ChorusFakeAppState extends State<ChorusFakeApp> {
  // The starter board is full; two free spots give the demo room to add.
  final FakeBoardStore _store =
      FakeBoardStore.seeded(leaveEmpty: const {(4, 5), (5, 5)});
  final FakeSpeech _speech =
      FakeSpeech(speakFor: const Duration(milliseconds: 900));
  final FakeSyncStatus _sync = FakeSyncStatus();

  @override
  void dispose() {
    _store.dispose();
    _sync.dispose();
    _speech.speaking.dispose();
    _speech.offlineVoiceReady.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chorus (demo data)',
      debugShowCheckedModeBanner: false,
      theme: chorusTheme(),
      // The fake voice is silent, so say on screen what it would speak.
      builder: (context, child) => Stack(
        children: [
          ?child,
          _WouldSay(speech: _speech),
        ],
      ),
      home: _HomePage(store: _store, speech: _speech, sync: _sync),
    );
  }
}

class _HomePage extends StatefulWidget {
  const _HomePage({
    required this.store,
    required this.speech,
    required this.sync,
  });

  final FakeBoardStore store;
  final FakeSpeech speech;
  final FakeSyncStatus sync;

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  int _remoteCount = 0;
  int _clashCount = 0;

  FakeBoardStore get _store => widget.store;

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  (int, int)? _firstFreeCell() {
    final board = _store.boards.firstWhere((b) => b.id == _store.homeBoardId);
    return emptyCells(board, _store.tiles, _store.boards).firstOrNull;
  }

  void _simulateRemoteWord() {
    final cell = _firstFreeCell();
    if (cell == null) {
      _say('The board is full. Remove a word in Edit board first.');
      return;
    }
    final word = _remoteWords[_remoteCount++ % _remoteWords.length];
    _store.remoteAdd(row: cell.$1, col: cell.$2, label: word);
    _say('Ms Lee added "$word" from another device.');
  }

  /// Two adults fill one empty spot while offline: this phone's word keeps
  /// it and the other arrives in the tray. With no free spot, the other
  /// adult's word simply loses to a word already on the board.
  Future<void> _simulateClash() async {
    final (mine, theirs) = _clashWords[_clashCount++ % _clashWords.length];
    final cell = _firstFreeCell();
    if (cell == null) {
      _store.remoteConflict(row: 0, col: 0, label: theirs);
    } else if (_store.role.canEdit) {
      await _store.addTile(
          boardId: _store.homeBoardId,
          row: cell.$1,
          col: cell.$2,
          label: mine);
      _store.remoteConflict(row: cell.$1, col: cell.$2, label: theirs);
    } else {
      _store.remoteAdd(
          row: cell.$1, col: cell.$2, label: mine, byName: 'Mum');
      _store.remoteConflict(row: cell.$1, col: cell.$2, label: theirs);
    }
    if (!mounted) return;
    _say('"$theirs" lost its spot and is waiting in Needs a home.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Chorus (demo data)')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Everything here runs on this device with made-up data. '
                  'Nothing is sent anywhere and the voice is silent: spoken '
                  'text appears at the bottom of the screen.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                _BigButton(
                  icon: Icons.record_voice_over,
                  label: 'Talker',
                  onPressed: () => _open(TalkerScreen(
                    store: _store,
                    speech: widget.speech,
                    sync: widget.sync,
                    onExit: () => Navigator.of(context).pop(),
                  )),
                ),
                _BigButton(
                  icon: Icons.edit,
                  label: 'Edit board',
                  onPressed: () =>
                      _open(EditorScreen(store: _store, sync: widget.sync)),
                ),
                _BigButton(
                  icon: Icons.info_outline,
                  label: 'Credits',
                  onPressed: () => _open(const CreditsScreen()),
                ),
                const Divider(height: 32),
                Text('Debug', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _simulateRemoteWord,
                  child: const Text('Simulate a word from another device'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _simulateClash,
                  child: const Text('Simulate an offline clash'),
                ),
                ListenableBuilder(
                  listenable: _store,
                  builder: (context, _) => SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sign in as a read-only partner'),
                    value: !_store.role.canEdit,
                    onChanged: (readOnly) => _store.role =
                        readOnly ? CircleRole.partner : CircleRole.guardian,
                  ),
                ),
                ListenableBuilder(
                  listenable: widget.sync,
                  builder: (context, _) => SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Pretend to be offline'),
                    value: widget.sync.state == SyncState.offline,
                    onChanged: (offline) {
                      widget.sync.hasUnsent = offline;
                      widget.sync.state =
                          offline ? SyncState.offline : SyncState.live;
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

class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(64),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
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
        return Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: IgnorePointer(
            child: SafeArea(
              child: Center(
                child: Material(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Text(
                      'Says: "${speech.spoken.last}"',
                      style: const TextStyle(color: Colors.white, fontSize: 18),
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
