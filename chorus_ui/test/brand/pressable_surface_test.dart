// The laminated press: it sinks 2 dp onto a 1 dp edge under the finger,
// answers taps, Enter and Space, shows keyboard focus, and under reduced
// motion changes only its edge.
import 'package:chorus_ui/brand/haptics.dart';
import 'package:chorus_ui/brand/pressable_surface.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:chorus_ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget surface, {
  bool reduced = false,
}) => tester.pumpWidget(
  MaterialApp(
    theme: chorusTheme(),
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: Scaffold(body: Center(child: surface)),
      ),
    ),
  ),
);

Rect _face(WidgetTester tester) =>
    tester.getRect(find.byKey(PressableSurface.faceKey));

/// How much of the edge shows under the face.
double _edgeShowing(WidgetTester tester) =>
    tester.getRect(find.byKey(PressableSurface.edgeKey)).bottom -
    _face(tester).bottom;

void main() {
  late List<ChorusHaptic> felt;
  setUp(() {
    felt = [];
    ChorusHaptics.sink = felt.add;
  });
  tearDown(() => ChorusHaptics.sink = null);

  testWidgets('a tap fires once, with its haptic moment', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      PressableSurface(
        onTap: () => taps++,
        haptic: ChorusHaptic.wordTapped,
        child: const Text('want'),
      ),
    );
    await tester.tap(find.text('want'));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(felt, [ChorusHaptic.wordTapped]);
  });

  testWidgets('with no haptic moment, nothing is felt', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      PressableSurface(onTap: () => taps++, child: const Text('Open')),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(felt, isEmpty);
  });

  testWidgets('while held it sinks 2 dp onto a 1 dp edge, and comes back on '
      'release', (tester) async {
    await _pump(
      tester,
      PressableSurface(onTap: () {}, child: const Text('go')),
    );
    final rest = _face(tester);
    expect(_edgeShowing(tester), closeTo(ChorusSpace.edge, 0.01));

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('go')),
    );
    await tester.pumpAndSettle();
    expect(_face(tester).top - rest.top, closeTo(ChorusSpace.pressSink, 0.05));
    expect(_edgeShowing(tester), closeTo(ChorusSpace.edgePressed, 0.05));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(_face(tester).top, closeTo(rest.top, 0.01));
    expect(_edgeShowing(tester), closeTo(ChorusSpace.edge, 0.01));
  });

  testWidgets('a release halfway down turns the spring round where it is', (
    tester,
  ) async {
    await _pump(
      tester,
      PressableSurface(onTap: () {}, child: const Text('go')),
    );
    final rest = _face(tester).top;
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('go')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    final partway = _face(tester).top - rest;
    expect(partway, inExclusiveRange(0, ChorusSpace.pressSink));

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    final after = _face(tester).top - rest;
    expect(after, lessThan(ChorusSpace.pressSink), reason: 'never bottomed');
    await tester.pumpAndSettle();
    expect(_face(tester).top, closeTo(rest, 0.01));
  });

  testWidgets('Enter and Space press it, and keyboard focus shows an ink '
      'ring', (tester) async {
    var taps = 0;
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await _pump(
      tester,
      PressableSurface(
        onTap: () => taps++,
        focusNode: focus,
        child: const Text('Speak'),
      ),
    );
    expect(find.byKey(PressableSurface.focusRingKey), findsNothing);
    focus.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(taps, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(taps, 2);

    final ring = tester.widget<DecoratedBox>(
      find.byKey(PressableSurface.focusRingKey),
    );
    final border = (ring.decoration as BoxDecoration).border! as Border;
    expect(border.top.color, ChorusColors.light.ink);
    expect(border.top.width, 2);
  });

  testWidgets('screen readers hear a button with its label, and can press '
      'it', (tester) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await _pump(
      tester,
      PressableSurface(
        onTap: () => taps++,
        semanticLabel: 'want',
        child: const Icon(Icons.favorite_rounded),
      ),
    );
    expect(
      tester.getSemantics(find.byType(PressableSurface)),
      isSemantics(
        label: 'want',
        isButton: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
      ),
    );
    tester.semantics.tap(find.semantics.byLabel('want'));
    expect(taps, 1);
    semantics.dispose();
  });

  testWidgets('it is never smaller than 48 dp', (tester) async {
    await _pump(
      tester,
      PressableSurface(onTap: () {}, child: const SizedBox(width: 4)),
    );
    final size = tester.getSize(find.byType(PressableSurface));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('with no onTap it does not press or answer', (tester) async {
    await _pump(
      tester,
      const PressableSurface(onTap: null, child: Text('off')),
    );
    final rest = _face(tester).top;
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('off')),
    );
    await tester.pumpAndSettle();
    expect(_face(tester).top, rest);
    await gesture.up();
    expect(felt, isEmpty);
  });

  testWidgets('under reduced motion the face stays put and the edge changes '
      'at once', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      PressableSurface(onTap: () => taps++, child: const Text('go')),
      reduced: true,
    );
    final rest = _face(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('go')),
    );
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(_face(tester), rest, reason: 'no sink');
    expect(_edgeShowing(tester), closeTo(ChorusSpace.edgePressed, 0.01));

    await gesture.up();
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(_edgeShowing(tester), closeTo(ChorusSpace.edge, 0.01));
    expect(taps, 1);
  });

  testWidgets('the face is ink with card text unless given colours', (
    tester,
  ) async {
    await _pump(
      tester,
      PressableSurface(onTap: () {}, child: const Text('Open')),
    );
    final face = tester.widget<DecoratedBox>(
      find.byKey(PressableSurface.faceKey),
    );
    expect((face.decoration as BoxDecoration).color, ChorusColors.light.ink);
    final text = tester.widget<RichText>(
      find.descendant(
        of: find.byType(PressableSurface),
        matching: find.byType(RichText),
      ),
    );
    expect(text.text.style!.color, ChorusColors.light.card);
  });
}
