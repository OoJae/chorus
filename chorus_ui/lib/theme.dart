/// Colours and type for every Chorus screen.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';

import 'brand/laminated_border.dart';
import 'brand/motion.dart';
import 'brand/tokens.dart';

/// The light theme: ink on laminated card.
///
/// Colour belongs to words: every component here is ink, card and line, and
/// the only colour on a screen is its word tiles.
ThemeData chorusTheme() => _chorusTheme(ChorusColors.light, Brightness.light);

/// The dark theme: ink on slate, its own palette rather than the light one
/// inverted.
ThemeData chorusDarkTheme() => _chorusTheme(ChorusColors.dark, Brightness.dark);

ThemeData _chorusTheme(ChorusColors c, Brightness brightness) {
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.ink,
    onPrimary: c.card,
    primaryContainer: c.line,
    onPrimaryContainer: c.ink,
    secondary: c.ink,
    onSecondary: c.card,
    secondaryContainer: c.line,
    onSecondaryContainer: c.ink,
    tertiary: c.ink,
    onTertiary: c.card,
    tertiaryContainer: c.line,
    onTertiaryContainer: c.ink,
    error: c.alert,
    onError: c.card,
    errorContainer: Color.alphaBlend(
      c.alert.withValues(alpha: 0.14),
      c.surface,
    ),
    onErrorContainer: c.ink,
    surface: c.card,
    onSurface: c.ink,
    onSurfaceVariant: c.inkMuted,
    surfaceDim: c.card,
    surfaceBright: c.surface,
    surfaceContainerLowest: c.surface,
    surfaceContainerLow: c.surface,
    surfaceContainer: c.surface,
    surfaceContainerHigh: c.surface,
    surfaceContainerHighest: c.line,
    outline: c.inkMuted,
    outlineVariant: c.line,
    // Surfaces are flat: depth is the laminated edge, never a shadow.
    shadow: Colors.transparent,
    scrim: Colors.black,
    inverseSurface: c.ink,
    onInverseSurface: c.card,
    inversePrimary: c.card,
    surfaceTint: Colors.transparent,
  );
  final text = _textTheme(c);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.card,
    canvasColor: c.card,
    dividerColor: c.line,
    // What a disabled list tile, among others, falls back to.
    disabledColor: c.ink.withValues(alpha: 0.38),
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    textTheme: text,
    primaryTextTheme: text.apply(bodyColor: c.card, displayColor: c.card),
    iconTheme: IconThemeData(color: c.ink, size: 24),
    primaryIconTheme: IconThemeData(color: c.card, size: 24),
    extensions: [c],
    appBarTheme: AppBarThemeData(
      backgroundColor: c.card,
      foregroundColor: c.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      centerTitle: false,
      iconTheme: IconThemeData(color: c.ink),
      actionsIconTheme: IconThemeData(color: c.ink),
      titleTextStyle: text.titleLarge,
      toolbarTextStyle: text.bodyMedium,
    ),
    filledButtonTheme: FilledButtonThemeData(style: _laminatedStyle()),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: _laminatedStyle().copyWith(
        backgroundColor: _byState(
          c.ink,
          disabled: c.ink.withValues(alpha: 0.12),
        ),
        foregroundColor: _byState(
          c.card,
          disabled: c.ink.withValues(alpha: 0.38),
        ),
        iconColor: _byState(c.card, disabled: c.ink.withValues(alpha: 0.38)),
        overlayColor: _overlay(c.card),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: _byState(
          c.ink,
          disabled: c.ink.withValues(alpha: 0.38),
        ),
        iconColor: _byState(c.ink, disabled: c.ink.withValues(alpha: 0.38)),
        overlayColor: _overlay(c.ink),
        side: WidgetStateProperty.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.disabled)
                ? c.ink.withValues(alpha: 0.12)
                : c.ink,
            width: 1.5,
          ),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(ChorusSpace.buttonRadius),
            ),
          ),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(64, 48)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        ),
        textStyle: const WidgetStatePropertyAll(ChorusType.label),
        elevation: const WidgetStatePropertyAll(0),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: _byState(
          c.ink,
          disabled: c.ink.withValues(alpha: 0.38),
        ),
        iconColor: _byState(c.ink, disabled: c.ink.withValues(alpha: 0.38)),
        overlayColor: _overlay(c.ink),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(ChorusSpace.buttonRadius),
            ),
          ),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        textStyle: const WidgetStatePropertyAll(ChorusType.label),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: _byState(
          c.ink,
          disabled: c.ink.withValues(alpha: 0.38),
        ),
        iconColor: _byState(c.ink, disabled: c.ink.withValues(alpha: 0.38)),
        overlayColor: _overlay(c.ink),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.ink,
      foregroundColor: c.card,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(ChorusSpace.buttonRadius),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: c.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      // A field's outline is how it is found, so it needs 3:1 against the
      // page and the sheet: muted ink, not the hairline.
      border: _field(c.inkMuted),
      enabledBorder: _field(c.inkMuted),
      focusedBorder: _field(c.ink, width: 2),
      errorBorder: _field(c.alert, width: 1.5),
      focusedErrorBorder: _field(c.alert, width: 2),
      disabledBorder: _field(c.line.withValues(alpha: 0.5)),
      labelStyle: _fieldLabel(c),
      floatingLabelStyle: _fieldLabel(c),
      hintStyle: TextStyle(color: c.inkMuted),
      helperStyle: text.bodySmall?.copyWith(color: c.inkMuted),
      errorStyle: text.bodySmall?.copyWith(color: c.alert),
      counterStyle: text.bodySmall?.copyWith(color: c.inkMuted),
      iconColor: c.ink,
      prefixIconColor: c.inkMuted,
      suffixIconColor: c.inkMuted,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.ink,
      selectionColor: c.ink.withValues(alpha: 0.2),
      selectionHandleColor: c.ink,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surface,
      selectedColor: c.ink,
      disabledColor: c.line,
      checkmarkColor: c.card,
      side: WidgetStateBorderSide.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.selected) ? c.ink : c.inkMuted,
        ),
      ),
      labelStyle: ChorusType.label.copyWith(
        color: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? c.ink.withValues(alpha: 0.38)
              : states.contains(WidgetState.selected)
              ? c.card
              : c.ink,
        ),
      ),
      iconTheme: IconThemeData(color: c.ink, size: 18),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(ChorusSpace.buttonRadius),
        ),
      ),
      elevation: 0,
      pressElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        final on = states.contains(WidgetState.selected);
        final colour = on ? c.card : c.inkMuted;
        return states.contains(WidgetState.disabled)
            ? colour.withValues(alpha: 0.5)
            : colour;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return c.line;
        return states.contains(WidgetState.selected) ? c.ink : c.surface;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return c.line;
        return states.contains(WidgetState.selected) ? c.ink : c.inkMuted;
      }),
      overlayColor: _overlay(c.ink),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? (states.contains(WidgetState.disabled)
                  ? c.ink.withValues(alpha: 0.38)
                  : c.ink)
            : Colors.transparent,
      ),
      checkColor: WidgetStatePropertyAll(c.card),
      side: BorderSide(color: c.inkMuted, width: 2),
      overlayColor: _overlay(c.ink),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? c.ink : c.inkMuted,
      ),
      overlayColor: _overlay(c.ink),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: c.ink,
      unselectedLabelColor: c.inkMuted,
      indicatorColor: c.ink,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: c.ink, width: 3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      ),
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: c.line,
      labelStyle: ChorusType.label,
      unselectedLabelStyle: ChorusType.label,
      overlayColor: _overlay(c.ink),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      modalBackgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      dragHandleColor: c.inkMuted,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ChorusSpace.sheetRadius),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(ChorusSpace.panelRadius),
        ),
      ),
      iconColor: c.ink,
      titleTextStyle: ChorusType.headline.copyWith(color: c.ink),
      contentTextStyle: ChorusType.body.copyWith(color: c.ink),
    ),
    // Fixed at the bottom, as before: whether one floats is each screen's
    // call.
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.ink,
      contentTextStyle: ChorusType.body.copyWith(color: c.card),
      actionTextColor: c.card,
      closeIconColor: c.card,
      disabledActionTextColor: c.card.withValues(alpha: 0.6),
      elevation: 0,
    ),
    // No textColor: a list tile gives it to the subtitle too, over the
    // muted ink of subtitleTextStyle.
    listTileTheme: ListTileThemeData(
      iconColor: c.ink,
      selectedColor: c.ink,
      titleTextStyle: ChorusType.body.copyWith(color: c.ink),
      subtitleTextStyle: ChorusType.body.copyWith(color: c.inkMuted),
      leadingAndTrailingTextStyle: ChorusType.status.copyWith(
        color: c.inkMuted,
      ),
    ),
    dividerTheme: DividerThemeData(color: c.line, thickness: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.ink,
      linearTrackColor: c.line,
      circularTrackColor: Colors.transparent,
      refreshBackgroundColor: c.surface,
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(ChorusSpace.panelRadius),
        ),
        side: BorderSide(color: c.line),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: c.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      textStyle: ChorusType.body.copyWith(color: c.ink),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(ChorusSpace.buttonRadius),
        ),
        side: BorderSide(color: c.line),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: c.ink,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      textStyle: ChorusType.label.copyWith(color: c.card),
    ),
  );
}

