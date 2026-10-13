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

/// What a live event tells the other members of a circle.
enum LiveKind implements _is.SerializableModel {
  /// An adult tapped a tile; it glows on the other devices.
  pulse,

  /// The child's device said something. Sent only while a guardian has
  /// turned sharing on.
  said,

  /// A member joined or is still here.
  presence;

  static LiveKind fromJson(String name) {
    switch (name) {
      case 'pulse':
        return LiveKind.pulse;
      case 'said':
        return LiveKind.said;
      case 'presence':
        return LiveKind.presence;
      default:
        throw ArgumentError('Value "$name" cannot be converted to "LiveKind"');
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
