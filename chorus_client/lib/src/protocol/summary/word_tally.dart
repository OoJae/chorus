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

/// One word and how many times it was spoken in a week.
abstract class WordTally
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  WordTally._({
    required this.label,
    required this.count,
  });

  factory WordTally({
    required String label,
    required int count,
  }) = _WordTallyImpl;

  factory WordTally.fromJson(Map<String, dynamic> jsonSerialization) {
    return WordTally(
      label: jsonSerialization['label'] as String,
      count: jsonSerialization['count'] as int,
    );
  }

  String label;

  int count;

  /// Returns a shallow copy of this [WordTally]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  WordTally copyWith({
    String? label,
    int? count,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WordTally',
      'label': label,
      'count': count,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WordTally',
      'label': label,
      'count': count,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _WordTallyImpl extends WordTally {
  _WordTallyImpl({
    required String label,
    required int count,
  }) : super._(
         label: label,
         count: count,
       );

  /// Returns a shallow copy of this [WordTally]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  WordTally copyWith({
    String? label,
    int? count,
  }) {
    return WordTally(
      label: label ?? this.label,
      count: count ?? this.count,
    );
  }
}
