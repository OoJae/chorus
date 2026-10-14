/// The bundled fonts, loaded for widget tests that measure real text.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Loads Fraunces, Atkinson Hyperlegible Next and IBM Plex Mono under the
/// names `ChorusType` uses. `flutter test` draws every font it has not been
/// given as full squares, so without this nothing can be said about what
/// fits on a phone.
///
/// Works from this package's own tests and from the app's.
@visibleForTesting
Future<void> loadChorusFonts() async {
  for (final (family, file) in const [
    ('Fraunces', 'Fraunces-Variable.ttf'),
    ('AtkinsonHyperlegibleNext', 'AtkinsonHyperlegibleNext-Variable.ttf'),
    ('IBMPlexMono', 'IBMPlexMono-Medium.ttf'),
  ]) {
    final loader = FontLoader('packages/chorus_ui/$family')
      ..addFont(_load('assets/fonts/$file'));
    await loader.load();
  }
}

/// The app bundles this package's files under its name; this package's own
/// tests run it as the app, with the files at their own paths.
Future<ByteData> _load(String path) async {
  try {
    return await rootBundle.load('packages/chorus_ui/$path');
  } on Object {
    return rootBundle.load(path);
  }
}
