/// Pictures for the starter words, from Mulberry Symbols by Steve Lee
/// (CC BY-SA 4.0, see `assets/symbols/LICENSE.md`).
///
/// A tile finds its picture by its label, so boards made before the pictures
/// existed gain them with no change to their data. A tile's own photo always
/// wins over these.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The board words that have a picture, in lower case. Each has a PNG of
/// 128 px at `assets/symbols/<word>.png` in this package, with 256 px and
/// 384 px versions under `2.0x/` and `3.0x/` that Flutter picks by screen
/// density. The pronoun "I" is `i.png`.
const List<String> symbolWords = [
  'finished',
  'get',
  'go',
  'good',
  'help',
  'i',
  'in',
  'look',
  'make',
  'more',
  'on',
  'open',
  'put',
  'same',
  'some',
  'turn',
  'up',
  'want',
  'what',
  'when',
  'where',
  'who',
  'why',
];

/// The asset path of the picture for [label], or null when the word has
/// none. Case and surrounding spaces are ignored, so "I" and " Want " match.
String? symbolAssetFor(String label) {
  final word = label.trim().toLowerCase();
  return symbolWords.contains(word) ? 'assets/symbols/$word.png' : null;
}

/// The picture for [label] as an image from this package, or null when the
/// word has none.
AssetImage? symbolImageFor(String label) {
  final path = symbolAssetFor(label);
  return path == null ? null : _SymbolImage(path);
}

/// A picture from this package, found both in the app, which bundles it
/// under `packages/chorus_ui/`, and when this package runs as the app itself
/// (its own tests and `main_fake.dart`), which bundles it under its own path.
class _SymbolImage extends AssetImage {
  const _SymbolImage(super.assetName) : super(package: 'chorus_ui');

  @override
  Future<AssetBundleImageKey> obtainKey(ImageConfiguration configuration) {
    final chosen = bundle ?? configuration.bundle ?? rootBundle;
    // The manifest is cached after its first load, so this stays synchronous
    // from then on, as AssetImage is.
    return AssetManifest.loadFromAssetBundle(chosen).then(
      (manifest) => manifest.getAssetVariants(keyName) != null
          ? super.obtainKey(configuration)
          : AssetImage(assetName, bundle: bundle).obtainKey(configuration),
    );
  }
}
