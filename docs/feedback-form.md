> Owner: paste everything below the line into the "Most Valuable Feedback" form. First resolve each [bracketed] sentence (delete it, or remove the brackets once checked on a device) and each TODO(owner).

---

# Chorus: feedback on Serverpod 4 and `serverpod_offline_sync`

## Summary

Chorus is an offline-first talking picture board for a non-speaking child: the child's device speaks from a local replica while adults edit the board from their own devices. It is built on Serverpod 4.0.4, `serverpod_offline_sync` 0.0.10 and Flutter 3.47.7, deployed on Serverpod Cloud (TODO(owner): plan name), and has been run in a desktop browser and on a physical Android phone. Each finding names the test in https://github.com/OoJae/chorus, the source file, or the device check behind it.

## What worked well

- `serverpod cloud launch` built and rolled out the scaffold, the sync module and its migrations on the first attempt.
- Emailed sign-up codes worked on Cloud with no configuration.
- Tests need no Docker: `database.dataPath` gives an embedded Postgres.
- The module ran on a physical Android phone (arm64, release build) and in a browser, where the SQLite replica persists in IndexedDB. A board created in the browser reached the phone through sync.
- Unique conflicts resolve identically on the server and every replica (T1 below), in automated tests against real Postgres and SQLite. Not yet tried on two physical devices.
- After an offline collision every node agreed after two one-shot sync rounds, as expected: the device that syncs first learns of the other's write on its next sync.

## Findings, most time saved first

Tests are in `chorus_server/test/sync/` unless a path is given.

**1. A write outside `transactionForUser` disappears without an error**
- Expected: an exception, or a row its author can see.
- Got: no error, and no other member receives the row. When its parent is in a shared space, its unique key becomes `<value>__hidden__<id>` at once and ordinary reads omit it, even for the author.
- Repro: `spaces_test.dart`, T9.
- Workaround: one write path, `chorus_flutter/lib/src/sync/replica_service.dart`.
- Suggest: throw, or warn in debug mode, when a personal-space row references a row in another space.

**2. `updateRow` without `columns` is whole-row last-writer-wins**
- Expected: the field-level merge the README describes.
- Got: the later writer's stale values overwrite another member's earlier change to a different column.
- Repro: `merge_test.dart`, "T3 control".
- Workaround: always pass `columns`.
- Suggest: merge only changed columns, or document the rule.

**3. Reads span every space, and `spaceId` is null on rows**
- Expected: a way to read one space, or to tell a row's space.
- Got: an unfiltered `find` returns rows from two shared spaces and the personal space together, each with `spaceId` null.
- Repro: `spaces_test.dart`, T10.
- Workaround: our own `circleId` column on every synced table, filtered in every query.
- Suggest: a space filter on reads, and the space UUID on rows.

**4. No reconnect, no status, and `syncOnce` cannot be cancelled**
- Expected: continuous sync resumes after a drop and reports its state.
- Got (read in `client_sync.dart` and `engine.dart`, no test): `syncContinuously` runs until its stream ends and does not retry. `syncOnce` returns a bare `Future` and, unlike continuous mode, reads inbound with no timeout.
- Workaround: a 700-line supervisor, `chorus_flutter/lib/src/sync/sync_supervisor.dart`. [On the phone, sync resumed by itself after the network came back.]
- Suggest: built-in reconnect with backoff, a status stream, a cancellable `syncOnce`.

**5. A unique conflict raises no event**
- Expected: a typed signal naming the losing row.
- Got: `onMergeSuccess(spaceUuid, syncedHlc)` says a space merged, not what changed, and the module's server endpoint passes no callback. The loser is found by parsing the `__conflict__<UUID>` suffix; `CrdtProjectionReason.uniqueConflict` is marked diagnostic-only.
- Repro: `cell_conflict_test.dart`, T1.
- Workaround: re-read after every merge and parse keys (`chorus_shared/lib/src/cell_key.dart`).
- Suggest: a typed conflict event (table, column, winner, loser).

**6. A demoted member's pending edits are dropped silently**
- Expected: an error, or a list of refused rows.
- Got: a member writes offline, is made read-only on the server, then syncs. `syncOnce` completes normally; the row never reaches the server and stays on the author's device looking saved. In the source, the client stops sending for that space once the handshake delivers the new role (`space_state.dart`), so the server's `unauthorizedWrite` check is never reached.
- Repro: `spaces_test.dart`, "T8 ... made read-only".
- Workaround: none; Chorus has no demote endpoint yet.
- Suggest: report withheld changes to the app.

**7. Generated test tools do not wire the sync engine**
- Expected: `withServerpod` wires the engine, as the generated `Serverpod` class does.
- Got: `session.offlineSync` throws `StateError`.
- Workaround: pass `databaseInterceptor: offlineSyncDatabaseInterceptor` and call `session.serverpod.initializeOfflineSync(syncTables: syncTables)` (`chorus_server/test/integration/circle_endpoint_test.dart`).
- Related: `ValueEncoder` in `serverpod_database` is a process-wide static, so a Postgres server and a SQLite replica in one isolate render each other's dialect (`operator does not exist: uuid = bit`); see `replicas.dart`.
- Suggest: generate the wiring when `databaseSync` is on; make the encoder per database.

**8. Web needs `sqlite3.wasm` and `db_worker.js`, matched to `pubspec.lock`**
- Expected: the scaffold or a build step supplies them.
- Got: neither name appears in the module README or the Serverpod 4.0.4 packages we use; they are `sqlite_async`'s defaults. We fetched the builds for `sqlite3` 3.7.1 and `sqlite_async` 0.14.5 by hand (`docs/BUILD.md`) and did not test the failure without them.
- Suggest: a CLI step that fetches matching files.

**9. The latest module version on pub.dev needs a Serverpod beta**
- Expected: the newest version works with stable Serverpod.
- Got: 0.0.11, published two hours after 0.0.10, requires `serverpod: ^4.1.0-beta.3`; 0.0.10 requires `>=4.0.4 <4.1.0` (pub.dev API, 13 Oct 2026). We pinned 0.0.10 and did not test what `pub add` resolves.
- Suggest: a compatibility table at the top of the README.

**10. A duplicate primary key on SQLite raises the base exception**
- Expected: `DatabaseUniqueViolationException`, as a unique-index clash gives (code 2067).
- Got: `DatabaseQueryException`, `UNIQUE constraint failed: board.id`, code 1555. The adapter maps only 2067 (`sqlite_error_codes.dart`).
- Repro: `merge_test.dart`, "T7 ... seeds again".
- Workaround: catch the base type when seeding.
- Suggest: map 1555 too.

**11. Two tabs of one browser profile sign each other out**
- Expected: both tabs stay signed in.
- Got: one tab was signed out; the server logged `RefreshTokenNotFoundException`. Seen once, in Edge. A refresh with a stale rotating secret deletes the token row (`serverpod_auth_core_server`, `jwt_admin.dart`), and each tab appears to cache its own copy.
- Repro: two tabs, one profile, one user.
- Workaround: a normal window and a private window.
- Suggest: re-read the stored token before refreshing, or document the limit.

## Three small proposals, ranked

1. A debug-mode guard for finding 1, the costliest silent failure.
2. One richer sync callback: changed tables, conflict losers, withheld changes (findings 5 and 6).
3. A "before you ship" README section: compatibility table, web files, "always pass `columns`", "reads span all your spaces", test-tools wiring.
