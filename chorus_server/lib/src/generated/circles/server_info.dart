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

/// What a client needs before it starts syncing.
abstract class ServerInfo
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ServerInfo._({
    required this.serverTime,
    required this.minBuild,
  });

  factory ServerInfo({
    required DateTime serverTime,
    required int minBuild,
  }) = _ServerInfoImpl;

  factory ServerInfo.fromJson(Map<String, dynamic> jsonSerialization) {
    return ServerInfo(
      serverTime: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['serverTime'],
      ),
      minBuild: jsonSerialization['minBuild'] as int,
    );
  }

  /// The server's clock. The sync engine refuses changes stamped more than a
  /// minute ahead, so the app compares this with the device clock first.
  DateTime serverTime;

  /// Clients older than this build must update before syncing.
  int minBuild;

  /// Returns a shallow copy of this [ServerInfo]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ServerInfo copyWith({
    DateTime? serverTime,
    int? minBuild,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ServerInfo',
      'serverTime': serverTime.toJson(),
      'minBuild': minBuild,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ServerInfo',
      'serverTime': serverTime.toJson(),
      'minBuild': minBuild,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _ServerInfoImpl extends ServerInfo {
  _ServerInfoImpl({
    required DateTime serverTime,
    required int minBuild,
  }) : super._(
         serverTime: serverTime,
         minBuild: minBuild,
       );

  /// Returns a shallow copy of this [ServerInfo]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ServerInfo copyWith({
    DateTime? serverTime,
    int? minBuild,
  }) {
    return ServerInfo(
      serverTime: serverTime ?? this.serverTime,
      minBuild: minBuild ?? this.minBuild,
    );
  }
}
