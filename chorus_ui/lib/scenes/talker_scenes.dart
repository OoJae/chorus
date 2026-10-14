/// Picture scenes on the child's board: the "Scenes" button in the status
/// row, the picker it opens, and a scene's photo full-screen, where tapping
/// a spot speaks its word, outlines the spot and adds the word to the
/// strip.
library;

import 'dart:async';

import 'package:chorus_shared/chorus_shared.dart' show TileFacts;
import 'package:flutter/material.dart';

import '../brand/haptics.dart';
import '../brand/pressable_surface.dart';
import '../brand/tokens.dart';
import '../contracts_media.dart';
import '../contracts_scenes.dart';
import '../features/flags/w8.dart';
import 'scene_photo.dart';

/// The button's words, for a screen reader and its tooltip.
const String scenesLabel = 'Scenes';

/// The picker's title.
const String chooseSceneTitle = 'Choose a scene';

/// Leaves a scene or the picker, back to the board.
const String backToBoardLabel = 'Back to the board';

/// How long a tapped spot stays outlined.
const Duration spotLitFor = Duration(milliseconds: 900);

/// A spot's word as the strip holds it. It is never a tile on a board, so
/// the board's word log never takes it.
TileFacts sceneWord(Scene scene, int index) {
  final spot = scene.spots[index];
  return TileFacts(
    id: 'scene:${scene.id}:$index',
    boardId: '',
    cellKey: '',
    label: spot.label,
    speech: spot.speech,
  );
}

/// The "Scenes" button for the child's status row, or null while the flag
/// is off, there is no [book], or the row has no room for it. The talker's
/// one hook.
///
/// The status marks are drawn smaller when they do not fit, so a button
/// that made them too wide would move every one of them. It is left out on
/// a phone on its side ([short]), on a screen narrower than a common phone,
/// and at large text; below 1000 wide it is an icon alone.
Widget? talkerScenesButton(
  SceneBook? book, {
  required ValueChanged<TileFacts> onWord,
  required bool roomy,
  required bool short,
  required double width,
  double textScale = 1,
  MediaStore? media,
}) {
  if (!pictureScenesEnabled || book == null) return null;
  if (short || width < 340 || textScale > 1.1) return null;
  return TalkerScenesButton(
    book: book,
    onWord: onWord,
    media: media,
    compact: !roomy || width < 1000,
  );
}

/// "Scenes" in the child's status row. Draws nothing while the flag is off
/// or the circle has no scene, so the row is as it was.
///
/// While it shows, it asks [media] for each scene's photo, so the photos
/// are on this device before the connection goes. When the board opens it
/// asks [book] for the latest scenes.
class TalkerScenesButton extends StatefulWidget {
  const TalkerScenesButton({
    super.key,
    required this.book,
    required this.onWord,
    this.media,
    this.compact = false,
  });

  final SceneBook book;

  /// Adds a tapped spot's word to the strip and speaks it.
  final ValueChanged<TileFacts> onWord;
  final MediaStore? media;

  /// The icon alone.
  final bool compact;

  /// The button, for tests.
  static const Key buttonKey = ValueKey('TalkerScenesButton');

  @override
  State<TalkerScenesButton> createState() => _TalkerScenesButtonState();
}

