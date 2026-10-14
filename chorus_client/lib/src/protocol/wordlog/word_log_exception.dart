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
import '../wordlog/word_log_failure.dart' as _il93n8mw;

/// Sent to the client when words are refused by the word log.
abstract class WordLogException
    implements
        _isc.SerializableException,
        _isc.SerializableModel,
        _isc.ProtocolSerialization {
  WordLogException._({required this.failure});

  factory WordLogException({required _il93n8mw.WordLogFailure failure}) =
      _WordLogExceptionImpl;

  factory WordLogException.fromJson(Map<String, dynamic> jsonSerialization) {
    return WordLogException(
      failure: _il93n8mw.WordLogFailure.fromJson(
        (jsonSerialization['failure'] as String),
      ),
    );
  }

  _il93n8mw.WordLogFailure failure;

  /// Returns a shallow copy of this [WordLogException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  WordLogException copyWith({_il93n8mw.WordLogFailure? failure});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WordLogException',
      'failure': failure.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WordLogException',
      'failure': failure.toJson(),
    };
  }

  @override
  String toString() {
    return 'WordLogException(failure: $failure)';
  }
}

class _WordLogExceptionImpl extends WordLogException {
  _WordLogExceptionImpl({required _il93n8mw.WordLogFailure failure})
    : super._(failure: failure);

  /// Returns a shallow copy of this [WordLogException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  WordLogException copyWith({_il93n8mw.WordLogFailure? failure}) {
    return WordLogException(failure: failure ?? this.failure);
  }
}
