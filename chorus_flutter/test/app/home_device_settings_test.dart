// Home's way into "This device", with the circle's voice in it.
import 'package:chorus_flutter/screens/home_screen.dart';
import 'package:chorus_flutter/screens/services.dart';
import 'package:chorus_ui/device/device_settings_scope.dart';
import 'package:chorus_ui/device/device_settings_screen.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_device.dart';
import 'package:chorus_ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  Future<void> pumpHome(WidgetTester tester, {bool scope = true}) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final selected = circle();
    final workspace = FakeWorkspace();
    final home = HomeScreen(
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
      services: CircleServices(userId: 'me', voice: FakeVoiceChoice()),
    );
    final app = MaterialApp(theme: chorusTheme(), home: home);
    await tester.pumpWidget(
      scope
          ? DeviceSettingsScope(store: InMemoryDeviceSettings(), child: app)
          : app,
    );
    await tester.pump();
  }

  testWidgets('home opens "This device", voice and keyguard included', (
    tester,
  ) async {
    await pumpHome(tester);
    await tester.scrollUntilVisible(find.text(deviceSettingsTitle), 200);
    await tester.tap(find.text(deviceSettingsTitle));
    await tester.pumpAndSettle();
    expect(find.byType(DeviceSettingsScreen), findsOneWidget);
    expect(find.text(voiceHeading), findsOneWidget);
    expect(find.text(keyguardTemplateLabel), findsOneWidget);
  });

  testWidgets('without device settings home offers no entry', (tester) async {
    await pumpHome(tester, scope: false);
    expect(find.text(deviceSettingsTitle), findsNothing);
  });
}
