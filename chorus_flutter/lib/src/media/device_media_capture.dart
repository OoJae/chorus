/// The device's camera, photo library and microphone.
library;

import 'dart:async';

import 'package:chorus_ui/contracts_media.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';

import 'clip_player.dart';
import 'scratch_none.dart' if (dart.library.io) 'scratch_io.dart';

/// [MediaCapture] on the platform's own picker and recorder.
///
/// Nothing here stores or sends anything. A picked photo is handed back as
/// bytes; a recording lives in a scratch file (or, in a browser, in the
/// page's memory) only until it is handed back, and is then deleted.
class DeviceMediaCapture implements MediaCapture {
  DeviceMediaCapture({ClipPlayer? player}) : _player = player ?? DeviceClipPlayer();

  final ClipPlayer _player;
  final ImagePicker _picker = ImagePicker();

  AudioRecorder? _recorder;
  Timer? _limit;
  DateTime? _startedAt;

  /// The stop in progress or finished, so the five-second limit and the
  /// adult letting go do not both stop the recorder.
  Future<Uint8List?>? _stopping;

  /// A clip shorter than this is a slip of the finger, not a word.
  static const Duration shortestClip = Duration(milliseconds: 300);

  /// The system camera is offered on phones and tablets (in their browsers
  /// too). On a desktop the picker opens a file dialog only.
  @override
  bool get hasCamera =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<Uint8List?> pickImage({required bool fromCamera}) async {
    try {
      final file = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        // The platform shrinks a camera photo first where it can, so the
        // store's own shrinking has little left to decode.
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 88,
        requestFullMetadata: false,
      );
      if (file == null) return null;
      return await file.readAsBytes();
    } catch (_) {
      // No camera, permission refused, or the picker is already open.
      return null;
    }
  }

  @override
  Future<bool> startRecording() async {
    try {
      final recorder = _recorder ??= AudioRecorder();
      if (!await recorder.hasPermission()) return false;
      if (await recorder.isRecording()) await recorder.cancel();
      _limit?.cancel();
      _stopping = null;
      final (encoder, extension) = await _encoderFor(recorder);
      final path = await scratchPath(
          'chorus_clip_${DateTime.now().microsecondsSinceEpoch}.$extension');
      await recorder.start(
        RecordConfig(
          encoder: encoder,
          // Speech, one voice, a few words: mono at a low bit rate is
          // clear and keeps a clip to a few tens of kilobytes.
          numChannels: 1,
          bitRate: 48000,
          sampleRate: encoder == AudioEncoder.wav ? 16000 : 44100,
          autoGain: true,
          noiseSuppress: true,
        ),
        // A browser recorder keeps the clip itself and ignores the path.
        path: path ?? '',
      );
      _startedAt = DateTime.now();
      _limit = Timer(maxClipLength, () => unawaited(stopRecording()));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// AAC plays everywhere the app runs, so it is used wherever the device
  /// can record it. Most browsers cannot and record Opus instead; the last
  /// resort is uncompressed audio at a low sample rate.
  Future<(AudioEncoder, String)> _encoderFor(AudioRecorder recorder) async {
    if (!kIsWeb) return (AudioEncoder.aacLc, 'm4a');
    if (await recorder.isEncoderSupported(AudioEncoder.aacLc)) {
      return (AudioEncoder.aacLc, 'm4a');
    }
    if (await recorder.isEncoderSupported(AudioEncoder.opus)) {
      return (AudioEncoder.opus, 'webm');
    }
    return (AudioEncoder.wav, 'wav');
  }

  @override
  Future<Uint8List?> stopRecording() => _stopping ??= _stop();

  Future<Uint8List?> _stop() async {
    _limit?.cancel();
    final recorder = _recorder;
    final startedAt = _startedAt;
    _startedAt = null;
    if (recorder == null || startedAt == null) return null;
    try {
      final tooShort = DateTime.now().difference(startedAt) < shortestClip;
      final path = await recorder.stop();
      if (path == null) return null;
      // On a phone this is the scratch file; in a browser, a link to the
      // clip in the page's memory. XFile reads both.
      final bytes = tooShort ? null : await XFile(path).readAsBytes();
      await deleteScratch(path);
      return (bytes == null || bytes.isEmpty) ? null : bytes;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cancelRecording() async {
    _limit?.cancel();
    _startedAt = null;
    _stopping = null;
    try {
      // Also removes the scratch file.
      await _recorder?.cancel();
    } catch (_) {}
  }

  @override
  Future<void> playClip(Uint8List bytes) async {
    await _player.play(bytes: bytes);
  }

  @override
  Future<void> stopClip() => _player.stop();

  /// Releases the microphone and the player.
  Future<void> dispose() async {
    _limit?.cancel();
    try {
      await _recorder?.dispose();
    } catch (_) {}
    _recorder = null;
    await _player.dispose();
  }
}
