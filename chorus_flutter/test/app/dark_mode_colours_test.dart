// Dark mode follows the system, so the app's screens take their colours
// from the theme: nothing in a fixed black that vanishes on slate, or a
// fixed white that the dark theme's light ink sits on unreadable.
import 'dart:io';
import 'dart:math' as math;

import 'package:chorus_flutter/screens/status_views.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:chorus_ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2 contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  test('no screen draws in a fixed black or white', () {
    final fixed = RegExp(r'Colors\.(white|black)');
    final found = [
      for (final file in Directory('lib').listSync(recursive: true))
        if (file is File && file.path.endsWith('.dart'))
          for (final (i, line) in file.readAsLinesSync().indexed)
            if (fixed.hasMatch(line)) '${file.path}:${i + 1}',
    ];
    expect(found, isEmpty, reason: 'use the theme or ChorusColors');
  });

  testWidgets('an outlined big button reads on slate', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: chorusDarkTheme(),
        home: Scaffold(
          body: BigButton(
            icon: Icons.refresh_rounded,
            label: 'Try again',
            primary: false,
            onPressed: () {},
          ),
        ),
      ),
    );
    final ink = tester
        .renderObject<RenderParagraph>(find.text('Try again'))
        .text
        .style!
        .color!;
    expect(
      _contrast(ink, ChorusColors.dark.card),
      greaterThanOrEqualTo(4.5),
    );
  });
}
