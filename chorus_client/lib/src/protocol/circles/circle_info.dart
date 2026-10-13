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
import '../circles/circle_role.dart' as _ihm6sz5o;
import '../circles/member_info.dart' as _iyhy3baj;

/// A circle as the signed-in adult sees it.
abstract class CircleInfo
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  CircleInfo._({
    required this.spaceUuid,
    required this.childName,
    required this.myRole,
    required this.myDisplayName,
    required this.members,
  });

  factory CircleInfo({
    required _isc.UuidValue spaceUuid,
    required String childName,
    required _ihm6sz5o.CircleRole myRole,
    required String myDisplayName,
    required List<_iyhy3baj.MemberInfo> members,
  }) = _CircleInfoImpl;

  factory CircleInfo.fromJson(Map<String, dynamic> jsonSerialization) {
    return CircleInfo(
      spaceUuid: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['spaceUuid'],
      ),
      childName: jsonSerialization['childName'] as String,
      myRole: _ihm6sz5o.CircleRole.fromJson(
        (jsonSerialization['myRole'] as String),
      ),
      myDisplayName: jsonSerialization['myDisplayName'] as String,
      members: _iuvo7w6p.Protocol().deserialize<List<_iyhy3baj.MemberInfo>>(
        jsonSerialization['members'],
      ),
    );
  }

  /// UUID of the circle's sync space; pass it as `spaceId` when writing.
  _isc.UuidValue spaceUuid;

  String childName;

  _ihm6sz5o.CircleRole myRole;

  String myDisplayName;

  List<_iyhy3baj.MemberInfo> members;

  /// Returns a shallow copy of this [CircleInfo]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  CircleInfo copyWith({
    _isc.UuidValue? spaceUuid,
    String? childName,
    _ihm6sz5o.CircleRole? myRole,
    String? myDisplayName,
    List<_iyhy3baj.MemberInfo>? members,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CircleInfo',
      'spaceUuid': spaceUuid.toJson(),
      'childName': childName,
      'myRole': myRole.toJson(),
      'myDisplayName': myDisplayName,
      'members': members.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CircleInfo',
      'spaceUuid': spaceUuid.toJson(),
      'childName': childName,
      'myRole': myRole.toJson(),
      'myDisplayName': myDisplayName,
      'members': members.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _CircleInfoImpl extends CircleInfo {
  _CircleInfoImpl({
    required _isc.UuidValue spaceUuid,
    required String childName,
    required _ihm6sz5o.CircleRole myRole,
    required String myDisplayName,
    required List<_iyhy3baj.MemberInfo> members,
  }) : super._(
         spaceUuid: spaceUuid,
         childName: childName,
         myRole: myRole,
         myDisplayName: myDisplayName,
         members: members,
       );

  /// Returns a shallow copy of this [CircleInfo]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  CircleInfo copyWith({
    _isc.UuidValue? spaceUuid,
    String? childName,
    _ihm6sz5o.CircleRole? myRole,
    String? myDisplayName,
    List<_iyhy3baj.MemberInfo>? members,
  }) {
    return CircleInfo(
      spaceUuid: spaceUuid ?? this.spaceUuid,
      childName: childName ?? this.childName,
      myRole: myRole ?? this.myRole,
      myDisplayName: myDisplayName ?? this.myDisplayName,
      members: members ?? this.members.map((e0) => e0.copyWith()).toList(),
    );
  }
}
