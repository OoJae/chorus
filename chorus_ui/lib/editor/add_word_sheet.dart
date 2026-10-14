/// The sheet an adult fills in to add a word, and the form it shares with
/// the edit sheet.
library;

import 'dart:async';

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'photo_ideas_strip.dart';

import '../brand/haptics.dart';
import '../brand/tokens.dart';
import '../contracts.dart';
import '../contracts_media.dart';
import '../contracts_photo_ideas.dart';
import '../contracts_suggest.dart';
import '../features/flags/w2.dart' as w2;

/// Shown when the cell was filled between opening the sheet and saving.
const String spotTakenMessage =
    'That spot was just taken. Your word is waiting in Needs a home.';

/// Shown when the store refused the new word.
const String wordNotAddedMessage =
    'That word could not be added. Nothing was changed.';

/// Shown when the word was saved but its picture or clip was not.
const String mediaNotSavedMessage =
    'The word was saved, but its photo or recording could not be.';

/// Shown under the photo row when the picked file is not a usable picture.
const String photoUnusableMessage =
    'That photo could not be used. Try another one.';

/// Shown when the microphone cannot be used.
const String microphoneUnavailableMessage =
    'The microphone is not available. Check that this app may use it.';

/// Shown when the adult let go before anything was recorded.
const String holdLongerMessage =
    'Keep holding the button while you say the word.';

/// Label of the button that asks for a word to go with a picked photo.
const String suggestFromPhotoLabel = 'Suggest a word from the photo';

/// Shown under that button before it is used: what pressing it sends.
const String suggestSendsPhotoMessage =
    'This sends the photo to the server to be described. Nothing goes on '
    'the board until you choose.';

/// Shown when no suggestion came back, whatever the reason.
const String noSuggestionMessage =
    'No suggestion this time. Type the word instead.';

/// One choice in the colour picker: a plain-words [name] for a colour [key].
class WordColour {
  const WordColour(this.name, this.key);

  final String name;

  /// The `colorKey` stored on the tile.
  final String key;
}

/// The colour picker's choices, in the order shown.
final List<WordColour> wordColours = [
  WordColour('Action', _knownKey(const ['verb', 'action'])),
  WordColour('Person', _knownKey(const ['pronoun', 'person'])),
  WordColour('Question', _knownKey(const ['question'])),
  WordColour('Describing', _knownKey(const ['descriptor', 'adjective'])),
  WordColour('Not', _knownKey(const ['negation', 'not'])),
  WordColour('Other', _knownKey(const ['determiner', 'other'])),
];

/// The first of [candidates] that [colorForKey] has a colour for; the first
/// candidate if none has, which then draws in the plain family.
String _knownKey(List<String> candidates) => candidates.firstWhere(
  colorForKey.containsKey,
  orElse: () => candidates.first,
);

/// What an adult typed into a [WordForm].
class WordDraft {
  const WordDraft({
    required this.label,
    required this.speech,
    this.colorKey,
    this.imageHash,
    this.audioHash,
  });

  /// Trimmed, never empty.
  final String label;

  /// Trimmed; empty means "say the word as written".
  final String speech;

  /// Null when no colour was picked.
  final String? colorKey;

  /// Hash of the picture the adult took or chose. Null means "leave the
  /// picture as it is"; empty means "remove it".
  final String? imageHash;

  /// Hash of the clip the adult recorded; null and empty as for
  /// [imageHash].
  final String? audioHash;
}

/// Writes the picture and recording of [draft] to [tile] when they differ
/// from what the tile has. Does nothing for a draft that leaves both alone,
/// and nothing for a [store] that is not a [TileMediaWriter]. Throws if the
/// store refuses the write.
Future<void> saveDraftMedia(
  BoardStore store,
  TileFacts tile,
  WordDraft draft,
) async {
  String? changed(String? wanted, String? held) =>
      (wanted == null || wanted == (held ?? '')) ? null : wanted;
  final imageHash = changed(draft.imageHash, tile.imageHash);
  final audioHash = changed(draft.audioHash, tile.audioHash);
  if (imageHash == null && audioHash == null) return;
  final Object target = store;
  if (target is! TileMediaWriter) return;
  await target.setTileMedia(
    tile.id,
    imageHash: imageHash,
    audioHash: audioHash,
  );
}

