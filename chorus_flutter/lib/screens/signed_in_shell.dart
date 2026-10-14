/// Everything a signed-in adult sees: opening, first run, or home.
library;

import 'dart:async';

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_ui/contracts.dart' hide CircleRole;
import 'package:flutter/material.dart';

import '../src/sync/replica_board_store.dart';
import 'first_run_screen.dart';
import 'home_screen.dart';
import 'services.dart';
import 'status_views.dart';

/// Opens the local replica, finds the adult's circles and shows the right
/// screen. Every wait says what it is waiting for and every failure offers
/// Retry.
///
/// Circles remembered on this device are shown at once, before the server
/// answers, so the board opens with no signal.
class SignedInShell extends StatefulWidget {
  const SignedInShell({
    super.key,
    required this.gateway,
    required this.openWorkspace,
    required this.speech,
  });

  final CircleGateway gateway;
  final WorkspaceOpener openWorkspace;
  final SpeechService speech;

  @override
  State<SignedInShell> createState() => _SignedInShellState();
}

class _SignedInShellState extends State<SignedInShell> {
  /// Long enough for a slow first sync; after it the home screen offers
  /// Retry instead of spinning for ever.
  static const _readyTimeout = Duration(seconds: 45);

  /// How long sign-out waits for the replica to close. A sync the engine
  /// will not let go of must not keep the adult on "Signing out…".
  static const _closeTimeout = Duration(seconds: 5);

  Workspace? _workspace;

  /// Null until the circles are known.
  List<CircleInfo>? _circles;
  UuidValue? _selectedId;

  /// One store per circle, made on first use and owned by the workspace.
  final Map<UuidValue, BoardStore> _stores = {};
  final Map<UuidValue, CircleReadiness> _readiness = {};

  /// The one unfinished readying call per circle. Giving up on the wait
  /// does not stop the work, so Retry joins it instead of starting another.
  final Map<UuidValue, Future<void>> _readying = {};

  String? _loading = 'Opening Chorus…';
  String? _error;

  /// Whether another screen is open over this one.
  bool _covered = false;

  @override
  void initState() {
    super.initState();
    // Never throws; makes the first spoken word quick.
    unawaited(widget.speech.warmUp());
    _start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The editor and the talker open over home and are handed the circle's
    // one store, which only re-reads when it is told the replica changed.
    // Ask again as anything opens, so a change it was never told about
    // cannot leave a screen on old rows.
    final covered = ModalRoute.isCurrentOf(context) == false;
    if (covered && !_covered) _reread();
    _covered = covered;
  }

  /// Asks the selected circle's store to read the replica again.
  void _reread() {
    final store = _stores[_selectedId];
    if (store is! ReplicaBoardStore) return;
    unawaited(store.refresh().then<void>((_) {}, onError: (Object _) {}));
  }

