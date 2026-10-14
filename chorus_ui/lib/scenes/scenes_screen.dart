/// Picture scenes for adults: the list, making a scene from a photo, and
/// drawing its spots.
library;

import 'dart:async';

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';

import '../brand/haptics.dart';
import '../brand/tokens.dart';
import '../contracts_media.dart';
import '../contracts_scenes.dart';
import 'scene_photo.dart';

/// Home's entry and the list's title.
const String scenesTitle = 'Scenes';

/// Makes a scene from a photo.
const String makeSceneLabel = 'Make a scene from a photo';

/// Shown when the circle has no scene yet.
const String noScenesYetMessage =
    'A scene is a family photo with spots that speak. Make one from a photo, '
    'then draw a spot round each person or thing and type its word.';

/// Shown to a read-only partner under the list.
const String scenesReadOnlyMessage =
    'You can look at the scenes. Only the family and therapist can change '
    'them.';

/// How to draw, over the photo in the editor.
const String drawSpotsHint =
    'Drag on the photo to draw a spot. Tap a spot to change its word, move '
    'it or make it bigger.';

/// Shown when the picked file is not a photo.
const String notAPhotoMessage = 'That file is not a photo. Try another one.';

/// The editor's menu items.
const String renameSceneLabel = 'Rename this scene';
const String archiveSceneLabel = 'Remove this scene';
const String changeWordLabel = 'Change word';
const String removeSpotLabel = 'Remove spot';

/// The adult's list of scenes, with "Make a scene from a photo" for an
/// editor. [capture] picks the photo and [media] keeps it and sends it, as
/// the add-word sheet does; without both, no scene can be made here.
class ScenesScreen extends StatefulWidget {
  const ScenesScreen({super.key, required this.book, this.media, this.capture});

  final SceneBook book;
  final MediaStore? media;
  final MediaCapture? capture;

  @override
  State<ScenesScreen> createState() => _ScenesScreenState();
}

class _ScenesScreenState extends State<ScenesScreen> {
  bool _making = false;

  @override
  void initState() {
    super.initState();
    unawaited(widget.book.refresh());
  }

  bool get _canMake =>
      widget.book.canEdit && widget.media != null && widget.capture != null;

  Future<void> _make({required bool fromCamera}) async {
    final capture = widget.capture, media = widget.media;
    if (capture == null || media == null || _making) return;
    final messenger = ScaffoldMessenger.of(context);
    final bytes = await capture.pickImage(fromCamera: fromCamera);
    if (bytes == null || !mounted) return;
    final name = await askSceneName(context, title: 'Name this scene');
    if (name == null || !mounted) return;
    setState(() => _making = true);
    try {
      final String hash;
      try {
        hash = await media.addImage(bytes);
      } on FormatException {
        ChorusHaptics.failed();
        messenger.showSnackBar(const SnackBar(content: Text(notAPhotoMessage)));
        return;
      }
      final scene = await widget.book.create(name, hash);
      ChorusHaptics.wordAdded();
      if (!mounted) return;
      await _open(scene);
    } on Object {
      ChorusHaptics.failed();
      messenger.showSnackBar(
        const SnackBar(content: Text(sceneNotSavedMessage)),
      );
    } finally {
      if (mounted) setState(() => _making = false);
    }
  }

