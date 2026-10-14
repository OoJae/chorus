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
import '../summary/word_tally.dart' as _id72khb3;

/// One week of the word log, for the adults ("This week"). The same fields
/// as `WeekSummary` in chorus_shared, which works it out.
abstract class WeekReport
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  WeekReport._({
    required this.weekStart,
    required this.topWords,
    required this.firstTimeWords,
    required this.addedWords,
    required this.notUsedYet,
    required this.totalUses,
    required this.wordsUsed,
    required this.computedAt,
  });

  factory WeekReport({
    required DateTime weekStart,
    required List<_id72khb3.WordTally> topWords,
    required List<String> firstTimeWords,
    required List<String> addedWords,
    required List<String> notUsedYet,
    required int totalUses,
    required int wordsUsed,
    required DateTime computedAt,
  }) = _WeekReportImpl;

  factory WeekReport.fromJson(Map<String, dynamic> jsonSerialization) {
    return WeekReport(
      weekStart: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['weekStart'],
      ),
      topWords: _iuvo7w6p.Protocol().deserialize<List<_id72khb3.WordTally>>(
        jsonSerialization['topWords'],
      ),
      firstTimeWords: _iuvo7w6p.Protocol().deserialize<List<String>>(
        jsonSerialization['firstTimeWords'],
      ),
      addedWords: _iuvo7w6p.Protocol().deserialize<List<String>>(
        jsonSerialization['addedWords'],
      ),
      notUsedYet: _iuvo7w6p.Protocol().deserialize<List<String>>(
        jsonSerialization['notUsedYet'],
      ),
      totalUses: jsonSerialization['totalUses'] as int,
      wordsUsed: jsonSerialization['wordsUsed'] as int,
      computedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['computedAt'],
      ),
    );
  }

  /// Monday 00:00 UTC. The week runs seven days from here.
  DateTime weekStart;

  /// Most used first, at most ten.
  List<_id72khb3.WordTally> topWords;

  /// Spoken this week and never before it.
  List<String> firstTimeWords;

  /// Added to a board this week and still on one.
  List<String> addedWords;

  /// On a board and never spoken by the end of the week.
  List<String> notUsedYet;

  /// Taps this week.
  int totalUses;

  /// Different words spoken this week.
  int wordsUsed;

  /// When these numbers were worked out.
  DateTime computedAt;

  /// Returns a shallow copy of this [WeekReport]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  WeekReport copyWith({
    DateTime? weekStart,
    List<_id72khb3.WordTally>? topWords,
    List<String>? firstTimeWords,
    List<String>? addedWords,
    List<String>? notUsedYet,
    int? totalUses,
    int? wordsUsed,
    DateTime? computedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WeekReport',
      'weekStart': weekStart.toJson(),
      'topWords': topWords.toJson(valueToJson: (v) => v.toJson()),
      'firstTimeWords': firstTimeWords.toJson(),
      'addedWords': addedWords.toJson(),
      'notUsedYet': notUsedYet.toJson(),
      'totalUses': totalUses,
      'wordsUsed': wordsUsed,
      'computedAt': computedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WeekReport',
      'weekStart': weekStart.toJson(),
      'topWords': topWords.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'firstTimeWords': firstTimeWords.toJson(),
      'addedWords': addedWords.toJson(),
      'notUsedYet': notUsedYet.toJson(),
      'totalUses': totalUses,
      'wordsUsed': wordsUsed,
      'computedAt': computedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _WeekReportImpl extends WeekReport {
  _WeekReportImpl({
    required DateTime weekStart,
    required List<_id72khb3.WordTally> topWords,
    required List<String> firstTimeWords,
    required List<String> addedWords,
    required List<String> notUsedYet,
    required int totalUses,
    required int wordsUsed,
    required DateTime computedAt,
  }) : super._(
         weekStart: weekStart,
         topWords: topWords,
         firstTimeWords: firstTimeWords,
         addedWords: addedWords,
         notUsedYet: notUsedYet,
         totalUses: totalUses,
         wordsUsed: wordsUsed,
         computedAt: computedAt,
       );

  /// Returns a shallow copy of this [WeekReport]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  WeekReport copyWith({
    DateTime? weekStart,
    List<_id72khb3.WordTally>? topWords,
    List<String>? firstTimeWords,
    List<String>? addedWords,
    List<String>? notUsedYet,
    int? totalUses,
    int? wordsUsed,
    DateTime? computedAt,
  }) {
    return WeekReport(
      weekStart: weekStart ?? this.weekStart,
      topWords: topWords ?? this.topWords.map((e0) => e0.copyWith()).toList(),
      firstTimeWords:
          firstTimeWords ?? this.firstTimeWords.map((e0) => e0).toList(),
      addedWords: addedWords ?? this.addedWords.map((e0) => e0).toList(),
      notUsedYet: notUsedYet ?? this.notUsedYet.map((e0) => e0).toList(),
      totalUses: totalUses ?? this.totalUses,
      wordsUsed: wordsUsed ?? this.wordsUsed,
      computedAt: computedAt ?? this.computedAt,
    );
  }
}
