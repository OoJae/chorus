import 'dart:convert';

import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_features.dart';
import 'package:chorus_ui/features/export_obf_screen.dart';
import 'package:chorus_ui/features/share_view_only_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features_harness.dart';

void main() {
  // Wednesday 14 October 2026, 09:00 UTC.
  final clock = DateTime.utc(2026, 10, 14, 9);

  late FakeBoardStore store;
  late FakeBoardSharing sharing;
  late BoardFacts home;
  String? copied;

  setUp(() {
    store = FakeBoardStore.seeded();
    sharing = FakeBoardSharing(store: store, now: () => clock);
    home = store.boards.firstWhere((board) => board.isHome);
    copied = null;
  });

  void catchClipboard(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
  }

  group('Share a view-only board', () {
    final shared = <(Uri, String, String)>[];

    Future<void> pump(
      WidgetTester tester, {
      bool withShare = true,
      SyncStatus? sync,
    }) async {
      shared.clear();
      setScreen(tester, const Size(360, 820));
      catchClipboard(tester);
      await tester.pumpWidget(
        featureApp(
          ShareViewOnlyScreen(
            sharing: sharing,
            board: home,
            childName: 'Maya',
            sync: sync,
            onShare: withShare
                ? (url, text, title) async {
                    shared.add((url, text, title));
                    return true;
                  }
                : null,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('explains who it is for, and shares nothing until asked', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('Share a view-only board'), findsOneWidget);
      expect(find.textContaining('babysitter'), findsOneWidget);
      expect(find.textContaining('no account'), findsOneWidget);
      expect(find.textContaining('after 7 days'), findsOneWidget);
      expect(sharing.shared, isEmpty);
    });

    testWidgets('makes the link and shows it with its expiry, Copy and '
        'Share', (tester) async {
      await pump(tester);
      await tester.tap(find.text(makeViewOnlyLinkLabel));
      await tester.pumpAndSettle();

      final link = sharing.shared.single;
      expect(sharing.isOpen(link), isTrue);
      expect(find.text(link.url.toString()), findsOneWidget);
      // Seven days on: Wednesday 21 October.
      expect(find.textContaining('Opens until Wed, Oct 21'), findsOneWidget);

      await tester.tap(find.text('Copy link'));
      await tester.pumpAndSettle();
      expect(copied, link.url.toString());
      expect(find.text('Link copied.'), findsOneWidget);

      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(shared.single.$1, link.url);
      expect(shared.single.$3, "Maya's board");
      expect(shared.single.$2, contains('Tap a word to hear it.'));
    });

    testWidgets('offers Copy alone where there is no share sheet', (
      tester,
    ) async {
      await pump(tester, withShare: false);
      await tester.tap(find.text(makeViewOnlyLinkLabel));
      await tester.pumpAndSettle();
      expect(find.text('Copy link'), findsOneWidget);
      expect(find.text('Share'), findsNothing);
    });

    testWidgets('"Stop sharing" asks first, then the link stops opening', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.text(makeViewOnlyLinkLabel));
      await tester.pumpAndSettle();
      final link = sharing.shared.single;

      await tester.tap(find.text(stopSharingLabel));
      await tester.pumpAndSettle();
      expect(find.text('Stop sharing this board?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(sharing.isOpen(link), isTrue);

      await tester.tap(find.text(stopSharingLabel));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(stopSharingLabel),
        ),
      );
      await tester.pumpAndSettle();
      expect(sharing.isOpen(link), isFalse);
      expect(find.textContaining('You stopped sharing.'), findsOneWidget);
      expect(find.text(link.url.toString()), findsNothing);
      expect(find.text('Make a new link'), findsOneWidget);
    });

    testWidgets('with no connection it says so, and the reason when asked', (
      tester,
    ) async {
      sharing.online = false;
      await pump(tester, sync: FakeSyncStatus(state: SyncState.offline));
      expect(find.textContaining('This device is offline.'), findsOneWidget);
      await tester.tap(find.text(makeViewOnlyLinkLabel));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'This needs a connection. Try again when the device is online.',
        ),
        findsOneWidget,
      );
      expect(find.text(makeViewOnlyLinkLabel), findsOneWidget);
    });
  });

  group('Export as Open Board Format', () {
    Future<void> pump(WidgetTester tester) async {
      setScreen(tester, const Size(360, 820));
      catchClipboard(tester);
      await tester.pumpWidget(
        featureApp(
          ExportObfScreen(sharing: sharing, board: home, childName: 'Maya'),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('explains the file, makes it when asked, and shows the link', (
      tester,
    ) async {
      await pump(tester);
      expect(find.textContaining('other AAC apps can open'), findsOneWidget);
      expect(
        find.textContaining('No photos and no recordings'),
        findsOneWidget,
      );
      expect(sharing.exported, isEmpty);

      await tester.tap(find.text(makeObfFileLabel));
      await tester.pumpAndSettle();
      final url = sharing.exported.keys.single;
      expect(find.text(url.toString()), findsOneWidget);
      expect(find.text('Works for 30 days'), findsOneWidget);
      // The file at the link is this board, words in their places.
      final file = jsonDecode(sharing.exported[url]!) as Map<String, Object?>;
      expect(file['format'], obfFormat);

      await tester.tap(find.text('Copy link'));
      await tester.pumpAndSettle();
      expect(copied, url.toString());
    });

    testWidgets('a failure says why and leaves the button to try again', (
      tester,
    ) async {
      sharing.online = false;
      await pump(tester);
      await tester.tap(find.text(makeObfFileLabel));
      await tester.pumpAndSettle();
      expect(find.textContaining('This needs a connection.'), findsOneWidget);
      expect(find.text(makeObfFileLabel), findsOneWidget);

      sharing.online = true;
      await tester.tap(find.text(makeObfFileLabel));
      await tester.pumpAndSettle();
      expect(sharing.exported, hasLength(1));
      expect(find.textContaining('This needs a connection.'), findsNothing);
    });
  });
}