  Future<void> _open(Scene scene) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SceneEditorScreen(
        book: widget.book,
        sceneId: scene.id,
        media: widget.media,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final capture = widget.capture;
    return Scaffold(
      appBar: AppBar(title: const Text(scenesTitle)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.book,
          builder: (context, _) {
            final scenes = widget.book.scenes;
            return ListView(
              padding: const EdgeInsets.all(ChorusSpace.marginPhone),
              children: [
                if (scenes.isEmpty)
                  Text(
                    noScenesYetMessage,
                    style: ChorusType.body.copyWith(color: colors.ink),
                  ),
                if (!widget.book.canEdit) ...[
                  Text(
                    scenesReadOnlyMessage,
                    style: ChorusType.body.copyWith(color: colors.inkMuted),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_canMake) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _making ? null : () => _make(fromCamera: false),
                    icon: const Icon(Icons.add_photo_alternate_rounded),
                    label: const Text(makeSceneLabel),
                  ),
                  if (capture!.hasCamera) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _making ? null : () => _make(fromCamera: true),
                      icon: const Icon(Icons.photo_camera_rounded),
                      label: const Text('Take a photo for a scene'),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
                for (final scene in scenes)
                  ListTile(
                    key: ValueKey('scene-${scene.id}'),
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    leading: SizedBox(
                      width: 72,
                      child: ScenePhoto(
                        scene: scene,
                        media: widget.media,
                        overlay: (_, _) => const SizedBox.shrink(),
                      ),
                    ),
                    title: Text(scene.name),
                    subtitle: Text(
                      scene.spots.length == 1
                          ? '1 spot'
                          : '${scene.spots.length} spots',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _open(scene),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Asks for a scene name, starting from [initial]. Completes with the name
/// tidied, or null when the adult cancelled.
Future<String?> askSceneName(
  BuildContext context, {
  required String title,
  String initial = '',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TextDialog(
      title: title,
      fieldLabel: 'Scene name',
      submitLabel: 'Save',
      initial: initial,
      maxLength: maxSceneNameLength,
      problem: sceneNameProblem,
    ),
  );
}

/// A dialog with one text field, checked by [problem] before it closes.
class _TextDialog extends StatefulWidget {
  const _TextDialog({
    required this.title,
    required this.fieldLabel,
    required this.submitLabel,
    required this.initial,
    required this.maxLength,
    required this.problem,
  });

  final String title;
  final String fieldLabel;
  final String submitLabel;
  final String initial;
  final int maxLength;
  final String? Function(String) problem;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initial,
  );
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final error = widget.problem(_text.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(_text.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _text,
        autofocus: true,
        maxLength: widget.maxLength,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: widget.fieldLabel,
          errorText: _error,
        ),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.submitLabel)),
      ],
    );
  }
}

/// Asks for a spot's word and what it says. Completes with the two, or
/// null when the adult cancelled.
Future<({String label, String? speech})?> askSpotWord(
  BuildContext context, {
  String label = '',
  String? speech,
}) {
  return showDialog<({String label, String? speech})>(
    context: context,
    builder: (_) => _SpotWordDialog(label: label, speech: speech),
  );
}

class _SpotWordDialog extends StatefulWidget {
  const _SpotWordDialog({required this.label, this.speech});

  final String label;
  final String? speech;

  @override
  State<_SpotWordDialog> createState() => _SpotWordDialogState();
}

class _SpotWordDialogState extends State<_SpotWordDialog> {
  late final TextEditingController _label = TextEditingController(
    text: widget.label,
  );
  late final TextEditingController _speech = TextEditingController(
    text: widget.speech ?? '',
  );
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    _speech.dispose();
    super.dispose();
  }

  void _submit() {
    final error = spotWordProblem(_label.text, speech: _speech.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final speech = _speech.text.trim();
    Navigator.of(
      context,
    ).pop((label: _label.text.trim(), speech: speech.isEmpty ? null : speech));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('What does this spot say?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const ValueKey('spot-label'),
            controller: _label,
            autofocus: true,
            decoration: InputDecoration(labelText: 'Word', errorText: _error),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('spot-speech'),
            controller: _speech,
            decoration: const InputDecoration(
              labelText: 'What it says (optional)',
              helperText: 'For example "Grandma Rose" for the word "Nan".',
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

/// One scene for an editor: drag on the photo to draw a spot, tap a spot to
/// choose it, drag a chosen spot to move it and its corner to resize it.
/// Every finished change is saved at once. A read-only partner sees the
/// photo and its spots only.
class SceneEditorScreen extends StatefulWidget {
  const SceneEditorScreen({
    super.key,
    required this.book,
    required this.sceneId,
    this.media,
  });

  final SceneBook book;
  final String sceneId;
  final MediaStore? media;

  /// The handle that resizes the chosen spot, for tests.
  static const Key resizeKey = ValueKey('SceneEditorScreen.resize');

  /// The spot being drawn, for tests.
  static const Key draftKey = ValueKey('SceneEditorScreen.draft');

  @override
  State<SceneEditorScreen> createState() => _SceneEditorScreenState();
}

enum _Drag { draw, move, resize }

class _SceneEditorScreenState extends State<SceneEditorScreen> {
  /// The spots as this screen holds them; saved after each change.
  List<SceneSpot>? _spots;
  int? _chosen;
  _Drag? _drag;
  Offset? _dragStart;
  SpotRect? _draft;
  SpotRect? _before;

  Scene? get _scene =>
      widget.book.scenes.where((s) => s.id == widget.sceneId).firstOrNull;

  bool get _canEdit => widget.book.canEdit;

  Future<void> _save(List<SceneSpot> spots) async {
    setState(() => _spots = spots);
    try {
      final saved = await widget.book.setSpots(widget.sceneId, spots);
      if (mounted) setState(() => _spots = saved.spots);
    } on Object {
      ChorusHaptics.failed();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(sceneNotSavedMessage)));
    }
  }

  void _start(Offset at, Size size, List<SceneSpot> spots) {
    if (!_canEdit || size.isEmpty) return;
    final x = at.dx / size.width, y = at.dy / size.height;
    final chosen = _chosen;
    if (chosen != null && chosen < spots.length) {
      final rect = spotRectIn(spots[chosen].rect, size);
      // The corner handle, a fingertip round the bottom-right corner.
      if ((at - rect.bottomRight).distance <= ChorusSpace.minTarget / 2) {
        _drag = _Drag.resize;
      } else if (rect.contains(at)) {
        _drag = _Drag.move;
      }
      if (_drag != null) {
        _before = spots[chosen].rect;
        _dragStart = at;
        return;
      }
    }
    _drag = _Drag.draw;
    _dragStart = at;
    setState(() => _draft = SpotRect.fromDrag(x, y, x, y));
  }

  void _update(Offset at, Size size, List<SceneSpot> spots) {
    final start = _dragStart;
    if (start == null || size.isEmpty) return;
    final dx = (at.dx - start.dx) / size.width;
    final dy = (at.dy - start.dy) / size.height;
    switch (_drag) {
      case _Drag.draw:
        setState(
          () => _draft = SpotRect.fromDrag(
            start.dx / size.width,
            start.dy / size.height,
            at.dx / size.width,
            at.dy / size.height,
          ),
        );
      case _Drag.move || _Drag.resize:
        final chosen = _chosen!;
        final before = _before!;
        final rect = _drag == _Drag.move
            ? before.moved(dx, dy)
            : before.resized(dx, dy);
        setState(() {
          _spots = [
            for (var i = 0; i < spots.length; i++)
              i == chosen ? spots[i].copyWith(rect: rect) : spots[i],
          ];
        });
      case null:
        break;
    }
  }

  Future<void> _end(List<SceneSpot> spots) async {
    final drag = _drag;
    final draft = _draft;
    _drag = null;
    _dragStart = null;
    _before = null;
    if (drag == _Drag.draw && draft != null) {
      setState(() => _draft = draft);
      if (spots.length >= maxSpotsPerScene) {
        setState(() => _draft = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'A scene has room for $maxSpotsPerScene spots. Remove one '
              'first.',
            ),
          ),
        );
        return;
      }
      final word = await askSpotWord(context);
      if (!mounted) return;
      setState(() => _draft = null);
      if (word == null) return;
      final next = [
        ...spots,
        SceneSpot(rect: draft, label: word.label, speech: word.speech),
      ];
      _chosen = next.length - 1;
      await _save(next);
    } else if (drag == _Drag.move || drag == _Drag.resize) {
      await _save(spots);
    }
  }

  void _tap(Offset at, Size size, List<SceneSpot> spots) {
    if (size.isEmpty) return;
    final index = spotAt(
      [for (final spot in spots) spot.rect],
      at.dx / size.width,
      at.dy / size.height,
    );
    setState(() => _chosen = index);
  }

  Future<void> _changeWord(List<SceneSpot> spots, int index) async {
    final word = await askSpotWord(
      context,
      label: spots[index].label,
      speech: spots[index].speech,
    );
    if (word == null || !mounted) return;
    await _save([
      for (var i = 0; i < spots.length; i++)
        i == index
            ? SceneSpot(
                rect: spots[i].rect,
                label: word.label,
                speech: word.speech,
              )
            : spots[i],
    ]);
  }

  Future<void> _remove(List<SceneSpot> spots, int index) async {
    setState(() => _chosen = null);
    await _save([
      for (var i = 0; i < spots.length; i++)
        if (i != index) spots[i],
    ]);
  }

  Future<void> _menu(String choice, Scene scene) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      switch (choice) {
        case 'rename':
          final name = await askSceneName(
            context,
            title: 'Rename "${scene.name}"',
            initial: scene.name,
          );
          if (name != null) await widget.book.rename(scene.id, name);
        case 'archive':
          final sure = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text('Remove "${scene.name}"?'),
              content: const Text(
                'It leaves every device in the circle. The photo stays on '
                'the words that use it.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Keep'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Remove'),
                ),
              ],
            ),
          );
          if (sure == true) {
            await widget.book.archive(scene.id);
            navigator.pop();
          }
      }
    } on Object {
      ChorusHaptics.failed();
      messenger.showSnackBar(
        const SnackBar(content: Text(sceneNotSavedMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.book,
      builder: (context, _) {
        final scene = _scene;
        if (scene == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(scenesTitle)),
            body: const Center(child: Text('This scene was removed.')),
          );
        }
        final spots = _spots ?? scene.spots;
        final chosen = _chosen != null && _chosen! < spots.length
            ? _chosen
            : null;
        final colors = ChorusColors.of(context);
        return Scaffold(
          appBar: AppBar(
            title: Text(scene.name),
            actions: [
              if (_canEdit)
                PopupMenuButton<String>(
                  tooltip: 'More for this scene',
                  onSelected: (choice) => _menu(choice, scene),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'rename',
                      child: Text(renameSceneLabel),
                    ),
                    PopupMenuItem(
                      value: 'archive',
                      child: Text(archiveSceneLabel),
                    ),
                  ],
                ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _canEdit ? drawSpotsHint : scenesReadOnlyMessage,
                    style: ChorusType.body.copyWith(color: colors.inkMuted),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ScenePhoto(
                      scene: scene,
                      media: widget.media,
                      overlay: (context, size) => GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        // A spot starts where the finger went down, not
                        // where the drag was first noticed.
                        dragStartBehavior: DragStartBehavior.down,
                        onTapUp: (d) => _tap(d.localPosition, size, spots),
                        onPanStart: _canEdit
                            ? (d) => _start(d.localPosition, size, spots)
                            : null,
                        onPanUpdate: _canEdit
                            ? (d) => _update(
                                d.localPosition,
                                size,
                                _spots ?? scene.spots,
                              )
                            : null,
                        onPanEnd: _canEdit
                            ? (_) => _end(_spots ?? scene.spots)
                            : null,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (var i = 0; i < spots.length; i++)
                              Positioned.fromRect(
                                rect: spotRectIn(spots[i].rect, size),
                                child: _SpotLabel(
                                  spot: spots[i],
                                  chosen: chosen == i,
                                ),
                              ),
                            if (_draft != null)
                              Positioned.fromRect(
                                key: SceneEditorScreen.draftKey,
                                rect: spotRectIn(_draft!, size),
                                child: const SpotOutline(lit: true),
                              ),
                            if (chosen != null && _canEdit)
                              Positioned.fromRect(
                                rect: Rect.fromCenter(
                                  center: spotRectIn(
                                    spots[chosen].rect,
                                    size,
                                  ).bottomRight,
                                  width: 28,
                                  height: 28,
                                ),
                                child: IgnorePointer(
                                  child: DecoratedBox(
                                    key: SceneEditorScreen.resizeKey,
                                    decoration: BoxDecoration(
                                      color: colors.ink,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: colors.surface,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (chosen != null && _canEdit) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: () => _changeWord(spots, chosen),
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text(changeWordLabel),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _remove(spots, chosen),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text(removeSpotLabel),
                        ),
                      ],
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

/// A spot in the editor: its outline and its word in an ink pill.
class _SpotLabel extends StatelessWidget {
  const _SpotLabel({required this.spot, required this.chosen});

  final SceneSpot spot;
  final bool chosen;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        SpotOutline(lit: chosen),
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.ink,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                spot.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ChorusType.label.copyWith(color: colors.surface),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
