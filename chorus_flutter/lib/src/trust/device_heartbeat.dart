/// Tells the server, at most once a minute, that this device is up to date
/// with a circle, for "Who is up to date".
library;

import 'dart:async';

import 'package:chorus_ui/contracts.dart';

/// Sends a heartbeat while [sync] is live with nothing waiting to send:
/// as soon as it gets there, then every [every] while it stays there.
/// Never sends while working offline. Failures are dropped: the next one
/// tries again.
class DeviceHeartbeat {
  DeviceHeartbeat({
    required this.sync,
    required this.send,
    this.every = const Duration(minutes: 1),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    sync.addListener(_check);
    _timer = Timer.periodic(every, (_) => _check());
    _check();
  }

  final SyncStatus sync;

  /// Sends one report: the time this device was last in step.
  final Future<void> Function(DateTime lastSyncAt) send;

  final Duration every;
  final DateTime Function() _now;

  Timer? _timer;
  DateTime? _lastSent;
  bool _sending = false;
  bool _disposed = false;

  void _check() {
    if (_disposed || _sending) return;
    if (sync.workingOffline || sync.state != SyncState.live || sync.hasUnsent) {
      return;
    }
    final now = _now();
    final last = _lastSent;
    if (last != null && now.difference(last) < every) return;
    _lastSent = now;
    _sending = true;
    unawaited(
      Future<void>.sync(() => send(now.toUtc()))
          .then<void>((_) {}, onError: (Object _) => _lastSent = last)
          .whenComplete(() => _sending = false),
    );
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    sync.removeListener(_check);
  }
}
