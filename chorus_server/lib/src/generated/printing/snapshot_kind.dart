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

/// What a stored board snapshot is for.
enum SnapshotKind implements _is.SerializableModel {
  /// A paper copy, at `/print/<token>`.
  print,

  /// A page that speaks, for someone outside the circle, at `/b/<token>`.
  viewOnly;

  static SnapshotKind fromJson(String name) {
    switch (name) {
      case 'print':
        return SnapshotKind.print;
      case 'viewOnly':
        return SnapshotKind.viewOnly;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "SnapshotKind"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