TextTheme _textTheme(ChorusColors c) {
  const display = ChorusType.display;
  const title = ChorusType.title;
  return TextTheme(
    displayLarge: display,
    displayMedium: ChorusType.frauncesAt(display, 40, 44),
    displaySmall: ChorusType.frauncesAt(display, 36, 40),
    headlineLarge: title,
    headlineMedium: ChorusType.frauncesAt(title, 26, 30),
    headlineSmall: ChorusType.frauncesAt(title, 24, 28),
    // App bar and sheet titles.
    titleLarge: ChorusType.frauncesAt(title, 22, 28),
    titleMedium: ChorusType.headline,
    titleSmall: ChorusType.headline.copyWith(fontSize: 16, height: 22 / 16),
    bodyLarge: ChorusType.body,
    // Material's default text style, and what TileLabelSizer measures tile
    // labels in.
    bodyMedium: ChorusType.body,
    // Reading text is never below 16.
    bodySmall: ChorusType.body.copyWith(fontSize: 16, height: 22 / 16),
    labelLarge: ChorusType.label,
    labelMedium: ChorusType.label.copyWith(
      fontSize: 14,
      height: 18 / 14,
      letterSpacing: 0.02 * 14,
    ),
    labelSmall: ChorusType.label.copyWith(
      fontSize: 13,
      height: 16 / 13,
      letterSpacing: 0.02 * 13,
    ),
  ).apply(bodyColor: c.ink, displayColor: c.ink);
}

