// Home's way in to "Who is up to date", "Under the hood" and, through the
// editor, "Try a clash".
import 'package:chorus_flutter/screens/home_screen.dart';
import 'package:chorus_flutter/screens/services.dart';
import 'package:chorus_flutter/src/trust/trust_services.dart';
import 'package:chorus_ui/editor/editor_screen.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_clash.dart';
import 'package:chorus_ui/fakes_trust.dart';
import 'package:chorus_ui/features/clash/clash_guide.dart';
import 'package:chorus_ui/features/trust/under_the_hood_screen.dart';
import 'package:chorus_ui/features/trust/who_is_up_to_date_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  Future<void> pumpHome(WidgetTester tester, CircleServices services) async {
    final workspace = FakeWorkspace();
    final selected = circle();
    await pumpScreen(
      tester,
      HomeScreen(
        circles: [selected],
        selected: selected,
        onSelect: (_) {},
        store: workspace.boardStore(selected),
        sync: workspace.sync,
        speech: FakeSpeech(),
        gateway: FakeGateway(),
        readiness: CircleReadiness.ready,
        onRetryReady: () {},
        onSignOut: () {},
        services: services,
      ),
    );
  }

  testWidgets('without the trust services home offers neither entry', (
    tester,
  ) async {
    await pumpHome(tester, const CircleServices(userId: 'me'));
    expect(find.text(whoIsUpToDateTitle), findsNothing);
    expect(find.text(underTheHoodTitle), findsNothing);
  });

  testWidgets('"Who is up to date" and "Under the hood" open from home', (
    tester,
  ) async {
    await pumpHome(
      tester,
      CircleServices(
        userId: 'me',
        trust: TrustServices(
          devices: FakeDeviceDirectory(),
          inspector: FakeReplicaInspector(),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.text(whoIsUpToDateTitle),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(whoIsUpToDateTitle));
    await tester.pumpAndSettle();
    expect(find.byType(WhoIsUpToDateScreen), findsOneWidget);
    expect(find.text('This device: up to date'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text(underTheHoodTitle),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(underTheHoodTitle));
    await tester.pumpAndSettle();
    expect(find.byType(UnderTheHoodScreen), findsOneWidget);
    expect(find.text('0.0.10'), findsOneWidget);
  });

  testWidgets('the editor opened from home offers "Try a clash"', (
    tester,
  ) async {
    await pumpHome(
      tester,
      CircleServices(
        userId: 'me',
        trust: TrustServices(clash: FakeClashPartner()),
      ),
    );
    await tester.tap(find.text(editWordsLabel));
    await tester.pumpAndSettle();
    expect(find.byType(EditorScreen), findsOneWidget);
    await tester.tap(find.byTooltip(boardMenuLabel));
    await tester.pumpAndSettle();
    expect(find.text(tryAClashLabel), findsOneWidget);
  });
}
