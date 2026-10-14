/// English word endings for the talker's "word endings" key: plural, -ing,
/// past, third person -s and possessive 's, with the common irregular
/// forms a young child meets. Pure rules, no data from the board.
library;

/// One ending the key can put on a word.
enum WordEnding {
  /// dog → dogs, box → boxes, baby → babies, child → children.
  plural,

  /// 's: Mum → Mum's, dogs → dogs'.
  possessive,

  /// run → running, make → making, see → seeing.
  ing,

  /// want → wanted, go → went, stop → stopped.
  past,

  /// go → goes, do → does, have → has.
  thirdPerson,
}

/// What a word is, as far as its endings go.
enum WordKind {
  /// Takes plural and 's.
  noun,

  /// Takes -ing, -ed and -s.
  verb,

  /// Takes no ending: a pronoun, a question word, a describing word, "not".
  none,

  /// Not known: the common endings are offered.
  unknown,
}

/// A word with one ending on it.
class EndingForm {
  const EndingForm(this.ending, this.text);

  /// Null for the plain word, offered back when the word already has an
  /// ending ("went" offers "go").
  final WordEnding? ending;
  final String text;

  @override
  bool operator ==(Object other) =>
      other is EndingForm && other.ending == ending && other.text == text;

  @override
  int get hashCode => Object.hash(ending, text);

  @override
  String toString() => 'EndingForm(${ending?.name ?? 'base'}, "$text")';
}

/// Plurals that do not add -s or -es.
const Map<String, String> irregularPlurals = {
  'child': 'children',
  'foot': 'feet',
  'mouse': 'mice',
  'person': 'people',
  'tooth': 'teeth',
  'man': 'men',
  'woman': 'women',
  'goose': 'geese',
  'ox': 'oxen',
  'louse': 'lice',
  'die': 'dice',
  'leaf': 'leaves',
  'knife': 'knives',
  'wife': 'wives',
  'life': 'lives',
  'half': 'halves',
  'wolf': 'wolves',
  'loaf': 'loaves',
  'shelf': 'shelves',
  'thief': 'thieves',
  'calf': 'calves',
  'scarf': 'scarves',
  'elf': 'elves',
  'potato': 'potatoes',
  'tomato': 'tomatoes',
  'hero': 'heroes',
  'echo': 'echoes',
  'mango': 'mangoes',
  'quiz': 'quizzes',
  'grandchild': 'grandchildren',
  'policeman': 'policemen',
  'fireman': 'firemen',
  'snowman': 'snowmen',
};

/// Nouns that are the same one or many.
const Set<String> unchangingPlurals = {
  'sheep',
  'fish',
  'deer',
  'moose',
  'series',
  'species',
  'aircraft',
  'salmon',
  'trout',
  'bison',
  'shrimp',
  'clothes',
  'pants',
  'trousers',
  'scissors',
  'glasses',
  'pyjamas',
  'pajamas',
  'jeans',
  'shorts',
};

