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

/// A view-only board page anyone with the link can open, with no account.
abstract class ViewOnlyLink
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ViewOnlyLink._({
    required this.token,
    required this.url,
    required this.exportUrl,
    required this.expiresAt,
  });

  factory ViewOnlyLink({
    required String token,
    required String url,
    required String exportUrl,
    required DateTime expiresAt,
  }) = _ViewOnlyLinkImpl;

  factory ViewOnlyLink.fromJson(Map<String, dynamic> jsonSerialization) {
    return ViewOnlyLink(
      token: jsonSerialization['token'] as String,
      url: jsonSerialization['url'] as String,
      exportUrl: jsonSerialization['exportUrl'] as String,
      expiresAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
    );
  }

  /// The key to the page; also what `withdraw` takes.
  String token;

  /// The page, on the web server as the outside world reaches it.
  String url;

  /// The same board as an Open Board Format (.obf) file.
  String exportUrl;

  /// When the page stops opening, UTC.
  DateTime expiresAt;

  /// Returns a shallow copy of this [ViewOnlyLink]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ViewOnlyLink copyWith({
    String? token,
    String? url,
    String? exportUrl,
    DateTime? expiresAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ViewOnlyLink',
      'token': token,
      'url': url,
      'exportUrl': exportUrl,
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ViewOnlyLink',
      'token': token,
      'url': url,
      'exportUrl': exportUrl,
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _ViewOnlyLinkImpl extends ViewOnlyLink {
  _ViewOnlyLinkImpl({
    required String token,
    required String url,
    required String exportUrl,
    required DateTime expiresAt,
  }) : super._(
         token: token,
         url: url,
         exportUrl: exportUrl,
         expiresAt: expiresAt,
       );

  /// Returns a shallow copy of this [ViewOnlyLink]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ViewOnlyLink copyWith({
    String? token,
    String? url,
    String? exportUrl,
    DateTime? expiresAt,
  }) {
    return ViewOnlyLink(
      token: token ?? this.token,
      url: url ?? this.url,
      exportUrl: exportUrl ?? this.exportUrl,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
