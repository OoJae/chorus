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

/// A circle's voice as the app sees it: see CircleVoice.
abstract class VoiceSetting
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  VoiceSetting._({
    this.voiceName,
    required this.rate,
    required this.pitch,
    this.changedAt,
  });

  factory VoiceSetting({
    String? voiceName,
    required double rate,
    required double pitch,
    DateTime? changedAt,
  }) = _VoiceSettingImpl;

  factory VoiceSetting.fromJson(Map<String, dynamic> jsonSerialization) {
    return VoiceSetting(
      voiceName: jsonSerialization['voiceName'] as String?,
      rate: (jsonSerialization['rate'] as num).toDouble(),
      pitch: (jsonSerialization['pitch'] as num).toDouble(),
      changedAt: jsonSerialization['changedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['changedAt']),
    );
  }

  String? voiceName;

  double rate;

  double pitch;

  DateTime? changedAt;

  /// Returns a shallow copy of this [VoiceSetting]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  VoiceSetting copyWith({
    String? voiceName,
    double? rate,
    double? pitch,
    DateTime? changedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'VoiceSetting',
      if (voiceName != null) 'voiceName': voiceName,
      'rate': rate,
      'pitch': pitch,
      if (changedAt != null) 'changedAt': changedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'VoiceSetting',
      if (voiceName != null) 'voiceName': voiceName,
      'rate': rate,
      'pitch': pitch,
      if (changedAt != null) 'changedAt': changedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _VoiceSettingImpl extends VoiceSetting {
  _VoiceSettingImpl({
    String? voiceName,
    required double rate,
    required double pitch,
    DateTime? changedAt,
  }) : super._(
         voiceName: voiceName,
         rate: rate,
         pitch: pitch,
         changedAt: changedAt,
       );

  /// Returns a shallow copy of this [VoiceSetting]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  VoiceSetting copyWith({
    Object? voiceName = _Undefined,
    double? rate,
    double? pitch,
    Object? changedAt = _Undefined,
  }) {
    return VoiceSetting(
      voiceName: voiceName is String? ? voiceName : this.voiceName,
      rate: rate ?? this.rate,
      pitch: pitch ?? this.pitch,
      changedAt: changedAt is DateTime? ? changedAt : this.changedAt,
    );
  }
}
