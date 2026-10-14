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

/// One spoken word as the child's device sends it to the word log: the
/// tile, its board and the time. No label, no sentence.
abstract class WordUseEntry
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  WordUseEntry._({
    required this.tileId,
    required this.boardId,
    required this.spokenAt,
  });

  factory WordUseEntry({
    required _isc.UuidValue tileId,
    required _isc.UuidValue boardId,
    required DateTime spokenAt,
  }) = _WordUseEntryImpl;

  factory WordUseEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return WordUseEntry(
      tileId: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['tileId']),
      boardId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['boardId'],
      ),
      spokenAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['spokenAt'],
      ),
    );
  }

  _isc.UuidValue tileId;

  _isc.UuidValue boardId;

  DateTime spokenAt;

  /// Returns a shallow copy of this [WordUseEntry]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  WordUseEntry copyWith({
    _isc.UuidValue? tileId,
    _isc.UuidValue? boardId,
    DateTime? spokenAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WordUseEntry',
      'tileId': tileId.toJson(),
      'boardId': boardId.toJson(),
      'spokenAt': spokenAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WordUseEntry',
      'tileId': tileId.toJson(),
      'boardId': boardId.toJson(),
      'spokenAt': spokenAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _WordUseEntryImpl extends WordUseEntry {
  _WordUseEntryImpl({
    required _isc.UuidValue tileId,
    required _isc.UuidValue boardId,
    required DateTime spokenAt,
  }) : super._(
         tileId: tileId,
         boardId: boardId,
         spokenAt: spokenAt,
       );

  /// Returns a shallow copy of this [WordUseEntry]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  WordUseEntry copyWith({
    _isc.UuidValue? tileId,
    _isc.UuidValue? boardId,
    DateTime? spokenAt,
  }) {
    return WordUseEntry(
      tileId: tileId ?? this.tileId,
      boardId: boardId ?? this.boardId,
      spokenAt: spokenAt ?? this.spokenAt,
    );
  }
}
