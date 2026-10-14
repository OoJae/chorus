/// Sharing a board outside the circle, as the screens see it.
///
/// Kept apart from `contracts.dart` so every screen works without it: the
/// "Share a view-only board" and "Export (.obf)" actions appear only when a
/// [BoardSharing] is given.
library;

import 'package:chorus_shared/chorus_shared.dart';

/// A link to a board page anyone can open, with no account.
class SharedLink {
  const SharedLink({required this.url, required this.expiresAt});

  final Uri url;

  /// When the page stops opening, UTC.
  final DateTime expiresAt;

  @override
  bool operator ==(Object other) =>
      other is SharedLink && other.url == url && other.expiresAt == expiresAt;

  @override
  int get hashCode => Object.hash(url, expiresAt);

  @override
  String toString() => 'SharedLink($url, until $expiresAt)';
}

/// How long a view-only board stays open.
const Duration viewOnlyLinkLasts = Duration(days: 7);

/// Thrown when a link could not be made or withdrawn, for example with no
/// connection. [message] is written for the adult.
class SharingFailed implements Exception {
  const SharingFailed(this.message);

  final String message;

  @override
  String toString() => 'SharingFailed: $message';
}

/// Board pages kept on the server, made from what this device shows. Each
/// needs the network.
abstract class BoardSharing {
  /// A page of [board] that speaks when a word is tapped, for a babysitter.
  /// It holds the words and colours only (see `printSnapshotJson`), and
  /// stops opening after [viewOnlyLinkLasts]. Throws [SharingFailed].
  Future<SharedLink> shareViewOnly(BoardFacts board);

  /// Stops [link] opening, now. Safe to call twice. Throws [SharingFailed].
  Future<void> withdraw(SharedLink link);

  /// A link to [board] as an Open Board Format (.obf) file, for another AAC
  /// app. Throws [SharingFailed].
  Future<Uri> exportObf(BoardFacts board);
}
