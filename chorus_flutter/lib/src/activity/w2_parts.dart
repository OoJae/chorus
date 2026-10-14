/// What "What changed", "Suggest a word" and "People in this circle" need
/// beyond the board store, for one circle and adult.
///
/// The app sets [w2RemoteFor] once its client exists; until then (and in
/// widget tests) the parts that need the server are simply left out, and
/// home shows what works without them.
library;

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_ui/contracts_activity.dart';

import '../../screens/support/circle_cache_none.dart'
    if (dart.library.io) '../../screens/support/circle_cache_io.dart'
    if (dart.library.js_interop) '../../screens/support/circle_cache_web.dart'
    as platform;

/// The parts of one circle that need the server.
typedef W2Remote = ({WordSuggestions? suggestions, CircleMembers? members});

/// Makes the server parts of [circle] for the signed-in adult [userId]. Set
/// by the app; null leaves them out.
W2Remote Function(CircleInfo circle, String userId)? w2RemoteFor;

/// Everything one circle offers for these features.
class W2Parts {
  W2Parts._(this.seen, this.suggestions, this.members);

  /// When "What changed" was last opened on this device.
  final ActivitySeen seen;

  /// Null when the app has no server to ask.
  final WordSuggestions? suggestions;
  final CircleMembers? members;
}

final Map<String, W2Parts> _parts = {};

/// The parts of [circle] for [userId], the same object on every call for
/// the same circle, adult and role.
W2Parts w2PartsFor(CircleInfo circle, String userId) {
  final key = '$userId/${circle.spaceUuid.uuid}/${circle.myRole.name}';
  return _parts[key] ??= () {
    final remote = w2RemoteFor?.call(circle, userId);
    return W2Parts._(
      DeviceActivitySeen(userId: userId, circleId: circle.spaceUuid.uuid),
      remote?.suggestions,
      remote?.members,
    );
  }();
}

/// The last look at "What changed", kept on this device per adult and
/// circle: a small file on phones and desktops, local storage on the web.
class DeviceActivitySeen implements ActivitySeen {
  DeviceActivitySeen({required this.userId, required this.circleId});

  final String userId;
  final String circleId;
  DateTime? _known;

  String get _name => 'chorus_activity_seen_${userId}_$circleId.txt';

  @override
  Future<DateTime?> lastLooked() async {
    final known = _known;
    if (known != null) return known;
    try {
      final text = await platform.readText(_name);
      return _known = text == null ? null : DateTime.tryParse(text.trim());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> markLooked(DateTime at) async {
    _known = at.toUtc();
    try {
      await platform.writeText(_name, at.toUtc().toIso8601String());
    } catch (_) {
      // Storage refused: it holds for this run only.
    }
  }
}

/// [WordSuggestions] on the server's `wordSuggestion` endpoint.
class ServerWordSuggestions implements WordSuggestions {
  ServerWordSuggestions(this._client, this._circleSpace);

  final Client _client;
  final UuidValue _circleSpace;

  @override
  Future<void> suggest(String label) =>
      _client.wordSuggestion.suggest(_circleSpace, label, null, null);

  @override
  Future<List<WordSuggestionItem>> open() async {
    final rows = await _client.wordSuggestion.list(_circleSpace);
    return [
      for (final row in rows)
        WordSuggestionItem(
          id: row.id,
          label: row.label,
          speech: row.speech,
          colorKey: row.colorKey,
          byName: row.suggestedByName,
          at: row.createdAt,
          fromPhoto: row.source == 'photo',
        ),
    ];
  }

  @override
  Future<void> resolve(WordSuggestionItem item, {required bool added}) =>
      _client.wordSuggestion.resolve(_circleSpace, item.id, added);
}

/// "Guardian", "Therapist", "Teacher" or "Partner (view only)".
String roleNameOf(CircleRole role) => switch (role) {
  CircleRole.guardian => 'Guardian',
  CircleRole.therapist => 'Therapist',
  CircleRole.teacher => 'Teacher',
  CircleRole.partner => 'Partner (view only)',
};

/// [CircleMembers] on the server's `members` endpoint.
class ServerCircleMembers implements CircleMembers {
  ServerCircleMembers(
    this._client,
    this._circleSpace, {
    required this.myUserId,
    required this.canRemove,
  });

  final Client _client;
  final UuidValue _circleSpace;
  final String myUserId;

  @override
  final bool canRemove;

  @override
  Future<List<CircleMember>> list() async {
    final rows = await _client.members.list(_circleSpace);
    return [
      for (final row in rows)
        CircleMember(
          userId: row.userId.uuid,
          name: row.displayName,
          roleName: roleNameOf(row.role),
          isMe: row.userId.uuid.toLowerCase() == myUserId.toLowerCase(),
        ),
    ];
  }

  @override
  Future<void> remove(CircleMember member) => _client.members.remove(
    _circleSpace,
    UuidValue.withValidation(member.userId),
  );
}

/// The server parts for [circle], on [client]. What the app sets
/// [w2RemoteFor] to.
W2Remote serverW2Remote(Client client, CircleInfo circle, String userId) => (
  suggestions: ServerWordSuggestions(client, circle.spaceUuid),
  members: ServerCircleMembers(
    client,
    circle.spaceUuid,
    myUserId: userId,
    canRemove: circle.myRole == CircleRole.guardian,
  ),
);
