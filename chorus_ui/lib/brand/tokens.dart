/// The Chorus design tokens: interface colours, tile colours, type, space
/// and shape. Screens read these instead of writing their own values.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The interface colours of one mode. All chrome is ink on card: colour on a
/// screen comes only from word tiles ([TileFamily]), never from here.
///
/// Read them with `Theme.of(context).extension<ChorusColors>()`, or
/// [ChorusColors.of], which also works under a theme without them.
@immutable
class ChorusColors extends ThemeExtension<ChorusColors> {
  const ChorusColors({
    required this.card,
    required this.surface,
    required this.ink,
    required this.inkMuted,
    required this.line,
    required this.alert,
  });

  /// Laminated card stock.
  static const ChorusColors light = ChorusColors(
    card: Color(0xFFF6F2EA),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF15171A),
    inkMuted: Color(0xFF5A5F67),
    line: Color(0xFFDCD6CB),
    alert: Color(0xFFB42318),
  );

  /// Slate: its own palette rather than the light one inverted. It also
  /// suits children with cortical visual impairment, who often use dark
  /// backgrounds.
  static const ChorusColors dark = ChorusColors(
    card: Color(0xFF101214),
    surface: Color(0xFF1B1E22),
    ink: Color(0xFFEEE9E0),
    inkMuted: Color(0xFFA4A8AF),
    line: Color(0xFF30343A),
    alert: Color(0xFFFF8A7A),
  );

  /// The page background.
  final Color card;

  /// Sheets, panels and fields. In the dark they are raised by being
  /// lighter, never by a shadow.
  final Color surface;

  /// Text, icons, primary buttons and the focus ring.
  final Color ink;

  /// Secondary text.
  final Color inkMuted;

  /// Hairlines, empty-cell borders and dividers.
  final Color line;

  /// Errors only, such as "Nothing was changed" or a failed sync. Not an
  /// accent.
  final Color alert;

  /// The colours of the theme around [context]. A theme built without them
  /// (a test pumping a bare MaterialApp) gets the set for its brightness.
  static ChorusColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<ChorusColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  ChorusColors copyWith({
    Color? card,
    Color? surface,
    Color? ink,
    Color? inkMuted,
    Color? line,
    Color? alert,
  }) => ChorusColors(
    card: card ?? this.card,
    surface: surface ?? this.surface,
    ink: ink ?? this.ink,
    inkMuted: inkMuted ?? this.inkMuted,
    line: line ?? this.line,
    alert: alert ?? this.alert,
  );

  @override
  ChorusColors lerp(covariant ThemeExtension<ChorusColors>? other, double t) {
    if (other is! ChorusColors) return this;
    return ChorusColors(
      card: Color.lerp(card, other.card, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      line: Color.lerp(line, other.line, t)!,
      alert: Color.lerp(alert, other.alert, t)!,
    );
  }
}

/// A tile's face and the darker 3 dp edge under it.
@immutable
class TileColors {
  const TileColors({required this.fill, required this.edge});

  final Color fill;
  final Color edge;
}

/// The label colour on every tile, in both modes: at least 9:1 on every
/// fill.
const Color tileLabelInk = Color(0xFF15171A);

/// Laid over a face colour to draw its darker edge, where no edge colour is
/// given: a primary button, an onboarding choice.
const Color laminatedEdgeShade = Color(0x4D000000);

/// The darker edge for a pressable thing coloured [face].
Color edgeFor(Color face) => Color.alphaBlend(laminatedEdgeShade, face);

/// The Fitzgerald colour key, retuned as laminated card. In AAC the colours
/// mean grammar, which is why nothing else on a screen is coloured.
///
/// The dark fills are 8 to 12% less bright, so they do not glare on slate.
enum TileFamily {
  /// Verbs.
  action(
    light: TileColors(fill: Color(0xFFC7EFB2), edge: Color(0xFF7DB863)),
    dark: TileColors(fill: Color(0xFFA9D993), edge: Color(0xFF5F9A48)),
  ),

  /// Pronouns and people.
  person(
    light: TileColors(fill: Color(0xFFFFEFA0), edge: Color(0xFFD6B53F)),
    dark: TileColors(fill: Color(0xFFE7D57D), edge: Color(0xFFB0942D)),
  ),

  /// Describing words.
  describe(
    light: TileColors(fill: Color(0xFFC0DBFF), edge: Color(0xFF6E9FE0)),
    dark: TileColors(fill: Color(0xFF9DC2F1), edge: Color(0xFF4F7EBF)),
  ),

