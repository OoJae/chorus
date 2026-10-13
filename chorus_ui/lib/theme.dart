/// Colours and type for every Chorus screen.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';

/// High-contrast Material 3 theme: black on white, large type, no tinting.
ThemeData chorusTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1F4E9C),
    brightness: Brightness.light,
  ).copyWith(
    surface: Colors.white,
    onSurface: Colors.black,
    surfaceTint: Colors.transparent,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.white,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );
  return base.copyWith(
    textTheme: base.textTheme
        .apply(bodyColor: Colors.black, displayColor: Colors.black)
        .copyWith(
          bodyLarge: base.textTheme.bodyLarge
              ?.copyWith(fontSize: 18, color: Colors.black),
          bodyMedium: base.textTheme.bodyMedium
              ?.copyWith(fontSize: 16, color: Colors.black),
          labelLarge: base.textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
  );
}

/// Background colour for a part-of-speech key; white when the key is null or
/// not in [colorForKey].
Color tileColor(String? colorKey) =>
    Color(colorForKey[colorKey] ?? 0xFFFFFFFF);

/// Black or white, whichever reads better on [background].
Color inkOn(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : Colors.black;