/// Opens the sheet for a new word in the empty cell ([row], [col]) and adds
/// it to [store]. Does nothing for a read-only role.
///
/// If the cell was filled in the meantime the word goes to the tray and a
/// snackbar says so.
///
/// With [media] and [capture], and a [store] that is a [TileMediaWriter],
/// the sheet also offers a photo and a recording. Both are optional and
/// both work with no connection. With a [suggester] that is available, a
/// picked photo can be sent for a suggested word, which only fills in the
/// form.
Future<void> showAddWordSheet(
  BuildContext context, {
  required BoardStore store,
  required String boardId,
  required int row,
  required int col,
  MediaStore? media,
  MediaCapture? capture,
  WordSuggester? suggester,
}) async {
  if (!store.role.canEdit) return;
  // Looked up now: the caller's context may be gone once the sheet closes.
  final messenger = ScaffoldMessenger.maybeOf(context);
  final draft = await showModalBottomSheet<WordDraft>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => WordForm(
      title: 'Add a word',
      submitLabel: 'Add to board',
      media: (store as Object) is TileMediaWriter ? media : null,
      capture: capture,
      suggester: suggester,
      onSubmit: (draft) => Navigator.of(sheetContext).pop(draft),
      onAddIdeas: (ideas) {
        Navigator.of(sheetContext).pop();
        unawaited(_ideasToTray(store, boardId, ideas, messenger));
      },
    ),
  );
  if (draft == null) return;
  final before = {for (final tile in store.tiles) tile.id};
  final bool placed;
  try {
    placed = await store.addTile(
      boardId: boardId,
      row: row,
      col: col,
      label: draft.label,
      speech: draft.speech.isEmpty ? null : draft.speech,
      colorKey: draft.colorKey,
    );
  } on Object {
    // The board was resized or removed, or the role changed, meanwhile.
    ChorusHaptics.failed();
    messenger?.showSnackBar(const SnackBar(content: Text(wordNotAddedMessage)));
    return;
  }
  if (placed) {
    ChorusHaptics.wordAdded();
  } else {
    messenger?.showSnackBar(const SnackBar(content: Text(spotTakenMessage)));
  }
  if (draft.imageHash == null && draft.audioHash == null) return;
  try {
    // addTile does not hand back the id, so the new word is the one this
    // adult just made that was not there before.
    final added = store.tiles.lastWhere(
      (tile) =>
          !before.contains(tile.id) &&
          tile.label == draft.label &&
          tile.createdByName == store.myName,
    );
    await saveDraftMedia(store, added, draft);
  } on Object {
    messenger?.showSnackBar(
      const SnackBar(content: Text(mediaNotSavedMessage)),
    );
  }
}

/// Label, optional spoken text and colour for one word, and with [media]
/// and [capture] an optional photo and recording.
///
/// A picked photo and a recorded clip stay in this form until the adult
/// saves: only then are they handed to [media], so a sheet that is closed
/// keeps and sends nothing.
///
/// Sized for a bottom sheet: it pads itself above the keyboard.
class WordForm extends StatefulWidget {
  const WordForm({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.onSubmit,
    this.initial,
    this.onRemove,
    this.media,
    this.capture,
    this.speaker,
    this.suggester,
    this.onAddIdeas,
  });

  /// Puts every idea for the photo under "Needs a home"; null leaves the
  /// button out.
  final ValueChanged<List<WordIdea>>? onAddIdeas;

  final String title;
  final String submitLabel;

  /// Called with a valid draft; an empty label never reaches it.
  final ValueChanged<WordDraft> onSubmit;

  /// The tile being edited; null for a new word.
  final TileFacts? initial;

  /// When set, a "Remove from board" action is shown.
  final VoidCallback? onRemove;

  /// Where a photo and a recording are kept. The photo and recording rows
  /// appear only when this and [capture] are both set.
  final MediaStore? media;

  /// The camera, photo library and microphone.
  final MediaCapture? capture;

  /// When set, a recording the tile already has can be played back.
  final TileSpeaker? speaker;

  /// When set and available, a photo picked in this form can be sent for a
  /// suggested word. Never used for a photo the tile already has.
  final WordSuggester? suggester;

  @override
  State<WordForm> createState() => _WordFormState();
}

class _WordFormState extends State<WordForm> {
  late final TextEditingController _label = TextEditingController(
    text: widget.initial?.label ?? '',
  );
  late final TextEditingController _speech = TextEditingController(
    text: widget.initial?.speech ?? '',
  );
  late String? _colorKey = widget.initial?.colorKey;
  String? _labelError;

