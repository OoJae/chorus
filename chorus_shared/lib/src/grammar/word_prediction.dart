/// Word prediction for the talker's keyboard: a bundled list of common
/// words, ranked, combined with how often this device has spoken each word.
library;

import 'dart:math' as math;

import '../starter_board.dart';

/// Words a young child hears and says most, most common first. Written for
/// Chorus: the core words first, then the words of home, food, play, people
/// and feelings. The starter board's words are added where missing; see
/// [predictionWords].
const List<String> commonChildWords = [
  // Core words, most used first.
  'I', 'you', 'it', 'want', 'more', 'go', 'not', 'that', 'help', 'stop',
  'like', 'get', 'make', 'look', 'do', 'put', 'turn', 'open', 'up', 'in',
  'on', 'all', 'some', 'here', 'what', 'where', 'who', 'why', 'when', 'can',
  'good', 'same', 'different', 'he', 'she', 'finished',
  // Little words that join a sentence.
  'the', 'a', 'and', 'is', 'to', 'my', 'me', 'no', 'yes', 'please', 'thank',
  'mine', 'your', 'we', 'they', 'this', 'out', 'down', 'off', 'with', 'now',
  'again', 'too', 'are', 'am', 'was', 'have', 'need', 'don\'t', 'can\'t',
  'it\'s', 'there', 'one', 'two', 'three', 'big', 'little', 'all done',
  'come', 'eat', 'drink', 'play', 'see', 'give', 'take', 'feel', 'love',
  'know', 'think', 'say', 'tell', 'read', 'sleep', 'wash', 'sit', 'stand',
  'walk', 'run', 'jump', 'climb', 'swing', 'slide', 'swim', 'ride', 'push',
  'pull', 'throw', 'catch', 'kick', 'draw', 'paint', 'build', 'sing',
  'dance', 'listen', 'watch', 'wait', 'hug', 'kiss', 'tickle', 'hold',
  'carry', 'fix', 'try', 'find', 'hide', 'share', 'show', 'clean', 'cook',
  'bake', 'pour', 'cut', 'brush', 'close', 'break', 'fall', 'hurt', 'cry',
  'laugh', 'smile', 'talk', 'call', 'ask', 'work', 'bring', 'keep', 'leave',
  'stay', 'start', 'finish', 'change', 'move', 'shake', 'blow', 'bounce',
  // People.
  'mum', 'mummy', 'mom', 'mommy', 'dad', 'daddy', 'baby', 'brother',
  'sister', 'grandma', 'grandpa', 'nana', 'friend', 'teacher', 'doctor',
  'nurse', 'boy', 'girl', 'man', 'woman', 'people', 'family', 'everyone',
  // Feelings and the body.
  'happy', 'sad', 'angry', 'scared', 'tired', 'hungry', 'thirsty', 'sick',
  'hot', 'cold', 'okay', 'better', 'bored', 'excited', 'silly', 'calm',
  'loud', 'quiet', 'pain', 'head', 'tummy', 'hand', 'hands', 'foot', 'feet',
  'leg', 'arm', 'eye', 'eyes', 'ear', 'nose', 'mouth', 'teeth', 'hair',
  'face', 'back', 'body',
  // Food and drink.
  'water', 'milk', 'juice', 'snack', 'apple', 'banana', 'bread', 'toast',
  'cheese', 'biscuit', 'cookie', 'cake', 'chocolate', 'sweets', 'yogurt',
  'cereal', 'pasta', 'rice', 'chicken', 'pizza', 'chips', 'fries', 'soup',
  'egg', 'sandwich', 'grapes', 'orange', 'strawberry', 'carrot', 'peas',
  'ice cream', 'breakfast', 'lunch', 'dinner', 'tea', 'food', 'cup',
  'plate', 'bowl', 'spoon', 'fork', 'bottle', 'yummy', 'yucky',
  // Home and things.
  'home', 'house', 'room', 'bed', 'bath', 'toilet', 'potty', 'door',
  'window', 'chair', 'table', 'kitchen', 'garden', 'car', 'bus', 'train',
  'bike', 'ball', 'book', 'toy', 'toys', 'doll', 'blocks', 'puzzle',
  'game', 'phone', 'tablet', 'tv', 'music', 'song', 'video', 'bubbles',
  'crayon', 'paper', 'blanket', 'teddy', 'shoes', 'socks', 'coat', 'hat',
  'clothes', 'pyjamas', 'nappy', 'light', 'box', 'bag', 'key', 'money',
  // Places and outside.
  'park', 'school', 'shop', 'outside', 'inside', 'beach', 'pool', 'zoo',
  'farm', 'playground', 'swimming', 'library', 'hospital', 'church',
  'sun', 'rain', 'snow', 'tree', 'flower', 'grass', 'sky', 'water',
  // Animals.
  'dog', 'cat', 'fish', 'bird', 'duck', 'horse', 'cow', 'pig', 'sheep',
  'rabbit', 'bear', 'lion', 'tiger', 'monkey', 'elephant', 'dinosaur',
  'frog', 'mouse', 'spider', 'bee', 'butterfly',
  // Describing.
  'fast', 'slow', 'heavy', 'soft', 'hard', 'wet', 'dry', 'dirty', 'new',
  'old', 'nice', 'bad', 'funny', 'pretty', 'red', 'blue', 'green',
  'yellow', 'pink', 'purple', 'black', 'white', 'brown', 'long', 'short',
  'full', 'empty', 'broken', 'gone', 'first', 'last', 'next', 'very',
  'lots', 'many', 'every', 'other', 'any', 'only', 'because',
  // Little words of place and time.
  'over', 'under', 'behind', 'between', 'near', 'far', 'away', 'around',
  'top', 'bottom', 'front', 'side', 'later', 'soon', 'today', 'tomorrow',
  'yesterday', 'morning', 'night', 'bedtime', 'time', 'day', 'week',
  'then', 'before', 'after', 'if', 'but', 'or', 'so', 'how', 'which',
  'his', 'her', 'our', 'their', 'them', 'him', 'us', 'these', 'those',
  // Social words.
  'hello', 'hi', 'bye', 'goodbye', 'sorry', 'thanks', 'oops', 'wow', 'uh oh',
  'yay', 'well done', 'my turn', 'your turn', 'let\'s', 'maybe', 'sure',
  'break', 'quiet', 'loud', 'name', 'birthday', 'party', 'present',
  'holiday', 'outside', 'walk',
];

