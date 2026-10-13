/// Remembers the adult's circles on this device.
///
/// The circle list comes from the server, but the child's phone must open
/// its board with no signal. The last list seen is kept per user: in a small
/// file on phones and desktops, in the browser's local storage on the web.
library;

import 'dart:convert';

import 'package:chorus_client/chorus_client.dart';

import 'circle_cache_none.dart'
    if (dart.library.io) 'circle_cache_io.dart'
    if (dart.library.js_interop) 'circle_cache_web.dart'
    as platform;

/// The saved list for [userId]; empty when none was saved or it is unreadable.
Future<List<CircleInfo>> readCircleCache(String userId) async {
  try {
    final text = await platform.readText(_fileName(userId));
    if (text == null) return const [];
    return [
      for (final item in jsonDecode(text) as List)
        CircleInfo.fromJson((item as Map).cast<String, dynamic>()),
    ];
  } catch (_) {
    return const [];
  }
}

/// Saves [circles] for [userId]. A failure is ignored: the cache only speeds
/// up and protects the next start.
Future<void> writeCircleCache(String userId, List<CircleInfo> circles) async {
  try {
    await platform.writeText(
      _fileName(userId),
      jsonEncode([for (final circle in circles) circle.toJson()]),
    );
  } catch (_) {}
}

String _fileName(String userId) => 'chorus_circles_$userId.json';
