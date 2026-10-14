/// What the feature screen tests share: the app around a screen, and the
/// screen sizes every screen must look deliberate at.
library;

import 'package:chorus_ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phone portrait (short and tall), phone landscape, laptop and desktop.
const List<Size> featureSizes = [
  Size(360, 640),
  Size(360, 820),
  Size(820, 360),
  Size(1280, 800),
  Size(1440, 900),
];

/// [home] in the Chorus theme, as the app shows it.
Widget featureApp(
  Widget home, {
  Brightness brightness = Brightness.light,
  bool reduced = false,
  double textScale = 1,
}) => MaterialApp(
  theme: chorusTheme(),
  darkTheme: chorusDarkTheme(),
  themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      disableAnimations: reduced,
      textScaler: TextScaler.linear(textScale),
    ),
    child: child!,
  ),
  home: home,
);

/// Lays the test out on a screen [size] logical pixels big.
void setScreen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
