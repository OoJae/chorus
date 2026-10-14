// Pure rules behind the talker access features: the scanning order, the
// keyguard geometry and its millimetres, the device settings as kept, and
// the recent sentences.
import 'dart:ui';

import 'package:chorus_ui/contracts_device.dart';
import 'package:chorus_ui/contracts_voice.dart';
import 'package:chorus_ui/device/device_settings_screen.dart';
import 'package:chorus_ui/talker/keyguard_geometry.dart';
import 'package:chorus_ui/talker/recent_sentences.dart';
import 'package:chorus_ui/talker/scan_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScanOrder', () {
    // Row 0: cols 0, 2. Row 1: empty. Row 2: col 1.
    final order = ScanOrder([(2, 1), (0, 2), (0, 0)]);
    const row0 = ScanPosition(ScanPhase.rows, 0);
    const row2 = ScanPosition(ScanPhase.rows, 2);

    test('visits only rows with words, top first, then wraps', () {
      expect(order.rows, [0, 2]);
      expect(order.start, row0);
      expect(order.next(row0), row2);
      expect(order.next(row2), row0);
    });

    test('a select on a row highlights its first word', () {
      final selection = order.select(row0)!;
      expect(selection.chosen, isNull);
      expect(selection.next, const ScanPosition(ScanPhase.cells, 0, 0));
    });

    test('words in a row go left to right, then back to the next row', () {
      const first = ScanPosition(ScanPhase.cells, 0, 0);
      expect(order.next(first), const ScanPosition(ScanPhase.cells, 0, 2));
      expect(order.next(const ScanPosition(ScanPhase.cells, 0, 2)), row2);
    });

    test('a select on a word chooses it and starts again at the top', () {
      final selection = order.select(
        const ScanPosition(ScanPhase.cells, 2, 1),
      )!;
      expect(selection.chosen, (2, 1));
      expect(selection.next, row0);
    });

    test('an empty board has nothing to scan', () {
      final empty = ScanOrder(const []);
      expect(empty.isEmpty, isTrue);
      expect(empty.start, isNull);
      expect(empty.next(row0), isNull);
      expect(empty.select(row0), isNull);
    });

    test('keeps its place when the board changes, or finds the nearest', () {
      final smaller = ScanOrder([(0, 0)]);
      expect(smaller.keep(row0), row0);
      expect(smaller.keep(const ScanPosition(ScanPhase.cells, 0, 2)), row0);
      expect(smaller.keep(row2), row0);
      expect(smaller.keep(null), row0);
    });
  });

  group('KeyguardGeometry', () {
    test('roomy: fixed offset from the top, equal cells and gaps', () {
      final g = KeyguardGeometry.of(
        body: const Size(1000, 800),
        layout: KeyguardLayout.roomy,
        rows: 6,
        cols: 6,
      );
      // 6 edge + 72 strip + 8 + 52 status + 8 + 48 tabs + 8.
      expect(g.grid.top, 202);
      expect(g.grid.left, 6);
      expect(g.grid.width, 988);
      expect(g.grid.height, 800 - 202 - 6);
      expect(g.gap, 4);
      final a = g.cell(0, 0);
      final b = g.cell(0, 1);
      expect(a.left, 10);
      expect(a.top, 206);
      expect(b.left - a.left, closeTo(988 / 6, 1e-9));
      expect(a.width, closeTo(988 / 6 - 8, 1e-9));
      expect(g.cells, hasLength(36));
    });

    test('narrow and short keep their own fixed places', () {
      final narrow = KeyguardGeometry.of(
        body: const Size(360, 760),
        layout: KeyguardLayout.narrow,
        rows: 6,
        cols: 6,
      );
      expect(narrow.grid.top, 6 + 64 + 8 + 52 + 8 + 48 + 8 + 48 + 8);
      final short = KeyguardGeometry.of(
        body: const Size(800, 380),
        layout: KeyguardLayout.short,
        rows: 4,
        cols: 8,
      );
      expect(short.grid.top, 62);
      expect(short.grid.left, 6 + 92 + 4);
      expect(short.gap, 3);
    });

    test('a screen too small for the grid gives empty cells, never less', () {
      final g = KeyguardGeometry.of(
        body: const Size(100, 100),
        layout: KeyguardLayout.roomy,
        rows: 6,
        cols: 6,
      );
      expect(g.grid.height, 0);
      expect(g.cell(0, 0).height, 0);
    });

    test('millimetres come from the diagonal', () {
      // A 3 by 4 screen with a 5 inch diagonal: 127 mm over 500 px.
      expect(
        millimetresPerPixel(const Size(300, 400), 5),
        closeTo(0.254, 1e-9),
      );
      expect(millimetresPerPixel(const Size(300, 400), 0), isNull);
      expect(millimetresPerPixel(const Size(300, 400), double.nan), isNull);
      expect(millimetresPerPixel(Size.zero, 10), isNull);
    });

    test('the SVG is the screen and every hole, in millimetres', () {
      const g = KeyguardGeometry(
        grid: Rect.fromLTWH(0, 100, 200, 100),
        rows: 1,
        cols: 2,
        gap: 4,
      );
      final svg = keyguardSvg(
        screen: const Size(200, 400),
        geometry: g,
        mmPerPixel: 0.5,
      );
      expect(svg, contains('width="100.00mm" height="200.00mm"'));
      expect(svg, contains('viewBox="0 0 100.00 200.00"'));
      // Hole 1: x 4, y 104, 92 by 92 px.
      expect(svg, contains('<rect x="2.00" y="52.00" width="46.00" '));
      // Hole 2 starts at 104 px.
      expect(svg, contains('<rect x="52.00" y="52.00" width="46.00" '));
      expect('<rect '.allMatches(svg), hasLength(3));
    });
  });

  group('DeviceSettings', () {
    test('are kept and read back the same', () {
      const settings = DeviceSettings(
        holdTime: Duration(milliseconds: 600),
        repeatGuard: Duration(seconds: 1),
        selectOnRelease: false,
        scanMode: ScanMode.twoSwitches,
        scanStep: Duration(seconds: 1),
        scanPreview: true,
        keyguard: true,
      );
      expect(DeviceSettings.fromJson(settings.toJson()), settings);
      expect(settings.plainTouch, isFalse);
    });

    test('anything damaged reads as the board as it always was', () {
      expect(DeviceSettings.fromJson(null), const DeviceSettings());
      expect(DeviceSettings.fromJson('x'), const DeviceSettings());
      expect(
        DeviceSettings.fromJson({
          'holdMs': -1,
          'scan': 'sideways',
          'stepMs': 5,
        }),
        const DeviceSettings(),
      );
      expect(const DeviceSettings().plainTouch, isTrue);
    });

    test('the voice is kept and read back the same', () {
      const prefs = VoicePrefs(voiceName: 'Samantha', rate: 1.2, pitch: 0.8);
      expect(VoicePrefs.fromJson(prefs.toJson()), prefs);
      expect(VoicePrefs.fromJson({'rate': 9}), const VoicePrefs());
    });

    test('times read as people say them', () {
      expect(durationLabel(Duration.zero), 'Off');
      expect(durationLabel(const Duration(milliseconds: 300)), '0.3 s');
      expect(durationLabel(const Duration(seconds: 1)), '1 s');
      expect(durationLabel(const Duration(milliseconds: 500)), '0.5 s');
    });
  });

  group('RecentSentences', () {
    test('newest first, no repeats, and only the last few', () {
      final recent = RecentSentences(limit: 3);
      recent
        ..add('I want juice')
        ..add('go')
        ..add('  ')
        ..add('I want juice')
        ..add('more')
        ..add('help');
      expect(recent.sentences, ['help', 'more', 'I want juice']);
      recent.clear();
      expect(recent.sentences, isEmpty);
    });
  });
}