/// Past tenses that do not add -ed: about a hundred of the verbs a child
/// hears most.
const Map<String, String> irregularPasts = {
  'am': 'was',
  'is': 'was',
  'are': 'were',
  'be': 'was',
  'go': 'went',
  'eat': 'ate',
  'see': 'saw',
  'come': 'came',
  'do': 'did',
  'get': 'got',
  'give': 'gave',
  'have': 'had',
  'has': 'had',
  'make': 'made',
  'say': 'said',
  'take': 'took',
  'think': 'thought',
  'find': 'found',
  'know': 'knew',
  'tell': 'told',
  'feel': 'felt',
  'leave': 'left',
  'put': 'put',
  'bring': 'brought',
  'begin': 'began',
  'keep': 'kept',
  'hold': 'held',
  'write': 'wrote',
  'stand': 'stood',
  'hear': 'heard',
  'let': 'let',
  'mean': 'meant',
  'set': 'set',
  'meet': 'met',
  'run': 'ran',
  'pay': 'paid',
  'sit': 'sat',
  'speak': 'spoke',
  'lead': 'led',
  'read': 'read',
  'grow': 'grew',
  'lose': 'lost',
  'fall': 'fell',
  'send': 'sent',
  'build': 'built',
  'understand': 'understood',
  'draw': 'drew',
  'break': 'broke',
  'spend': 'spent',
  'cut': 'cut',
  'drive': 'drove',
  'buy': 'bought',
  'wear': 'wore',
  'choose': 'chose',
  'throw': 'threw',
  'catch': 'caught',
  'win': 'won',
  'forget': 'forgot',
  'sell': 'sold',
  'fight': 'fought',
  'teach': 'taught',
  'sleep': 'slept',
  'swim': 'swam',
  'sing': 'sang',
  'drink': 'drank',
  'ride': 'rode',
  'hide': 'hid',
  'bite': 'bit',
  'blow': 'blew',
  'fly': 'flew',
  'shake': 'shook',
  'wake': 'woke',
  'hurt': 'hurt',
  'hit': 'hit',
  'shut': 'shut',
  'feed': 'fed',
  'slide': 'slid',
  'stick': 'stuck',
  'swing': 'swung',
  'sting': 'stung',
  'dig': 'dug',
  'hang': 'hung',
  'spin': 'spun',
  'become': 'became',
  'bend': 'bent',
  'lend': 'lent',
  'shoot': 'shot',
  'steal': 'stole',
  'freeze': 'froze',
  'sweep': 'swept',
  'tear': 'tore',
  'ring': 'rang',
  'sink': 'sank',
  'shine': 'shone',
  'light': 'lit',
  'can': 'could',
  'will': 'would',
  'lie': 'lay',
  'fit': 'fit',
  'quit': 'quit',
  'spread': 'spread',
  'cost': 'cost',
};

/// Third person forms that do not simply add -s or -es.
const Map<String, String> irregularThirdPersons = {
  'be': 'is',
  'am': 'is',
  'are': 'is',
  'have': 'has',
  'do': 'does',
  'go': 'goes',
};

/// Verbs whose -ing form is not made by the rules below.
const Map<String, String> irregularIngs = {
  'be': 'being',
  'see': 'seeing',
  'flee': 'fleeing',
  'agree': 'agreeing',
  'free': 'freeing',
  'ski': 'skiing',
  'dye': 'dyeing',
  'singe': 'singeing',
  'picnic': 'picnicking',
  'panic': 'panicking',
  'mimic': 'mimicking',
  'quit': 'quitting',
};

/// Verbs of more than one syllable stressed on the end, which double
/// their last letter: begin → beginning, forget → forgotten.
const Set<String> _doublesFinal = {
  'begin',
  'forget',
  'admit',
  'prefer',
  'regret',
  'occur',
  'control',
  'refer',
  'permit',
  'upset',
  'commit',
  'omit',
  'patrol',
  'quit',
  'quiz',
};

/// Common verbs that take the regular endings, so a word with no colour
/// is still known for one.
const Set<String> regularVerbs = {
  'want',
  'like',
  'look',
  'help',
  'play',
  'jump',
  'walk',
  'talk',
  'open',
  'turn',
  'finish',
  'stop',
  'need',
  'love',
  'watch',
  'wash',
  'push',
  'pull',
  'kick',
  'cook',
  'clean',
  'climb',
  'cry',
  'dance',
  'listen',
  'move',
  'paint',
  'smile',
  'laugh',
  'call',
  'ask',
  'work',
  'wait',
  'use',
  'close',
  'carry',
  'hug',
  'kiss',
  'touch',
  'tickle',
  'brush',
  'change',
  'try',
  'share',
  'show',
  'start',
  'hurry',
  'hate',
  'hope',
  'live',
  'miss',
  'rest',
  'fix',
  'mix',
  'bake',
  'pour',
  'roll',
  'bounce',
  'splash',
  'tidy',
  'fill',
  'pick',
  'drop',
  'hop',
  'clap',
  'shout',
  'whisper',
  'yell',
  'cuddle',
  'colour',
  'color',
  'count',
  'point',
  'chase',
  'tap',
  'drum',
  'stay',
  'visit',
  'happen',
  'answer',
  'learn',
  'remember',
  'enjoy',
  'cover',
  'dress',
  'zip',
  'scream',
  'sneeze',
  'cough',
  'yawn',
  'blink',
  'sniff',
  'smell',
  'taste',
  'pretend',
  'build',
  'hide',
  'feel',
};

