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

/// A spot of a scene as the app sends and sees it: a rectangle in
/// fractions (0 to 1) of the photo, and the word it says.
abstract class SceneSpotInfo
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  SceneSpotInfo._({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.label,
    this.speech,
  });

  factory SceneSpotInfo({
    required double x,
    required double y,
    required double width,
    required double height,
    required String label,
    String? speech,
  }) = _SceneSpotInfoImpl;

  factory SceneSpotInfo.fromJson(Map<String, dynamic> jsonSerialization) {
    return SceneSpotInfo(
      x: (jsonSerialization['x'] as num).toDouble(),
      y: (jsonSerialization['y'] as num).toDouble(),
      width: (jsonSerialization['width'] as num).toDouble(),
      height: (jsonSerialization['height'] as num).toDouble(),
      label: jsonSerialization['label'] as String,
      speech: jsonSerialization['speech'] as String?,
    );
  }

  double x;

  double y;

  double width;

  double height;

  String label;

  String? speech;

  /// Returns a shallow copy of this [SceneSpotInfo]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  SceneSpotInfo copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    String? label,
    String? speech,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SceneSpotInfo',
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'label': label,
      if (speech != null) 'speech': speech,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SceneSpotInfo',
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'label': label,
      if (speech != null) 'speech': speech,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SceneSpotInfoImpl extends SceneSpotInfo {
  _SceneSpotInfoImpl({
    required double x,
    required double y,
    required double width,
    required double height,
    required String label,
    String? speech,
  }) : super._(
         x: x,
         y: y,
         width: width,
         height: height,
         label: label,
         speech: speech,
       );

  /// Returns a shallow copy of this [SceneSpotInfo]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  SceneSpotInfo copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    String? label,
    Object? speech = _Undefined,
  }) {
    return SceneSpotInfo(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      label: label ?? this.label,
      speech: speech is String? ? speech : this.speech,
    );
  }
}
