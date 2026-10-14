/// A scene's photo with its spots drawn on it, fitted whole into the room
/// there is. Shared by the child's scene and the adult's scene editor.
library;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../brand/tokens.dart';
import '../contracts_media.dart';
import '../contracts_scenes.dart';

/// Width over height assumed for a photo until its size is known, and for
/// one that is not on this device yet.
const double defaultSceneAspect = 4 / 3;

/// Lays out [scene]'s photo as large as fits, centred, and hands
/// [overlay] the size it is drawn at, so spots can be placed on it in
/// fractions of that size.
class ScenePhoto extends StatefulWidget {
  const ScenePhoto({
    super.key,
    required this.scene,
    required this.overlay,
    this.media,
  });

  final Scene scene;
  final MediaStore? media;

  /// Drawn over the photo, the photo's size given.
  final Widget Function(BuildContext context, Size size) overlay;

  /// The photo's frame, for tests.
  static const Key frameKey = ValueKey('ScenePhoto.frame');

  @override
  State<ScenePhoto> createState() => _ScenePhotoState();
}

class _ScenePhotoState extends State<ScenePhoto> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  double? _aspect;

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  void _stopListening() {
    final listener = _listener;
    if (listener != null) _stream?.removeListener(listener);
    _stream = null;
    _listener = null;
  }

  /// Learns the photo's shape once it is decoded.
  void _watch(ImageProvider image) {
    final stream = image.resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _stopListening();
    final listener = ImageStreamListener((info, _) {
      final width = info.image.width, height = info.image.height;
      if (!mounted || width <= 0 || height <= 0) return;
      final aspect = width / height;
      if (aspect == _aspect) return;
      void apply() {
        if (mounted && aspect != _aspect) setState(() => _aspect = aspect);
      }

      // A picture already in memory answers at once, while this is being
      // built: take its shape after the frame.
      if (SchedulerBinding.instance.schedulerPhase ==
          SchedulerPhase.persistentCallbacks) {
        SchedulerBinding.instance.addPostFrameCallback((_) => apply());
      } else {
        apply();
      }
    });
    stream.addListener(listener);
    _stream = stream;
    _listener = listener;
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.media;
    final colors = ChorusColors.of(context);
    if (media == null) return _frame(context, null, colors);
    return ListenableBuilder(
      listenable: media,
      builder: (context, _) =>
          _frame(context, media.imageFor(widget.scene.imageHash), colors),
    );
  }

  Widget _frame(
    BuildContext context,
    ImageProvider? image,
    ChorusColors colors,
  ) {
    if (image != null) _watch(image);
    return Center(
      child: AspectRatio(
        key: ScenePhoto.frameKey,
        aspectRatio: _aspect ?? defaultSceneAspect,
        child: LayoutBuilder(
          builder: (context, box) => Stack(
            fit: StackFit.expand,
            children: [
              if (image == null)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.card,
                    border: Border.all(color: colors.line, width: 2),
                    borderRadius: BorderRadius.circular(ChorusSpace.tileRadius),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.photo_rounded,
                      size: 48,
                      color: colors.inkMuted,
                    ),
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(ChorusSpace.tileRadius),
                  child: Image(image: image, fit: BoxFit.fill),
                ),
              widget.overlay(context, box.biggest),
            ],
          ),
        ),
      ),
    );
  }
}

/// [rect] (fractions of the photo) in the units of a photo drawn at [size].
Rect spotRectIn(SpotRect rect, Size size) => Rect.fromLTWH(
  rect.x * size.width,
  rect.y * size.height,
  rect.width * size.width,
  rect.height * size.height,
);

/// The outline of one spot: a light line with an ink line inside it, so it
/// shows on any photo. [lit] draws it thick, for a spot just tapped or
/// chosen.
class SpotOutline extends StatelessWidget {
  const SpotOutline({super.key, required this.lit});

  final bool lit;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ChorusSpace.tileRadius),
          border: Border.all(
            color: colors.surface.withValues(alpha: lit ? 1 : 0.85),
            width: lit ? 6 : 2.5,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(lit ? 6 : 2.5),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ChorusSpace.tileRadius - 4),
              border: Border.all(color: colors.ink, width: lit ? 3 : 1.5),
            ),
          ),
        ),
      ),
    );
  }
}