/// [commonChildWords] with the starter board's words added where missing,
/// without repeats, most common first.
final List<String> predictionWords = _buildWords();

List<String> _buildWords() {
  final seen = <String>{};
  final words = <String>[];
  void add(String word) {
    if (seen.add(word.toLowerCase())) words.add(word);
  }

  for (final word in commonChildWords) {
    add(word);
  }
  for (final word in universalCore36) {
    add(word.label);
  }
  return List.unmodifiable(words);
}

/// The word being typed at the end of [text]: the letters after the last
/// space, or empty when [text] ends in a space.
String wordBeingTyped(String text) {
  final space = text.lastIndexOf(' ');
  return space < 0 ? text : text.substring(space + 1);
}

/// [text] with the word being typed replaced by [word] and a space after
/// it, ready for the next word.
String completeWord(String text, String word) {
  final space = text.lastIndexOf(' ');
  final head = space < 0 ? '' : text.substring(0, space + 1);
  return '$head$word ';
}

/// Up to [limit] words that start with [prefix], best first.
///
/// A word this device has spoken ([counts], by lowercase word) comes before
/// any it has not, and more uses before fewer; then the bundled rank of
/// [words] decides. Words in [counts] that are not in [words] are offered
/// too. Matching ignores case; an empty [prefix] offers the most likely
/// words of all.
List<String> predictWords(
  String prefix, {
  Map<String, int> counts = const {},
  int limit = 3,
  List<String>? words,
}) {
  if (limit <= 0) return const [];
  final ranked = words ?? predictionWords;
  final wanted = prefix.trim().toLowerCase();
  final scores = <String, double>{};
  final shown = <String, String>{};
  final total = ranked.length;
  for (var i = 0; i < total; i++) {
    final word = ranked[i];
    final key = word.toLowerCase();
    if (!key.startsWith(wanted) || scores.containsKey(key)) continue;
    scores[key] = 1 - i / math.max(1, total);
    shown[key] = word;
  }
  for (final MapEntry(:key, :value) in counts.entries) {
    final lower = key.toLowerCase();
    if (value <= 0 || lower.isEmpty || !lower.startsWith(wanted)) continue;
    // A spoken word is worth more than any rank: log so a word said a
    // hundred times does not bury one said ten.
    scores[lower] = (scores[lower] ?? 0) + 1 + math.log(1 + value) / math.ln2;
    shown.putIfAbsent(lower, () => key);
  }
  final keys = scores.keys.toList()
    ..sort((a, b) {
      final byScore = scores[b]!.compareTo(scores[a]!);
      return byScore != 0 ? byScore : a.compareTo(b);
    });
  return [for (final key in keys.take(limit)) shown[key]!];
}

/// [counts] after [text] was spoken once more on this device: each word
/// counted by its lowercase form. Words of letters only; at most [maxWords]
/// are kept, the least used dropped first.
Map<String, int> countSpokenWords(
  Map<String, int> counts,
  String text, {
  int maxWords = 500,
}) {
  final next = Map<String, int>.of(counts);
  for (final raw in text.toLowerCase().split(RegExp(r'\s+'))) {
    final word = raw.replaceAll(RegExp(r"^[^a-z']+|[^a-z']+$"), '');
    if (word.isEmpty || !RegExp(r"^[a-z][a-z']*$").hasMatch(word)) continue;
    if (word.length > 30) continue;
    next[word] = (next[word] ?? 0) + 1;
  }
  if (next.length > maxWords) {
    final order = next.keys.toList()
      ..sort((a, b) => next[a]!.compareTo(next[b]!));
    for (final word in order.take(next.length - maxWords)) {
      next.remove(word);
    }
  }
  return next;
}
