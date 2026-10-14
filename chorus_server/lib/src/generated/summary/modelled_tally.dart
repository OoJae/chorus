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

/// One word in a week: how often an adult modelled it ("Show words on the
/// board") and how often the child said it.
abstract class ModelledTally
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ModelledTally._({
    required this.label,
    required this.modelled,
    required this.said,
  });

  factory ModelledTally({
    required String label,
    required int modelled,
    required int said,
  }) = _ModelledTallyImpl;

  factory ModelledTally.fromJson(Map<String, dynamic> jsonSerialization) {
    return ModelledTally(
      label: jsonSerialization['label'] as String,
      modelled: jsonSerialization['modelled'] as int,
      said: jsonSerialization['said'] as int,
    );
  }

  String label;

  int modelled;

  int said;

  /// Returns a shallow copy of this [ModelledTally]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ModelledTally copyWith({
    String? label,
    int? modelled,
    int? said,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ModelledTally',
      'label': label,
      'modelled': modelled,
      'said': said,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ModelledTally',
      'label': label,
      'modelled': modelled,
      'said': said,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _ModelledTallyImpl extends ModelledTally {
  _ModelledTallyImpl({
    required String label,
    required int modelled,
    required int said,
  }) : super._(
         label: label,
         modelled: modelled,
         said: said,
       );

  /// Returns a shallow copy of this [ModelledTally]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ModelledTally copyWith({
    String? label,
    int? modelled,
    int? said,
  }) {
    return ModelledTally(
      label: label ?? this.label,
      modelled: modelled ?? this.modelled,
      said: said ?? this.said,
    );
  }
}
