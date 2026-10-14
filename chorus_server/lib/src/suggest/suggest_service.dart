/// The rules behind `suggest.fromPhoto`: find the photo, count the call
/// against the circle's daily budget, ask a vision model for one word, and
/// clean up whatever comes back.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'vision_transport.dart';

/// Private storage that holds a circle's media. The media endpoint stores
/// every file here under `MediaObject.path`.
const mediaStorageId = 'private';

/// Suggestions a circle may ask for per UTC day.
const defaultDailyBudget = 40;

/// The model asked when the `suggestModel` password is not set.
const defaultSuggestModel = 'claude-opus-5-5';

/// Longest label a tile can show comfortably.
const maxLabelLength = 24;

/// Longest text a suggested tile may speak.
const maxSpeechLength = 80;

/// The colour keys a suggestion may carry. `noun` has no colour of its own
/// in the shared palette and shows as a plain tile.
const suggestColorKeys = {
  'verb',
  'pronoun',
  'question',
  'descriptor',
  'determiner',
  'negation',
  'noun',
};

/// Largest photo sent to the model. Its base64 form stays under the
/// service's 5 MB limit for one image.
const maxImageBytes = 3700000;

/// Models that take the server-side fallback for a declined request.
const _fallbackModels = {
  'claude-opus-5-5',
  'claude-opus-5',
  'claude-fable-5-1',
};

const _fallbackBeta = 'server-side-fallback-2026-07-01';

/// Everything the service needs from outside. Tests replace it through
/// [suggestSettingsOverride]; the server reads it from its passwords.
class SuggestSettings {
  const SuggestSettings({
    required this.apiKey,
    this.model = defaultSuggestModel,
    this.baseUrl = anthropicBaseUrl,
    this.dailyBudget = defaultDailyBudget,
    this.transport = const HttpVisionTransport(),
    this.retryDelay = const Duration(seconds: 1),
    this.now,
  });

  /// From the passwords `anthropicApiKey`, `suggestModel` and
  /// `suggestBaseUrl`. Set them in `config/passwords.yaml` or as
  /// `SERVERPOD_PASSWORD_<name>`.
  factory SuggestSettings.fromPasswords(Session session) {
    final model = session.serverpod.getPassword('suggestModel')?.trim();
    final baseUrl = session.serverpod.getPassword('suggestBaseUrl')?.trim();
    return SuggestSettings(
      apiKey: session.serverpod.getPassword('anthropicApiKey'),
      model: model == null || model.isEmpty ? defaultSuggestModel : model,
      baseUrl: baseUrl == null || baseUrl.isEmpty ? anthropicBaseUrl : baseUrl,
    );
  }

  /// Null or blank when the service is not set up.
  final String? apiKey;
  final String model;

  /// Where the Messages API lives: Anthropic's own service, or another one
  /// that speaks the same protocol.
  final String baseUrl;
  final int dailyBudget;
  final VisionTransport transport;

  /// Pause before the one retry after a 429 or a 5xx.
  final Duration retryDelay;

  /// The clock that decides which day a call counts against.
  final DateTime Function()? now;
}

/// Set by tests to answer the model call themselves. Null on a real server.
SuggestSettings? suggestSettingsOverride;

/// Suggests one word for the circle's verified image [imageSha256].
///
/// The caller has already been checked as an editing member of
/// [circleSpace]. Throws [SuggestException] for every way this can fail.
///
/// A call counts against the budget once it is about to reach the model,
/// whether or not the model then answers; a missing key or photo costs
/// nothing.
Future<WordSuggestion> suggestFromPhoto(
  Session session,
  UuidValue circleSpace,
  String imageSha256,
  String locale, {
  SuggestSettings? settings,
}) async {
  final s =
      settings ??
      suggestSettingsOverride ??
      SuggestSettings.fromPasswords(session);
  final apiKey = s.apiKey?.trim() ?? '';
  if (apiKey.isEmpty) throw _fail(SuggestFailure.notConfigured);

  final image = await _loadImage(session, circleSpace, imageSha256);

  final today = _day((s.now ?? DateTime.now)().toUtc());
  if (!await _reserveCall(session, circleSpace, today, s.dailyBudget)) {
    throw _fail(SuggestFailure.overBudget);
  }

  final reply = await _ask(session, s, apiKey, image, cleanLocale(locale));
  return parseSuggestion(reply);
}

SuggestException _fail(SuggestFailure failure) =>
    SuggestException(failure: failure);

/// A photo ready to send: its bytes and what kind of image they are.
typedef _Image = ({Uint8List bytes, String mediaType});

final _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');

