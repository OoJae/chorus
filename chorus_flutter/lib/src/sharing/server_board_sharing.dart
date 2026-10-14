/// View-only links and .obf exports, over the server's `sharing` and
/// `printing` endpoints.
library;

import 'dart:async';

import 'package:chorus_client/chorus_client.dart' hide CircleRole;
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart' show SyncState, SyncStatus;
import 'package:chorus_ui/contracts_sharing.dart';
import 'package:flutter/foundation.dart';

/// What a snapshot is built from: the boards and words on this device.
typedef BoardSnapshot = ({
  String childName,
  List<BoardFacts> boards,
  List<TileFacts> tiles,
});

/// Publishes snapshots of this device's boards for people outside the
/// circle.
///
/// Each snapshot is built here with `printSnapshotJson`, from the words this
/// device shows: the server never reads the replica for it. A view-only
/// link is the `/b/<token>` page, open for seven days unless withdrawn. An
/// export stores the board as a paper copy does (30 days, the screens'
/// `obfExportLinkLasts`) and links to `/export/<token>`, the same board as
/// an .obf file; no speaking page is made for it.
///
/// In the released web app the pages are on the server the app came from,
/// so a link is built on the page's own address; anywhere else the app only
/// knows the API server, so it takes the address the server gives.
///
/// Every failure is a [SharingFailed] with words for the adult.
class ServerBoardSharing implements BoardSharing {
  ServerBoardSharing({
    required this._publishViewOnly,
    required this._withdraw,
    required this._publishCopy,
    required this._exportUrl,
    required this._snapshot,
    this._sync,
    this.pageBase,
    this.timeout = const Duration(seconds: 30),
  });

  /// The sharing the app uses for [circleSpace].
  factory ServerBoardSharing.forClient(
    Client client, {
    required UuidValue circleSpace,
    required Future<BoardSnapshot> Function() snapshot,
    SyncStatus? sync,
  }) => ServerBoardSharing(
    publishViewOnly: (json) =>
        client.sharing.publishViewOnly(circleSpace, json),
    withdraw: (token) => client.sharing.withdraw(circleSpace, token),
    publishCopy: (json) => client.printing.publishBoard(circleSpace, json),
    exportUrl: (token) => client.sharing.exportUrl(token),
    snapshot: snapshot,
    sync: sync,
    pageBase: kIsWeb && kReleaseMode ? Uri.base : null,
  );

  final Future<ViewOnlyLink> Function(String boardJson) _publishViewOnly;
  final Future<bool> Function(String token) _withdraw;
  final Future<String> Function(String boardJson) _publishCopy;
  final Future<String> Function(String token) _exportUrl;
  final Future<BoardSnapshot> Function() _snapshot;
  final SyncStatus? _sync;

  /// The address the pages are on, when this app was served from it (the
  /// released web app). Null asks the server.
  final Uri? pageBase;

  /// Longest wait for each call to the server.
  final Duration timeout;

  static const String _noConnection =
      'Chorus could not reach the server. Check the connection and try '
      'again.';

  @override
  Future<SharedLink> shareViewOnly(BoardFacts board) async {
    _requireReachable();
    final json = await _snapshotOf(board);
    try {
      final link = await _publishViewOnly(json).timeout(timeout);
      final base = pageBase;
      return SharedLink(
        url: base != null
            ? base.resolve('/b/${link.token}')
            : Uri.parse(link.url),
        expiresAt: link.expiresAt.toUtc(),
      );
    } catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<void> withdraw(SharedLink link) async {
    _requireReachable();
    final token = link.url.pathSegments.lastWhere(
      (segment) => segment.isNotEmpty,
      orElse: () => '',
    );
    if (token.isEmpty) {
      throw const SharingFailed('This is not a link Chorus made.');
    }
    try {
      // False means it had already stopped, which is what was asked.
      await _withdraw(token).timeout(timeout);
    } catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<Uri> exportObf(BoardFacts board) async {
    _requireReachable();
    final json = await _snapshotOf(board);
    try {
      final token = await _publishCopy(json).timeout(timeout);
      final base = pageBase;
      if (base != null) return base.resolve('/export/$token');
      return Uri.parse(await _exportUrl(token).timeout(timeout));
    } catch (error) {
      throw _failure(error);
    }
  }

  /// [board] as this device holds it now, as snapshot JSON.
  Future<String> _snapshotOf(BoardFacts board) async {
    try {
      final now = await _snapshot();
      final current =
          now.boards.where((other) => other.id == board.id).firstOrNull ??
          board;
      return printSnapshotJson(
        childName: now.childName,
        board: current,
        tiles: now.tiles,
        boards: now.boards,
      );
    } catch (_) {
      throw const SharingFailed(
        'The board saved on this device could not be read. Try again.',
      );
    }
  }

  /// Fails at once when this device is known to have no way to the server.
  void _requireReachable() {
    final sync = _sync;
    if (sync == null) return;
    if (sync.workingOffline) {
      throw const SharingFailed(
        'This device is set to work offline. Switch off "Work offline" and '
        'try again.',
      );
    }
    if (sync.state == SyncState.offline) {
      throw const SharingFailed(
        'This needs a connection. Try again when the device is online.',
      );
    }
  }

  static SharingFailed _failure(Object error) {
    if (error is SharingFailed) return error;
    if (error is CircleException) {
      return SharingFailed(switch (error.failure) {
        CircleFailure.notAMember =>
          'You are no longer part of this circle. Ask a parent or guardian '
              'to invite you again.',
        CircleFailure.notAllowed =>
          'Only the adults who can change the board can share it.',
        _ => _noConnection,
      });
    }
    return const SharingFailed(_noConnection);
  }
}
