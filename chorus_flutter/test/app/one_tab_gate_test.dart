import 'dart:async';

import 'package:chorus_flutter/src/tabs/one_tab_gate.dart';
import 'package:chorus_flutter/src/tabs/tab_seat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

const _openElsewhere = 'Chorus is open in another tab';
const _moved = 'Chorus moved to another tab';
const _useHere = 'Use Chorus in this tab';
const _howToTryTwo =
    'Chorus runs in one tab of this browser at a time. Use it here, and the '
    'other tab stops. Nothing saved is lost. To try a second adult, sign in '
    'from a private window (Incognito in Chrome, InPrivate in Edge) or '
    'another browser.';

/// A [TabSeat] the test moves between this tab and "another tab".
class _FakeSeat implements TabSeat {
  _FakeSeat({this.free = true});

  /// Whether [claim] finds the seat free.
  final bool free;

  /// Thrown by the next [claim] or [takeOver], then cleared.
  Object? failNext;

  /// When set, [claim] waits for it before answering.
  Completer<void>? claimGate;

  int claims = 0;
  int takeOvers = 0;
  int releases = 0;

  // Sync, so a test sees what the gate does before any frame is drawn.
  final StreamController<void> _taken = StreamController<void>.broadcast(
    sync: true,
  );

  /// Another tab takes the seat from this one.
  void takeAway() => _taken.add(null);

  void _maybeFail() {
    final error = failNext;
    failNext = null;
    if (error != null) throw error;
  }

  @override
  Future<bool> claim() async {
    claims++;
    await claimGate?.future;
    _maybeFail();
    return free;
  }

  @override
  Future<void> takeOver() async {
    takeOvers++;
    _maybeFail();
  }

  @override
  Stream<void> get taken => _taken.stream;

  @override
  void release() => releases++;
}

/// Counts how often the signed-in app was started and closed.
class _Runs {
  int started = 0;
  int closed = 0;
}

/// Stands in for the signed-in shell.
class _App extends StatefulWidget {
  const _App(this.runs);

  final _Runs runs;

  @override
  State<_App> createState() => _AppState();
}

class _AppState extends State<_App> {
  @override
  void initState() {
    super.initState();
    widget.runs.started++;
  }

