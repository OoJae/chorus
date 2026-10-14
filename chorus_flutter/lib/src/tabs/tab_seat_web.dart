/// The seat in a browser: a Web Lock, which the browser gives to one tab of
/// a site at a time and takes back by itself when that tab closes or
/// reloads. A private window and a different browser have locks of their
/// own, as they have storage of their own.
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'tab_seat.dart';

/// One name whoever is signed in: the tabs share their sign-in as well.
const String _lockName = 'chorus-seat';

/// Null in a browser without Web Locks, and on a page not served securely.
@JS('navigator.locks')
external web.LockManager? get _locks;

TabSeat openPlatformTabSeat() => _WebTabSeat();

class _WebTabSeat implements TabSeat {
  final StreamController<void> _taken = StreamController<void>.broadcast();

  /// Set from asking for the lock until this tab no longer has it. The
  /// browser keeps the lock for as long as a promise made from this is
  /// unsettled, so completing it is what gives the lock back.
  Completer<void>? _hold;

  /// Whether the request behind [_hold] got the lock.
  Future<bool>? _held;

  @override
  Stream<void> get taken => _taken.stream;

  @override
  Future<bool> claim() => _held ?? _ask(web.LockOptions(ifAvailable: true));

  @override
  Future<void> takeOver() async {
    final held = _held;
    if (held != null && await held) return;
    await _ask(web.LockOptions(steal: true));
  }

  Future<bool> _ask(web.LockOptions options) {
    final locks = _locks;
    // This browser cannot tell its tabs apart: carry on as the only one.
    if (locks == null) return Future.value(true);
    final hold = Completer<void>();
    final answer = Completer<bool>();
    _hold = hold;
    _held = answer.future;

    void over() {
      if (!identical(_hold, hold)) return;
      _hold = null;
      _held = null;
    }

    JSPromise<JSAny?>? decided(web.Lock? lock) {
      // No lock: another tab has it. Completed: released while the browser
      // was deciding, so the lock goes straight back.
      if (lock == null || hold.isCompleted) {
        over();
        answer.complete(false);
        return null;
      }
      answer.complete(true);
      return hold.future.toJS;
    }

    locks
        .request(_lockName, options, decided.toJS)
        .toDart
        .then<void>(
          (_) {},
          onError: (Object _) {
            if (!answer.isCompleted) {
              // The browser would not consider the request at all. That
              // must not keep anyone from their board.
              over();
              answer.complete(true);
            } else if (identical(_hold, hold)) {
              // Refused after it was granted: another tab took the lock.
              over();
              _taken.add(null);
            }
          },
        );
    return answer.future;
  }

  @override
  void release() {
    final hold = _hold;
    _hold = null;
    _held = null;
    if (hold != null && !hold.isCompleted) hold.complete();
  }
}
