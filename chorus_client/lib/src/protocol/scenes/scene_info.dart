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
import 'package:chorus_client/src/protocol/protocol.dart' as _iuvo7w6p;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import '../scenes/scene_spot_info.dart' as _in70irsi;

/// A scene as the app sees it, with its spots.
abstract class SceneInfo
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  SceneInfo._({
    required this.id,
    required this.name,
    required this.imageHash,
    required this.createdAt,
    required this.spots,
  });

  factory SceneInfo({
    required int id,
    required String name,
    required String imageHash,
    required DateTime createdAt,
    required List<_in70irsi.SceneSpotInfo> spots,
  }) = _SceneInfoImpl;

  factory SceneInfo.fromJson(Map<String, dynamic> jsonSerialization) {
    return SceneInfo(
      id: jsonSerialization['id'] as int,
      name: jsonSerialization['name'] as String,
      imageHash: jsonSerialization['imageHash'] as String,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      spots: _iuvo7w6p.Protocol().deserialize<List<_in70irsi.SceneSpotInfo>>(
        jsonSerialization['spots'],
      ),
    );
  }

  int id;

  String name;

  String imageHash;

  DateTime createdAt;

  List<_in70irsi.SceneSpotInfo> spots;

  /// Returns a shallow copy of this [SceneInfo]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  SceneInfo copyWith({
    int? id,
    String? name,
    String? imageHash,
    DateTime? createdAt,
    List<_in70irsi.SceneSpotInfo>? spots,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SceneInfo',
      'id': id,
      'name': name,
      'imageHash': imageHash,
      'createdAt': createdAt.toJson(),
      'spots': spots.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SceneInfo',
      'id': id,
      'name': name,
      'imageHash': imageHash,
      'createdAt': createdAt.toJson(),
      'spots': spots.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _SceneInfoImpl extends SceneInfo {
  _SceneInfoImpl({
    required int id,
    required String name,
    required String imageHash,
    required DateTime createdAt,
    required List<_in70irsi.SceneSpotInfo> spots,
  }) : super._(
         id: id,
         name: name,
         imageHash: imageHash,
         createdAt: createdAt,
         spots: spots,
       );

  /// Returns a shallow copy of this [SceneInfo]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  SceneInfo copyWith({
    int? id,
    String? name,
    String? imageHash,
    DateTime? createdAt,
    List<_in70irsi.SceneSpotInfo>? spots,
  }) {
    return SceneInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      imageHash: imageHash ?? this.imageHash,
      createdAt: createdAt ?? this.createdAt,
      spots: spots ?? this.spots.map((e0) => e0.copyWith()).toList(),
    );
  }
}