  /// Question words.
  question(
    light: TileColors(fill: Color(0xFFDDCBFF), edge: Color(0xFF9B7BDF)),
    // One step greener than the plan's #C1ADEF, which gives the label
    // 8.97:1: this keeps the promised 9:1 and looks the same.
    dark: TileColors(fill: Color(0xFFC1AEEF), edge: Color(0xFF7A5BC1)),
  ),

  /// Negation.
  not(
    light: TileColors(fill: Color(0xFFFFD2AE), edge: Color(0xFFD88858)),
    dark: TileColors(fill: Color(0xFFEFB88E), edge: Color(0xFFB76A3D)),
  ),

  /// Everything else, and a tile with no colour.
  other(
    light: TileColors(fill: Color(0xFFE5E4E0), edge: Color(0xFFA9A8A3)),
    dark: TileColors(fill: Color(0xFFCAC9C4), edge: Color(0xFF8D8C87)),
  );

  const TileFamily({required this.light, required this.dark});

  final TileColors light;
  final TileColors dark;

  TileColors colorsFor(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  /// The family of a tile's stored `colorKey`: the keys of `colorForKey` in
  /// `chorus_shared`, and the plain names the colour picker falls back to.
  /// A missing or unknown key (an imported board, an AI guess such as
  /// "noun") is [other].
  static TileFamily forKey(String? colorKey) =>
      switch (colorKey?.trim().toLowerCase()) {
        'verb' || 'action' => action,
        'pronoun' || 'person' => person,
        'descriptor' || 'adjective' || 'describe' => describe,
        'question' => question,
        'negation' || 'not' => not,
        _ => other,
      };
}

/// The type roles. Every style names its font with the `chorus_ui` package
/// prefix, so the app gets the bundled fonts without having to know that
/// they live in a package.
///
/// Sizes are logical pixels, which follow the Android font scale. The styles
/// carry no colour: they take it from the theme around them.
///
/// Fraunces and Atkinson are variable fonts. On Android and on the web the
/// engine sets the weight axis from `fontWeight` unless a style names it, so
/// the Atkinson styles leave it to `fontWeight`: a copy at another weight
/// (a tile label at w700) then draws at that weight. Fraunces names all
/// four of its axes, as its own defaults are weight 900 and wonky.
abstract final class ChorusType {
  // The app registers a package's fonts under "packages/<package>/<family>";
  // `flutter run -t lib/main_fake.dart` runs this package as the app, which
  // registers them under the bare name, hence the fallback.
  static const String _fraunces = 'packages/chorus_ui/Fraunces';
  static const String _atkinson = 'packages/chorus_ui/AtkinsonHyperlegibleNext';
  static const String _plexMono = 'packages/chorus_ui/IBMPlexMono';
  static const List<String> _frauncesFallback = ['Fraunces'];
  static const List<String> _atkinsonFallback = ['AtkinsonHyperlegibleNext'];
  static const List<String> _plexMonoFallback = ['IBMPlexMono'];

  /// The largest text scale display type follows. Body text is never
  /// capped.
  static const double displayMaxScale = 1.3;

