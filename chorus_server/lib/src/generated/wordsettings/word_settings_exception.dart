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
import 'package:serverpod/serverpod.dart' as _is;

/// Refusal from the hidden words and second language endpoints.
abstract class WordSettingsException
    implements
        _is.SerializableException,
        _is.SerializableModel,
        _is.ProtocolSerialization {
  WordSettingsException._({required this.reason});

  factory WordSettingsException({required String reason}) =
      _WordSettingsExceptionImpl;

  factory WordSettingsException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WordSettingsException(reason: jsonSerialization['reason'] as String);
  }

  /// What was wrong with the request, in words for a log.
  String reason;

  /// Returns a shallow copy of this [WordSettingsException]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WordSettingsException copyWith({String? reason});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WordSettingsException',
      'reason': reason,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WordSettingsException',
      'reason': reason,
    };
  }

  @override
  String toString() {
    return 'WordSettingsException(reason: $reason)';
  }
}

class _WordSettingsExceptionImpl extends WordSettingsException {
  _WordSettingsExceptionImpl({required String reason})
    : super._(reason: reason);

  /// Returns a shallow copy of this [WordSettingsException]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WordSettingsException copyWith({String? reason}) {
    return WordSettingsException(reason: reason ?? this.reason);
  }
}
