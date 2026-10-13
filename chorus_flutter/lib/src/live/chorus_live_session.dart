/// The live session of one circle, over the server's `live.join` stream.
library;

import 'dart:async';

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart' show SyncState, SyncStatus;
import 'package:chorus_ui/contracts_live.dart';

/// Opens the stream: `client.live.join` in the app, a fake in tests.
typedef LiveJoin =
    Stream<LiveEvent> Function(
      UuidValue circleSpace,
      Stream<LiveEvent> outgoing,
    );

/// Keeps one circle's live stream open while the device is online.
///
/// Nothing is written to disk and nothing received is kept past the
/// connection, except the last shared sentence, which stays in memory until
/// this object is disposed. When the stream drops it is opened again after
/// `backoffDelay`, counting attempts from the last time the server was
/// heard from.
///
/// The stream carries no list of who is joined, so presence is built from
/// `presence` events. The server puts their meaning in `text`: `joined`
/// when a member's stream opens, `here` for one already present (and for
/// every presence event a device sends itself), `left` when a stream
/// closes. Each device sends one on connecting and every [presenceEvery],
/// answers the first one it sees from a newcomer, removes a member who
/// left, and forgets one not heard from for [presenceTtl].
///
/// Members are told apart by account, so two devices signed in as the same
/// adult show as one name.
///
/// A stream the server refuses because this adult is not in the circle is
/// not reopened.
///
/// Call [start] once; [dispose] closes the stream.
class ChorusLiveSession extends LiveSession {
  ChorusLiveSession({
    required this._join,
    required this.circleSpace,
    this._sync,
    this.mayShareSaid = true,
    this._loadShareSaid,
    this._saveShareSaid,
    this.pulseFor = livePulseFor,
    this.presenceEvery = const Duration(seconds: 10),
    this.presenceTtl = const Duration(seconds: 25),
    this.settleAfter = const Duration(milliseconds: 1500),
    this.stableAfter = const Duration(seconds: 30),
  });

  /// The session the app uses.
  factory ChorusLiveSession.forClient(
    Client client, {
    required UuidValue circleSpace,
    SyncStatus? sync,
    bool mayShareSaid = true,
    Future<bool> Function()? loadShareSaid,
    Future<void> Function(bool value)? saveShareSaid,
  }) => ChorusLiveSession(
    join: client.live.join,
    circleSpace: circleSpace,
    sync: sync,
    mayShareSaid: mayShareSaid,
    loadShareSaid: loadShareSaid,
    saveShareSaid: saveShareSaid,
  );

  final LiveJoin _join;
  final UuidValue circleSpace;

  /// Says whether the device is online. Without it the session always
  /// tries.
  final SyncStatus? _sync;

  /// False for anyone but a guardian: [shareSaid] then cannot be turned on.
  final bool mayShareSaid;

  /// Reads and writes the per-device sharing switch. Without them the
  /// switch starts off and lasts as long as this object.
  final Future<bool> Function()? _loadShareSaid;
  final Future<void> Function(bool value)? _saveShareSaid;

  final Duration pulseFor;
  final Duration presenceEvery;
  final Duration presenceTtl;

  /// The stream gives no sign that it opened. One that has not failed for
  /// this long counts as connected; any event from the server does at once.
  final Duration settleAfter;

  /// A connection that lasted this long resets the backoff even if the
  /// server never sent anything.
  final Duration stableAfter;

  /// `text` of the presence event the server sends when a stream closes.
  static const String _left = 'left';

  bool _started = false;
  bool _disposed = false;
  bool _connected = false;
  bool _shareSaid = false;

  /// True once the server has said this adult is not in the circle. Asking
  /// again would get the same answer, so the session stays closed.
  bool _refused = false;

  /// True once this device's user has set the switch, so a slow read of
  /// the saved value cannot undo their choice.
  bool _shareSaidTouched = false;
  String? _lastSaid;

