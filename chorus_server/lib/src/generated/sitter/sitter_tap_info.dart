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

/// A word a sitter tapped, as the circle's feed shows it.
abstract class SitterTapInfo
    implements _is.SerializableModel, _is.ProtocolSerialization {
  SitterTapInfo._({
    required this.label,
    required this.tappedAt,
  });

  factory SitterTapInfo({
    required String label,
    required DateTime tappedAt,
  }) = _SitterTapInfoImpl;

  factory SitterTapInfo.fromJson(Map<String, dynamic> jsonSerialization) {
    return SitterTapInfo(
      label: jsonSerialization['label'] as String,
      tappedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['tappedAt'],
      ),
    );
  }

  String label;

  DateTime tappedAt;

  /// Returns a shallow copy of this [SitterTapInfo]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  SitterTapInfo copyWith({
    String? label,
    DateTime? tappedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SitterTapInfo',
      'label': label,
      'tappedAt': tappedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SitterTapInfo',
      'label': label,
      'tappedAt': tappedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _SitterTapInfoImpl extends SitterTapInfo {
  _SitterTapInfoImpl({
    required String label,
    required DateTime tappedAt,
  }) : super._(
         label: label,
         tappedAt: tappedAt,
       );

  /// Returns a shallow copy of this [SitterTapInfo]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  SitterTapInfo copyWith({
    String? label,
    DateTime? tappedAt,
  }) {
    return SitterTapInfo(
      label: label ?? this.label,
      tappedAt: tappedAt ?? this.tappedAt,
    );
  }
}
