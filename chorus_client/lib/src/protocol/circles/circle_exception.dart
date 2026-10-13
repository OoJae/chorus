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
import '../circles/circle_failure.dart' as _idwrg59z;

/// Sent to the client when a circle request is refused.
abstract class CircleException
    implements
        _isc.SerializableException,
        _isc.SerializableModel,
        _isc.ProtocolSerialization {
  CircleException._({required this.failure});

  factory CircleException({required _idwrg59z.CircleFailure failure}) =
      _CircleExceptionImpl;

  factory CircleException.fromJson(Map<String, dynamic> jsonSerialization) {
    return CircleException(
      failure: _idwrg59z.CircleFailure.fromJson(
        (jsonSerialization['failure'] as String),
      ),
    );
  }

  _idwrg59z.CircleFailure failure;

  /// Returns a shallow copy of this [CircleException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  CircleException copyWith({_idwrg59z.CircleFailure? failure});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CircleException',
      'failure': failure.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CircleException',
      'failure': failure.toJson(),
    };
  }

  @override
  String toString() {
    return 'CircleException(failure: $failure)';
  }
}

class _CircleExceptionImpl extends CircleException {
  _CircleExceptionImpl({required _idwrg59z.CircleFailure failure})
    : super._(failure: failure);

  /// Returns a shallow copy of this [CircleException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  CircleException copyWith({_idwrg59z.CircleFailure? failure}) {
    return CircleException(failure: failure ?? this.failure);
  }
}