/// Words that take no ending in the key: pronouns, determiners, question
/// words, little words of place and joining.
const Set<String> _noEndingWords = {
  'i',
  'me',
  'my',
  'mine',
  'you',
  'your',
  'yours',
  'he',
  'him',
  'his',
  'she',
  'her',
  'hers',
  'it',
  'its',
  'we',
  'us',
  'our',
  'they',
  'them',
  'their',
  'this',
  'that',
  'these',
  'those',
  'a',
  'an',
  'the',
  'some',
  'all',
  'any',
  'more',
  'not',
  'no',
  'yes',
  'here',
  'there',
  'in',
  'on',
  'up',
  'down',
  'out',
  'off',
  'at',
  'to',
  'with',
  'and',
  'or',
  'but',
  'what',
  'where',
  'why',
  'who',
  'when',
  'how',
  'which',
  'very',
  'too',
  'again',
  'please',
  'thank',
  'hello',
  'hi',
  'bye',
  'goodbye',
  'oh',
  'uh',
  'same',
  'different',
  'good',
  'bad',
  'big',
  'little',
  'hot',
  'cold',
  'now',
  'later',
  'today',
  'tomorrow',
  'yesterday',
  'if',
  'because',
  'so',
  'from',
  'for',
  'of',
  'by',
  'about',
  'under',
  'over',
  'into',
  'onto',
  'yummy',
  'yucky',
  'happy',
  'sad',
  'tired',
  'hungry',
  'thirsty',
  'sick',
  'ok',
  'okay',
};

/// The verbs the endings know, irregular and regular.
Set<String> get knownVerbs => {...irregularPasts.keys, ...regularVerbs};

/// Every form a base word may be seen as, mapped back to the base.
final Map<String, String> _bases = _buildBases();

Map<String, String> _buildBases() {
  final bases = <String, String>{};
  for (final MapEntry(:key, :value) in irregularPasts.entries) {
    if (key == 'am' || key == 'is' || key == 'are' || key == 'has') continue;
    bases.putIfAbsent(value, () => key);
  }
  for (final MapEntry(:key, :value) in irregularPlurals.entries) {
    bases.putIfAbsent(value, () => key);
  }
  for (final verb in knownVerbs) {
    if (verb == 'am' || verb == 'is' || verb == 'are' || verb == 'has') {
      continue;
    }
    for (final form in [ingOf(verb), pastOf(verb), thirdPersonOf(verb)]) {
      if (form != verb) bases.putIfAbsent(form, () => verb);
    }
  }
  // Past forms that are also words of their own stay as they are.
  bases.remove('read');
  bases.remove('put');
  bases.remove('cut');
  bases.remove('hit');
  bases.remove('let');
  bases.remove('set');
  bases.remove('hurt');
  bases.remove('shut');
  bases.remove('fit');
  bases.remove('quit');
  bases.remove('cost');
  bases.remove('spread');
  bases.remove('left');
  bases.remove('lay');
  return bases;
}

/// The base word of [word] when it is a form the endings know (went → go,
/// running → run, children → child, finished → finish), else [word]
/// itself. Case is kept.
String baseWordOf(String word) {
  final lower = word.toLowerCase();
  final base = _bases[lower];
  if (base == null) return word;
  return _matchCase(word, base);
}

bool _isVowel(String c) => 'aeiou'.contains(c);

bool _isConsonant(String c) =>
    c.length == 1 && 'bcdfghjklmnpqrstvwxyz'.contains(c);

