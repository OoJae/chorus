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

/// Why words were not added to the log. Nothing of the call was kept.
enum WordLogFailure implements _is.SerializableModel {
  /// The circle's log is off. The device should drop what it holds.
  off,

  /// More than 200 words in one call.
  tooMany,

  /// A time more than five minutes ahead, or more than 30 days ago.
  badTime,

  /// A tile the server does not know in this circle, perhaps not synced
  /// yet. Worth sending again later.
  unknownTile;

  static WordLogFailure fromJson(String name) {
    switch (name) {
      case 'off':
        return WordLogFailure.off;
      case 'tooMany':
        return WordLogFailure.tooMany;
      case 'badTime':
        return WordLogFailure.badTime;
      case 'unknownTile':
        return WordLogFailure.unknownTile;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "WordLogFailure"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
