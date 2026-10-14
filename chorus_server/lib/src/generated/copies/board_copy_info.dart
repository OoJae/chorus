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
import 'package:chorus_server/src/generated/protocol.dart' as _iq1qvsxu;
import 'package:serverpod/serverpod.dart' as _is;
import '../copies/board_copy_word.dart' as _ivdpg0kb;

/// A board copy as the app sees it. [words] is empty in a list and filled
/// by `get`.
abstract class BoardCopyInfo
    implements _is.SerializableModel, _is.ProtocolSerialization {
  BoardCopyInfo._({
    required this.id,
    required this.boardId,
    required this.boardName,
    required this.rows,
    required this.cols,
    required this.name,
    required this.takenByName,
    required this.takenAt,
    required this.wordCount,
    required this.words,
  });

  factory BoardCopyInfo({
    required int id,
    required _is.UuidValue boardId,
    required String boardName,
    required int rows,
    required int cols,
    required String name,
    required String takenByName,
    required DateTime takenAt,
    required int wordCount,
    required List<_ivdpg0kb.BoardCopyWord> words,
  }) = _BoardCopyInfoImpl;

  factory BoardCopyInfo.fromJson(Map<String, dynamic> jsonSerialization) {
    return BoardCopyInfo(
      id: jsonSerialization['id'] as int,
      boardId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['boardId'],
      ),
      boardName: jsonSerialization['boardName'] as String,
      rows: jsonSerialization['rows'] as int,
      cols: jsonSerialization['cols'] as int,
      name: jsonSerialization['name'] as String,
      takenByName: jsonSerialization['takenByName'] as String,
      takenAt: _is.DateTimeJsonExtension.fromJson(jsonSerialization['takenAt']),
      wordCount: jsonSerialization['wordCount'] as int,
      words: _iq1qvsxu.Protocol().deserialize<List<_ivdpg0kb.BoardCopyWord>>(
        jsonSerialization['words'],
      ),
    );
  }

  int id;

  _is.UuidValue boardId;

  String boardName;

  int rows;

  int cols;

  String name;

  String takenByName;

  DateTime takenAt;

  int wordCount;

  List<_ivdpg0kb.BoardCopyWord> words;

  /// Returns a shallow copy of this [BoardCopyInfo]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  BoardCopyInfo copyWith({
    int? id,
    _is.UuidValue? boardId,
    String? boardName,
    int? rows,
    int? cols,
    String? name,
    String? takenByName,
    DateTime? takenAt,
    int? wordCount,
    List<_ivdpg0kb.BoardCopyWord>? words,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BoardCopyInfo',
      'id': id,
      'boardId': boardId.toJson(),
      'boardName': boardName,
      'rows': rows,
      'cols': cols,
      'name': name,
      'takenByName': takenByName,
      'takenAt': takenAt.toJson(),
      'wordCount': wordCount,
      'words': words.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'BoardCopyInfo',
      'id': id,
      'boardId': boardId.toJson(),
      'boardName': boardName,
      'rows': rows,
      'cols': cols,
      'name': name,
      'takenByName': takenByName,
      'takenAt': takenAt.toJson(),
      'wordCount': wordCount,
      'words': words.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _BoardCopyInfoImpl extends BoardCopyInfo {
  _BoardCopyInfoImpl({
    required int id,
    required _is.UuidValue boardId,
    required String boardName,
    required int rows,
    required int cols,
    required String name,
    required String takenByName,
    required DateTime takenAt,
    required int wordCount,
    required List<_ivdpg0kb.BoardCopyWord> words,
  }) : super._(
         id: id,
         boardId: boardId,
         boardName: boardName,
         rows: rows,
         cols: cols,
         name: name,
         takenByName: takenByName,
         takenAt: takenAt,
         wordCount: wordCount,
         words: words,
       );

  /// Returns a shallow copy of this [BoardCopyInfo]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  BoardCopyInfo copyWith({
    int? id,
    _is.UuidValue? boardId,
    String? boardName,
    int? rows,
    int? cols,
    String? name,
    String? takenByName,
    DateTime? takenAt,
    int? wordCount,
    List<_ivdpg0kb.BoardCopyWord>? words,
  }) {
    return BoardCopyInfo(
      id: id ?? this.id,
      boardId: boardId ?? this.boardId,
      boardName: boardName ?? this.boardName,
      rows: rows ?? this.rows,
      cols: cols ?? this.cols,
      name: name ?? this.name,
      takenByName: takenByName ?? this.takenByName,
      takenAt: takenAt ?? this.takenAt,
      wordCount: wordCount ?? this.wordCount,
      words: words ?? this.words.map((e0) => e0.copyWith()).toList(),
    );
  }
}