  @override
  void dispose() {
    // Signed out from elsewhere, or the app is going away.
    final workspace = _workspace;
    _workspace = null;
    if (workspace != null) {
      unawaited(workspace.close().then<void>((_) {}, onError: (Object _) {}));
    }
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _loading = 'Opening Chorus…';
      _error = null;
    });
    try {
      final workspace = _workspace ?? await widget.openWorkspace();
      if (!mounted) {
        // Signed out while it opened: nobody else will close it, and its
        // sync would start on its own.
        unawaited(workspace.close().then<void>((_) {}, onError: (Object _) {}));
        return;
      }
      _workspace = workspace;
    } catch (_) {
      _fail('Chorus could not open the boards saved on this device.');
      return;
    }

    final remembered = await widget.gateway.rememberedCircles();
    if (!mounted) return;
    if (remembered.isNotEmpty) {
      _show(remembered);
      unawaited(_refresh());
      return;
    }

    setState(() => _loading = 'Finding your boards…');
    try {
      final circles = await widget.gateway.myCircles();
      if (!mounted) return;
      _show(circles);
    } catch (_) {
      _fail(
        'Chorus could not reach the server to find your boards. '
        'Check the connection and try again.',
      );
    }
  }

  /// Replaces the remembered circles with the server's list, quietly: with
  /// no signal the remembered ones stay.
  Future<void> _refresh() async {
    try {
      final circles = await widget.gateway.myCircles();
      if (!mounted || _workspace == null) return;
      _show(circles);
    } catch (_) {}
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _loading = null;
      _error = message;
    });
  }

  void _show(List<CircleInfo> circles) {
    final keep = circles.any((circle) => circle.spaceUuid == _selectedId);
    setState(() {
      _circles = circles;
      if (!keep) _selectedId = circles.firstOrNull?.spaceUuid;
      _loading = null;
      _error = null;
    });
    final selected = _selected;
    if (selected != null) _prepare(selected);
  }

  CircleInfo? get _selected {
    final circles = _circles;
    if (circles == null) return null;
    return circles
        .where((circle) => circle.spaceUuid == _selectedId)
        .firstOrNull;
  }

  /// A circle just created or joined: show it and get its board ready.
  void _adopt(CircleInfo circle) {
    _selectedId = circle.spaceUuid;
    _show([
      for (final other in _circles ?? const <CircleInfo>[])
        if (other.spaceUuid != circle.spaceUuid) other,
      circle,
    ]);
  }

  void _select(CircleInfo circle) {
    setState(() => _selectedId = circle.spaceUuid);
    _prepare(circle);
  }

  /// Waits for sync to deliver the circle so this device may write to it.
  /// A guardian's device also seeds the starter board when there is none;
  /// the seed uses fixed ids, so doing it from two devices is harmless.
  Future<void> _prepare(CircleInfo circle, {bool retry = false}) async {
    final workspace = _workspace;
    if (workspace == null) return;
    final id = circle.spaceUuid;
    // Retry also asks for a sync now, whatever state the circle is in: a
    // circle can be ready and still be waiting for its board to arrive.
    if (retry) {
      unawaited(workspace.sync.syncNow().then<void>((_) {}, onError: (_) {}));
    }
    final now = _readiness[id];
    if (now == CircleReadiness.preparing || now == CircleReadiness.ready) {
      return;
    }
    if (now == CircleReadiness.failed && !retry) return;
    setState(() => _readiness[id] = CircleReadiness.preparing);
    var result = CircleReadiness.ready;
    Future<void>? ready;
    try {
      ready = _readying[id];
      if (ready == null) {
        late final Future<void> call;
        call = workspace
            .ensureCircleReady(
              circle,
              seedIfEmpty: circle.myRole == CircleRole.guardian,
            )
            .whenComplete(() {
              if (identical(_readying[id], call)) _readying.remove(id);
            });
        ready = _readying[id] = call;
      }
      await ready.timeout(_readyTimeout);
    } on TimeoutException {
      result = CircleReadiness.failed;
      // Nobody is waiting any more, but the work goes on. When it finishes,
      // the note must clear by itself: the chip will say "Up to date" and a
      // note asking for Retry beside it would contradict it.
      unawaited(
        ready?.then<void>((_) {
          if (!mounted || !identical(_workspace, workspace)) return;
          // A Retry since then has a wait of its own; leave the state to it.
          if (_readiness[id] != CircleReadiness.failed) return;
          setState(() => _readiness[id] = CircleReadiness.ready);
        }, onError: (Object _) {}),
      );
    } catch (_) {
      result = CircleReadiness.failed;
    }
    if (!mounted || !identical(_workspace, workspace)) return;
    setState(() => _readiness[id] = result);
  }

  Future<void> _signOut() async {
    setState(() {
      _loading = 'Signing out…';
      _error = null;
    });
    final workspace = _workspace;
    _workspace = null;
    _stores.clear();
    _readiness.clear();
    _readying.clear();
    try {
      await workspace?.close().timeout(_closeTimeout);
    } catch (_) {
      // Signing out matters more than a clean close, or a finished one.
    }
    try {
      await widget.gateway.signOut();
    } catch (_) {
      _circles = null;
      _fail('Signing out did not finish. Check the connection and try again.');
    }
  }

  /// Photos, the live session and the rest are extras: if they cannot be
  /// made on this device the board still opens without them.
  CircleServices? _servicesFor(Workspace workspace, CircleInfo circle) {
    try {
      return workspace.servicesFor(circle);
    } catch (_) {
      return null;
    }
  }

  void _addBoard() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) => FirstRunScreen(
          gateway: widget.gateway,
          addingAnother: true,
          onCircle: (circle) {
            Navigator.of(routeContext).pop();
            _adopt(circle);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loading = _loading;
    if (loading != null) {
      return Scaffold(
        body: SafeArea(child: LoadingView(message: loading)),
      );
    }
    final error = _error;
    final workspace = _workspace;
    final circles = _circles;
    if (error != null || workspace == null || circles == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chorus')),
        body: SafeArea(
          child: ErrorView(
            message: error ?? 'Chorus is not ready yet.',
            onRetry: _start,
            onSignOut: _signOut,
          ),
        ),
      );
    }
    final selected = _selected;
    if (selected == null) {
      return FirstRunScreen(
        gateway: widget.gateway,
        onCircle: _adopt,
        onSignOut: _signOut,
      );
    }

    final BoardStore store;
    try {
      store = _stores[selected.spaceUuid] ??= workspace.boardStore(selected);
    } catch (_) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chorus')),
        body: SafeArea(
          child: ErrorView(
            message:
                "Chorus could not open ${selected.childName}'s board "
                'on this device.',
            onRetry: () => setState(() {}),
            onSignOut: _signOut,
          ),
        ),
      );
    }
    return HomeScreen(
      circles: circles,
      selected: selected,
      onSelect: _select,
      store: store,
      sync: workspace.sync,
      speech: widget.speech,
      gateway: widget.gateway,
      readiness: _readiness[selected.spaceUuid] ?? CircleReadiness.preparing,
      onRetryReady: () => _prepare(selected, retry: true),
      onSignOut: _signOut,
      onAddBoard: _addBoard,
      services: _servicesFor(workspace, selected),
    );
  }
}
