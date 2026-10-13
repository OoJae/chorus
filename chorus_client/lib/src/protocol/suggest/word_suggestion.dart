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

/// A word proposed for a photo. Nothing is added to a board until an adult
/// approves it on their own device.
abstract class WordSuggestion
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  WordSuggestion._({
    required this.label,
    required this.speech,
    required this.colorKey,
    required this.alternatives,
  });

  factory WordSuggestion({
    required String label,
    required String speech,
    required String colorKey,
    required List<String> alternatives,
  }) = _WordSuggestionImpl;

  factory WordSuggestion.fromJson(Map<String, dynamic> jsonSerialization) {
    return WordSuggestion(
      label: jsonSerialization['label'] as String,
      speech: jsonSerialization['speech'] as String,
      colorKey: jsonSerialization['colorKey'] as String,
      alternatives: _iuvo7w6p.Protocol().deserialize<List<String>>(
        jsonSerialization['alternatives'],
      ),
    );
  }

  /// The text shown on the tile.
  String label;

  /// What the tile says aloud.
  String speech;

  /// A colour key from the shared palette.
  String colorKey;

  /// Other labels the adult may pick instead, best first.
  List<String> alternatives;

  /// Returns a shallow copy of this [WordSuggestion]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  WordSuggestion copyWith({
    String? label,
    String? speech,
    String? colorKey,
    List<String>? alternatives,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WordSuggestion',
      'label': label,
      'speech': speech,
      'colorKey': colorKey,
      'alternatives': alternatives.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WordSuggestion',
      'label': label,
      'speech': speech,
      'colorKey': colorKey,
      'alternatives': alternatives.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _WordSuggestionImpl extends WordSuggestion {
  _WordSuggestionImpl({
    required String label,
    required String speech,
    required String colorKey,
    required List<String> alternatives,
  }) : super._(
         label: label,
         speech: speech,
         colorKey: colorKey,
         alternatives: alternatives,
       );

  /// Returns a shallow copy of this [WordSuggestion]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  WordSuggestion copyWith({
    String? label,
    String? speech,
    String? colorKey,
    List<String>? alternatives,
  }) {
    return WordSuggestion(
      label: label ?? this.label,
      speech: speech ?? this.speech,
      colorKey: colorKey ?? this.colorKey,
      alternatives: alternatives ?? this.alternatives.map((e0) => e0).toList(),
    );
  }
}
