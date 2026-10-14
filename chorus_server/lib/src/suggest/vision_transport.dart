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

/// Anthropic's own Messages API, the default service.
const anthropicBaseUrl = 'https://api.anthropic.com';

/// Whether [baseUrl] is Anthropic's own service rather than another one that
/// speaks the same protocol.
bool isAnthropicBaseUrl(String baseUrl) =>
    Uri.tryParse(baseUrl)?.host == Uri.parse(anthropicBaseUrl).host;

/// Sends one Messages request and returns the reply, whatever its status.
///
/// Throws only when no reply arrived at all (no connection, timeout).
abstract interface class VisionTransport {
  Future<VisionReply> send({
    required String apiKey,
    required Map<String, Object?> body,
    List<String> betas = const [],
    String baseUrl = anthropicBaseUrl,
  });
}

/// The real transport: one POST to `<baseUrl>/v1/messages`.
///
/// Never logs anything. The key travels only in the request headers and the
/// photo only in the request body.
class HttpVisionTransport implements VisionTransport {
  const HttpVisionTransport({this.timeout = const Duration(seconds: 45)});

  /// How long one attempt may take before it counts as no reply.
  final Duration timeout;

  @override
  Future<VisionReply> send({
    required String apiKey,
    required Map<String, Object?> body,
    List<String> betas = const [],
    String baseUrl = anthropicBaseUrl,
  }) async {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final client = http.Client();
    try {
      final response = await client
          .post(
            Uri.parse('$base/v1/messages'),
            headers: {
              'x-api-key': apiKey,
              // Services that only copy the protocol often read the key from
              // here instead. Anthropic's own service gets just x-api-key.
              if (!isAnthropicBaseUrl(base)) 'authorization': 'Bearer $apiKey',
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
