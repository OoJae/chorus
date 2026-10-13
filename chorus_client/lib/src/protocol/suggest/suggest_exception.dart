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
import '../suggest/suggest_failure.dart' as _isym1twt;

/// Sent to the client when a suggestion request is refused or fails.
abstract class SuggestException
    implements
        _isc.SerializableException,
        _isc.SerializableModel,
        _isc.ProtocolSerialization {
  SuggestException._({required this.failure});

  factory SuggestException({required _isym1twt.SuggestFailure failure}) =
      _SuggestExceptionImpl;

  factory SuggestException.fromJson(Map<String, dynamic> jsonSerialization) {
    return SuggestException(
      failure: _isym1twt.SuggestFailure.fromJson(
        (jsonSerialization['failure'] as String),
      ),
    );
  }

  _isym1twt.SuggestFailure failure;

  /// Returns a shallow copy of this [SuggestException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  SuggestException copyWith({_isym1twt.SuggestFailure? failure});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SuggestException',
      'failure': failure.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SuggestException',
      'failure': failure.toJson(),
    };
  }

  @override
  String toString() {
    return 'SuggestException(failure: $failure)';
  }
}

class _SuggestExceptionImpl extends SuggestException {
  _SuggestExceptionImpl({required _isym1twt.SuggestFailure failure})
    : super._(failure: failure);

  /// Returns a shallow copy of this [SuggestException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  SuggestException copyWith({_isym1twt.SuggestFailure? failure}) {
    return SuggestException(failure: failure ?? this.failure);
  }
}
