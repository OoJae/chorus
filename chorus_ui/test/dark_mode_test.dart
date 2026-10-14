// Dark mode follows the system, so every screen takes its colours from the
// theme: nothing is drawn on a fixed white face that the dark theme's light
// ink then sits on, unreadable.
import 'dart:io';
import 'dart:math' as math;

import 'package:chorus_ui/brand/tokens.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/editor/model_mode_bar.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_live.dart';
import 'package:chorus_ui/talker/talker_screen.dart';
import 'package:chorus_ui/theme.dart';
import 'package:chorus_ui/widgets/sync_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2 contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// The colour [text] is drawn in, inherited style included.
Color _inkOf(WidgetTester tester, Finder text) =>
    tester.renderObject<RenderParagraph>(text).text.style!.color!;

Future<void> _pumpDark(WidgetTester tester, Widget home) =>
    tester.pumpWidget(MaterialApp(theme: chorusDarkTheme(), home: home));

void main() {
  test('no screen draws in a fixed black or white', () {
    // The theme itself is the one place: the scrim, and inkOn's choice.
    final fixed = RegExp(r'Colors\.(white|black)');
    final found = [
      for (final file in Directory('lib').listSync(recursive: true))
        if (file is File &&
            file.path.endsWith('.dart') &&
            !file.path.endsWith('${Platform.pathSeparator}theme.dart'))
          for (final (i, line) in file.readAsLinesSync().indexed)
            if (fixed.hasMatch(line)) '${file.path}:${i + 1}',
    ];
    expect(found, isEmpty, reason: 'use ChorusColors or TileFamily');
  });

  for (final on in [false, true]) {
    testWidgets('the mode bar reads in the dark, ${on ? 'on' : 'off'}', (
      tester,
    ) async {
      final live = FakeLiveSession(present: ['Dad']);
      await _pumpDark(
        tester,
        Scaffold(
          body: ModelModeBar(live: live, enabled: on, onChanged: (_) {}),
        ),
      );
      final face = tester
          .widget<Material>(
            find
                .descendant(
                  of: find.byType(ModelModeBar),
                  matching: find.byType(Material),
                )
                .first,
          )
          .color!;
      expect(face.computeLuminance(), lessThan(0.1), reason: 'a dark face');
      for (final text in [
        find.text('Show words on the board'),
        find.textContaining(on ? 'Tap a word' : 'Turn on'),
        if (on) find.text('Here now: Dad'),
      ]) {
        expect(
          _contrast(_inkOf(tester, text), face),
          greaterThanOrEqualTo(4.5),
          reason: '$text',
        );
      }
    });
  }

  testWidgets('the sync chip and its "Sync now" read in the dark', (
    tester,
  ) async {
    await _pumpDark(
      tester,
      Scaffold(
        body: Center(
          child: SyncChip(sync: FakeSyncStatus(state: SyncState.offline)),
        ),
      ),
    );
    final chip = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(SyncChip),
            matching: find.byType(Container),
          )
          .first,
    );
    final face = (chip.decoration! as BoxDecoration).color!;
    expect(face, ChorusColors.dark.surface);
    for (final text in [
      find.text('Offline, saved on this device'),
      find.text('Sync now'),
    ]) {
      expect(
        _contrast(_inkOf(tester, text), face),
        greaterThanOrEqualTo(4.5),
        reason: '$text',
      );
    }
  });

  testWidgets("the child's board is slate in the dark, with its strip and "
      'controls in light ink', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pumpDark(
      tester,
      TalkerScreen(
        store: FakeBoardStore.seeded(),
        speech: FakeSpeech(),
        sync: FakeSyncStatus(),
      ),
    );
    const dark = ChorusColors.dark;
    final page = tester
        .widget<Scaffold>(find.byType(Scaffold))
        .backgroundColor!;
    expect(page, dark.surface);
    expect(
      _contrast(_inkOf(tester, find.text(leaveLabel)), page),
      greaterThanOrEqualTo(7),
    );
    final speak = tester.widget<Icon>(
      find.descendant(
        of: find.bySemanticsLabel('Speak'),
        matching: find.byType(Icon),
      ),
    );
    expect(speak.color, anyOf(dark.ink, dark.surface));
    expect(tester.takeException(), isNull);
  });
}
