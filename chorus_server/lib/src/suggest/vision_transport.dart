/// The one HTTPS call the suggestion service makes, behind an interface so
/// tests can answer it without a network or a key.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// What came back from the model service: the HTTP status and the raw body.
class VisionReply {
  const VisionReply(this.status, this.body);

  final int status;
  final String body;
}

/// Sends one Messages request and returns the reply, whatever its status.
///
/// Throws only when no reply arrived at all (no connection, timeout).
abstract interface class VisionTransport {
  Future<VisionReply> send({
    required String apiKey,
    required Map<String, Object?> body,
    List<String> betas = const [],
  });
}

/// The real transport: one POST to the Messages API.
///
/// Never logs anything. The key travels only in the request header and the
/// photo only in the request body.
class HttpVisionTransport implements VisionTransport {
  const HttpVisionTransport({this.timeout = const Duration(seconds: 45)});

  static final _endpoint = Uri.parse('https://api.anthropic.com/v1/messages');

  /// How long one attempt may take before it counts as no reply.
  final Duration timeout;

  @override
  Future<VisionReply> send({
    required String apiKey,
    required Map<String, Object?> body,
    List<String> betas = const [],
  }) async {
    final client = http.Client();
    try {
      final response = await client
          .post(
            _endpoint,
            headers: {
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
              'content-type': 'application/json',
              if (betas.isNotEmpty) 'anthropic-beta': betas.join(','),
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
      return VisionReply(response.statusCode, utf8.decode(response.bodyBytes));
    } finally {
      client.close();
    }
  }
}