/// Syllables as groups of vowels; a final silent e is not one.
int _syllables(String word) {
  var w = word.replaceAll('qu', 'q');
  if (w.length > 2 && w.endsWith('e') && !w.endsWith('ee')) {
    w = w.substring(0, w.length - 1);
  }
  var count = 0;
  var inVowel = false;
  for (var i = 0; i < w.length; i++) {
    final c = w[i];
    final vowel = _isVowel(c) || (c == 'y' && i > 0);
    if (vowel && !inVowel) count++;
    inVowel = vowel;
  }
  return count == 0 ? 1 : count;
}

/// Doubles the last consonant before -ing and -ed: stop → stopp-, but
/// not rain, fix, play or open.
bool _doublesLast(String verb) {
  if (_doublesFinal.contains(verb)) return true;
  if (verb.length < 3) return false;
  final last = verb[verb.length - 1];
  final mid = verb[verb.length - 2];
  final before = verb[verb.length - 3];
  if (!_isConsonant(last) || 'wxy'.contains(last)) return false;
  if (!_isVowel(mid)) return false;
  if (_isVowel(before)) return false;
  return _syllables(verb) == 1;
}

String _matchCase(String original, String form) {
  if (original.isEmpty) return form;
  if (original == original.toUpperCase() && original.length > 1) {
    return form.toUpperCase();
  }
  final first = original[0];
  if (first != first.toLowerCase()) {
    return form[0].toUpperCase() + form.substring(1);
  }
  return form;
}

/// Applies [rule] to the last word of [label], keeping its case, so
/// "ice cream" → "ice creams".
String _onLastWord(String label, String Function(String lower) rule) {
  final trimmed = label.trim();
  if (trimmed.isEmpty) return label;
  final space = trimmed.lastIndexOf(' ');
  final head = space < 0 ? '' : trimmed.substring(0, space + 1);
  final word = space < 0 ? trimmed : trimmed.substring(space + 1);
  return head + _matchCase(word, rule(word.toLowerCase()));
}

/// child → children, dog → dogs, box → boxes, baby → babies, sheep → sheep.
String pluralOf(String noun) => _onLastWord(noun, (w) {
  final irregular = irregularPlurals[w];
  if (irregular != null) return irregular;
  if (unchangingPlurals.contains(w)) return w;
  if (w.endsWith('man') && w.length > 3) {
    return '${w.substring(0, w.length - 3)}men';
  }
  if (w.endsWith('s') ||
      w.endsWith('x') ||
      w.endsWith('z') ||
      w.endsWith('ch') ||
      w.endsWith('sh')) {
    return '${w}es';
  }
  if (w.length > 1 && w.endsWith('y') && _isConsonant(w[w.length - 2])) {
    return '${w.substring(0, w.length - 1)}ies';
  }
  return '${w}s';
});

/// run → running, make → making, see → seeing, lie → lying.
String ingOf(String verb) => _onLastWord(verb, (w) {
  final irregular = irregularIngs[w];
  if (irregular != null) return irregular;
  if (w.endsWith('ie')) return '${w.substring(0, w.length - 2)}ying';
  if (w.endsWith('ee') || w.endsWith('oe') || w.endsWith('ye')) {
    return '${w}ing';
  }
  if (w.length > 2 && w.endsWith('e')) {
    return '${w.substring(0, w.length - 1)}ing';
  }
  if (_doublesLast(w)) return '$w${w[w.length - 1]}ing';
  return '${w}ing';
});

/// want → wanted, go → went, like → liked, cry → cried, stop → stopped.
String pastOf(String verb) => _onLastWord(verb, (w) {
  final irregular = irregularPasts[w];
  if (irregular != null) return irregular;
  if (w.endsWith('e')) return '${w}d';
  if (w.length > 1 && w.endsWith('y') && _isConsonant(w[w.length - 2])) {
    return '${w.substring(0, w.length - 1)}ied';
  }
  if (w.endsWith('c') && irregularIngs.containsKey(w)) return '${w}ked';
  if (_doublesLast(w)) return '$w${w[w.length - 1]}ed';
  return '${w}ed';
});

