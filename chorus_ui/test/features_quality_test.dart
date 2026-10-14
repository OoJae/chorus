// The quality floor for the feature screens: every size from a small
// phone to a desktop, at normal and doubled text, in light and dark; the
// reduced-motion path; touch targets and screen reader labels.
import 'dart:async';
import 'dart:math' as math;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/brand/test_fonts.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/contracts_wordlog.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_features.dart';
import 'package:chorus_ui/features/export_obf_screen.dart';
import 'package:chorus_ui/features/feature_page.dart';
import 'package:chorus_ui/features/share_view_only_screen.dart';
import 'package:chorus_ui/features/this_week_screen.dart';
import 'package:chorus_ui/features/word_log_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features_harness.dart';

/// A source that never answers: the screen stays on its skeleton.
class _NeverSource implements WeekSummarySource {
  @override
  Future<WeekSummary?> thisWeek() => Completer<WeekSummary?>().future;
}

class _NoWeek implements WeekSummarySource {
  @override
  Future<WeekSummary?> thisWeek() async => null;
}

/// WCAG 2 contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// One screen in one state: how to build it, and what to do once it is
/// on screen.
typedef _Case = ({
  String name,
  Widget Function() build,
  Future<void> Function(WidgetTester tester)? then,
});

void main() {
  setUpAll(loadChorusFonts);

  // Wednesday 14 October 2026, 09:00 UTC.
  final clock = DateTime.utc(2026, 10, 14, 9);
  DateTime now() => clock;

  List<_Case> cases() {
    final store = FakeBoardStore.seeded();
    final home = store.boards.firstWhere((board) => board.isHome);
    TileFacts word(String label) =>
        store.tiles.firstWhere((tile) => tile.label == label);

    final log = FakeWordLog(enabled: true, now: now);
    for (final label in ['want', 'more', 'help', 'go', 'stop', 'want', 'I']) {
      log.noteSpoken(word(label));
    }
    final week = FakeWeekSummarySource(store: store, log: log, now: now);
    final offlineLog = FakeWordLog(enabled: true, online: false, now: now)
      ..noteSpoken(word('want'));

    Future<void> tapMake(WidgetTester tester, String label) async {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    return [
      (
        name: 'word log, guardian',
        build: () => WordLogScreen(
          log: offlineLog,
          childName: 'Maya',
          summary: week,
          store: store,
          sync: FakeSyncStatus(state: SyncState.offline),
        ),
        then: null,
      ),
      (
        name: 'word log, teacher',
        build: () => WordLogScreen(
          log: FakeWordLog(role: CircleRole.teacher, enabled: true),
          childName: 'Maya',
        ),
        then: null,
      ),
      (
        name: 'this week',
        build: () => ThisWeekScreen(
          source: week,
          childName: 'Maya',
          log: log,
          tiles: store.tiles,
          role: CircleRole.guardian,
        ),
        then: null,
      ),
      (
        name: 'this week, loading',
        build: () => ThisWeekScreen(source: _NeverSource(), childName: 'Maya'),
        then: null,
      ),
      (
        name: 'this week, could not be had',
        build: () => ThisWeekScreen(source: _NoWeek(), childName: 'Maya'),
        then: null,
      ),
      (
        name: 'this week, log off',
        build: () => ThisWeekScreen(
          source: week,
          childName: 'Maya',
          log: FakeWordLog(),
          onOpenWordLog: () {},
        ),
        then: null,
      ),
      (
        name: 'share view-only, shared',
        build: () => ShareViewOnlyScreen(
          sharing: FakeBoardSharing(store: store, now: now),
          board: home,
          childName: 'Maya',
          onShare: (_, _, _) async => true,
        ),
        then: (tester) => tapMake(tester, makeViewOnlyLinkLabel),
      ),
      (
        name: 'share view-only, offline',
        build: () => ShareViewOnlyScreen(
          sharing: FakeBoardSharing(online: false, now: now),
          board: home,
          childName: 'Maya',
          sync: FakeSyncStatus(state: SyncState.offline),
        ),
        then: (tester) => tapMake(tester, makeViewOnlyLinkLabel),
      ),
      (
        name: 'export, made',
        build: () => ExportObfScreen(
          sharing: FakeBoardSharing(store: store, now: now),
          board: home,
          childName: 'Maya',
          onShare: (_, _, _) async => true,
        ),
        then: (tester) => tapMake(tester, makeObfFileLabel),
      ),
    ];
  }

  group('no overflow', () {
    for (final size in featureSizes) {
      for (final scale in [1.0, 2.0]) {
        for (final brightness in Brightness.values) {
          final where =
              '${size.width.toInt()}x${size.height.toInt()}, text '
              '$scale, ${brightness.name}';
          testWidgets(where, (tester) async {
            setScreen(tester, size);
            for (final screen in cases()) {
              await tester.pumpWidget(
                featureApp(
                  screen.build(),
                  brightness: brightness,
                  textScale: scale,
                ),
              );
              await tester.pumpAndSettle();
              await screen.then?.call(tester);
              expect(
                tester.takeException(),
                isNull,
                reason: '${screen.name} at $where',
              );
              // A new screen each time, not an update of the last one.
              await tester.pumpWidget(const SizedBox());
            }
          });
        }
      }
    }
  });

  testWidgets('dark mode is slate, with every line in light ink', (
    tester,
  ) async {
    setScreen(tester, const Size(360, 820));
    const dark = ChorusColors.dark;
    for (final screen in cases()) {
      await tester.pumpWidget(
        featureApp(screen.build(), brightness: Brightness.dark),
      );
      await tester.pumpAndSettle();
      await screen.then?.call(tester);
      final page = tester
          .widget<Scaffold>(find.byType(Scaffold).first)
          .backgroundColor;
      expect(page, dark.card, reason: screen.name);
      final title = tester
          .renderObject<RenderParagraph>(
            find
                .descendant(
                  of: find.byType(FeaturePage),
                  matching: find.byType(RichText),
                )
                .first,
          )
          .text
          .style!
          .color!;
      expect(
        _contrast(title, dark.card),
        greaterThanOrEqualTo(7),
        reason: screen.name,
      );
      await tester.pumpWidget(const SizedBox());
    }
  });

  group('reduced motion', () {
    /// The rise of the page as it comes in, if any.
    double rise(WidgetTester tester) {
      final moved = tester
          .widgetList<Transform>(
            find.descendant(
              of: find.byType(FeatureEntrance),
              matching: find.byType(Transform),
            ),
          )
          .map((transform) => transform.transform.getTranslation().y)
          .where((y) => y > 0.01);
      return moved.isEmpty ? 0 : moved.reduce(math.max);
    }

    double opacity(WidgetTester tester) => tester
        .widget<Opacity>(
          find
              .descendant(
                of: find.byType(FeatureEntrance),
                matching: find.byType(Opacity),
              )
              .first,
        )
        .opacity;

    Widget screen() => WordLogScreen(log: FakeWordLog(), childName: 'Maya');

    testWidgets('the page rises in on the entrance curve', (tester) async {
      setScreen(tester, const Size(360, 820));
      await tester.pumpWidget(featureApp(screen()));
      expect(rise(tester), greaterThan(FeatureEntrance.rise / 2));
      await tester.pump(ChorusMotionTimes.reduced);
      expect(opacity(tester), lessThan(1), reason: 'still coming in');
      await tester.pumpAndSettle();
      expect(rise(tester), 0);
      expect(opacity(tester), 1);
    });

    testWidgets('it becomes a 150 ms fade with no movement', (tester) async {
      setScreen(tester, const Size(360, 820));
      await tester.pumpWidget(featureApp(screen(), reduced: true));
      expect(rise(tester), 0);
      await tester.pump(const Duration(milliseconds: 75));
      expect(rise(tester), 0);
      expect(opacity(tester), closeTo(0.5, 0.05));
      await tester.pump(const Duration(milliseconds: 80));
      expect(opacity(tester), 1);
      expect(tester.hasRunningAnimations, isFalse);
    });

    for (final reduced in [false, true]) {
      testWidgets('a link that was just made is scrolled into view'
          '${reduced ? ' at once' : ' on the entrance curve'}', (tester) async {
        setScreen(tester, const Size(360, 640));
        final store = FakeBoardStore.seeded();
        await tester.pumpWidget(
          featureApp(
            ShareViewOnlyScreen(
              sharing: FakeBoardSharing(store: store),
              board: store.boards.first,
              childName: 'Maya',
            ),
            reduced: reduced,
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(makeViewOnlyLinkLabel));
        await tester.pumpAndSettle();
        await tester.tap(find.text(makeViewOnlyLinkLabel));
        // The link is built, then the scroll starts after that frame.
        await tester.pump();
        await tester.pump();
        double offset() => tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .pixels;
        final first = offset();
        await tester.pump(const Duration(milliseconds: 100));
        if (reduced) {
          expect(offset(), first, reason: 'it jumped, and stays');
        } else {
          expect(offset(), greaterThan(first), reason: 'still gliding');
        }
        await tester.pumpAndSettle();
        expect(
          tester.getRect(find.text('Copy link')).bottom,
          lessThanOrEqualTo(640),
        );
      });
    }
  });

  testWidgets('touch targets are 48 dp and every control has a label', (
    tester,
  ) async {
    setScreen(tester, const Size(360, 640));
    final handle = tester.ensureSemantics();
    for (final screen in cases()) {
      await tester.pumpWidget(featureApp(screen.build()));
      await tester.pumpAndSettle();
      await screen.then?.call(tester);
      await expectLater(
        tester,
        meetsGuideline(androidTapTargetGuideline),
        reason: screen.name,
      );
      await expectLater(
        tester,
        meetsGuideline(labeledTapTargetGuideline),
        reason: screen.name,
      );
      await tester.pumpWidget(const SizedBox());
    }
    handle.dispose();
  });

  testWidgets('decorative icons and skeletons are silent to screen readers', (
    tester,
  ) async {
    setScreen(tester, const Size(360, 820));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      featureApp(ThisWeekScreen(source: _NeverSource(), childName: 'Maya')),
    );
    await tester.pump();
    expect(find.bySemanticsLabel('Loading this week'), findsOneWidget);
    final skeleton = tester.getSemantics(
      find.bySemanticsLabel('Loading this week'),
    );
    expect(skeleton.childrenCount, 0, reason: 'one label for the group');

    await tester.pumpWidget(
      featureApp(WordLogScreen(log: FakeWordLog(), childName: 'Maya')),
    );
    await tester.pumpAndSettle();
    final fact = tester.getSemantics(
      find.text('Which word was tapped, and when.'),
    );
    expect(fact.label, 'Which word was tapped, and when.');
    handle.dispose();
  });
}

/// The reduced-motion fade, for the timing checks.
abstract final class ChorusMotionTimes {
  static const Duration reduced = Duration(milliseconds: 150);
}
