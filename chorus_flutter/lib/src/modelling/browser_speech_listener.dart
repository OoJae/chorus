/// The browser's speech recognition for "Listen" in model mode, where the
/// browser has one (Chrome, Edge, Safari); elsewhere it is not available
/// and "Listen" is not shown.
library;

import 'package:chorus_ui/contracts_modelling.dart';

import 'speech_recognition_none.dart'
    if (dart.library.js_interop) 'speech_recognition_web.dart'
    as platform;

/// A [SpeechListener] over the browser's `SpeechRecognition`, in English.
SpeechListener browserSpeechListener() => platform.PlatformSpeechListener();
