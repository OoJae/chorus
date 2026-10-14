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

/// One word in the circle's second language, as the app sees it.
abstract class WordTranslation
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  WordTranslation._({
    required this.tileId,
    required this.languageCode,
    required this.label,
    this.speech,
  });

  factory WordTranslation({
    required _isc.UuidValue tileId,
    required String languageCode,
    required String label,
    String? speech,
  }) = _WordTranslationImpl;

  factory WordTranslation.fromJson(Map<String, dynamic> jsonSerialization) {
    return WordTranslation(
      tileId: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['tileId']),
      languageCode: jsonSerialization['languageCode'] as String,
      label: jsonSerialization['label'] as String,
      speech: jsonSerialization['speech'] as String?,
    );
  }

  _isc.UuidValue tileId;

  String languageCode;

  String label;

  String? speech;

  /// Returns a shallow copy of this [WordTranslation]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  WordTranslation copyWith({
    _isc.UuidValue? tileId,
    String? languageCode,
    String? label,
    String? speech,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WordTranslation',
      'tileId': tileId.toJson(),
      'languageCode': languageCode,
      'label': label,
      if (speech != null) 'speech': speech,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WordTranslation',
      'tileId': tileId.toJson(),
      'languageCode': languageCode,
      'label': label,
      if (speech != null) 'speech': speech,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WordTranslationImpl extends WordTranslation {
  _WordTranslationImpl({
    required _isc.UuidValue tileId,
    required String languageCode,
    required String label,
    String? speech,
  }) : super._(
         tileId: tileId,
         languageCode: languageCode,
         label: label,
         speech: speech,
       );

  /// Returns a shallow copy of this [WordTranslation]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  WordTranslation copyWith({
    _isc.UuidValue? tileId,
    String? languageCode,
    String? label,
    Object? speech = _Undefined,
  }) {
    return WordTranslation(
      tileId: tileId ?? this.tileId,
      languageCode: languageCode ?? this.languageCode,
      label: label ?? this.label,
      speech: speech is String? ? speech : this.speech,
    );
  }
}
