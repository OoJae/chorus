// The light and dark themes: built from the tokens, ink on card with no
// accent colour, and every component drawn without errors in both.
import 'dart:math' as math;

import 'package:chorus_ui/brand/laminated_border.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:chorus_ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A page with one of each component the screens use.
class _Everything extends StatefulWidget {
  const _Everything();

  @override
  State<_Everything> createState() => _EverythingState();
}

class _EverythingState extends State<_Everything> {
  bool _on = true;
  int _chip = 0;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit words'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Home'),
              Tab(text: 'My words'),
            ],
          ),
        ),
        // Everything built at once, not as it scrolls into view.
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(onPressed: () {}, child: const Text('Open board')),
              FilledButton.tonal(onPressed: () {}, child: const Text('Tonal')),
              ElevatedButton(onPressed: () {}, child: const Text('Elevated')),
              OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
              TextButton(onPressed: () {}, child: const Text('Text')),
              const FilledButton(onPressed: null, child: Text('Disabled')),
              IconButton(onPressed: () {}, icon: const Icon(Icons.add_rounded)),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Word',
                  helperText: 'As it is said.',
                ),
              ),
              Wrap(
                children: [
                  for (var i = 0; i < 2; i++)
                    ChoiceChip(
                      label: Text('Choice $i'),
                      selected: _chip == i,
                      onSelected: (_) => setState(() => _chip = i),
                    ),
                  ActionChip(label: const Text('Action'), onPressed: () {}),
                ],
              ),
              SwitchListTile(
                title: const Text('Work offline'),
                subtitle: const Text('Changes wait on this device.'),
                value: _on,
                onChanged: (on) => setState(() => _on = on),
              ),
              const ListTile(
                leading: Icon(Icons.print_rounded),
                title: Text('Print a paper copy'),
              ),
              const Divider(),
              const LinearProgressIndicator(value: 0.4),
              const CircularProgressIndicator(value: 0.4),
              const Card(child: Text('A card')),
              Builder(
                builder: (context) => TextButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nothing was changed.')),
                  ),
                  child: const Text('Snack'),
                ),
              ),
              Builder(
                builder: (context) => TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const AlertDialog(
                      title: Text('Archive this board?'),
                      content: Text('Its words go to Needs a home.'),
                    ),
                  ),
                  child: const Text('Dialog'),
                ),
              ),
              Builder(
                builder: (context) => TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    builder: (_) => const SizedBox(
                      height: 200,
                      child: Center(child: Text('Add a word')),
                    ),
                  ),
                  child: const Text('Sheet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// WCAG 2 contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final (name, build, colors, brightness) in [
    ('light', chorusTheme, ChorusColors.light, Brightness.light),
    ('dark', chorusDarkTheme, ChorusColors.dark, Brightness.dark),
  ]) {
    group('$name theme', () {
      test('is built from the tokens', () {
        final theme = build();
        expect(theme.useMaterial3, isTrue);
        expect(theme.brightness, brightness);
        expect(theme.colorScheme.brightness, brightness);
        expect(theme.extension<ChorusColors>(), same(colors));
        expect(theme.scaffoldBackgroundColor, colors.card);
        expect(theme.colorScheme.primary, colors.ink);
        expect(theme.colorScheme.onPrimary, colors.card);
        expect(theme.colorScheme.error, colors.alert);
        expect(theme.appBarTheme.backgroundColor, colors.card);
        expect(theme.appBarTheme.elevation, 0);
        expect(theme.bottomSheetTheme.backgroundColor, colors.surface);
      });

      test('colour belongs to words: the chrome is ink, card and line', () {
        final scheme = build().colorScheme;
        final chrome = {
          colors.card,
          colors.surface,
          colors.ink,
          colors.inkMuted,
          colors.line,
        };
        for (final role in [
          scheme.primary,
          scheme.onPrimary,
          scheme.primaryContainer,
          scheme.secondary,
          scheme.secondaryContainer,
          scheme.tertiary,
          scheme.tertiaryContainer,
          scheme.surface,
          scheme.surfaceContainerHighest,
          scheme.onSurface,
          scheme.onSurfaceVariant,
          scheme.outline,
          scheme.outlineVariant,
          scheme.inverseSurface,
        ]) {
          expect(chrome, contains(role));
        }
      });

      test('type: Atkinson to read, Fraunces for titles, sizes from the '
          'plan', () {
        final text = build().textTheme;
        expect(text.bodyMedium!.fontFamily, ChorusType.body.fontFamily);
        expect(text.bodyMedium!.fontSize, 17);
        expect(text.bodyLarge!.fontSize, 17);
        expect(text.bodySmall!.fontSize, greaterThanOrEqualTo(16));
        expect(text.labelLarge!.fontSize, 15);
        expect(text.displayLarge!.fontFamily, ChorusType.display.fontFamily);
        expect(text.displayLarge!.fontSize, 48);
        expect(text.headlineLarge!.fontSize, 30);
        expect(text.titleLarge!.fontFamily, ChorusType.title.fontFamily);
        expect(text.bodyMedium!.color, colors.ink);
        expect(text.displayLarge!.color, colors.ink);
      });

      test('shapes: buttons 16 on a laminated edge, sheets 28, dialogs 24, '
          'and snackbars keep their default place', () {
        final theme = build();
        final filled = theme.filledButtonTheme.style!;
        expect(filled.shape!.resolve({}), const LaminatedBorder());
        expect(
          filled.shape!.resolve({WidgetState.pressed}),
          const LaminatedBorder.pressed(),
        );
        expect(filled.minimumSize!.resolve({})!.height, 48);
        final elevated = theme.elevatedButtonTheme.style!;
        expect(elevated.backgroundColor!.resolve({}), colors.ink);
        expect(elevated.foregroundColor!.resolve({}), colors.card);
        expect(elevated.shape!.resolve({}), isA<LaminatedBorder>());
        expect(
          (theme.bottomSheetTheme.shape! as RoundedRectangleBorder)
              .borderRadius,
          const BorderRadius.vertical(top: Radius.circular(28)),
        );
        expect(
          (theme.dialogTheme.shape! as RoundedRectangleBorder).borderRadius,
          const BorderRadius.all(Radius.circular(24)),
        );
        expect(theme.snackBarTheme.behavior, isNull);
        expect(theme.snackBarTheme.backgroundColor, colors.ink);
      });

      test('switches are ink when on, inputs ink when focused', () {
        final theme = build();
        expect(
          theme.switchTheme.trackColor!.resolve({WidgetState.selected}),
          colors.ink,
        );
        expect(
          theme.switchTheme.thumbColor!.resolve({WidgetState.selected}),
          colors.card,
        );
        final input = theme.inputDecorationTheme;
        expect(input.fillColor, colors.surface);
        expect(input.enabledBorder!.borderSide.color, colors.inkMuted);
        expect(input.focusedBorder!.borderSide.color, colors.ink);
        expect(theme.progressIndicatorTheme.color, colors.ink);
        expect(theme.iconTheme.color, colors.ink);
      });

      test('a field\'s outline stands out 3:1 from the page and the sheet, '
          'at rest and focused', () {
        final input = build().inputDecorationTheme;
        for (final border in [
          input.border!,
          input.enabledBorder!,
          input.focusedBorder!,
          input.errorBorder!,
        ]) {
          for (final background in [colors.card, colors.surface]) {
            expect(
              _contrast(border.borderSide.color, background),
              greaterThanOrEqualTo(3),
              reason: '$border on $background',
            );
          }
        }
      });

      testWidgets('every component draws, and opens, without an error', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(theme: build(), home: const _Everything()),
        );
        await tester.ensureVisible(find.text('Sheet'));
        await tester.tap(find.text('Sheet'));
        await tester.pumpAndSettle();
        expect(find.text('Add a word'), findsOneWidget);
        await tester.tapAt(const Offset(4, 4));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Dialog'));
        await tester.tap(find.text('Dialog'));
        await tester.pumpAndSettle();
        expect(find.text('Archive this board?'), findsOneWidget);
        await tester.tapAt(const Offset(4, 4));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Snack'));
        await tester.tap(find.text('Snack'));
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Nothing was changed.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  }

  testWidgets('a filled button sinks onto its thin edge while pressed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: chorusTheme(),
        home: Center(
          child: FilledButton(onPressed: () {}, child: const Text('Go')),
        ),
      ),
    );
    LaminatedBorder shape() =>
        tester
                .widget<Material>(
                  find.descendant(
                    of: find.byType(FilledButton),
                    matching: find.byType(Material),
                  ),
                )
                .shape!
            as LaminatedBorder;
    expect(shape().sink, 0);
    expect(shape().edge, 3);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FilledButton)),
    );
    await tester.pumpAndSettle();
    expect(shape().sink, 2);
    expect(shape().edge, 1);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(shape().sink, 0);
  });

  testWidgets('with both themes, the app follows the system into the dark', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: chorusTheme(),
        darkTheme: chorusDarkTheme(),
        themeMode: ThemeMode.system,
        home: const Scaffold(body: Text('Maya')),
      ),
    );
    final scaffold = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(Scaffold),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(scaffold.color, ChorusColors.dark.card);
  });

  group('LaminatedBorder', () {
    const box = Rect.fromLTWH(0, 0, 100, 48);

    test('the face sits above the edge, and both sink when pressed', () {
      const rest = LaminatedBorder();
      expect(rest.getOuterPath(box).getBounds(), box);
      expect(rest.getInnerPath(box).getBounds().bottom, 45);

      const pressed = LaminatedBorder.pressed();
      expect(pressed.getOuterPath(box).getBounds().top, 2);
      expect(pressed.getInnerPath(box).getBounds().bottom, 47);
    });

    test('it blends between rest and pressed, so the press can animate', () {
      final half =
          const LaminatedBorder().lerpTo(const LaminatedBorder.pressed(), 0.5)
              as LaminatedBorder;
      expect(half.sink, 1);
      expect(half.edge, 2);
      expect(
        const LaminatedBorder().copyWith(side: const BorderSide(width: 2)),
        isA<LaminatedBorder>().having((b) => b.edge, 'edge', 3),
      );
    });
  });
}
