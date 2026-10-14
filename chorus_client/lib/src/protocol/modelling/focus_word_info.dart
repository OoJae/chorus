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

/// A focus word of the week as the app sees it.
abstract class FocusWordInfo
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  FocusWordInfo._({
    required this.tileId,
    required this.tip,
    required this.weekStart,
  });

  factory FocusWordInfo({
    required _isc.UuidValue tileId,
    required String tip,
    required DateTime weekStart,
  }) = _FocusWordInfoImpl;

  factory FocusWordInfo.fromJson(Map<String, dynamic> jsonSerialization) {
    return FocusWordInfo(
      tileId: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['tileId']),
      tip: jsonSerialization['tip'] as String,
      weekStart: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['weekStart'],
      ),
    );
  }

  _isc.UuidValue tileId;

  String tip;

  /// Monday 00:00 UTC of the week it is pinned for.
  DateTime weekStart;

  /// Returns a shallow copy of this [FocusWordInfo]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  FocusWordInfo copyWith({
    _isc.UuidValue? tileId,
    String? tip,
    DateTime? weekStart,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FocusWordInfo',
      'tileId': tileId.toJson(),
      'tip': tip,
      'weekStart': weekStart.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'FocusWordInfo',
      'tileId': tileId.toJson(),
      'tip': tip,
      'weekStart': weekStart.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _FocusWordInfoImpl extends FocusWordInfo {
  _FocusWordInfoImpl({
    required _isc.UuidValue tileId,
    required String tip,
    required DateTime weekStart,
  }) : super._(
         tileId: tileId,
         tip: tip,
         weekStart: weekStart,
       );

  /// Returns a shallow copy of this [FocusWordInfo]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  FocusWordInfo copyWith({
    _isc.UuidValue? tileId,
    String? tip,
    DateTime? weekStart,
  }) {
    return FocusWordInfo(
      tileId: tileId ?? this.tileId,
      tip: tip ?? this.tip,
      weekStart: weekStart ?? this.weekStart,
    );
  }
}
