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

/// A circle's second language as the app sees it.
abstract class SecondLanguage
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  SecondLanguage._({
    required this.code,
    required this.name,
  });

  factory SecondLanguage({
    required String code,
    required String name,
  }) = _SecondLanguageImpl;

  factory SecondLanguage.fromJson(Map<String, dynamic> jsonSerialization) {
    return SecondLanguage(
      code: jsonSerialization['code'] as String,
      name: jsonSerialization['name'] as String,
    );
  }

  /// A BCP 47 language code, e.g. `yo`, `es`, `fr`.
  String code;

  /// Its name, e.g. "Yoruba".
  String name;

  /// Returns a shallow copy of this [SecondLanguage]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  SecondLanguage copyWith({
    String? code,
    String? name,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SecondLanguage',
      'code': code,
      'name': name,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SecondLanguage',
      'code': code,
      'name': name,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _SecondLanguageImpl extends SecondLanguage {
  _SecondLanguageImpl({
    required String code,
    required String name,
  }) : super._(
         code: code,
         name: name,
       );

  /// Returns a shallow copy of this [SecondLanguage]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  SecondLanguage copyWith({
    String? code,
    String? name,
  }) {
    return SecondLanguage(
      code: code ?? this.code,
      name: name ?? this.name,
    );
  }
}
