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

/// A suggested word as editors see it in "Needs a home".
abstract class SuggestedWordInfo
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  SuggestedWordInfo._({
    required this.id,
    required this.label,
    this.speech,
    this.colorKey,
    required this.suggestedByName,
    required this.source,
    required this.createdAt,
  });

  factory SuggestedWordInfo({
    required int id,
    required String label,
    String? speech,
    String? colorKey,
    required String suggestedByName,
    required String source,
    required DateTime createdAt,
  }) = _SuggestedWordInfoImpl;

  factory SuggestedWordInfo.fromJson(Map<String, dynamic> jsonSerialization) {
    return SuggestedWordInfo(
      id: jsonSerialization['id'] as int,
      label: jsonSerialization['label'] as String,
      speech: jsonSerialization['speech'] as String?,
      colorKey: jsonSerialization['colorKey'] as String?,
      suggestedByName: jsonSerialization['suggestedByName'] as String,
      source: jsonSerialization['source'] as String,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  int id;

  String label;

  String? speech;

  String? colorKey;

  String suggestedByName;

  String source;

  DateTime createdAt;

  /// Returns a shallow copy of this [SuggestedWordInfo]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  SuggestedWordInfo copyWith({
    int? id,
    String? label,
    String? speech,
    String? colorKey,
    String? suggestedByName,
    String? source,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SuggestedWordInfo',
      'id': id,
      'label': label,
      if (speech != null) 'speech': speech,
      if (colorKey != null) 'colorKey': colorKey,
      'suggestedByName': suggestedByName,
      'source': source,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SuggestedWordInfo',
      'id': id,
      'label': label,
      if (speech != null) 'speech': speech,
      if (colorKey != null) 'colorKey': colorKey,
      'suggestedByName': suggestedByName,
      'source': source,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SuggestedWordInfoImpl extends SuggestedWordInfo {
  _SuggestedWordInfoImpl({
    required int id,
    required String label,
    String? speech,
    String? colorKey,
    required String suggestedByName,
    required String source,
    required DateTime createdAt,
  }) : super._(
         id: id,
         label: label,
         speech: speech,
         colorKey: colorKey,
         suggestedByName: suggestedByName,
         source: source,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [SuggestedWordInfo]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  SuggestedWordInfo copyWith({
    int? id,
    String? label,
    Object? speech = _Undefined,
    Object? colorKey = _Undefined,
    String? suggestedByName,
    String? source,
    DateTime? createdAt,
  }) {
    return SuggestedWordInfo(
      id: id ?? this.id,
      label: label ?? this.label,
      speech: speech is String? ? speech : this.speech,
      colorKey: colorKey is String? ? colorKey : this.colorKey,
      suggestedByName: suggestedByName ?? this.suggestedByName,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