  @override
  void dispose() {
    widget.runs.closed++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('the editor')),
            ),
          ),
          child: const Text('the board'),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('a free seat shows the app', (tester) async {
    final seat = _FakeSeat();
    final runs = _Runs();
    await pumpScreen(tester, OneTabGate(seat: seat, child: _App(runs)));

    // Never a blank screen while the browser is asked.
    expect(find.text('Opening Chorus…'), findsOneWidget);
    expect(runs.started, 0);

    await tester.pump();

    expect(seat.claims, 1);
    expect(find.text('the board'), findsOneWidget);
    expect(find.text(_openElsewhere), findsNothing);
    expect(runs.started, 1);
  });

  testWidgets('a seat held by another tab shows the notice, and the app is '
      'never started', (tester) async {
    final seat = _FakeSeat(free: false);
    final runs = _Runs();
    await pumpScreen(tester, OneTabGate(seat: seat, child: _App(runs)));
    await tester.pumpAndSettle();

    expect(find.text(_openElsewhere), findsOneWidget);
    expect(find.text(_howToTryTwo), findsOneWidget);
    expect(find.text(_useHere), findsOneWidget);
    expect(find.text('the board'), findsNothing);
    expect(runs.started, 0);
    expect(seat.takeOvers, 0);
  });

  testWidgets('"Use Chorus in this tab" takes the seat over and shows the '
      'app', (tester) async {
    final seat = _FakeSeat(free: false);
    final runs = _Runs();
    await pumpScreen(tester, OneTabGate(seat: seat, child: _App(runs)));
    await tester.pumpAndSettle();

    await tester.tap(find.text(_useHere));
    await tester.pumpAndSettle();

    expect(seat.takeOvers, 1);
    expect(find.text('the board'), findsOneWidget);
    expect(find.text(_openElsewhere), findsNothing);
    expect(runs.started, 1);
  });

  testWidgets('taking over reads the browser again before the app starts, '
      'and a free seat does not', (tester) async {
    final seat = _FakeSeat(free: false);
    final runs = _Runs();
    final reading = Completer<void>();
    final startedWhenRead = <int>[];
    Future<void> reread() {
      startedWhenRead.add(runs.started);
      return reading.future;
    }

    await pumpScreen(
      tester,
      OneTabGate(seat: seat, afterTakeOver: reread, child: _App(runs)),
    );
    await tester.pumpAndSettle();
    expect(startedWhenRead, isEmpty);

    await tester.tap(find.text(_useHere));
    await tester.pump();

    expect(startedWhenRead, [0]);
    expect(find.text('Opening Chorus…'), findsOneWidget);
    expect(runs.started, 0);

    reading.complete();
    await tester.pumpAndSettle();

    expect(find.text('the board'), findsOneWidget);
    expect(runs.started, 1);

    // A tab that finds the seat free has just read the browser.
    var freeReads = 0;
    await pumpScreen(
      tester,
      OneTabGate(
        key: UniqueKey(),
        seat: _FakeSeat(),
        afterTakeOver: () async => freeReads++,
        child: _App(_Runs()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('the board'), findsOneWidget);
    expect(freeReads, 0);
  });

  testWidgets('only a tab that holds the seat is told it does, and a tab '
      'that takes it over is told after reading the browser', (tester) async {
    final events = <String>[];
    final seat = _FakeSeat(free: false);
    await pumpScreen(
      tester,
      OneTabGate(
        seat: seat,
        afterTakeOver: () async => events.add('read'),
        onHeld: () => events.add('held'),
        child: _App(_Runs()),
      ),
    );
    await tester.pumpAndSettle();
    expect(events, isEmpty, reason: 'another tab holds the seat');

    await tester.tap(find.text(_useHere));
    await tester.pumpAndSettle();
    expect(events, ['read', 'held']);

    // Taken away and brought back: told again.
    seat.takeAway();
    await tester.pumpAndSettle();
    await tester.tap(find.text(_useHere));
    await tester.pumpAndSettle();
    expect(events, ['read', 'held', 'read', 'held']);

    // A free seat, and a seat that cannot be asked for, are held at once.
    for (final other in [
      _FakeSeat(),
      _FakeSeat(free: false)..failNext = StateError('no locks'),
    ]) {
      var held = 0;
      await pumpScreen(
        tester,
        OneTabGate(
          key: UniqueKey(),
          seat: other,
          onHeld: () => held++,
          child: _App(_Runs()),
        ),
      );
      await tester.pumpAndSettle();
      expect(held, 1);
    }
  });

  testWidgets('a read of the browser that fails still shows the app', (
    tester,
  ) async {
    final seat = _FakeSeat(free: false);
    final runs = _Runs();
    await pumpScreen(
      tester,
      OneTabGate(
        seat: seat,
        afterTakeOver: () async => throw StateError('storage'),
        child: _App(runs),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(_useHere));
    await tester.pumpAndSettle();

    expect(find.text('the board'), findsOneWidget);
    expect(runs.started, 1);
  });

  testWidgets('a seat taken by another tab closes the app and says where '
      'Chorus went', (tester) async {
    final seat = _FakeSeat();
    final runs = _Runs();
    var told = 0;
    await pumpScreen(
      tester,
      OneTabGate(seat: seat, onTaken: () => told++, child: _App(runs)),
    );
    await tester.pumpAndSettle();
    expect(runs.started, 1);

    seat.takeAway();

    // Told at once: a tab in the background draws no frame to wait for.
    expect(told, 1);
    expect(runs.closed, 0);

    await tester.pumpAndSettle();

    expect(runs.closed, 1);
    expect(find.text('the board'), findsNothing);
    expect(find.text(_moved), findsOneWidget);
    expect(find.text(_howToTryTwo), findsOneWidget);
    expect(find.text(_openElsewhere), findsNothing);

    // And it can be brought back, as a fresh start.
    await tester.tap(find.text(_useHere));
    await tester.pumpAndSettle();

    expect(seat.takeOvers, 1);
    expect(find.text('the board'), findsOneWidget);
    expect(runs.started, 2);
  });

  testWidgets('a screen open over the app goes with it when the seat is '
      'taken', (tester) async {
    final seat = _FakeSeat();
    final runs = _Runs();
    await pumpScreen(tester, OneTabGate(seat: seat, child: _App(runs)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('the board'));
    await tester.pumpAndSettle();
    expect(find.text('the editor'), findsOneWidget);

    seat.takeAway();
    await tester.pumpAndSettle();

    expect(find.text('the editor'), findsNothing);
    expect(find.text(_moved), findsOneWidget);
    expect(runs.closed, 1);
  });

  testWidgets('leaving the gate gives the seat up', (tester) async {
    final seat = _FakeSeat();
    await pumpScreen(tester, OneTabGate(seat: seat, child: _App(_Runs())));
    await tester.pumpAndSettle();
    expect(seat.releases, 0);

    // Signed out: the sign-in screen takes the gate's place.
    await pumpScreen(tester, const Text('signed out'));

    expect(seat.releases, 1);

    // A tab that takes the seat afterwards is no news for a gate that left.
    seat.takeAway();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving while the browser is still asked gives the seat up '
      'and shows nothing', (tester) async {
    final seat = _FakeSeat()..claimGate = Completer<void>();
    final runs = _Runs();
    await pumpScreen(tester, OneTabGate(seat: seat, child: _App(runs)));
    await tester.pump();

    await pumpScreen(tester, const Text('signed out'));
    seat.claimGate!.complete();
    await tester.pumpAndSettle();

    expect(seat.releases, 1);
    expect(runs.started, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a seat that cannot be asked for keeps nobody from the app', (
    tester,
  ) async {
    final seat = _FakeSeat(free: false)..failNext = StateError('no locks');
    final runs = _Runs();
    await pumpScreen(tester, OneTabGate(seat: seat, child: _App(runs)));
    await tester.pumpAndSettle();

    expect(find.text('the board'), findsOneWidget);
    expect(runs.started, 1);
  });

  testWidgets('a take-over that fails still shows the app', (tester) async {
    final seat = _FakeSeat(free: false);
    final runs = _Runs();
    await pumpScreen(tester, OneTabGate(seat: seat, child: _App(runs)));
    await tester.pumpAndSettle();

    seat.failNext = StateError('no locks');
    await tester.tap(find.text(_useHere));
    await tester.pumpAndSettle();

    expect(find.text('the board'), findsOneWidget);
    expect(runs.started, 1);
  });

  testWidgets('with no seat given the gate uses the real one, which a '
      'phone always holds', (tester) async {
    final runs = _Runs();
    await pumpScreen(tester, OneTabGate(child: _App(runs)));
    await tester.pumpAndSettle();

    expect(find.text('the board'), findsOneWidget);
    expect(runs.started, 1);
  });
}
