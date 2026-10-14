/// Pictures for the starter words and the words of the ready-made boards:
/// from Mulberry Symbols by Steve Lee, and for starter words Mulberry has no
/// picture for, drawn for Chorus in the same style by the Chorus authors
/// ([chorusDrawnSymbols]). All CC BY-SA 4.0, see `assets/symbols/LICENSE.md`.
///
/// A tile finds its picture by its label, so boards made before the pictures
/// existed gain them with no change to their data. A tile's own photo always
/// wins over these.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../features/flags/w7.dart';

/// The starter words, every one of which has a picture, in lower case.
const List<String> starterSymbolWords = [
  'all',
  'can',
  'different',
  'do',
  'finished',
  'get',
  'go',
  'good',
  'he',
  'help',
  'here',
  'i',
  'in',
  'it',
  'like',
  'look',
  'make',
  'more',
  'not',
  'on',
  'open',
  'put',
  'same',
  'she',
  'some',
  'stop',
  'that',
  'turn',
  'up',
  'want',
  'what',
  'when',
  'where',
  'who',
  'why',
  'you',
];

/// The words of the ready-made boards that have a Mulberry Symbols picture
/// and are not starter words. Hidden again when `readyMadeBoardsEnabled` is
/// false.
const List<String> readyBoardSymbolWords = [
  'angry',
  'apple',
  'baby',
  'banana',
  'beach',
  'bed',
  'big',
  'biscuit',
  'blue',
  'bread',
  'broken',
  'brother',
  'build',
  'bus',
  'cafe',
  'calm',
  'car',
  'cereal',
  'cheese',
  'chicken',
  'climb',
  'close',
  'come',
  'dad',
  'dance',
  'dentist',
  'dirty',
  'doctor',
  'draw',
  'drink',
  'dry',
  'eat',
  'egg',
  'empty',
  'excited',
  'family',
  'fast',
  'full',
  'funny',
  'garden',
  'give',
  'grapes',
  'green',
  'happy',
  'hard',
  'home',
  'hot',
  'hug',
  'hungry',
  'juice',
  'jump',
  'little',
  'loud',
  'milk',
  'mum',
  'nurse',
  'outside',
  'pasta',
  'pizza',
  'play',
  'pull',
  'push',
  'quiet',
  'read',
  'red',
  'rice',
  'run',
  'sad',
  'scared',
  'school',
  'shop',
  'sing',
  'sister',
  'sit',
  'sleep',
  'soft',
  'swim',
  'take',
  'teacher',
  'thirsty',
  'toast',
  'toilet',
  'upstairs',
  'walk',
  'wash',
  'water',
  'wet',
  'worried',
  'yellow',
  'yogurt',
  'yucky',
  'yummy',
];

/// The board words that have a picture, in lower case. Each has a PNG of
/// 128 px at `assets/symbols/<word>.png` in this package, with 256 px and
/// 384 px versions under `2.0x/` and `3.0x/` that Flutter picks by screen
/// density. The pronoun "I" is `i.png`.
const List<String> symbolWords = [
  ...starterSymbolWords,
  ...readyBoardSymbolWords,
];

/// The pictured words whose symbol was drawn for Chorus, because Mulberry
/// Symbols has none a child would read as that word. Credited to the Chorus
/// authors, CC BY-SA 4.0.
const Set<String> chorusDrawnSymbols = {
  'can',
  'different',
  'do',
  'here',
  'it',
  'stop',
  'that',
  'you',
};

/// The words that gained a picture so that every starter word has one: the
/// five from Mulberry Symbols and [chorusDrawnSymbols]. Hidden again when
/// `coreSymbolsEnabled` is false.
const Set<String> addedCoreSymbols = {
  'all',
  'he',
  'like',
  'not',
  'she',
  ...chorusDrawnSymbols,
};

/// The asset path of the picture for [label], or null when the word has
/// none. Case and surrounding spaces are ignored, so "I" and " Want " match.
String? symbolAssetFor(String label) {
  final word = label.trim().toLowerCase();
  if (!coreSymbolsEnabled && addedCoreSymbols.contains(word)) return null;
  if (!readyMadeBoardsEnabled && readyBoardSymbolWords.contains(word)) {
    return null;
  }
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
