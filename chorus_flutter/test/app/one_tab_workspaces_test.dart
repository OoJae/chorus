import 'dart:async';

import 'package:chorus_flutter/screens/services.dart';
import 'package:chorus_flutter/src/tabs/tab_workspaces.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  test(
    'closing all closes what the shell has open, without the shell',
    () async {
      final workspace = _CountedWorkspace();
      final workspaces = TabWorkspaces(() async => workspace);

      await workspaces.open();
      expect(workspace.closes, 0);

      workspaces.closeAll();

      expect(workspace.closes, 1);
    },
  );

  test('what the shell asks of its workspace reaches the real one', () async {
    final workspace = FakeWorkspace();
    final workspaces = TabWorkspaces(() async => workspace);
    final opened = await workspaces.open();

    await opened.ensureCircleReady(circle(), seedIfEmpty: true);

    expect(opened.sync, same(workspace.sync));
    expect(workspace.readied, [('Maya', true)]);
    expect(opened.boardStore(circle()), isNotNull);
    expect(opened.servicesFor(circle()), isNull);
  });

  test('the shell closing after all were closed waits for that close, and '
      'nothing is closed twice', () async {
    final workspace = _CountedWorkspace()..closeGate = Completer<void>();
    final workspaces = TabWorkspaces(() async => workspace);
    final opened = await workspaces.open();

    workspaces.closeAll();
    // The shell, disposed a frame later.
    var shellDone = false;
    final shellClose = opened.close().then((_) => shellDone = true);
    await Future<void>.delayed(Duration.zero);

    expect(workspace.closes, 1);
    // Sync is still stopping: the database must not be closed under it.
    expect(shellDone, isFalse);

    workspace.closeGate!.complete();
    await shellClose;
    expect(workspace.closes, 1);
  });

  test('a workspace the shell closed itself is not closed again', () async {
    final workspace = _CountedWorkspace();
    final workspaces = TabWorkspaces(() async => workspace);
    final opened = await workspaces.open();

    // Signed out.
    await opened.close();
    workspaces.closeAll();

    expect(workspace.closes, 1);
  });

  test('a workspace still opening when all are closed is closed as it '
      'arrives', () async {
    final workspace = _CountedWorkspace();
    final opening = Completer<Workspace>();
    final workspaces = TabWorkspaces(() => opening.future);

    final asked = workspaces.open();
    workspaces.closeAll();
    opening.complete(workspace);

    // The shell that asked still gets it, and closes it again unharmed.
    final opened = await asked;
    expect(workspace.closes, 1);
    await opened.close();
    expect(workspace.closes, 1);
  });

  test('a workspace opened after a close is left open', () async {
    final made = <FakeWorkspace>[];
    final workspaces = TabWorkspaces(() async {
      made.add(FakeWorkspace());
      return made.last;
    });

    await workspaces.open();
    workspaces.closeAll();
    await workspaces.open();

    expect(made.first.closed, isTrue);
    expect(made.last.closed, isFalse);

    // And closing again reaches only the one still open.
    workspaces.closeAll();
    expect(made.last.closed, isTrue);
  });

  test('a workspace that will not close is no error for the app', () async {
    final workspaces = TabWorkspaces(() async => _StuckWorkspace());
    final opened = await workspaces.open();

    workspaces.closeAll();

    // Nothing escapes as an unhandled error, and the shell's own close
    // hears the failure as it did before.
    await Future<void>.delayed(Duration.zero);
    await expectLater(opened.close(), throwsStateError);
  });
}

class _CountedWorkspace extends FakeWorkspace {
  int closes = 0;

  @override
  Future<void> close() {
    closes++;
    return super.close();
  }
}

class _StuckWorkspace extends FakeWorkspace {
  @override
  Future<void> close() async => throw StateError('still merging');
}
