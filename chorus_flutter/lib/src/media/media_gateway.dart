/// The server side of media, as the local store needs it.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:chorus_client/chorus_client.dart';
import 'package:http/http.dart' as http;

/// Sends files to the circle's private storage and gets them back.
///
/// An interface so the store and the queue can be tested with no server.
abstract class MediaGateway {
  /// Puts [bytes] on the server under [hash]. Completes only when the
  /// server holds bytes it has checked against the hash; throws otherwise.
  Future<void> upload(String hash, Uint8List bytes, {required bool isAudio});

  /// Short-lived links for those of [hashes] the server holds for this
  /// circle. Hashes it does not hold are left out.
  Future<Map<String, String>> downloadUrls(List<String> hashes);

  /// The bytes behind a link from [downloadUrls].
  Future<Uint8List> fetch(String url);
}

/// [MediaGateway] over the generated client, for one circle.
class ServerMediaGateway implements MediaGateway {
  ServerMediaGateway(this._client, this.circleSpace, {http.Client? httpClient})
    : _http = httpClient;

  final Client _client;

  /// UUID of the circle's sync space.
  final UuidValue circleSpace;
  final http.Client? _http;

  /// Larger than any file the app makes; a link that returns more is not
  /// one of ours.
  static const int maxDownloadBytes = 2 * 1000 * 1000;

  @override
  Future<void> upload(
    String hash,
    Uint8List bytes, {
    required bool isAudio,
  }) async {
    final ticket = await _client.media.requestUpload(
      circleSpace,
      hash,
      isAudio ? MediaKind.audio : MediaKind.image,
      bytes.length,
    );
    final description = ticket.uploadDescription;
    // No description: the circle already holds verified bytes for the hash.
    if (description == null) return;
    final uploaded = await FileUploader(
      description,
    ).uploadByteData(ByteData.sublistView(bytes));
    // Asked even when the upload was refused: the storage refuses a second
    // copy of bytes it already holds (another editor sent the same file, or
    // this is a retry), and the server then verifies what is there.
    final verified = await _client.media.confirmUpload(circleSpace, hash);
    if (!verified) {
      throw StateError(
        uploaded
            ? 'The server could not verify the upload.'
            : 'The upload did not go through.',
      );
    }
  }

  @override
  Future<Map<String, String>> downloadUrls(List<String> hashes) =>
      _client.media.downloadUrls(circleSpace, hashes);

  @override
  Future<Uint8List> fetch(String url) async {
    final uri = Uri.parse(url);
    final response = await (_http == null ? http.get(uri) : _http.get(uri))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw StateError('Download failed with status ${response.statusCode}.');
    }
    if (response.bodyBytes.length > maxDownloadBytes) {
      throw StateError('The download is larger than any Chorus file.');
    }
    return response.bodyBytes;
  }
}
