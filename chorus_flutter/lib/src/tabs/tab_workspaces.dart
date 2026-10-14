/// What the signed-in shell has open in this tab, so it can be closed
/// without the shell.
library;

import 'dart:async';

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_ui/contracts.dart' show BoardStore, SyncStatus;

import '../../screens/services.dart';

/// Opens the shell's workspaces and remembers them.
///
/// The shell closes its workspace when it is disposed. But a tab in the
/// background draws no frames: when another tab takes the seat, the shell
/// here is not disposed until someone looks at this tab again, and its sync
/// would run on beside the other tab's. [closeAll] stops it at once.
class TabWorkspaces {
  TabWorkspaces(this._open);

  final WorkspaceOpener _open;
  final Set<_TabWorkspace> _opened = {};

  /// Goes up with every [closeAll], so a workspace that was still opening
  /// then can tell.
  int _closings = 0;

  /// Opens a workspace for the shell. One that was still opening when
  /// [closeAll] ran is closed as it arrives: the shell that asked for it is
  /// on its way out.
  Future<Workspace> open() async {
    final closings = _closings;
    final workspace = _TabWorkspace(await _open(), _opened.remove);
    if (closings == _closings) {
      _opened.add(workspace);
    } else {
      _close(workspace);
    }
    return workspace;
  }

  /// Closes every workspace still open. The shell closes its own again when
  /// it is disposed, and that second close waits for this one.
  void closeAll() {
    _closings++;
    final opened = List.of(_opened);
    _opened.clear();
    opened.forEach(_close);
  }

  void _close(Workspace workspace) {
    unawaited(workspace.close().then<void>((_) {}, onError: (Object _) {}));
  }
}

/// A workspace that is closed once however often it is asked. Two closes
/// at once would not wait for each other: the second would take the
/// database away while the first is still stopping sync.
class _TabWorkspace implements Workspace {
  _TabWorkspace(this._workspace, this._onClose);

  final Workspace _workspace;

  /// Tells [TabWorkspaces] to forget this one, whoever closed it.
  final void Function(_TabWorkspace) _onClose;

  Future<void>? _closing;

  @override
  SyncStatus get sync => _workspace.sync;

  @override
  Future<void> ensureCircleReady(
    CircleInfo circle, {
    bool seedIfEmpty = false,
  }) => _workspace.ensureCircleReady(circle, seedIfEmpty: seedIfEmpty);

  @override
  BoardStore boardStore(CircleInfo circle) => _workspace.boardStore(circle);

  @override
  CircleServices? servicesFor(CircleInfo circle) =>
      _workspace.servicesFor(circle);

  @override
  Future<void> close() {
    _onClose(this);
    return _closing ??= Future<void>.sync(_workspace.close);
  }
}