/// go → goes, do → does, have → has, want → wants, cry → cries.
String thirdPersonOf(String verb) => _onLastWord(verb, (w) {
  final irregular = irregularThirdPersons[w];
  if (irregular != null) return irregular;
  if (w.endsWith('s') ||
      w.endsWith('x') ||
      w.endsWith('z') ||
      w.endsWith('ch') ||
      w.endsWith('sh') ||
      (w.endsWith('o') && !w.endsWith('oo'))) {
    return '${w}es';
  }
  if (w.length > 1 && w.endsWith('y') && _isConsonant(w[w.length - 2])) {
    return '${w.substring(0, w.length - 1)}ies';
  }
  return '${w}s';
});

/// Mum → Mum's, dog → dog's, dogs → dogs', children → children's,
/// bus → bus's.
String possessiveOf(String noun) {
  final trimmed = noun.trim();
  if (trimmed.isEmpty) return noun;
  final lower = trimmed.toLowerCase();
  final plural =
      lower.endsWith('s') &&
      !lower.endsWith('ss') &&
      !lower.endsWith('us') &&
      !lower.endsWith('is') &&
      lower.length > 3;
  return plural ? "$trimmed'" : "$trimmed's";
}

/// [word] with [ending] on it.
String applyEnding(String word, WordEnding ending) => switch (ending) {
  WordEnding.plural => pluralOf(word),
  WordEnding.possessive => possessiveOf(word),
  WordEnding.ing => ingOf(word),
  WordEnding.past => pastOf(word),
  WordEnding.thirdPerson => thirdPersonOf(word),
};

/// What [word] is for the endings. A tile's [colorKey] says first: a verb
/// tile is a verb, and a pronoun, question, describing or "not" tile takes
/// no ending. Otherwise the word itself: a known verb, a little word that
/// takes none, or unknown.
WordKind wordKindOf(String word, {String? colorKey}) {
  final last = word.trim().split(RegExp(r'\s+')).last.toLowerCase();
  if (last.isEmpty) return WordKind.none;
  if (!RegExp(r"^[a-z][a-z'-]*$").hasMatch(last)) return WordKind.none;
  switch (colorKey) {
    case 'verb':
      return WordKind.verb;
    case 'pronoun' || 'question' || 'descriptor' || 'negation':
      return WordKind.none;
  }
  if (_noEndingWords.contains(last)) return WordKind.none;
  if (knownVerbs.contains(last)) return WordKind.verb;
  if (irregularPlurals.containsKey(last) || unchangingPlurals.contains(last)) {
    return WordKind.noun;
  }
  return WordKind.unknown;
}

/// The endings that make sense for a word of [kind]: nouns get plural and
/// 's, verbs -ing, -ed and -s, an unknown word the common ones.
List<WordEnding> endingsFor(WordKind kind) => switch (kind) {
  WordKind.noun => const [WordEnding.plural, WordEnding.possessive],
  WordKind.verb => const [
    WordEnding.ing,
    WordEnding.past,
    WordEnding.thirdPerson,
  ],
  WordKind.none => const [],
  WordKind.unknown => const [
    WordEnding.plural,
    WordEnding.ing,
    WordEnding.past,
    WordEnding.possessive,
  ],
};

/// The forms the key offers for [word]: its base first when [word] already
/// has an ending (so "went" offers "go" back), then each ending that makes
/// sense, without repeats or forms equal to the word itself.
List<EndingForm> wordFormsFor(String word, {String? colorKey}) {
  final trimmed = word.trim();
  if (trimmed.isEmpty) return const [];
  final base = baseWordOf(trimmed);
  final kind = wordKindOf(base, colorKey: colorKey);
  final forms = <EndingForm>[];
  final seen = <String>{trimmed.toLowerCase()};
  if (seen.add(base.toLowerCase())) forms.add(EndingForm(null, base));
  for (final ending in endingsFor(kind)) {
    final text = applyEnding(base, ending);
    if (seen.add(text.toLowerCase())) forms.add(EndingForm(ending, text));
  }
  return forms;
}
