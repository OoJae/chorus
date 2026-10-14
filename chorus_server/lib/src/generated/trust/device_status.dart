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

/// One member's device, as "Who is up to date" shows it.
abstract class DeviceStatus
    implements _is.SerializableModel, _is.ProtocolSerialization {
  DeviceStatus._({
    required this.userId,
    required this.userName,
    required this.deviceId,
    required this.deviceLabel,
    required this.lastSyncAt,
    required this.lastSeenAt,
  });

  factory DeviceStatus({
    required _is.UuidValue userId,
    required String userName,
    required String deviceId,
    required String deviceLabel,
    required DateTime lastSyncAt,
    required DateTime lastSeenAt,
  }) = _DeviceStatusImpl;

  factory DeviceStatus.fromJson(Map<String, dynamic> jsonSerialization) {
    return DeviceStatus(
      userId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      userName: jsonSerialization['userName'] as String,
      deviceId: jsonSerialization['deviceId'] as String,
      deviceLabel: jsonSerialization['deviceLabel'] as String,
      lastSyncAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastSyncAt'],
      ),
      lastSeenAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastSeenAt'],
      ),
    );
  }

  _is.UuidValue userId;

  String userName;

  String deviceId;

  String deviceLabel;

  DateTime lastSyncAt;

  DateTime lastSeenAt;

  /// Returns a shallow copy of this [DeviceStatus]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DeviceStatus copyWith({
    _is.UuidValue? userId,
    String? userName,
    String? deviceId,
    String? deviceLabel,
    DateTime? lastSyncAt,
    DateTime? lastSeenAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeviceStatus',
      'userId': userId.toJson(),
      'userName': userName,
      'deviceId': deviceId,
      'deviceLabel': deviceLabel,
      'lastSyncAt': lastSyncAt.toJson(),
      'lastSeenAt': lastSeenAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DeviceStatus',
      'userId': userId.toJson(),
      'userName': userName,
      'deviceId': deviceId,
      'deviceLabel': deviceLabel,
      'lastSyncAt': lastSyncAt.toJson(),
      'lastSeenAt': lastSeenAt.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _DeviceStatusImpl extends DeviceStatus {
  _DeviceStatusImpl({
    required _is.UuidValue userId,
    required String userName,
    required String deviceId,
    required String deviceLabel,
    required DateTime lastSyncAt,
    required DateTime lastSeenAt,
  }) : super._(
         userId: userId,
         userName: userName,
         deviceId: deviceId,
         deviceLabel: deviceLabel,
         lastSyncAt: lastSyncAt,
         lastSeenAt: lastSeenAt,
       );

  /// Returns a shallow copy of this [DeviceStatus]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DeviceStatus copyWith({
    _is.UuidValue? userId,
    String? userName,
    String? deviceId,
    String? deviceLabel,
    DateTime? lastSyncAt,
    DateTime? lastSeenAt,
  }) {
    return DeviceStatus(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      deviceId: deviceId ?? this.deviceId,
      deviceLabel: deviceLabel ?? this.deviceLabel,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}
