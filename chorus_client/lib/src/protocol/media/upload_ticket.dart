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

/// Permission to upload one media file straight to private storage.
abstract class UploadTicket
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  UploadTicket._({
    required this.path,
    this.uploadDescription,
  });

  factory UploadTicket({
    required String path,
    String? uploadDescription,
  }) = _UploadTicketImpl;

  factory UploadTicket.fromJson(Map<String, dynamic> jsonSerialization) {
    return UploadTicket(
      path: jsonSerialization['path'] as String,
      uploadDescription: jsonSerialization['uploadDescription'] as String?,
    );
  }

  /// Where the file lives in private storage.
  String path;

  /// Opaque upload instructions for the client's file uploader. Null when the
  /// server already holds verified bytes for this hash: nothing to upload.
  String? uploadDescription;

  /// Returns a shallow copy of this [UploadTicket]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  UploadTicket copyWith({
    String? path,
    String? uploadDescription,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UploadTicket',
      'path': path,
      if (uploadDescription != null) 'uploadDescription': uploadDescription,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'UploadTicket',
      'path': path,
      if (uploadDescription != null) 'uploadDescription': uploadDescription,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UploadTicketImpl extends UploadTicket {
  _UploadTicketImpl({
    required String path,
    String? uploadDescription,
  }) : super._(
         path: path,
         uploadDescription: uploadDescription,
       );

  /// Returns a shallow copy of this [UploadTicket]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  UploadTicket copyWith({
    String? path,
    Object? uploadDescription = _Undefined,
  }) {
    return UploadTicket(
      path: path ?? this.path,
      uploadDescription: uploadDescription is String?
          ? uploadDescription
          : this.uploadDescription,
    );
  }
}
