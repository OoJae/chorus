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

/// This week's nudge as the app sees it: the word nobody has modelled yet
/// and its tip. The app words the message.
abstract class FocusNudgeInfo
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  FocusNudgeInfo._({
    required this.tileId,
    required this.label,
    required this.tip,
    required this.weekStart,
  });

  factory FocusNudgeInfo({
    required _isc.UuidValue tileId,
    required String label,
    required String tip,
    required DateTime weekStart,
  }) = _FocusNudgeInfoImpl;

  factory FocusNudgeInfo.fromJson(Map<String, dynamic> jsonSerialization) {
    return FocusNudgeInfo(
      tileId: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['tileId']),
      label: jsonSerialization['label'] as String,
      tip: jsonSerialization['tip'] as String,
      weekStart: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['weekStart'],
      ),
    );
  }

  _isc.UuidValue tileId;

  String label;

  String tip;

  DateTime weekStart;

  /// Returns a shallow copy of this [FocusNudgeInfo]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  FocusNudgeInfo copyWith({
    _isc.UuidValue? tileId,
    String? label,
    String? tip,
    DateTime? weekStart,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FocusNudgeInfo',
      'tileId': tileId.toJson(),
      'label': label,
      'tip': tip,
      'weekStart': weekStart.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'FocusNudgeInfo',
      'tileId': tileId.toJson(),
      'label': label,
      'tip': tip,
      'weekStart': weekStart.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _FocusNudgeInfoImpl extends FocusNudgeInfo {
  _FocusNudgeInfoImpl({
    required _isc.UuidValue tileId,
    required String label,
    required String tip,
    required DateTime weekStart,
  }) : super._(
         tileId: tileId,
         label: label,
         tip: tip,
         weekStart: weekStart,
       );

  /// Returns a shallow copy of this [FocusNudgeInfo]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  FocusNudgeInfo copyWith({
    _isc.UuidValue? tileId,
    String? label,
    String? tip,
    DateTime? weekStart,
  }) {
    return FocusNudgeInfo(
      tileId: tileId ?? this.tileId,
      label: label ?? this.label,
      tip: tip ?? this.tip,
      weekStart: weekStart ?? this.weekStart,
    );
  }
}
