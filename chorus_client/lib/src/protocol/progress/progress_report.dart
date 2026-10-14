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
import '../progress/focus_report_line.dart' as _i89nbke8;
import '../summary/week_report.dart' as _idaibkhp;

/// One week's progress in counts, for the printable report.
abstract class ProgressReport
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ProgressReport._({
    required this.childName,
    required this.week,
    required this.focus,
  });

  factory ProgressReport({
    required String childName,
    required _idaibkhp.WeekReport week,
    required List<_i89nbke8.FocusReportLine> focus,
  }) = _ProgressReportImpl;

  factory ProgressReport.fromJson(Map<String, dynamic> jsonSerialization) {
    return ProgressReport(
      childName: jsonSerialization['childName'] as String,
      week: _iuvo7w6p.Protocol().deserialize<_idaibkhp.WeekReport>(
        jsonSerialization['week'],
      ),
      focus: _iuvo7w6p.Protocol().deserialize<List<_i89nbke8.FocusReportLine>>(
        jsonSerialization['focus'],
      ),
    );
  }

  String childName;

  _idaibkhp.WeekReport week;

  List<_i89nbke8.FocusReportLine> focus;

  /// Returns a shallow copy of this [ProgressReport]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ProgressReport copyWith({
    String? childName,
    _idaibkhp.WeekReport? week,
    List<_i89nbke8.FocusReportLine>? focus,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProgressReport',
      'childName': childName,
      'week': week.toJson(),
      'focus': focus.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ProgressReport',
      'childName': childName,
      'week': week.toJsonForProtocol(),
      'focus': focus.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _ProgressReportImpl extends ProgressReport {
  _ProgressReportImpl({
    required String childName,
    required _idaibkhp.WeekReport week,
    required List<_i89nbke8.FocusReportLine> focus,
  }) : super._(
         childName: childName,
         week: week,
         focus: focus,
       );

  /// Returns a shallow copy of this [ProgressReport]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ProgressReport copyWith({
    String? childName,
    _idaibkhp.WeekReport? week,
    List<_i89nbke8.FocusReportLine>? focus,
  }) {
    return ProgressReport(
      childName: childName ?? this.childName,
      week: week ?? this.week.copyWith(),
      focus: focus ?? this.focus.map((e0) => e0.copyWith()).toList(),
    );
  }
}
