/// How long a word's label and spoken text may be, and how text that comes
/// from outside (a pasted name, an imported file) is tidied before it is
/// kept.
library;

/// The longest label a word may have, in characters: what the add-word
/// sheet allows, and about what one tile can show at a readable size.
const int maxTileLabelLength = 30;

/// The longest text a word may say, in characters.
const int maxTileSpeechLength = 80;

// C0 and C1 control characters and DEL. Line breaks and tabs are among them.
final RegExp _control = RegExp(r'[\u0000-\u001F\u007F-\u009F]');
final RegExp _spaces = RegExp(r'\s+');

/// [text] on one line: control characters and line breaks made spaces,
/// every run of spaces made one, and the ends trimmed. With [maxLength] it
/// is then cut to that many characters.
String tidyText(String text, {int? maxLength}) {
  final tidy = text.replaceAll(_control, ' ').replaceAll(_spaces, ' ').trim();
  return maxLength == null ? tidy : cutText(tidy, maxLength).trimRight();
}

/// The first [length] characters of [text], counted as Unicode code points
/// so a character outside the basic plane is never split in two.
String cutText(String text, int length) {
  final runes = text.runes;
  return runes.length <= length
      ? text
      : String.fromCharCodes(runes.take(length));
}
