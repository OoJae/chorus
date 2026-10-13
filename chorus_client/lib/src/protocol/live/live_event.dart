/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import '../live/live_kind.dart' as _i5zmgdvo;

/// One moment of a live session, relayed between the members who are joined
/// right now. Never stored.
abstract class LiveEvent
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  LiveEvent._({
    required this.kind,
    this.tileId,
    this.text,
    this.fromUser,
    String? fromName,
    DateTime? at,
  }) : fromName = fromName ?? '',
       at = at ?? DateTime.now();

  factory LiveEvent({
    required _i5zmgdvo.LiveKind kind,
    _isc.UuidValue? tileId,
    String? text,
    _isc.UuidValue? fromUser,
    String? fromName,
    DateTime? at,
  }) = _LiveEventImpl;

  factory LiveEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return LiveEvent(
      kind: _i5zmgdvo.LiveKind.fromJson((jsonSerialization['kind'] as String)),
      tileId: jsonSerialization['tileId'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['tileId']),
      text: jsonSerialization['text'] as String?,
      fromUser: jsonSerialization['fromUser'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['fromUser']),
      fromName: jsonSerialization['fromName'] as String?,
      at: jsonSerialization['at'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['at']),
    );
  }

  _i5zmgdvo.LiveKind kind;

  /// The tile a pulse points at.
  _isc.UuidValue? tileId;

  /// The words of a `said` event.
  String? text;

  /// Who sent it. Stamped by the server; whatever the client sends is ignored.
  _isc.UuidValue? fromUser;

  /// The sender's display name in the circle. Stamped by the server.
  String fromName;

  /// When the server relayed it. Stamped by the server.
  DateTime at;

  /// Returns a shallow copy of this [LiveEvent]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  LiveEvent copyWith({
    _i5zmgdvo.LiveKind? kind,
    _isc.UuidValue? tileId,
    String? text,
    _isc.UuidValue? fromUser,
    String? fromName,
    DateTime? at,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LiveEvent',
      'kind': kind.toJson(),
      if (tileId != null) 'tileId': tileId?.toJson(),
      if (text != null) 'text': text,
      if (fromUser != null) 'fromUser': fromUser?.toJson(),
      'fromName': fromName,
      'at': at.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LiveEvent',
      'kind': kind.toJson(),
      if (tileId != null) 'tileId': tileId?.toJson(),
      if (text != null) 'text': text,
      if (fromUser != null) 'fromUser': fromUser?.toJson(),
      'fromName': fromName,
      'at': at.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LiveEventImpl extends LiveEvent {
  _LiveEventImpl({
    required _i5zmgdvo.LiveKind kind,
    _isc.UuidValue? tileId,
    String? text,
    _isc.UuidValue? fromUser,
    String? fromName,
    DateTime? at,
  }) : super._(
         kind: kind,
         tileId: tileId,
         text: text,
         fromUser: fromUser,
         fromName: fromName,
         at: at,
       );

  /// Returns a shallow copy of this [LiveEvent]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  LiveEvent copyWith({
    _i5zmgdvo.LiveKind? kind,
    Object? tileId = _Undefined,
    Object? text = _Undefined,
    Object? fromUser = _Undefined,
    String? fromName,
    DateTime? at,
  }) {
    return LiveEvent(
      kind: kind ?? this.kind,
      tileId: tileId is _isc.UuidValue? ? tileId : this.tileId,
      text: text is String? ? text : this.text,
      fromUser: fromUser is _isc.UuidValue? ? fromUser : this.fromUser,
      fromName: fromName ?? this.fromName,
      at: at ?? this.at,
    );
  }
}