  /// A photo picked in this sheet, exactly as the picker returned it.
  Uint8List? _newImage;
  bool _removeImage = false;
  String? _photoMessage;

  /// The suggestion for [_newImage], while one is being fetched or shown.
  bool _suggesting = false;
  WordIdea? _idea;
  String? _suggestMessage;

  /// Several ideas for [_newImage], when the suggester offers them.
  List<WordIdea> _ideas = const [];

  /// A clip recorded in this sheet.
  Uint8List? _newClip;
  bool _removeClip = false;
  String? _clipMessage;

  _Recording _recording = _Recording.idle;

  /// True from press to release of the record button.
  bool _holding = false;
  Timer? _clipLimit;
  bool _saving = false;

  bool get _hasMedia => widget.media != null && widget.capture != null;

  String? get _heldImageHash => _removeImage ? null : widget.initial?.imageHash;

  String? get _heldAudioHash => _removeClip ? null : widget.initial?.audioHash;

  @override
  void dispose() {
    _clipLimit?.cancel();
    final capture = widget.capture;
    if (capture != null) {
      if (_recording != _Recording.idle) {
        unawaited(_quietly(capture.cancelRecording));
      }
      unawaited(_quietly(capture.stopClip));
    }
    _label.dispose();
    _speech.dispose();
    super.dispose();
  }

  /// The camera and microphone must never break the sheet.
  static Future<void> _quietly(Future<void> Function() action) async {
    try {
      await action();
    } on Object {
      // Nothing to do: the device refused.
    }
  }

  Future<void> _submit() async {
    if (_saving) return;
    final label = _label.text.trim();
    if (label.isEmpty) {
      setState(() => _labelError = 'Type the word first.');
      return;
    }
    String? imageHash = _removeImage ? '' : null;
    String? audioHash = _removeClip ? '' : null;
    final media = widget.media;
    final image = _newImage, clip = _newClip;
    if (media != null && (image != null || clip != null)) {
      setState(() => _saving = true);
      try {
        if (image != null) imageHash = await media.addImage(image);
      } on Object {
        if (!mounted) return;
        setState(() {
          _saving = false;
          _newImage = null;
          _photoMessage = photoUnusableMessage;
        });
        return;
      }
      try {
        if (clip != null) audioHash = await media.addAudio(clip);
      } on Object {
        if (!mounted) return;
        setState(() {
          _saving = false;
          _newClip = null;
          _clipMessage = 'That recording could not be kept. Record it again.';
        });
        return;
      }
      if (!mounted) return;
      setState(() => _saving = false);
    }
    widget.onSubmit(
      WordDraft(
        label: label,
        speech: _speech.text.trim(),
        colorKey: _colorKey,
        imageHash: imageHash,
        audioHash: audioHash,
      ),
    );
  }

  // ---- Photo -------------------------------------------------------------

