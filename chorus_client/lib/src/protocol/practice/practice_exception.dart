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
import '../practice/practice_failure.dart' as _i8dqmmuq;

/// Sent to the client when the practice partner cannot add its word.
abstract class PracticeException
    implements
        _isc.SerializableException,
        _isc.SerializableModel,
        _isc.ProtocolSerialization {
  PracticeException._({required this.failure});

  factory PracticeException({required _i8dqmmuq.PracticeFailure failure}) =
      _PracticeExceptionImpl;

  factory PracticeException.fromJson(Map<String, dynamic> jsonSerialization) {
    return PracticeException(
      failure: _i8dqmmuq.PracticeFailure.fromJson(
        (jsonSerialization['failure'] as String),
      ),
    );
  }

  _i8dqmmuq.PracticeFailure failure;

  /// Returns a shallow copy of this [PracticeException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  PracticeException copyWith({_i8dqmmuq.PracticeFailure? failure});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PracticeException',
      'failure': failure.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PracticeException',
      'failure': failure.toJson(),
    };
  }

  @override
  String toString() {
    return 'PracticeException(failure: $failure)';
  }
}

class _PracticeExceptionImpl extends PracticeException {
  _PracticeExceptionImpl({required _i8dqmmuq.PracticeFailure failure})
    : super._(failure: failure);

  /// Returns a shallow copy of this [PracticeException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  PracticeException copyWith({_i8dqmmuq.PracticeFailure? failure}) {
    return PracticeException(failure: failure ?? this.failure);
  }
}
