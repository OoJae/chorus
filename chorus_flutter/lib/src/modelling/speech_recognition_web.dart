/// The browser's `SpeechRecognition` (or `webkitSpeechRecognition`),
/// through `dart:js_interop`, feature-detected.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:chorus_ui/contracts_modelling.dart';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// The constructor the browser offers, or null.
JSFunction? _recognitionClass() {
  try {
    final window = web.window as JSObject;
    for (final name in ['SpeechRecognition', 'webkitSpeechRecognition']) {
      if (window.has(name)) return window[name] as JSFunction?;
    }
  } catch (_) {}
  return null;
}

class PlatformSpeechListener extends SpeechListener {
  JSObject? _recognition;
  bool _listening = false;
  bool _wanted = false;
  ValueChanged<String>? _onHeard;

  @override
  bool get available => _recognitionClass() != null;

  @override
  bool get listening => _listening;

  @override
  void start(ValueChanged<String> onHeard) {
    final make = _recognitionClass();
    if (make == null || _listening) return;
    _onHeard = onHeard;
    _wanted = true;
    try {
      final recognition = make.callAsConstructor<JSObject>();
      recognition['lang'] = 'en-US'.toJS;
      recognition['continuous'] = true.toJS;
      recognition['interimResults'] = false.toJS;
      recognition['onresult'] = ((JSObject event) => _onResult(event)).toJS;
      recognition['onend'] = ((JSObject _) => _onEnd()).toJS;
      recognition['onerror'] = ((JSObject _) => _onError()).toJS;
      recognition.callMethod<JSAny?>('start'.toJS);
      _recognition = recognition;
      _listening = true;
      notifyListeners();
    } catch (_) {
      _wanted = false;
      _recognition = null;
    }
  }

  void _onResult(JSObject event) {
    try {
      final results = event['results'] as JSObject;
      final from = (event['resultIndex'] as JSNumber).toDartInt;
      final count = (results['length'] as JSNumber).toDartInt;
      for (var i = from; i < count; i++) {
        final result = results.callMethod<JSObject>('item'.toJS, i.toJS);
        final isFinal = (result['isFinal'] as JSBoolean?)?.toDart ?? true;
        if (!isFinal) continue;
        final best = result.callMethod<JSObject>('item'.toJS, 0.toJS);
        final text = (best['transcript'] as JSString?)?.toDart ?? '';
        if (text.trim().isNotEmpty) _onHeard?.call(text);
      }
    } catch (_) {}
  }

  /// The browser stops after a pause; keep going until asked to stop.
  void _onEnd() {
    if (_wanted) {
      try {
        _recognition?.callMethod<JSAny?>('start'.toJS);
        return;
      } catch (_) {}
    }
    _listening = false;
    _recognition = null;
    notifyListeners();
  }

  void _onError() {
    // A refused microphone or no speech: stop quietly.
    _wanted = false;
  }

  @override
  void stop() {
    _wanted = false;
    _onHeard = null;
    try {
      _recognition?.callMethod<JSAny?>('stop'.toJS);
    } catch (_) {}
    _recognition = null;
    if (_listening) {
      _listening = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
