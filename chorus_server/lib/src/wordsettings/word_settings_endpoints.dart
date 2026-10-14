import 'package:serverpod/serverpod.dart';

import '../circles/membership_guard.dart';
import '../generated/protocol.dart';

/// Longest label or speech a translation may carry, in characters.
const int maxTranslationLength = 80;

/// Longest language name, in characters.
const int maxLanguageNameLength = 40;

/// Longest language code, in characters (BCP 47 tags are short).
const int maxLanguageCodeLength = 16;

/// Words an adult has hidden from the child's board for now.
///
/// Server-only rows beside the frozen synced tables: hiding never moves a
/// word and never touches its tile. Any member may read the list (the
/// child's board must show what is hidden whoever is signed in on it); only
/// an editing role may change it.
class HiddenWordsEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Ids of the tiles hidden in [circleSpace]. Members only.
  Future<List<UuidValue>> list(Session session, UuidValue circleSpace) async {
    await requireMember(session, circleSpace);
    final rows = await TileSetting.db.find(
      session,
      where: (t) => t.circleSpace.equals(circleSpace) & t.hidden.equals(true),
    );
    return [for (final row in rows) row.tileId];
  }

  /// Hides ([hidden] true) or shows again the tile [tileId] of
  /// [circleSpace]. Editing roles only. Asking for the state it is already
  /// in changes nothing. The tile need not have reached the server yet: a
  /// word added offline can be hidden at once.
  Future<void> setHidden(
    Session session,
    UuidValue circleSpace,
    UuidValue tileId,
    bool hidden,
  ) async {
    await requireMember(session, circleSpace, editing: true);
    await TileSetting.db.upsertRow(
      session,
      TileSetting(
        circleSpace: circleSpace,
        tileId: tileId,
        hidden: hidden,
        changedBy: callerId(session),
        changedAt: DateTime.now().toUtc(),
      ),
      conflictColumns: (t) => [t.circleSpace, t.tileId],
    );
  }
}

/// A circle's second (home) language and its words in it.
///
/// Any member may read them, so every board can show them; only an editing
/// role may change them.
class HomeLanguageEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// The circle's second language, or null when it has none. Members only.
  Future<SecondLanguage?> getLanguage(
    Session session,
    UuidValue circleSpace,
  ) async {
    await requireMember(session, circleSpace);
    final row = await CircleLanguage.db.findFirstRow(
      session,
      where: (t) => t.circleSpace.equals(circleSpace),
    );
    if (row == null) return null;
    return SecondLanguage(code: row.languageCode, name: row.languageName);
  }

  /// Sets the circle's second language, or clears it with null. Editing
  /// roles only. Translations into another language are kept, so switching
  /// back brings them back.
  Future<void> setLanguage(
    Session session,
    UuidValue circleSpace,
    SecondLanguage? language,
  ) async {
    await requireMember(session, circleSpace, editing: true);
    if (language == null) {
      await CircleLanguage.db.deleteWhere(
        session,
        where: (t) => t.circleSpace.equals(circleSpace),
      );
      return;
    }
    final code = language.code.trim();
    final name = language.name.trim();
    if (code.isEmpty ||
        code.length > maxLanguageCodeLength ||
        name.isEmpty ||
        name.length > maxLanguageNameLength) {
      throw WordSettingsException(reason: 'bad language');
    }
    await CircleLanguage.db.upsertRow(
      session,
      CircleLanguage(
        circleSpace: circleSpace,
        languageCode: code,
        languageName: name,
        changedBy: callerId(session),
        changedAt: DateTime.now().toUtc(),
      ),
      conflictColumns: (t) => [t.circleSpace],
    );
  }

  /// Every word of [circleSpace] in [languageCode]. Members only.
  Future<List<WordTranslation>> listTranslations(
    Session session,
    UuidValue circleSpace,
    String languageCode,
  ) async {
    await requireMember(session, circleSpace);
    final rows = await TileTranslation.db.find(
      session,
      where: (t) =>
          t.circleSpace.equals(circleSpace) &
          t.languageCode.equals(languageCode),
    );
    return [
      for (final row in rows)
        WordTranslation(
          tileId: row.tileId,
          languageCode: row.languageCode,
          label: row.label,
          speech: row.speech,
        ),
    ];
  }

  /// Sets one word in a second language. An empty label removes it, so the
  /// word shows in the first language again. Editing roles only.
  Future<void> setTranslation(
    Session session,
    UuidValue circleSpace,
    WordTranslation translation,
  ) async {
    await requireMember(session, circleSpace, editing: true);
    final code = translation.languageCode.trim();
    final label = translation.label.trim();
    final speech = translation.speech?.trim();
    if (code.isEmpty ||
        code.length > maxLanguageCodeLength ||
        label.length > maxTranslationLength ||
        (speech != null && speech.length > maxTranslationLength)) {
      throw WordSettingsException(reason: 'bad translation');
    }
    if (label.isEmpty) {
      await TileTranslation.db.deleteWhere(
        session,
        where: (t) =>
            t.circleSpace.equals(circleSpace) &
            t.tileId.equals(translation.tileId) &
            t.languageCode.equals(code),
      );
      return;
    }
    await TileTranslation.db.upsertRow(
      session,
      TileTranslation(
        circleSpace: circleSpace,
        tileId: translation.tileId,
        languageCode: code,
        label: label,
        speech: (speech == null || speech.isEmpty) ? null : speech,
        changedBy: callerId(session),
        changedAt: DateTime.now().toUtc(),
      ),
      conflictColumns: (t) => [t.circleSpace, t.tileId, t.languageCode],
    );
  }
}