  /// Bumped for every stream opened or dropped, so a callback from an old
  /// stream can tell it is stale.
  int _generation = 0;
  int _attempt = 0;
  SyncState? _syncState;
  StreamController<LiveEvent>? _out;
  StreamSubscription<LiveEvent>? _sub;
  Timer? _retry;
  Timer? _settle;
  Timer? _stable;
  Timer? _heartbeat;

  final Map<String, Timer> _pulses = {};
  final Map<String, _Peer> _peers = {};

  @override
  bool get connected => _connected;

  @override
  Set<String> get pulsing => Set.unmodifiable(_pulses.keys);

  @override
  List<String> get present {
    final names = <String>[];
    for (final peer in _peers.values) {
      if (!names.contains(peer.name)) names.add(peer.name);
    }
    return List.unmodifiable(names);
  }

  @override
  String? get lastSaid => _lastSaid;

  @override
  bool get shareSaid => _shareSaid;

  @override
  set shareSaid(bool value) {
    _shareSaidTouched = true;
    if (value && !mayShareSaid) return;
    if (_shareSaid == value) return;
    _shareSaid = value;
    // A failed save costs only the memory of the choice.
    final save = _saveShareSaid;
    if (save != null) {
      unawaited(Future.sync(() => save(value)).catchError((Object _) {}));
    }
    _notify();
  }

  /// Starts keeping the stream open and reads the saved sharing switch.
  /// Safe to call twice.
  void start() {
    if (_started || _disposed) return;
    _started = true;
    _syncState = _sync?.state;
    _sync?.addListener(_onSyncChanged);
    unawaited(_restoreShareSaid());
    if (_online) _open();
  }

  /// True once the server refused the stream because this adult is not a
  /// member of the circle.
  bool get refused => _refused;

  @override
  void sendPulse(String tileId) {
    if (!_connected) return;
    final UuidValue id;
    try {
      id = UuidValue.withValidation(tileId.toLowerCase());
    } on FormatException {
      return;
    }
    _send(LiveEvent(kind: LiveKind.pulse, tileId: id));
    // Glows here too, so the adult sees what the others see.
    _glow(id.uuid.toLowerCase());
  }

  @override
  void sendSaid(String text) {
    if (!_connected || !_shareSaid) return;
    final words = text.trim();
    if (words.isEmpty) return;
    _send(LiveEvent(kind: LiveKind.said, text: words));
  }

  Future<void> _restoreShareSaid() async {
    final load = _loadShareSaid;
    if (load == null || !mayShareSaid) return;
    bool saved;
    try {
      saved = await load();
    } catch (_) {
      // Unreadable: stay with the private default.
      return;
    }
    if (_disposed || _shareSaidTouched || saved == _shareSaid) return;
    _shareSaid = saved;
    _notify();
  }

  /// Whether a connection is worth trying. Clock skew and sync backoff do
  /// not stop the stream; it has its own backoff.
  bool get _online => switch (_sync?.state) {
    SyncState.signedOut ||
    SyncState.offline ||
    SyncState.needsUpdate ||
    SyncState.accessLost => false,
    _ => true,
  };

  void _onSyncChanged() {
    if (_disposed || !_started) return;
    final state = _sync?.state;
    final before = _syncState;
    _syncState = state;
    if (!_online) {
      _retry?.cancel();
      _retry = null;
      if (_sub != null) _close();
      return;
    }
    if (_sub != null || _refused) return;
    // The device came back, or sync has just got through: try now instead
    // of sitting out the rest of a long wait. Sync reports often, so only
    // the change to live counts, or it would defeat the backoff.
    final cameBack = _retry == null;
    final gotThrough = state == SyncState.live && before != SyncState.live;
    if (cameBack || gotThrough) {
      _attempt = 0;
      _open();
    }
  }