  /// Wordmark, the onboarding line, "Maya's board" on home, empty-state
  /// headlines: a soft picture-book serif, at most three times per app.
  /// Draw it with [displayScaler].
  static const TextStyle display = TextStyle(
    fontFamily: _fraunces,
    fontFamilyFallback: _frauncesFallback,
    fontSize: 48,
    height: 50 / 48,
    letterSpacing: -0.02 * 48,
    fontWeight: FontWeight.w600,
    fontVariations: [
      FontVariation.weight(600),
      FontVariation('SOFT', 100),
      FontVariation('WONK', 0),
      FontVariation.opticalSize(48),
    ],
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Screen titles in the adult screens.
  static const TextStyle title = TextStyle(
    fontFamily: _fraunces,
    fontFamilyFallback: _frauncesFallback,
    fontSize: 30,
    height: 34 / 30,
    fontWeight: FontWeight.w600,
    fontVariations: [
      FontVariation.weight(600),
      FontVariation('SOFT', 100),
      FontVariation('WONK', 0),
      FontVariation.opticalSize(30),
    ],
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Section heads.
  static const TextStyle headline = TextStyle(
    fontFamily: _atkinson,
    fontFamilyFallback: _atkinsonFallback,
    fontSize: 19,
    height: 24 / 19,
    fontWeight: FontWeight.w700,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// All reading text. Never set below 16.
  static const TextStyle body = TextStyle(
    fontFamily: _atkinson,
    fontFamilyFallback: _atkinsonFallback,
    fontSize: 17,
    height: 25 / 17,
    fontWeight: FontWeight.w400,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Buttons, tabs and fields.
  static const TextStyle label = TextStyle(
    fontFamily: _atkinson,
    fontFamilyFallback: _atkinsonFallback,
    fontSize: 15,
    height: 20 / 15,
    letterSpacing: 0.02 * 15,
    fontWeight: FontWeight.w600,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// The machine's voice: the sync chip, counts ("1 waiting", "Needs a home
  /// · 2") and times.
  static const TextStyle status = TextStyle(
    fontFamily: _plexMono,
    fontFamilyFallback: _plexMonoFallback,
    fontSize: 13,
    height: 16 / 13,
    letterSpacing: 0.04 * 13,
    fontWeight: FontWeight.w500,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// A word on a tile, at the one [size] its board uses (from
  /// `TileLabelSizer`, 14 to 32). Atkinson Hyperlegible keeps I, l and 1
  /// apart, for children with low vision.
  ///
  /// Family, weight and spacing match the body style `TileLabelSizer`
  /// measures with, so a label drawn in this style fits where it was
  /// measured to.
  static TextStyle tileLabel(double size) => TextStyle(
    fontFamily: _atkinson,
    fontFamilyFallback: _atkinsonFallback,
    fontSize: size,
    fontWeight: FontWeight.w700,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// The wordmark: "chorus" in [display]'s face at [size].
  static TextStyle wordmark(double size) => TextStyle(
    fontFamily: _fraunces,
    fontFamilyFallback: _frauncesFallback,
    fontSize: size,
    height: 1,
    letterSpacing: -0.02 * size,
    fontWeight: FontWeight.w600,
    fontVariations: [
      const FontVariation.weight(600),
      const FontVariation('SOFT', 100),
      const FontVariation('WONK', 0),
      FontVariation.opticalSize(_opticalSize(size)),
    ],
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// A copy of a Fraunces role at another [size] and [lineHeight], with the
  /// optical size following it.
  static TextStyle frauncesAt(TextStyle role, double size, double lineHeight) =>
      role.copyWith(
        fontSize: size,
        height: lineHeight / size,
        letterSpacing: role.letterSpacing == null
            ? null
            : role.letterSpacing! / role.fontSize! * size,
        fontVariations: [
          for (final variation
              in role.fontVariations ?? const <FontVariation>[])
            if (variation.axis == 'opsz')
              FontVariation.opticalSize(_opticalSize(size))
            else
              variation,
        ],
      );

  /// The text scale for display type: the reader's own, up to
  /// [displayMaxScale].
  static TextScaler displayScaler(BuildContext context) =>
      MediaQuery.textScalerOf(context).clamp(maxScaleFactor: displayMaxScale);

  // Fraunces draws optical sizes 9 to 144: "auto" is the size itself.
  static double _opticalSize(double size) => size.clamp(9, 144).toDouble();
}

/// Space and shape: a 4 dp grid with an 8 dp rhythm.
abstract final class ChorusSpace {
  /// The base grid.
  static const double grid = 4;

  /// [n] steps of the grid.
  static double steps(int n) => n * grid;

  /// The smallest space between two touch targets.
  static const double targetGap = 8;

  /// The smallest touch target.
  static const double minTarget = 48;

  /// Screen margin on phones.
  static const double marginPhone = 20;

  /// Screen margin at [wideFrom] and wider.
  static const double marginWide = 32;

  /// The width from which a screen counts as wide.
  static const double wideFrom = 600;

  /// The screen margin for a screen [width] wide.
  static double margin(double width) =>
      width >= wideFrom ? marginWide : marginPhone;

  /// The screen margin for the screen around [context].
  static double marginOf(BuildContext context) =>
      margin(MediaQuery.sizeOf(context).width);

  /// The laminated card corner of a tile.
  static const double tileRadius = 14;
  static const double buttonRadius = 16;
  static const double panelRadius = 24;
  static const double sheetRadius = 28;

  /// The darker edge under a pressable thing at rest: the card on Velcro.
  static const double edge = 3;

  /// The same edge while pressed.
  static const double edgePressed = 1;

  /// How far a pressed thing sinks: the edge it loses.
  static const double pressSink = edge - edgePressed;

  /// A tile's corner when the tile is small, as on a miniature board, so a
  /// 30 dp tile does not turn into a pill.
  static double tileRadiusFor(double tileSide) =>
      math.min(tileRadius, tileSide * 0.22);
}