  Future<void> _pickPhoto() async {
    final capture = widget.capture;
    if (capture == null || _saving) return;
    var fromCamera = false;
    if (capture.hasCamera) {
      final choice = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          title: const Text('Photo for this word'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const _DialogChoice(
                Icons.photo_camera_rounded,
                'Take a photo',
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const _DialogChoice(
                Icons.photo_library_rounded,
                'Choose a photo',
              ),
            ),
          ],
        ),
      );
      if (choice == null || !mounted) return;
      fromCamera = choice;
    }
    Uint8List? bytes;
    try {
      bytes = await capture.pickImage(fromCamera: fromCamera);
    } on Object {
      bytes = null;
    }
    if (!mounted || bytes == null || bytes.isEmpty) return;
    setState(() {
      _newImage = bytes;
      _removeImage = false;
      _photoMessage = null;
      _idea = null;
      _ideas = const [];
      _suggestMessage = null;
    });
  }

  void _removePhoto() => setState(() {
    _newImage = null;
    _removeImage = widget.initial?.imageHash != null;
    _photoMessage = null;
    _idea = null;
    _ideas = const [];
    _suggestMessage = null;
  });

  // ---- Suggestion --------------------------------------------------------

  /// Sends the picked photo for a word. Whatever goes wrong, the adult is
  /// left with the form as it was and a line saying to type the word.
  Future<void> _suggest() async {
    final suggester = widget.suggester;
    final photo = _newImage;
    if (suggester == null || photo == null || _suggesting || _saving) return;
    setState(() {
      _suggesting = true;
      _idea = null;
      _ideas = const [];
      _suggestMessage = null;
    });
    if (w2.photoIdeasEnabled && suggester is PhotoIdeasSuggester) {
      await _suggestIdeas(suggester as PhotoIdeasSuggester, photo);
      return;
    }
    WordIdea? idea;
    try {
      idea = await suggester.fromPhoto(photo);
    } on Object {
      idea = null;
    }
    if (!mounted) return;
    // The photo was changed or removed while the answer was on its way.
    final stale = !identical(photo, _newImage);
    setState(() {
      _suggesting = false;
      if (stale) return;
      _idea = idea;
      _suggestMessage = idea == null ? noSuggestionMessage : null;
    });
  }

  /// Asks for several ideas; whatever goes wrong, the adult types the word.
  Future<void> _suggestIdeas(PhotoIdeasSuggester ideas, Uint8List photo) async {
    List<WordIdea> found;
    try {
      found = await ideas.ideasFromPhoto(photo);
    } on Object {
      found = const [];
    }
    if (!mounted) return;
    final stale = !identical(photo, _newImage);
    setState(() {
      _suggesting = false;
      if (stale) return;
      _ideas = found;
      _suggestMessage = found.isEmpty ? noSuggestionMessage : null;
    });
  }

  /// Puts a suggested [word] into the form. The adult can still change it,
  /// and nothing is added until they press the submit button.
  void _useIdea(WordIdea idea, String word) {
    String cut(String text, int max) =>
        text.length > max ? text.substring(0, max) : text;
    final label = cut(word.trim(), 30);
    final speech = word == idea.label ? cut(idea.speech.trim(), 80) : '';
    setState(() {
      _label.text = label;
      _labelError = null;
      _speech.text = speech == label ? '' : speech;
      // A key the tiles have no colour for (a noun) leaves the word plain.
      _colorKey = colorForKey.containsKey(idea.colorKey) ? idea.colorKey : null;
    });
  }

  Widget _suggestRow(ThemeData theme, WordSuggester suggester) {
    return ValueListenableBuilder<bool>(
      valueListenable: suggester.available,
      builder: (context, available, _) {
        final idea = _idea;
        final message = _suggestMessage;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (available) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey('word-suggest-button'),
                onPressed: _saving || _suggesting ? null : _suggest,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
                icon: _suggesting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Icon(Icons.lightbulb_outline_rounded),
                label: Text(
                  _suggesting ? 'Looking at the photo' : suggestFromPhotoLabel,
                ),
              ),
              if (idea == null &&
                  _ideas.isEmpty &&
                  message == null &&
                  !_suggesting)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    suggestSendsPhotoMessage,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
            if (idea != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: const Text('Suggested. Tap one to use it:'),
                    ),
                    for (final word in {idea.label, ...idea.alternatives})
                      ActionChip(
                        label: Text(word),
                        onPressed: () => _useIdea(idea, word),
                      ),
                  ],
                ),
              ),
            if (_ideas.isNotEmpty)
              PhotoIdeasStrip(
                ideas: _ideas,
                onUse: (idea) => _useIdea(idea, idea.label),
                onAddAll: widget.onAddIdeas == null || _saving
                    ? null
                    : () => widget.onAddIdeas!(_ideas),
              ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Semantics(liveRegion: true, child: Text(message)),
              ),
          ],
        );
      },
    );
  }

  // ---- Recording ---------------------------------------------------------

  Future<void> _holdStart() async {
    final capture = widget.capture;
    if (capture == null || _saving || _recording != _Recording.idle) return;
    _holding = true;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _recording = _Recording.starting;
      _clipMessage = null;
    });
    bool started;
    try {
      await capture.stopClip();
      started = await capture.startRecording();
    } on Object {
      started = false;
    }
    if (!mounted) return;
    if (!started) {
      _holding = false;
      setState(() {
        _recording = _Recording.idle;
        _clipMessage = microphoneUnavailableMessage;
      });
      return;
    }
    if (!_holding) {
      // Let go while the device was still asking for the microphone.
      await _quietly(capture.cancelRecording);
      if (!mounted) return;
      setState(() {
        _recording = _Recording.idle;
        _clipMessage = holdLongerMessage;
      });
      return;
    }
    setState(() => _recording = _Recording.recording);
    _clipLimit = Timer(maxClipLength, _finishRecording);
  }

  void _holdEnd() {
    _holding = false;
    if (_recording == _Recording.recording) unawaited(_finishRecording());
  }

  Future<void> _finishRecording() async {
    final capture = widget.capture;
    if (capture == null || _recording != _Recording.recording) return;
    _clipLimit?.cancel();
    _holding = false;
    setState(() => _recording = _Recording.stopping);
    Uint8List? bytes;
    try {
      bytes = await capture.stopRecording();
    } on Object {
      bytes = null;
    }
    if (!mounted) return;
    setState(() {
      _recording = _Recording.idle;
      if (bytes == null || bytes.isEmpty) {
        _clipMessage = holdLongerMessage;
      } else {
        _newClip = bytes;
        _removeClip = false;
        _clipMessage = null;
      }
    });
  }

  /// For a screen reader or switch, which cannot hold: one activation
  /// starts, the next stops.
  void _toggleRecording() {
    if (_recording == _Recording.idle) {
      unawaited(_holdStart());
    } else {
      _holdEnd();
    }
  }

  Future<void> _playClip() async {
    final capture = widget.capture;
    final clip = _newClip;
    if (clip != null) {
      if (capture != null) await _quietly(() => capture.playClip(clip));
      return;
    }
    final tile = widget.initial, speaker = widget.speaker;
    if (tile != null && speaker != null) {
      await _quietly(() => speaker.speakTile(tile));
    }
  }

  void _removeRecording() => setState(() {
    _newClip = null;
    _removeClip = widget.initial?.audioHash != null;
    _clipMessage = null;
  });

  Widget _photoRow(ThemeData theme) {
    final media = widget.media!;
    final capture = widget.capture!;
    final newImage = _newImage;
    final heldHash = _heldImageHash;
    final hasPhoto = newImage != null || heldHash != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Photo (optional)', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Row(
          children: [
            if (hasPhoto) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: newImage != null
                      ? Image.memory(
                          newImage,
                          key: const ValueKey('word-photo-preview'),
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          semanticLabel: 'The photo for this word',
                          errorBuilder: (_, _, _) => const _NoPreview(),
                        )
                      : ListenableBuilder(
                          listenable: media,
                          builder: (context, _) {
                            final image = media.imageFor(heldHash);
                            if (image == null) return const _NoPreview();
                            return Image(
                              image: image,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                              semanticLabel: 'The photo for this word',
                              errorBuilder: (_, _, _) => const _NoPreview(),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _pickPhoto,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    icon: const Icon(Icons.add_a_photo_rounded),
                    label: Text(
                      capture.hasCamera
                          ? 'Take or choose a photo'
                          : 'Choose a photo',
                    ),
                  ),
                  if (hasPhoto)
                    TextButton(
                      onPressed: _saving ? null : _removePhoto,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      child: const Text('Remove photo'),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (_photoMessage != null) _Message(_photoMessage!),
        if (widget.suggester != null && newImage != null)
          _suggestRow(theme, widget.suggester!),
      ],
    );
  }

  Widget _recordRow(ThemeData theme) {
    final colors = ChorusColors.of(context);
    final hasNew = _newClip != null;
    final hasHeld = _heldAudioHash != null;
    final hasClip = hasNew || hasHeld;
    final canPlay = hasNew || (hasHeld && widget.speaker != null);
    final active = _recording != _Recording.idle;
    final recording = _recording == _Recording.recording;
    final caption = switch (_recording) {
      _Recording.idle => hasClip ? 'Hold to record again' : 'Hold to record',
      _Recording.starting => 'Getting ready',
      _Recording.recording => 'Recording. Let go to stop',
      _Recording.stopping => 'Saving',
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Record how we say it (optional)',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Semantics(
          button: true,
          enabled: !_saving,
          label: recording
              ? 'Recording. Activate to stop'
              : 'Record how we say it. Activate to start, again to stop',
          onTap: _saving ? null : _toggleRecording,
          excludeSemantics: true,
          // Raw pointer events: recording starts on touch and ends on
          // release, with no gesture to win first.
          child: Listener(
            key: const ValueKey('word-record-button'),
            onPointerDown: (_) => unawaited(_holdStart()),
            onPointerUp: (_) => _holdEnd(),
            onPointerCancel: (_) => _holdEnd(),
            // Ink while the microphone is on: the button turns over, as
            // a held card does. No colour: colour belongs to words.
            child: Material(
              color: active ? colors.ink : colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ChorusSpace.buttonRadius),
                side: BorderSide(
                  color: active ? colors.ink : colors.inkMuted,
                  width: active ? 2 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 56),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          recording
                              ? Icons.mic_rounded
                              : Icons.mic_none_rounded,
                          color: active ? colors.card : colors.ink,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            caption,
                            style: ChorusType.label.copyWith(
                              color: active ? colors.card : colors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // How much of the five seconds is used.
                  if (recording)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: maxClipLength,
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        color: colors.card,
                        backgroundColor: colors.inkMuted,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (hasClip && !active)
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (canPlay)
                TextButton.icon(
                  onPressed: _playClip,
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Play it back'),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('This word has a recording.'),
                ),
              TextButton(
                onPressed: _saving ? null : _removeRecording,
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: const Text('Remove recording'),
              ),
            ],
          ),
        if (_clipMessage != null) _Message(_clipMessage!),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    // A sheet is at most 640 wide: the phone's margin suits it everywhere.
    const margin = ChorusSpace.marginPhone;
    final brightness = theme.brightness;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(margin, 0, margin, 16 + keyboard),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(widget.title, style: theme.textTheme.titleLarge),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _label,
                autofocus: widget.initial == null,
                maxLength: maxTileLabelLength,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Word',
                  errorText: _labelError,
                ),
                onChanged: (_) {
                  if (_labelError != null) setState(() => _labelError = null);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _speech,
                maxLength: maxTileSpeechLength,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Says something different (optional)',
                  helperText: 'Leave empty to say the word as written.',
                  // Beside the counter it would be cut short on a phone.
                  helperMaxLines: 5,
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              Text('Colour', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              // Each chip's target is 48dp tall around a 32dp face, so the
              // rows stand apart without more space between them.
              Wrap(
                spacing: ChorusSpace.targetGap,
                children: [
                  for (final colour in wordColours)
                    ChoiceChip(
                      avatar: _Swatch(
                        TileFamily.forKey(colour.key).colorsFor(brightness),
                      ),
                      label: Text(colour.name),
                      showCheckmark: false,
                      selected: _colorKey == colour.key,
                      onSelected: (_) => setState(() => _colorKey = colour.key),
                    ),
                ],
              ),
              if (_hasMedia) ...[
                const SizedBox(height: 16),
                _photoRow(theme),
                const SizedBox(height: 16),
                _recordRow(theme),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(widget.submitLabel),
              ),
              if (widget.onRemove != null) ...[
                const SizedBox(height: ChorusSpace.targetGap),
                TextButton.icon(
                  onPressed: widget.onRemove,
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Remove from board'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Where the record button is between press and saved clip.
enum _Recording { idle, starting, recording, stopping }

/// An icon and a line of text in the take-or-choose dialog.
class _DialogChoice extends StatelessWidget {
  const _DialogChoice(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/// Stands in for a photo that is not on this device yet.
class _NoPreview extends StatelessWidget {
  const _NoPreview();

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    return ColoredBox(
      color: colors.line,
      child: Center(child: Icon(Icons.image_rounded, color: colors.inkMuted)),
    );
  }
}

/// A short notice under a media row, announced to screen readers.
class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Semantics(
        liveRegion: true,
        child: Text(
          text,
          style: ChorusType.body.copyWith(
            color: ChorusColors.of(context).alert,
          ),
        ),
      ),
    );
  }
}

/// The colour on a picker chip: a tiny laminated tile in the word family's
/// fill, on its darker edge, as the word will look on the board.
class _Swatch extends StatelessWidget {
  const _Swatch(this.colors);

  final TileColors colors;

  @override
  Widget build(BuildContext context) {
    const corner = BorderRadius.all(Radius.circular(5));
    return ExcludeSemantics(
      child: SizedBox(
        width: 18,
        height: 18,
        child: DecoratedBox(
          decoration: BoxDecoration(color: colors.edge, borderRadius: corner),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.fill,
                borderRadius: corner,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Puts photo [ideas] under "Needs a home" of [boardId] and says so.
Future<void> _ideasToTray(
  BoardStore store,
  String boardId,
  List<WordIdea> ideas,
  ScaffoldMessengerState? messenger,
) async {
  try {
    final added = await addIdeasToTray(store, boardId, ideas);
    if (added == 0) {
      ChorusHaptics.failed();
      messenger?.showSnackBar(
        const SnackBar(content: Text(ideasNotAddedMessage)),
      );
      return;
    }
    ChorusHaptics.wordAdded();
    messenger?.showSnackBar(SnackBar(content: Text(ideasInTrayMessage(added))));
  } on Object {
    ChorusHaptics.failed();
    messenger?.showSnackBar(const SnackBar(content: Text(wordNotAddedMessage)));
  }
}