  void _open() {
    _retry?.cancel();
    _retry = null;
    if (_disposed || _refused || _sub != null) return;
    final generation = ++_generation;
    final out = StreamController<LiveEvent>();
    _out = out;
    try {
      _sub = _join(circleSpace, out.stream).listen(
        (event) {
          if (generation == _generation) _onEvent(event);
        },
        onError: (Object error) {
          if (generation != _generation) return;
          // Not a member (any more): the same question gets the same answer.
          if (error is CircleException) _refused = true;
          _dropped();
        },
        onDone: () {
          if (generation == _generation) _dropped();
        },
        cancelOnError: true,
      );
    } catch (_) {
      _dropped();
      return;
    }
    // Buffered until the stream is really open.
    _sendPresence();
    _settle = Timer(settleAfter, () {
      if (generation == _generation) _markConnected();
    });
    _stable = Timer(stableAfter, () {
      if (generation == _generation) _attempt = 0;
    });
  }

  void _markConnected() {
    _settle?.cancel();
    _settle = null;
    if (_connected || _disposed) return;
    _connected = true;
    _heartbeat = Timer.periodic(presenceEvery, (_) => _sendPresence());
    _notify();
  }

  /// The stream failed or ended: forget everything live and try again.
  void _dropped() {
    _close();
    if (_disposed || !_started || !_online || _refused) return;
    _retry = Timer(backoffDelay(_attempt++), _open);
  }

  /// Tears the stream down and empties everything that was live.
  void _close() {
    _generation++;
    _settle?.cancel();
    _stable?.cancel();
    _heartbeat?.cancel();
    _settle = _stable = _heartbeat = null;
    final sub = _sub;
    final out = _out;
    _sub = null;
    _out = null;
    if (sub != null) unawaited(sub.cancel().catchError((Object _) {}));
    if (out != null) unawaited(out.close().catchError((Object _) {}));

    final changed = _connected || _peers.isNotEmpty || _pulses.isNotEmpty;
    _connected = false;
    for (final timer in _pulses.values) {
      timer.cancel();
    }
    _pulses.clear();
    for (final peer in _peers.values) {
      peer.expiry.cancel();
    }
    _peers.clear();
    if (changed) _notify();
  }

  void _onEvent(LiveEvent event) {
    // The server answered, so the next drop starts the backoff over.
    _attempt = 0;
    _markConnected();
    switch (event.kind) {
      case LiveKind.pulse:
        final tile = event.tileId;
        if (tile != null) _glow(tile.uuid.toLowerCase());
      case LiveKind.said:
        final text = event.text?.trim() ?? '';
        if (text.isEmpty) return;
        _lastSaid = text;
        _notify();
      case LiveKind.presence:
        _heard(event);
    }
  }

  void _glow(String tileId) {
    _pulses[tileId]?.cancel();
    _pulses[tileId] = Timer(pulseFor, () {
      _pulses.remove(tileId);
      _notify();
    });
    _notify();
  }

  /// Notes that the sender of a presence event is here, or has gone.
  void _heard(LiveEvent event) {
    final stamped = event.fromName.trim();
    final name = stamped.isNotEmpty ? stamped : 'Someone';
    final key = event.fromUser?.uuid ?? stamped;
    if (event.text == _left) {
      // If another device of the same adult is still joined, the server
      // has it say so straight after and the name comes back.
      final gone = _peers.remove(key);
      gone?.expiry.cancel();
      if (gone != null) _notify();
      return;
    }
    final known = _peers[key];
    known?.expiry.cancel();
    // Assigning in place keeps the order the members arrived in.
    _peers[key] = _Peer(
      name,
      Timer(presenceTtl, () {
        if (_peers.remove(key) != null) _notify();
      }),
    );
    if (known == null) {
      // A newcomer has not heard from this device yet.
      _sendPresence();
      _notify();
    } else if (known.name != name) {
      _notify();
    }
  }

  /// The server relays this as `here`, whatever it carries.
  void _sendPresence() => _send(LiveEvent(kind: LiveKind.presence));

  void _send(LiveEvent event) {
    final out = _out;
    if (out == null || out.isClosed) return;
    out.add(event);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _sync?.removeListener(_onSyncChanged);
    _disposed = true;
    _retry?.cancel();
    _retry = null;
    _close();
    super.dispose();
  }
}

/// Another device in the session and the timer that forgets it.
class _Peer {
  _Peer(this.name, this.expiry);

  final String name;
  final Timer expiry;
}
