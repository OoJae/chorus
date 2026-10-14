import 'package:serverpod/serverpod.dart';

import '../circles/membership_guard.dart';
import '../generated/protocol.dart';
import 'suggest_service.dart';

/// Optional help for adults: a word suggested for a photo.
///
/// The suggestion is only returned to the adult who asked. Nothing reaches a
/// board until they approve it on their own device.
class SuggestEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Suggests a word, in the language of [locale], for the circle's verified
  /// image with hash [imageSha256]. Editing roles only.
  ///
  /// Throws [SuggestException] when the service is not set up, the circle is
  /// over its daily budget, the photo cannot be read, or the call fails.
  Future<WordSuggestion> fromPhoto(
    Session session,
    UuidValue circleSpace,
    String imageSha256,
    String locale,
  ) async {
    await requireMember(session, circleSpace, editing: true);
    return suggestFromPhoto(session, circleSpace, imageSha256, locale);
  }

  /// Suggests 3 to 6 words across word types (things, actions, describing
  /// words), each with a part-of-speech colour key, for the circle's
  /// verified image [imageSha256]. Ideas for one photo are kept for a day.
  /// Editing roles only. Nothing is placed: an adult confirms each word.
  ///
  /// Throws [SuggestException] as [fromPhoto] does.
  Future<List<WordSuggestion>> ideasFromPhoto(
    Session session,
    UuidValue circleSpace,
    String imageSha256,
    String locale,
  ) async {
    await requireMember(session, circleSpace, editing: true);
    return suggestIdeasFromPhoto(session, circleSpace, imageSha256, locale);
  }
}
