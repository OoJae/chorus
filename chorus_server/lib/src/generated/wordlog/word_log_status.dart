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

/// Whether a circle keeps a word log, as one member sees it.
abstract class WordLogStatus
    implements _is.SerializableModel, _is.ProtocolSerialization {
  WordLogStatus._({
    required this.enabled,
    required this.canChange,
  });

  factory WordLogStatus({
    required bool enabled,
    required bool canChange,
  }) = _WordLogStatusImpl;

  factory WordLogStatus.fromJson(Map<String, dynamic> jsonSerialization) {
    return WordLogStatus(
      enabled: _is.BoolJsonExtension.fromJson(jsonSerialization['enabled']),
      canChange: _is.BoolJsonExtension.fromJson(jsonSerialization['canChange']),
    );
  }

  bool enabled;

  /// True when the caller may turn the log on or off and delete it: a
  /// guardian.
  bool canChange;

  /// Returns a shallow copy of this [WordLogStatus]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WordLogStatus copyWith({
    bool? enabled,
    bool? canChange,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WordLogStatus',
      'enabled': enabled,
      'canChange': canChange,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WordLogStatus',
      'enabled': enabled,
      'canChange': canChange,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _WordLogStatusImpl extends WordLogStatus {
  _WordLogStatusImpl({
    required bool enabled,
    required bool canChange,
  }) : super._(
         enabled: enabled,
         canChange: canChange,
       );

  /// Returns a shallow copy of this [WordLogStatus]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WordLogStatus copyWith({
    bool? enabled,
    bool? canChange,
  }) {
    return WordLogStatus(
      enabled: enabled ?? this.enabled,
      canChange: canChange ?? this.canChange,
    );
  }
}
