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

/// One member's device, as "Who is up to date" shows it.
abstract class DeviceStatus
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  DeviceStatus._({
    required this.userId,
    required this.userName,
    required this.deviceId,
    required this.deviceLabel,
    required this.lastSyncAt,
    required this.lastSeenAt,
  });

  factory DeviceStatus({
    required _isc.UuidValue userId,
    required String userName,
    required String deviceId,
    required String deviceLabel,
    required DateTime lastSyncAt,
    required DateTime lastSeenAt,
  }) = _DeviceStatusImpl;

  factory DeviceStatus.fromJson(Map<String, dynamic> jsonSerialization) {
    return DeviceStatus(
      userId: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      userName: jsonSerialization['userName'] as String,
      deviceId: jsonSerialization['deviceId'] as String,
      deviceLabel: jsonSerialization['deviceLabel'] as String,
      lastSyncAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastSyncAt'],
      ),
      lastSeenAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastSeenAt'],
      ),
    );
  }

  _isc.UuidValue userId;

  String userName;

  String deviceId;

  String deviceLabel;

  DateTime lastSyncAt;

  DateTime lastSeenAt;

  /// Returns a shallow copy of this [DeviceStatus]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  DeviceStatus copyWith({
    _isc.UuidValue? userId,
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
    return _isc.SerializationManager.encode(this);
  }
}

class _DeviceStatusImpl extends DeviceStatus {
  _DeviceStatusImpl({
    required _isc.UuidValue userId,
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
  @_isc.useResult
  @override
  DeviceStatus copyWith({
    _isc.UuidValue? userId,
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
