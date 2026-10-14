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

/// The word the practice partner put on the board, for "Try a clash".
abstract class PracticeWord
    implements _is.SerializableModel, _is.ProtocolSerialization {
  PracticeWord._({
    required this.tileId,
    required this.label,
    required this.cellKey,
    required this.partnerName,
  });

  factory PracticeWord({
    required _is.UuidValue tileId,
    required String label,
    required String cellKey,
    required String partnerName,
  }) = _PracticeWordImpl;

  factory PracticeWord.fromJson(Map<String, dynamic> jsonSerialization) {
    return PracticeWord(
      tileId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['tileId']),
      label: jsonSerialization['label'] as String,
      cellKey: jsonSerialization['cellKey'] as String,
      partnerName: jsonSerialization['partnerName'] as String,
    );
  }

  /// The partner's new tile.
  _is.UuidValue tileId;

  String label;

  /// The cell it was put in, as `<boardId>:<row>:<col>`.
  String cellKey;

  /// How the partner is named on every device.
  String partnerName;

  /// Returns a shallow copy of this [PracticeWord]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PracticeWord copyWith({
    _is.UuidValue? tileId,
    String? label,
    String? cellKey,
    String? partnerName,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PracticeWord',
      'tileId': tileId.toJson(),
      'label': label,
      'cellKey': cellKey,
      'partnerName': partnerName,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PracticeWord',
      'tileId': tileId.toJson(),
      'label': label,
      'cellKey': cellKey,
      'partnerName': partnerName,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _PracticeWordImpl extends PracticeWord {
  _PracticeWordImpl({
    required _is.UuidValue tileId,
    required String label,
    required String cellKey,
    required String partnerName,
  }) : super._(
         tileId: tileId,
         label: label,
         cellKey: cellKey,
         partnerName: partnerName,
       );

  /// Returns a shallow copy of this [PracticeWord]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PracticeWord copyWith({
    _is.UuidValue? tileId,
    String? label,
    String? cellKey,
    String? partnerName,
  }) {
    return PracticeWord(
      tileId: tileId ?? this.tileId,
      label: label ?? this.label,
      cellKey: cellKey ?? this.cellKey,
      partnerName: partnerName ?? this.partnerName,
    );
  }
}
