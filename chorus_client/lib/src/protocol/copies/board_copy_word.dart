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

/// One word of a board copy, as its tile was when the copy was taken.
abstract class BoardCopyWord
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  BoardCopyWord._({
    required this.label,
    this.speech,
    this.colorKey,
    this.imageHash,
    required this.cellKey,
  });

  factory BoardCopyWord({
    required String label,
    String? speech,
    String? colorKey,
    String? imageHash,
    required String cellKey,
  }) = _BoardCopyWordImpl;

  factory BoardCopyWord.fromJson(Map<String, dynamic> jsonSerialization) {
    return BoardCopyWord(
      label: jsonSerialization['label'] as String,
      speech: jsonSerialization['speech'] as String?,
      colorKey: jsonSerialization['colorKey'] as String?,
      imageHash: jsonSerialization['imageHash'] as String?,
      cellKey: jsonSerialization['cellKey'] as String,
    );
  }

  String label;

  String? speech;

  String? colorKey;

  String? imageHash;

  /// The cell it held: `<boardId>:<row>:<col>`.
  String cellKey;

  /// Returns a shallow copy of this [BoardCopyWord]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  BoardCopyWord copyWith({
    String? label,
    String? speech,
    String? colorKey,
    String? imageHash,
    String? cellKey,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BoardCopyWord',
      'label': label,
      if (speech != null) 'speech': speech,
      if (colorKey != null) 'colorKey': colorKey,
      if (imageHash != null) 'imageHash': imageHash,
      'cellKey': cellKey,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'BoardCopyWord',
      'label': label,
      if (speech != null) 'speech': speech,
      if (colorKey != null) 'colorKey': colorKey,
      if (imageHash != null) 'imageHash': imageHash,
      'cellKey': cellKey,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BoardCopyWordImpl extends BoardCopyWord {
  _BoardCopyWordImpl({
    required String label,
    String? speech,
    String? colorKey,
    String? imageHash,
    required String cellKey,
  }) : super._(
         label: label,
         speech: speech,
         colorKey: colorKey,
         imageHash: imageHash,
         cellKey: cellKey,
       );

  /// Returns a shallow copy of this [BoardCopyWord]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  BoardCopyWord copyWith({
    String? label,
    Object? speech = _Undefined,
    Object? colorKey = _Undefined,
    Object? imageHash = _Undefined,
    String? cellKey,
  }) {
    return BoardCopyWord(
      label: label ?? this.label,
      speech: speech is String? ? speech : this.speech,
      colorKey: colorKey is String? ? colorKey : this.colorKey,
      imageHash: imageHash is String? ? imageHash : this.imageHash,
      cellKey: cellKey ?? this.cellKey,
    );
  }
}
