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

/// One focus word in the progress report.
abstract class FocusReportLine
    implements _is.SerializableModel, _is.ProtocolSerialization {
  FocusReportLine._({
    required this.label,
    required this.tip,
    required this.modelled,
    required this.said,
  });

  factory FocusReportLine({
    required String label,
    required String tip,
    required int modelled,
    required int said,
  }) = _FocusReportLineImpl;

  factory FocusReportLine.fromJson(Map<String, dynamic> jsonSerialization) {
    return FocusReportLine(
      label: jsonSerialization['label'] as String,
      tip: jsonSerialization['tip'] as String,
      modelled: jsonSerialization['modelled'] as int,
      said: jsonSerialization['said'] as int,
    );
  }

  String label;

  String tip;

  int modelled;

  int said;

  /// Returns a shallow copy of this [FocusReportLine]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  FocusReportLine copyWith({
    String? label,
    String? tip,
    int? modelled,
    int? said,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FocusReportLine',
      'label': label,
      'tip': tip,
      'modelled': modelled,
      'said': said,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'FocusReportLine',
      'label': label,
      'tip': tip,
      'modelled': modelled,
      'said': said,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _FocusReportLineImpl extends FocusReportLine {
  _FocusReportLineImpl({
    required String label,
    required String tip,
    required int modelled,
    required int said,
  }) : super._(
         label: label,
         tip: tip,
         modelled: modelled,
         said: said,
       );

  /// Returns a shallow copy of this [FocusReportLine]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  FocusReportLine copyWith({
    String? label,
    String? tip,
    int? modelled,
    int? said,
  }) {
    return FocusReportLine(
      label: label ?? this.label,
      tip: tip ?? this.tip,
      modelled: modelled ?? this.modelled,
      said: said ?? this.said,
    );
  }
}
