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
import '../circles/circle_role.dart' as _ihm6sz5o;

/// One adult in a circle, as shown to the other members.
abstract class MemberInfo
    implements _is.SerializableModel, _is.ProtocolSerialization {
  MemberInfo._({
    required this.userId,
    required this.displayName,
    required this.role,
  });

  factory MemberInfo({
    required _is.UuidValue userId,
    required String displayName,
    required _ihm6sz5o.CircleRole role,
  }) = _MemberInfoImpl;

  factory MemberInfo.fromJson(Map<String, dynamic> jsonSerialization) {
    return MemberInfo(
      userId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      displayName: jsonSerialization['displayName'] as String,
      role: _ihm6sz5o.CircleRole.fromJson(
        (jsonSerialization['role'] as String),
      ),
    );
  }

  _is.UuidValue userId;

  String displayName;

  _ihm6sz5o.CircleRole role;

  /// Returns a shallow copy of this [MemberInfo]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  MemberInfo copyWith({
    _is.UuidValue? userId,
    String? displayName,
    _ihm6sz5o.CircleRole? role,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MemberInfo',
      'userId': userId.toJson(),
      'displayName': displayName,
      'role': role.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MemberInfo',
      'userId': userId.toJson(),
      'displayName': displayName,
      'role': role.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _MemberInfoImpl extends MemberInfo {
  _MemberInfoImpl({
    required _is.UuidValue userId,
    required String displayName,
    required _ihm6sz5o.CircleRole role,
  }) : super._(
         userId: userId,
         displayName: displayName,
         role: role,
       );

  /// Returns a shallow copy of this [MemberInfo]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  MemberInfo copyWith({
    _is.UuidValue? userId,
    String? displayName,
    _ihm6sz5o.CircleRole? role,
  }) {
    return MemberInfo(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
    );
  }
}
