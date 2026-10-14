/// The browser's own voice list, read for what flutter_tts leaves out:
/// whether each voice is on the device.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

Set<String> onlineVoiceNames() {
  try {
    return {
      for (final voice in web.window.speechSynthesis.getVoices().toDart)
        // Only a voice that says it is not local counts as online; one that
        // does not say is trusted, as the browser would.
        if (voice['localService'].dartify() == false) voice.name,
    };
  } catch (_) {
    return const {};
  }
}
