import 'package:chorus_ui/contracts_live.dart';
import 'package:chorus_ui/editor/model_mode_bar.dart';
import 'package:chorus_ui/fakes_live.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeLiveSession live;
  late bool enabled;

  Future<void> show(WidgetTester tester) => tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => ModelModeBar(
              live: live,
              enabled: enabled,
              onChanged: (value) => setState(() => enabled = value),
              labelFor: (id) => id == 't1' ? 'want' : null,
            ),
          ),
        ),
      ));

  setUp(() {
    live = FakeLiveSession(present: ['Dad', "Maya's board"]);
    enabled = false;
  });

  testWidgets('off: shows only the switch', (tester) async {
    live.receiveSaid('I want more');
    await show(tester);
    expect(find.text('Show words on the board'), findsOneWidget);
    expect(find.textContaining('Here now'), findsNothing);
    expect(find.textContaining('Just said'), findsNothing);
  });

  testWidgets('the switch reports the change', (tester) async {
    await show(tester);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(enabled, isTrue);
    expect(find.text("Here now: Dad, Maya's board"), findsOneWidget);
  });

  testWidgets('on: shows who is present and follows changes', (tester) async {
    enabled = true;
    await show(tester);
    expect(find.text("Here now: Dad, Maya's board"), findsOneWidget);

    live.setPresent([]);
    await tester.pump();
    expect(find.text(modelNobodyHereMessage), findsOneWidget);
  });

  testWidgets('on: shows the last sentence only once one was shared',
      (tester) async {
    enabled = true;
    await show(tester);
    expect(find.textContaining('Just said'), findsNothing);

    live.receiveSaid('I want more');
    await tester.pump();
    expect(find.text('Just said: I want more'), findsOneWidget);
  });

  testWidgets('on: names the word being shown until it fades', (tester) async {
    enabled = true;
    await show(tester);
    live.sendPulse('t1');
    await tester.pump();
    expect(find.text('Showing: want'), findsOneWidget);

    await tester.pump(livePulseFor);
    await tester.pump();
    expect(find.textContaining('Showing'), findsNothing);
  });

  testWidgets('on but disconnected: says so and shows nothing live',
      (tester) async {
    enabled = true;
    live.receiveSaid('I want more');
    live.setConnected(false);
    await show(tester);
    expect(find.text(modelNeedsConnectionMessage), findsOneWidget);
    expect(find.textContaining('Here now'), findsNothing);
    expect(find.textContaining('Just said'), findsNothing);
  });
}