class _TalkerScenesButtonState extends State<TalkerScenesButton> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.book.refresh().catchError((Object _) {}));
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book, media = widget.media, compact = widget.compact;
    final onWord = widget.onWord;
    if (!pictureScenesEnabled) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: book,
      builder: (context, _) {
        final scenes = book.scenes;
        if (scenes.isEmpty) return const SizedBox.shrink();
        for (final scene in scenes) {
          media?.imageFor(scene.imageHash);
        }
        final colors = ChorusColors.of(context);
        return Padding(
          padding: const EdgeInsets.only(right: ChorusSpace.targetGap),
          child: SizedBox(
            height: ChorusSpace.minTarget,
            child: PressableSurface(
              key: TalkerScenesButton.buttonKey,
              onTap: () => openScenePicker(
                context,
                book: book,
                media: media,
                onWord: onWord,
              ),
              semanticLabel: scenesLabel,
              color: colors.line,
              foregroundColor: colors.ink,
              padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_rounded, size: 24, color: colors.ink),
                  if (!compact) ...[
                    const SizedBox(width: 8),
                    Text(
                      scenesLabel,
                      style: ChorusType.label.copyWith(color: colors.ink),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Opens the picker over the board, and from it a scene.
Future<void> openScenePicker(
  BuildContext context, {
  required SceneBook book,
  required ValueChanged<TileFacts> onWord,
  MediaStore? media,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) =>
          ScenePickerScreen(book: book, media: media, onWord: onWord),
    ),
  );
}

/// The circle's scenes as big cards, each its photo and name.
class ScenePickerScreen extends StatelessWidget {
  const ScenePickerScreen({
    super.key,
    required this.book,
    required this.onWord,
    this.media,
  });

  final SceneBook book;
  final ValueChanged<TileFacts> onWord;
  final MediaStore? media;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(title: chooseSceneTitle),
              const SizedBox(height: 12),
              Expanded(
                child: ListenableBuilder(
                  listenable: book,
                  builder: (context, _) => LayoutBuilder(
                    builder: (context, box) => GridView.count(
                      crossAxisCount: box.maxWidth >= 900
                          ? 3
                          : box.maxWidth >= 480
                          ? 2
                          : 1,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: [
                        for (final scene in book.scenes)
                          _SceneCard(
                            scene: scene,
                            media: media,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => SceneScreen(
                                  scene: scene,
                                  media: media,
                                  onWord: onWord,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({required this.scene, required this.onTap, this.media});

  final Scene scene;
  final VoidCallback onTap;
  final MediaStore? media;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    return PressableSurface(
      onTap: onTap,
      semanticLabel: scene.name,
      color: colors.card,
      foregroundColor: colors.ink,
      borderRadius: ChorusSpace.panelRadius,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ScenePhoto(
              scene: scene,
              media: media,
              overlay: (_, _) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            scene.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: ChorusType.headline.copyWith(color: colors.ink),
          ),
        ],
      ),
    );
  }
}

/// "Back to the board" and a title, along the top of the picker and a
/// scene.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    return SizedBox(
      height: 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 56,
            child: PressableSurface(
              onTap: () => Navigator.of(context).maybePop(),
              semanticLabel: backToBoardLabel,
              color: colors.ink,
              foregroundColor: colors.surface,
              child: Center(
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 30,
                  color: colors.surface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ChorusType.title.copyWith(color: colors.ink),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One scene's photo, full-screen. Tapping a spot speaks its word, outlines
/// the spot for [spotLitFor] and adds the word to the strip; a tap between
/// spots does nothing.
class SceneScreen extends StatefulWidget {
  const SceneScreen({
    super.key,
    required this.scene,
    required this.onWord,
    this.media,
  });

  final Scene scene;
  final ValueChanged<TileFacts> onWord;
  final MediaStore? media;

  /// The outline of the spot just tapped, for tests.
  static const Key litKey = ValueKey('SceneScreen.lit');

  @override
  State<SceneScreen> createState() => _SceneScreenState();
}

class _SceneScreenState extends State<SceneScreen> {
  int? _lit;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tap(Offset at, Size size) {
    if (size.isEmpty) return;
    final scene = widget.scene;
    final index = spotAt(
      [for (final spot in scene.spots) spot.rect],
      at.dx / size.width,
      at.dy / size.height,
    );
    if (index == null) return;
    ChorusHaptics.wordTapped();
    widget.onWord(sceneWord(scene, index));
    _timer?.cancel();
    setState(() => _lit = index);
    _timer = Timer(spotLitFor, () {
      if (mounted) setState(() => _lit = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final scene = widget.scene;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(title: scene.name),
              const SizedBox(height: 12),
              Expanded(
                child: ScenePhoto(
                  scene: scene,
                  media: widget.media,
                  overlay: (context, size) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) => _tap(details.localPosition, size),
                    child: Stack(
                      children: [
                        for (var i = 0; i < scene.spots.length; i++)
                          Positioned.fromRect(
                            rect: spotRectIn(scene.spots[i].rect, size),
                            child: Semantics(
                              button: true,
                              label: scene.spots[i].label,
                              onTap: () => _tap(
                                spotRectIn(scene.spots[i].rect, size).center,
                                size,
                              ),
                              child: SpotOutline(
                                key: _lit == i ? SceneScreen.litKey : null,
                                lit: _lit == i,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
