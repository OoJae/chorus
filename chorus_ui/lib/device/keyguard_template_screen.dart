/// "Keyguard template": the child's grid in keyguard mode, drawn at full
/// size on this screen and saved as an SVG in real millimetres.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../brand/tokens.dart';
import '../talker/keyguard_geometry.dart';
import '../talker/talker_screen.dart' show TalkerLayout, talkerLayoutFor;
import 'text_share.dart';

const String keyguardTemplateTitle = 'Keyguard template';
const String keyguardTemplateIntro =
    "This is the board's grid in keyguard mode, worked out from this "
    "screen. Type the screen's size to get it in millimetres, for making "
    'or ordering a plastic keyguard. Keyguard mode must be on when the '
    'keyguard is used.';
const String screenSizeLabel = 'Screen size, corner to corner (inches)';
const String screenSizeHint = 'For example 10.1';
const String showOutlinesLabel = 'Show the outlines at full size';
const String showOutlinesHelp = 'Tap anywhere to come back.';
const String saveSvgLabel = 'Save as SVG';
const String copySvgLabel = 'Copy the SVG';
const String svgSavedMessage = 'Saved';
const String svgCopiedMessage = 'Copied';
const String typeScreenSizeMessage = 'Type the screen size first';
const String browserScreenNote =
    'In a browser, use the window full screen: the grid is worked out from '
    'the window.';

/// The size of one tile hole, for the page: "18.4 × 16.2 mm".
String cellSizeText(Size mm) =>
    '${mm.width.toStringAsFixed(1)} × ${mm.height.toStringAsFixed(1)} mm';

/// The keyguard layout for a talker body of [body].
KeyguardLayout keyguardLayoutFor(Size body) => switch (talkerLayoutFor(body)) {
  TalkerLayout.roomy => KeyguardLayout.roomy,
  TalkerLayout.narrow => KeyguardLayout.narrow,
  TalkerLayout.short => KeyguardLayout.short,
};

/// The grid for a board of [rows] by [cols] on the screen [media] describes,
/// in the whole screen's logical pixels: the talker's body is the screen
/// inside its safe area.
KeyguardGeometry keyguardGeometryFor(
  MediaQueryData media, {
  required int rows,
  required int cols,
}) {
  final padding = media.padding;
  final body = Size(
    media.size.width - padding.horizontal,
    media.size.height - padding.vertical,
  );
  return KeyguardGeometry.of(
    body: body,
    layout: keyguardLayoutFor(body),
    rows: rows,
    cols: cols,
  ).shift(Offset(padding.left, padding.top));
}

class KeyguardTemplateScreen extends StatefulWidget {
  const KeyguardTemplateScreen({
    super.key,
    required this.rows,
    required this.cols,
    this.saveFile,
  });

  final int rows;
  final int cols;

  /// Null is a download where there is one, else Copy.
  final SaveTextFile? Function()? saveFile;

  /// The full-size outlines, for tests.
  @visibleForTesting
  static const Key outlinesKey = ValueKey('KeyguardTemplate.outlines');

  @override
  State<KeyguardTemplateScreen> createState() => _KeyguardTemplateScreenState();
}

class _KeyguardTemplateScreenState extends State<KeyguardTemplateScreen> {
  final TextEditingController _inches = TextEditingController();

  @override
  void initState() {
    super.initState();
    _inches.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _inches.dispose();
    super.dispose();
  }

  double? get _diagonal =>
      double.tryParse(_inches.text.trim().replaceAll(',', '.'));

  void _say(String message) => ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _save(MediaQueryData media, KeyguardGeometry geometry) async {
    final diagonal = _diagonal;
    final perPixel = diagonal == null
        ? null
        : millimetresPerPixel(media.size, diagonal);
    if (perPixel == null) {
      _say(typeScreenSizeMessage);
      return;
    }
    final svg = keyguardSvg(
      screen: media.size,
      geometry: geometry,
      mmPerPixel: perPixel,
    );
    final name =
        'chorus-keyguard-${widget.rows}x${widget.cols}-'
        '${diagonal!.toStringAsFixed(1)}in.svg';
    final save = (widget.saveFile ?? systemSaveTextFile)();
    if (save != null && await save(name, svg)) {
      _say(svgSavedMessage);
      return;
    }
    try {
      await Clipboard.setData(ClipboardData(text: svg));
      _say(svgCopiedMessage);
    } catch (_) {}
  }

  void _showOutlines() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        pageBuilder: (context, _, _) =>
            _FullSizeOutlines(rows: widget.rows, cols: widget.cols),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final colors = ChorusColors.of(context);
    final geometry = keyguardGeometryFor(
      media,
      rows: widget.rows,
      cols: widget.cols,
    );
    final diagonal = _diagonal;
    final perPixel = diagonal == null
        ? null
        : millimetresPerPixel(media.size, diagonal);
    final cell = geometry.cell(0, 0);
    final canDownload = (widget.saveFile ?? systemSaveTextFile)() != null;
    return Scaffold(
      appBar: AppBar(title: const Text(keyguardTemplateTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ChorusSpace.marginPhone),
          children: [
            Text(
              keyguardTemplateIntro,
              style: ChorusType.body.copyWith(color: colors.ink),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _inches,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: screenSizeLabel,
                hintText: screenSizeHint,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${widget.rows} rows by ${widget.cols} columns',
              style: ChorusType.status.copyWith(color: colors.ink),
            ),
            if (perPixel != null)
              Text(
                'Each hole ${cellSizeText(Size(cell.width * perPixel, cell.height * perPixel))}',
                style: ChorusType.status.copyWith(color: colors.ink),
              ),
            const SizedBox(height: 8),
            Text(
              browserScreenNote,
              style: ChorusType.body.copyWith(color: colors.inkMuted),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _showOutlines,
              icon: const Icon(Icons.fullscreen_rounded),
              label: const Text(showOutlinesLabel),
            ),
            const SizedBox(height: ChorusSpace.targetGap),
            OutlinedButton.icon(
              onPressed: () => unawaited(_save(media, geometry)),
              icon: const Icon(Icons.download_rounded),
              label: Text(canDownload ? saveSvgLabel : copySvgLabel),
            ),
          ],
        ),
      ),
    );
  }
}

/// The outlines exactly where the child's tiles are in keyguard mode. A tap
/// anywhere comes back.
class _FullSizeOutlines extends StatelessWidget {
  const _FullSizeOutlines({required this.rows, required this.cols});

  final int rows;
  final int cols;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final geometry = keyguardGeometryFor(
      MediaQuery.of(context),
      rows: rows,
      cols: cols,
    );
    return Semantics(
      button: true,
      label: '$showOutlinesLabel. $showOutlinesHelp',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: ColoredBox(
          color: colors.surface,
          child: CustomPaint(
            key: KeyguardTemplateScreen.outlinesKey,
            size: Size.infinite,
            painter: _Outlines(geometry: geometry, ink: colors.ink),
          ),
        ),
      ),
    );
  }
}

class _Outlines extends CustomPainter {
  const _Outlines({required this.geometry, required this.ink});

  final KeyguardGeometry geometry;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = ink;
    for (final rect in geometry.cells) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect,
          const Radius.circular(ChorusSpace.tileRadius),
        ),
        line,
      );
    }
  }

  @override
  bool shouldRepaint(_Outlines old) =>
      old.geometry.grid != geometry.grid || old.ink != ink;
}