/// The verified bytes of the circle's image, or `unreadable`.
Future<_Image> _loadImage(
  Session session,
  UuidValue circleSpace,
  String sha256,
) async {
  final hash = sha256.trim().toLowerCase();
  if (!_sha256Pattern.hasMatch(hash)) throw _fail(SuggestFailure.unreadable);
  final media = await MediaObject.db.findFirstRow(
    session,
    where: (t) => t.circleSpace.equals(circleSpace) & t.sha256.equals(hash),
  );
  if (media == null ||
      media.verifiedAt == null ||
      media.kind != MediaKind.image) {
    throw _fail(SuggestFailure.unreadable);
  }
  final Uint8List bytes;
  try {
    final data = await session.storage.retrieveFile(
      storageId: mediaStorageId,
      path: media.path,
    );
    bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } catch (_) {
    throw _fail(SuggestFailure.unreadable);
  }
  final mediaType = imageMediaType(bytes);
  if (mediaType == null || bytes.length > maxImageBytes) {
    throw _fail(SuggestFailure.unreadable);
  }
  return (bytes: bytes, mediaType: mediaType);
}

/// The image type the model accepts that [bytes] start like, or null.
String? imageMediaType(Uint8List bytes) {
  bool starts(List<int> magic, [int at = 0]) {
    if (bytes.length < at + magic.length) return false;
    for (var i = 0; i < magic.length; i++) {
      if (bytes[at + i] != magic[i]) return false;
    }
    return true;
  }

  if (starts(const [0xFF, 0xD8, 0xFF])) return 'image/jpeg';
  if (starts(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
    return 'image/png';
  }
  if (starts(const [0x47, 0x49, 0x46, 0x38])) return 'image/gif';
  if (starts(const [0x52, 0x49, 0x46, 0x46]) &&
      starts(const [0x57, 0x45, 0x42, 0x50], 8)) {
    return 'image/webp';
  }
  return null;
}

String _day(DateTime utc) =>
    '${utc.year.toString().padLeft(4, '0')}-'
    '${utc.month.toString().padLeft(2, '0')}-'
    '${utc.day.toString().padLeft(2, '0')}';

/// Counts one call for [circleSpace] on [day] unless that would pass
/// [budget]. One statement, so two adults asking at once cannot both take
/// the last call.
Future<bool> _reserveCall(
  Session session,
  UuidValue circleSpace,
  String day,
  int budget,
) async {
  if (budget <= 0) return false;
  final result = await session.db.unsafeQuery(
    'INSERT INTO "ai_usage" ("circleSpace", "day", "calls") '
    'VALUES (CAST(@space AS uuid), @day, 1) '
    'ON CONFLICT ("circleSpace", "day") DO UPDATE '
    'SET "calls" = "ai_usage"."calls" + 1 '
    'WHERE "ai_usage"."calls" < @budget '
    'RETURNING "calls"',
    parameters: QueryParameters.named({
      'space': circleSpace.uuid,
      'day': day,
      'budget': budget,
    }),
  );
  return result.isNotEmpty;
}

final _localePattern = RegExp(r'^[A-Za-z]{2,3}([-_][A-Za-z0-9]{2,8}){0,3}$');

/// [locale] if it looks like a language tag, otherwise `en`. The tag goes
/// into the prompt, so nothing else is let through.
String cleanLocale(String locale) {
  final trimmed = locale.trim();
  return _localePattern.hasMatch(trimmed) ? trimmed : 'en';
}

const _instructions = '''
You help an adult add a word to a child's picture communication board (AAC).
Look at the photo and name the main thing in it with the one everyday word a
young child's board would use: short, concrete, the word a family would say
at home. Prefer a single word; use two only when one would be wrong.

Answer with one JSON object and nothing else:
{"label": string, "speech": string, "colorKey": string, "properName": boolean, "alternatives": [string]}

- label: the word shown on the tile, in the requested language, lower case
  unless it is a proper name.
- speech: what the tile says aloud. Usually the same as label.
- colorKey: the word's part of speech, one of verb, pronoun, question,
  descriptor, determiner, negation, noun.
- properName: true only when label is a proper name.
- alternatives: up to 3 other everyday words an adult might prefer, best
  first, never repeating label.

Never name or describe a person in the photo; for a person use a general
word such as "person", "baby" or "friend". If you cannot tell what the
photo shows, answer with an empty label.''';

const _schema = <String, Object?>{
  'type': 'object',
  'properties': {
    'label': {'type': 'string'},
    'speech': {'type': 'string'},
    'colorKey': {'type': 'string'},
    'properName': {'type': 'boolean'},
    'alternatives': {
      'type': 'array',
      'items': {'type': 'string'},
    },
  },
  'required': ['label', 'speech', 'colorKey', 'properName', 'alternatives'],
  'additionalProperties': false,
};

/// The request body. [plain] leaves out everything a model may not know
/// (effort, the output schema, the fallback), keeping only the basic shape.
Map<String, Object?> buildSuggestRequest({
  required String model,
  required Uint8List imageBytes,
  required String mediaType,
  required String locale,
  bool plain = false,
}) => {
  'model': model,
  'max_tokens': 4096,
  'system': _instructions,
  if (!plain)
    'output_config': {
      'effort': 'low',
      'format': {'type': 'json_schema', 'schema': _schema},
    },
  if (!plain && _fallbackModels.contains(model)) 'fallbacks': 'default',
  'messages': [
    {
      'role': 'user',
      'content': [
        {
          'type': 'image',
          'source': {
            'type': 'base64',
            'media_type': mediaType,
            'data': base64Encode(imageBytes),
          },
        },
        {
          'type': 'text',
          'text': 'Language: $locale. Answer with the JSON object only.',
        },
      ],
    },
  ],
};

/// Calls the model and returns the body of its 200 reply.
///
/// A 429 or a 5xx is tried once more. A 400 is tried once more in the plain
/// shape, in case the configured model does not take the optional fields.
/// A service other than Anthropic's own gets the plain shape from the start:
/// the optional fields are Anthropic's, and a first refusal would only cost
/// a round trip.
Future<String> _ask(
  Session session,
  SuggestSettings s,
  String apiKey,
  _Image image,
  String locale,
) async {
  var plain = !isAnthropicBaseUrl(s.baseUrl);
  var retried = false;
  while (true) {
    final body = buildSuggestRequest(
      model: s.model,
      imageBytes: image.bytes,
      mediaType: image.mediaType,
      locale: locale,
      plain: plain,
    );
    final VisionReply reply;
    try {
      reply = await s.transport.send(
        apiKey: apiKey,
        body: body,
        betas: body.containsKey('fallbacks') ? const [_fallbackBeta] : const [],
        baseUrl: s.baseUrl,
      );
    } catch (e) {
      // The error's type only: its message could quote the request.
      session.log(
        'Suggestion call got no reply (${e.runtimeType}).',
        level: LogLevel.warning,
      );
      throw _fail(SuggestFailure.failed);
    }
    final status = reply.status;
    if (status == 200) return reply.body;
    if ((status == 429 || status >= 500) && !retried) {
      retried = true;
      await Future<void>.delayed(s.retryDelay);
      continue;
    }
    if (status == 400 && !plain) {
      plain = true;
      continue;
    }
    session.log(
      'Suggestion call failed with status $status.',
      level: LogLevel.warning,
    );
    // A request the service will not take in any shape is, in practice, a
    // photo it cannot read or one that is too large.
    throw _fail(
      status == 400 || status == 413
          ? SuggestFailure.unreadable
          : SuggestFailure.failed,
    );
  }
}

/// Reads the model's reply [body] into a suggestion.
///
/// Throws `unreadable` when the model declined, said nothing usable, or
/// could not tell what the photo shows.
WordSuggestion parseSuggestion(String body) {
  final unreadable = _fail(SuggestFailure.unreadable);
  final Object? message;
  try {
    message = jsonDecode(body);
  } on FormatException {
    throw unreadable;
  }
  if (message is! Map || message['stop_reason'] == 'refusal') throw unreadable;
  final content = message['content'];
  if (content is! List) throw unreadable;
  final text = content
      .whereType<Map>()
      .where((block) => block['type'] == 'text' && block['text'] is String)
      .map((block) => block['text'] as String)
      .join('\n');

  final answer = _jsonObjectIn(text);
  if (answer == null) throw unreadable;

  final proper = answer['properName'] == true;
  String word(Object? raw, int max) {
    if (raw is! String) return '';
    final cleaned = _tidy(raw, max);
    return proper ? cleaned : cleaned.toLowerCase();
  }

  final label = word(answer['label'], maxLabelLength);
  if (label.isEmpty) throw unreadable;

  final rawSpeech = answer['speech'];
  var speech = rawSpeech is String ? _tidy(rawSpeech, maxSpeechLength) : '';
  if (speech.isEmpty) speech = label;

  final rawKey = answer['colorKey'];
  final key = rawKey is String ? rawKey.trim().toLowerCase() : '';

  final alternatives = <String>[];
  final rawAlternatives = answer['alternatives'];
  if (rawAlternatives is List) {
    for (final raw in rawAlternatives) {
      final alternative = word(raw, maxLabelLength);
      if (alternative.isEmpty ||
          alternative.toLowerCase() == label.toLowerCase() ||
          alternatives.any(
            (a) => a.toLowerCase() == alternative.toLowerCase(),
          )) {
        continue;
      }
      alternatives.add(alternative);
      if (alternatives.length == 3) break;
    }
  }

  return WordSuggestion(
    label: label,
    speech: speech,
    colorKey: suggestColorKeys.contains(key) ? key : 'noun',
    alternatives: alternatives,
  );
}

/// The first JSON object in [text], which may be wrapped in a code fence or
/// a sentence. Null when there is none.
Map<String, Object?>? _jsonObjectIn(String text) {
  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  if (start < 0 || end <= start) return null;
  try {
    final decoded = jsonDecode(text.substring(start, end + 1));
    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}

final _whitespace = RegExp(r'\s+');
final _edgeNoise = RegExp(
  r'''^["'“”‘’`\s]+|["'“”‘’`\s.,;:!]+$''',
);

/// One line, no wrapping quotes or trailing punctuation, at most [max]
/// characters.
String _tidy(String raw, int max) {
  var value = raw.replaceAll(_whitespace, ' ').replaceAll(_edgeNoise, '');
  if (value.length > max) value = value.substring(0, max).trimRight();
  return value;
}