/// An ink button on a laminated edge: it sinks onto a thinner edge while
/// pressed. Its colours come from the colour scheme (ink face, card text;
/// the tonal kind is line and ink).
ButtonStyle _laminatedStyle() => ButtonStyle(
  shape: WidgetStateProperty.resolveWith(
    (states) =>
        states.contains(WidgetState.pressed) &&
            !states.contains(WidgetState.disabled)
        ? const LaminatedBorder.pressed()
        : const LaminatedBorder(),
  ),
  // The label sits in the middle of the face, and sinks with it.
  padding: WidgetStateProperty.resolveWith(
    (states) => states.contains(WidgetState.pressed)
        ? const EdgeInsets.fromLTRB(24, 12, 24, 11)
        : const EdgeInsets.fromLTRB(24, 10, 24, 13),
  ),
  minimumSize: const WidgetStatePropertyAll(Size(64, 48)),
  textStyle: const WidgetStatePropertyAll(ChorusType.label),
  elevation: const WidgetStatePropertyAll(0),
  shadowColor: const WidgetStatePropertyAll(Colors.transparent),
  // The press spring settles in about this long.
  animationDuration: ChorusMotion.toggleDuration,
);

WidgetStateProperty<Color> _byState(Color color, {required Color disabled}) =>
    WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled) ? disabled : color,
    );

/// The wash over a pressed, focused or hovered control, in [color].
WidgetStateProperty<Color?> _overlay(Color color) =>
    WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return color.withValues(alpha: 0.1);
      }
      if (states.contains(WidgetState.focused)) {
        return color.withValues(alpha: 0.12);
      }
      if (states.contains(WidgetState.hovered)) {
        return color.withValues(alpha: 0.08);
      }
      return null;
    });

OutlineInputBorder _field(Color color, {double width = 1}) =>
    OutlineInputBorder(
      borderRadius: const BorderRadius.all(
        Radius.circular(ChorusSpace.buttonRadius),
      ),
      borderSide: BorderSide(color: color, width: width),
    );

/// A field's label: alert on an error, ink while focused, muted otherwise.
WidgetStateTextStyle _fieldLabel(ChorusColors c) =>
    WidgetStateTextStyle.resolveWith(
      (states) => TextStyle(
        color: states.contains(WidgetState.error)
            ? c.alert
            : states.contains(WidgetState.focused)
            ? c.ink
            : c.inkMuted,
      ),
    );

/// Background colour for a part-of-speech key; white when the key is null or
/// not in [colorForKey].
Color tileColor(String? colorKey) => Color(colorForKey[colorKey] ?? 0xFFFFFFFF);

/// Black or white, whichever reads better on [background].
Color inkOn(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark
    ? Colors.white
    : Colors.black;
