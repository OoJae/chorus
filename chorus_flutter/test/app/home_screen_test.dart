import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_flutter/screens/home_screen.dart';
import 'package:chorus_flutter/screens/services.dart';
import 'package:chorus_flutter/src/live/chorus_live_session.dart';
import 'package:chorus_flutter/screens/signed_in_shell.dart';
import 'package:chorus_shared/chorus_shared.dart' show BoardFacts;
import 'package:chorus_ui/features/trust/trust_words.dart';
import 'package:chorus_ui/contracts.dart' show BoardStore, SyncState;
import 'package:chorus_ui/brand/pressable_surface.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/editor/editor_screen.dart';
import 'package:chorus_ui/home/home.dart';
import 'package:chorus_ui/fakes_media.dart';
import 'package:chorus_ui/talker/talker_screen.dart';
import 'package:chorus_ui/widgets/sync_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// A circle whose board has not reached this device.
class _NoBoardYet extends FakeBoardStore {
  _NoBoardYet() : super.seeded();

  @override
  List<BoardFacts> get boards => const [];
}

void main() {
  /// Home for [selected] on fresh fakes.
  Future<FakeGateway> pumpHome(
    WidgetTester tester,
    CircleInfo selected, {
    List<CircleInfo>? circles,
    CircleReadiness readiness = CircleReadiness.ready,
    VoidCallback? onRetryReady,
    ValueChanged<CircleInfo>? onSelect,
    BoardStore? store,
    CircleServices? services,
    FakeSyncStatus? sync,
  }) async {
    final gateway = FakeGateway();
    final workspace = FakeWorkspace();
    await pumpScreen(
      tester,
      HomeScreen(
        circles: circles ?? [selected],
        selected: selected,
        onSelect: onSelect ?? (_) {},
        store: store ?? workspace.boardStore(selected),
        sync: sync ?? workspace.sync,
        speech: FakeSpeech(),
        gateway: gateway,
        readiness: readiness,
        onRetryReady: onRetryReady ?? () {},
        onSignOut: () {},
        services: services,
      ),
    );
    return gateway;
  }

  group('with the circle\'s services', () {
    testWidgets('none of the extras are offered without them', (tester) async {
      await pumpHome(tester, circle());
      expect(find.text(printCopyLabel), findsNothing);
      expect(find.text('Share what is said'), findsNothing);
    });

    testWidgets('a paper copy sends the board on this device and shows the '
        'link', (tester) async {
      final sent = <String>[];
      await pumpHome(
        tester,
        circle(),
        services: CircleServices(
          userId: 'me',
          publishBoard: (json) async {
            sent.add(json);
            return 'https://chorus.example/print/abc';
          },
        ),
      );
      await tester.tap(find.text(printCopyLabel));
      await tester.pumpAndSettle();

      final snapshot = jsonDecode(sent.single) as Map<String, dynamic>;
      expect(snapshot['childName'], 'Maya');
      expect(snapshot['rows'], 6);
      expect(snapshot['cols'], 6);
      expect(snapshot['tiles'], isNotEmpty);
      expect(find.text('https://chorus.example/print/abc'), findsOneWidget);
      expect(find.textContaining('Anyone with the link'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('https://chorus.example/print/abc'), findsNothing);
    });

    testWidgets('a paper copy that cannot be made says so and nothing '
        'else', (tester) async {
      await pumpHome(
        tester,
        circle(role: CircleRole.partner, myName: 'Gran'),
        services: CircleServices(
          userId: 'me',
          publishBoard: (_) => throw StateError('offline'),
        ),
      );
      await tester.tap(find.text(printCopyLabel));
      await tester.pumpAndSettle();
      expect(find.text(printCopyFailedMessage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('from the home screen the paper copy is of the home board; '
        'from the editor, of the board the adult is looking at', (
      tester,
    ) async {
      final sent = <Map<String, dynamic>>[];
      await pumpHome(
        tester,
        circle(),
        services: CircleServices(
          userId: 'me',
          publishBoard: (json) async {
            sent.add(jsonDecode(json) as Map<String, dynamic>);
            return 'https://chorus.example/print/abc';
          },
        ),
      );
      await tester.tap(find.text(printCopyLabel));
      await tester.pumpAndSettle();
      expect(sent.single['name'], 'Home');
      expect(sent.single['tiles'], hasLength(36));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(editWordsLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text('My words'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(printThisBoardLabel));
      await tester.pumpAndSettle();
      expect(sent, hasLength(2));
      expect(sent.last['name'], 'My words');
      expect(sent.last['tiles'], isEmpty);
      expect(find.text('https://chorus.example/print/abc'), findsOneWidget);
    });

    testWidgets('Work offline sits with the extras, pauses sync and keeps '
        'the paper copy off the network', (tester) async {
      final sync = FakeSyncStatus();
      final media = FakeMediaStore();
      var published = 0;
      await pumpHome(
        tester,
        circle(),
        sync: sync,
        services: CircleServices(
          userId: 'me',
          media: media,
          publishBoard: (_) async {
            published++;
            return 'https://chorus.example/print/abc';
          },
        ),
      );
      expect(find.text(printCopyLabel), findsOneWidget);
      final offline = find.widgetWithText(SwitchListTile, 'Work offline');
      expect(tester.widget<SwitchListTile>(offline).value, isFalse);

      await tester.tap(offline);
      await tester.pumpAndSettle();
      expect(sync.workingOffline, isTrue);
      expect(tester.widget<SwitchListTile>(offline).value, isTrue);
      expect(
        find.text('Working offline, saved on this device'),
        findsOneWidget,
      );
      expect(find.text('Sync now'), findsNothing);

      await tester.tap(find.text(printCopyLabel));
      await tester.pumpAndSettle();
      expect(find.text(printCopyOfflineMessage), findsOneWidget);
      expect(published, 0);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      await tester.tap(offline);
      await tester.pumpAndSettle();
      expect(sync.workingOffline, isFalse);
      await tester.tap(find.text(printCopyLabel));
      await tester.pumpAndSettle();
      expect(published, 1);
    });

    testWidgets('only a guardian is offered the sharing switch', (
      tester,
    ) async {
      ChorusLiveSession live({required bool forTalker}) => ChorusLiveSession(
        join: (_, _) => const Stream.empty(),
        circleSpace: mayaSpace,
      );
      await pumpHome(
        tester,
        circle(),
        services: CircleServices(userId: 'me', live: live),
      );
      expect(find.text('Share what is said'), findsOneWidget);

      await pumpHome(
        tester,
        circle(role: CircleRole.therapist, myName: 'Sam'),
        services: CircleServices(userId: 'me', live: live),
      );
      await tester.pumpAndSettle();
      expect(find.text('Share what is said'), findsNothing);
    });

    testWidgets('the talker and the editor each open a live session and '
        'close it when they are left', (tester) async {
      final opened = <bool>[];
      var streams = 0, cancelled = 0;
      ChorusLiveSession live({required bool forTalker}) {
        opened.add(forTalker);
        return ChorusLiveSession(
          join: (_, _) {
            streams++;
            final down = StreamController<LiveEvent>();
            down.onCancel = () => cancelled++;
            return down.stream;
          },
          circleSpace: mayaSpace,
        );
      }

      final media = FakeMediaStore();
      await pumpHome(
        tester,
        circle(),
        services: CircleServices(
          userId: 'me',
          live: live,
          media: media,
          speaker: FakeTileSpeaker(),
        ),
      );
      // Nothing is joined from the home screen.
      expect(opened, isEmpty);

      await tester.tap(find.text(openBoardLabel('Maya')));
      await tester.pumpAndSettle();
      final talker = tester.widget<TalkerScreen>(find.byType(TalkerScreen));
      expect(talker.live, isNotNull);
      expect(talker.media, same(media));
      expect(talker.speaker, isNotNull);
      expect(opened, [true]);
      expect((streams, cancelled), (1, 0));

      final hold = await tester.startGesture(
        tester.getCenter(find.text(leaveLabel)),
      );
      await tester.pump(const Duration(milliseconds: 2100));
      await hold.up();
      await tester.pumpAndSettle();
      expect(find.byType(TalkerScreen), findsNothing);
      expect(cancelled, 1);

      await tester.tap(find.text(editWordsLabel));
      await tester.pumpAndSettle();
      final editor = tester.widget<EditorScreen>(find.byType(EditorScreen));
      expect(editor.live, isNotNull);
      expect(editor.media, same(media));
      expect(opened, [true, false]);
      expect(streams, 2);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(cancelled, 2);
    });

    testWidgets('files still to be sent are counted on the home screen', (
      tester,
    ) async {
      final media = FakeMediaStore();
      await pumpHome(
        tester,
        circle(),
        services: CircleServices(userId: 'me', media: media),
      );
      expect(find.textContaining('waiting to be sent'), findsNothing);

      await media.addAudio(Uint8List.fromList([1, 2, 3]));
      await tester.pump();
      expect(
        find.text(
          '1 photo or recording is waiting to be sent from this device.',
        ),
        findsOneWidget,
      );
      media.finishUploads();
      await tester.pump();
      expect(find.textContaining('waiting to be sent'), findsNothing);
    });
  });

  group('the title and the chip', () {
    /// The chip's widest words: one state with "Sync now", one without.
    Future<FakeSyncStatus> widest(String which) async {
      final sync = FakeSyncStatus(state: SyncState.offline);
      if (which == 'working offline') await sync.setWorkingOffline(true);
      return sync;
    }

    /// The title is given at least its own width, so none of it is cut.
    void expectWholeTitle(WidgetTester tester) {
      final title = tester.renderObject<RenderParagraph>(
        find.text("Maya's board"),
      );
      expect(title.didExceedMaxLines, isFalse);
      expect(
        title.size.width,
        greaterThanOrEqualTo(
          title.getMinIntrinsicWidth(double.infinity) - 0.01,
        ),
      );
    }

    // The old app bar is gone: home is full bleed, the chip at the top of
    // the card and the display title under it.
    for (final which in ['offline', 'working offline']) {
      testWidgets('on a phone (360x820, $which) the chip is at the top, '
          'within the margins, and nothing overflows', (tester) async {
        final sync = await widest(which);
        await pumpHome(tester, circle(), sync: sync);
        tester.view.physicalSize = const Size(360, 820);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        expect(find.text(syncLabel(sync)), findsOneWidget);
        expectWholeTitle(tester);
        final title = tester.getRect(find.text("Maya's board"));
        final chip = tester.getRect(find.byType(SyncChip));
        expect(chip.bottom, lessThanOrEqualTo(title.top));
        expect(chip.left, ChorusSpace.marginPhone);
        expect(chip.right, lessThanOrEqualTo(360 - ChorusSpace.marginPhone));
        expect(chip.top, lessThan(80), reason: 'at the top of the screen');
        expect(
          find.text('Sync now'),
          which == 'offline' ? findsOneWidget : findsNothing,
        );
      });
    }

    testWidgets('on a wider screen the chip is still at the top and the '
        'title stays whole', (tester) async {
      final sync = await widest('offline');
      await pumpHome(tester, circle(), sync: sync);
      tester.view.physicalSize = const Size(1280, 800);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expectWholeTitle(tester);
      final title = tester.getRect(find.text("Maya's board"));
      final chip = tester.getRect(find.byType(SyncChip));
      expect(chip.bottom, lessThanOrEqualTo(title.top));
      expect(chip.left, moreOrLessEquals(title.left, epsilon: 1));
    });

    testWidgets('on a phone the sharing switch and the rest of a guardian\'s '
        'home lay out with no overflow', (tester) async {
      ChorusLiveSession live({required bool forTalker}) => ChorusLiveSession(
        join: (_, _) => const Stream.empty(),
        circleSpace: mayaSpace,
      );
      await pumpHome(
        tester,
        circle(),
        services: CircleServices(
          userId: 'me',
          live: live,
          media: FakeMediaStore(),
          publishBoard: (_) async => 'https://chorus.example/print/abc',
        ),
      );
      tester.view.physicalSize = const Size(360, 820);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Sign out'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Share what is said'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // The explanation is under the switch at the full width, not a
      // narrow column between the icon and the switch.
      final row = tester.getRect(
        find.widgetWithText(SwitchListTile, 'Share what is said'),
      );
      final text = tester.getRect(
        find.textContaining('While the talker is open'),
      );
      expect(text.top, greaterThanOrEqualTo(row.bottom));
      expect(text.width, greaterThan(280));
    });

    testWidgets('on a phone the "Work offline" explanation sits under its '
        'switch at the full width', (tester) async {
      await pumpHome(tester, circle());
      tester.view.physicalSize = const Size(360, 820);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Work offline'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);

      final row = tester.getRect(
        find.widgetWithText(SwitchListTile, 'Work offline'),
      );
      final text = tester.getRect(
        find.textContaining('Pauses sync on this device'),
      );
      expect(text.top, greaterThanOrEqualTo(row.bottom));
      expect(text.width, greaterThan(280));
    });
  });

  testWidgets('a guardian sees every action and the sync chip', (tester) async {
    await pumpHome(tester, circle());

    expect(find.text("Maya's board"), findsOneWidget);
    for (final label in [
      openBoardLabel('Maya'),
      editWordsLabel,
      'Invite someone',
      'Credits',
      'Sign out',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.byType(SyncChip), findsOneWidget);
    expect(find.text(everyoneUpToDateLabel), findsOneWidget);
    // One circle: no switcher.
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('a partner can view but is not offered editing or inviting', (
    tester,
  ) async {
    await pumpHome(tester, circle(role: CircleRole.partner, myName: 'Gran'));

    expect(find.text(viewBoardLabel('Maya')), findsOneWidget);
    expect(find.text(openBoardLabel('Maya')), findsNothing);
    expect(find.text(editWordsLabel), findsNothing);
    expect(find.text('Invite someone'), findsNothing);

    // Viewing is the child's board itself.
    await tester.tap(find.text(viewBoardLabel('Maya')));
    await tester.pumpAndSettle();
    expect(find.byType(TalkerScreen), findsOneWidget);
  });

  testWidgets('a therapist can edit but not invite', (tester) async {
    await pumpHome(tester, circle(role: CircleRole.therapist));

    expect(find.text(editWordsLabel), findsOneWidget);
    expect(find.text('Invite someone'), findsNothing);
  });

  testWidgets('inviting shows the code large with a copy button', (
    tester,
  ) async {
    final gateway = await pumpHome(tester, circle());

    await tester.tap(find.text('Invite someone'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Family or friend who can view'));
    await tester.pump();
    await tester.tap(find.text('Make a code'));
    await tester.pumpAndSettle();

    expect(gateway.invited, [CircleRole.partner]);
    expect(find.text('ABC234'), findsOneWidget);
    expect(find.text('Copy code'), findsOneWidget);
  });

  testWidgets('a refused invite is explained and can be retried', (
    tester,
  ) async {
    final gateway = await pumpHome(tester, circle());
    gateway.failNext = CircleException(failure: CircleFailure.notAllowed);

    await tester.tap(find.text('Invite someone'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Make a code'));
    await tester.pumpAndSettle();

    expect(find.text('Only a parent or guardian can do that.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('ABC234'), findsOneWidget);
  });

  testWidgets('with more than one circle a switcher chooses between them', (
    tester,
  ) async {
    final maya = circle();
    final sam = circle(space: samSpace, childName: 'Sam');
    CircleInfo? chosen;
    await pumpHome(
      tester,
      maya,
      circles: [maya, sam],
      onSelect: (circle) => chosen = circle,
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Sam'));
    expect(chosen?.childName, 'Sam');
  });

  testWidgets('a circle that could not be readied says so and offers Retry', (
    tester,
  ) async {
    var retries = 0;
    await pumpHome(
      tester,
      circle(),
      readiness: CircleReadiness.failed,
      onRetryReady: () => retries++,
    );

    expect(find.textContaining('could not check in'), findsOneWidget);
    // The board saved on the device still opens.
    expect(
      tester.widget<PressableSurface>(find.byKey(HomeActions.openKey)).onTap,
      isNotNull,
    );
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });

  testWidgets('a ready circle with no board yet explains and offers Retry', (
    tester,
  ) async {
    var retries = 0;
    await pumpHome(
      tester,
      circle(role: CircleRole.therapist),
      store: _NoBoardYet(),
      onRetryReady: () => retries++,
    );

    expect(find.textContaining('There is no board here yet'), findsOneWidget);
    expect(
      tester.widget<PressableSurface>(find.byKey(HomeActions.openKey)).onTap,
      isNull,
    );
    // The hero keeps the board's space, grey and still.
    expect(find.byKey(HomeHero.skeletonKey), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });

  group('signed-in shell', () {
    testWidgets('Retry joins the readying call still under way', (
      tester,
    ) async {
      final workspace = FakeWorkspace()..readyGate = Completer<void>();
      await pumpScreen(
        tester,
        SignedInShell(
          gateway: FakeGateway(circles: [circle()]),
          openWorkspace: () async => workspace,
          speech: FakeSpeech(),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(workspace.readied, hasLength(1));

      // The wait is given up on; the work is not.
      await tester.pump(const Duration(seconds: 46));
      expect(find.textContaining('could not check in'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(workspace.readied, hasLength(1), reason: 'no second call');
      expect(workspace.sync.syncNowCalls, 1);

      workspace.readyGate!.complete();
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('could not check in'), findsNothing);
      expect(find.textContaining('Checking for changes'), findsNothing);
    });

    testWidgets('sign out does not wait for ever on a replica that hangs', (
      tester,
    ) async {
      final gateway = FakeGateway(circles: [circle()]);
      final workspace = FakeWorkspace()..closeGate = Completer<void>();
      await pumpScreen(
        tester,
        SignedInShell(
          gateway: gateway,
          openWorkspace: () async => workspace,
          speech: FakeSpeech(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign out'));
      await tester.pump(const Duration(seconds: 4));
      expect(gateway.signOuts, 0);
      await tester.pump(const Duration(seconds: 2));
      expect(gateway.signOuts, 1);
    });

    testWidgets('remembered circles open home with no server answer', (
      tester,
    ) async {
      final gateway = FakeGateway(remembered: [circle()])
        ..failNext = Exception('offline');
      final workspace = FakeWorkspace()..failNextReady = Exception('offline');
      await pumpScreen(
        tester,
        SignedInShell(
          gateway: gateway,
          openWorkspace: () async => workspace,
          speech: FakeSpeech(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Maya's board"), findsOneWidget);
      expect(find.textContaining('could not check in'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.textContaining('could not check in'), findsNothing);
      expect(workspace.readied, [('Maya', true), ('Maya', true)]);
    });

    testWidgets('no signal and nothing remembered: an error with Retry', (
      tester,
    ) async {
      final gateway = FakeGateway(circles: [circle()])
        ..failNext = Exception('offline');
      await pumpScreen(
        tester,
        SignedInShell(
          gateway: gateway,
          openWorkspace: () async => FakeWorkspace(),
          speech: FakeSpeech(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('could not reach the server'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text("Maya's board"), findsOneWidget);
    });

    testWidgets('a replica that will not open offers Retry', (tester) async {
      var attempts = 0;
      await pumpScreen(
        tester,
        SignedInShell(
          gateway: FakeGateway(circles: [circle()]),
          openWorkspace: () async {
            if (attempts++ == 0) throw StateError('locked');
            return FakeWorkspace();
          },
          speech: FakeSpeech(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('could not open the boards'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text("Maya's board"), findsOneWidget);
    });

    testWidgets('an invited member does not seed the starter board', (
      tester,
    ) async {
      final workspace = FakeWorkspace();
      await pumpScreen(
        tester,
        SignedInShell(
          gateway: FakeGateway(circles: [circle(role: CircleRole.teacher)]),
          openWorkspace: () async => workspace,
          speech: FakeSpeech(),
        ),
      );
      await tester.pumpAndSettle();

      expect(workspace.readied, [('Maya', false)]);
    });

    testWidgets('sign out closes the replica, then signs out', (tester) async {
      final gateway = FakeGateway(circles: [circle()]);
      final workspace = FakeWorkspace();
      await pumpScreen(
        tester,
        SignedInShell(
          gateway: gateway,
          openWorkspace: () async => workspace,
          speech: FakeSpeech(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign out'));
      await tester.pump();
      await tester.pump();

      expect(workspace.closed, isTrue);
      expect(gateway.signOuts, 1);
      // While the auth state catches up the screen says what is happening.
      expect(find.text('Signing out…'), findsOneWidget);
    });
  });
}
