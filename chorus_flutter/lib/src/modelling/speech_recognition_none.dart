/// No speech recognition here (the installed app): "Listen" is not shown.
library;

import 'package:chorus_ui/contracts_modelling.dart';
import 'package:flutter/foundation.dart';

class PlatformSpeechListener extends SpeechListener {
  @override
  bool get available => false;

  @override
  bool get listening => false;

  @override
  void start(ValueChanged<String> onHeard) {}

  @override
  void stop() {}
}
