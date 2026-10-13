# Spike S4 results: what the sync engine really does

Run on 13 Oct 2026 against Serverpod 4.0.4, `serverpod_offline_sync` 0.0.10, embedded Postgres and real SQLite replica files, on the Mac (Dart 3.13.5).

Every row below is an automated test in `chorus_server/test/sync/`. Each scenario makes its own users and its own circle through the real `CircleEndpoint` over HTTP, opens one SQLite replica per device, and uses `syncOnce` to converge.

```
cd chorus_server
dart test test/sync --concurrency=1      # the 21 sync tests
dart test --concurrency=1                # all 35 server tests, 20 to 25 s
```

Plain `dart test` (files in parallel) also passed, in about 12 s.

**Verdict on S4: passes.** The plan's conflict design holds. Three things differ from what the plan assumes and need a product decision; they are marked **DIFFERS** and listed again under "Decisions this forces".

## Results

"Everywhere" means the server and every replica in the scenario, checked separately.

| # | Scenario | Expected by the plan | Observed | Result |
|---|---|---|---|---|
| T1 | Two members, both unsynced, each insert a different tile with the same placed `cellKey` | Both rows survive; the earlier claim keeps the cell; the later one becomes `<cell>__conflict__<its id>` | Exactly that, everywhere. The earlier write wins whichever device syncs first and whichever member wrote it (three orderings tested). `trayOf` reports the loser as `contested` with the right `wanted` cell; `gridOf` shows the winner. | pass |
| T2 | A replica that holds a tile in a cell inserts another with the same key | The insert throws; retrying with `trayKey` succeeds | Throws `DatabaseUniqueViolationException` (`UNIQUE constraint failed: tile.spaceId, tile.cellKey`, SQLite code 2067). Nothing is left behind, and the retry with `trayKey(id)` succeeds. An `updateRow` that moves a tray tile into an occupied cell throws the same type. Writing `<cell>__conflict__<uuid>` throws `OfflineSyncReservedValueException`. | pass |
| T3 | Two members change different columns of one tile, each naming its column | Both changes survive | Both survive everywhere. | pass |
| T3 control | The same two changes written with `updateRow` and no `columns` | Whole-row last-writer-wins | Confirmed: the later writer's stale `label` overwrote the earlier label change. The earlier edit is silently lost. | pass (confirms the rule) |
| T4 | Both change `label` while unsynced, each also inserting a `TileEdit` | One wins; both `TileEdit` rows survive | The later write wins everywhere, whichever device syncs first and whichever member wrote later (three orderings tested). Both `TileEdit` rows are on the server and on both replicas, so the overwritten value can be restored. | pass |
| T5 | Give the T1 loser a fresh empty cell with one `updateRow` naming `cellKey` | Converges clean | Clean placed key everywhere, tray empty. Works when the loser's author does it and when the other member does it. | pass |
| T6 | Archive the T1 winner (`archivedAt` and `cellKey = trayKey(id)` in one update naming both) | The engine hands the cell to the waiting loser on every device | It does, with no app code. The loser's key loses its suffix on the archiving device **immediately, before any sync**, and on the server and the other replica after one sync round. Tray empty afterwards. For a talker holding the old snapshot, `reconcileSnapshot` classes this as `replaced`, not `added`. | pass, with one **DIFFERS** in how the child's board must treat it |
| T7 | Two replicas each insert the starter board and its 36 tiles with the deterministic ids while unsynced | 36 tiles and an empty tray | 36 tiles, empty tray, no empty cells, everywhere. Tested with two devices of one guardian and with a guardian and a teacher. With two different users the later seed's columns win field by field (`createdByName` became the later seeder's on all 36). | pass |
| T7 retry | A device that already holds the starter board seeds again | Not specified | The insert throws `DatabaseQueryException` (`UNIQUE constraint failed: board.id`, SQLite code 1555). This is the base type, **not** `DatabaseUniqueViolationException`. Nothing changes. | recorded |
| T8 | Guardian and teacher read-write, partner read-only | Writes by the first two reach all three; a partner write is refused | Both tiles reach all three replicas. A partner write is refused **on the device**: `transactionForUser` throws `OfflineSyncSpaceRoleException` (role `readOnly`) before the callback runs, for insert and update alike. Nothing is stored. | pass |
| T8 early | A member joined on the server but the device has not synced yet | Writes need one sync first | `transactionForUser` throws `OfflineSyncSpaceMembershipException`. After one `syncOnce` the same write succeeds. | pass |
| T8 stale | A read-write member writes offline, is made read-only on the server, then syncs | Not specified | `syncOnce` completes with **no error**. The server never takes the row and no other member gets it, but the row stays visible on the author's own device. After that sync the device knows its new role and further writes throw `OfflineSyncSpaceRoleException`. | **DIFFERS**: a refused write is silent |
| T9 | A tile for a shared board written with the ordinary ORM call, outside `transactionForUser` | Lands in the author's personal space; the author sees it, nobody else does | No error. The server files it under the author's personal space and the other member never gets it. But the author does **not** see it either: its board lives in the circle's space, and the engine hides a row whose parent is in another space. The row's key is rewritten to `<cell>__hidden__<its id>` at once and ordinary reads leave it out (it shows only with `where: (t) => t.includeHiddenRows`). The cell stays free for a proper write. | **DIFFERS**: the word vanishes instead of showing on one device |
| T9 seed | A board and a tile both written outside `transactionForUser` | As above | Nothing is hidden, because parent and child are both personal. The author sees the board under the `circleId` filter; no other member ever does. | pass (this is the bug as the plan describes it) |
| T10 | A user in two circles, with personal rows too | A query filtered by `circleId` returns only that circle's rows | Confirmed. An unfiltered read returns the rows of both circles and the personal rows together, and `spaceId` is null on every row read back. A member of one circle gets only that circle's rows. | pass |

## Exact exception types

| Situation | Type | Thrown by | When |
|---|---|---|---|
| Insert or update into an occupied cell on one replica | `DatabaseUniqueViolationException` (package `serverpod_database`), SQLite code 2067 | the local write | inside the transaction, which rolls back |
| Insert of a row whose id already exists locally (second seed) | `DatabaseQueryException`, SQLite code 1555 | the local write | inside the transaction |
| Writing a unique value ending in `__conflict__<uuid>` | `OfflineSyncReservedValueException` | the local write | before the row is stored |
| Read-only member writes | `OfflineSyncSpaceRoleException` (has `userId`, `spaceId`, `role`) | `transactionForUser` | before the callback runs |
| Member writes before a sync delivered the membership | `OfflineSyncSpaceMembershipException` (has `userId`, `spaceId`) | `transactionForUser` | before the callback runs |
| Server drops a write from a member it no longer lets write | none | n/a | `syncOnce` completes normally |
| Write outside `transactionForUser` | none | n/a | the write succeeds |

`DatabaseUniqueViolationException` extends `DatabaseQueryException`, so catch the subtype first.

## Timings

All measured over loopback on one machine, with no network delay. They show the engine's own cost, not what a phone on mobile data will see.

| What | Observed |
|---|---|
| One `syncOnce` | 18 to 31 ms at best, median 25 to 47 ms, worst 60 to 504 ms per test file (about 270 syncs per run, four runs) |
| The `syncOnce` that delivers a new membership | 28 to 43 ms |
| Seeding the board and 36 tiles locally, one transaction | 22 to 28 ms |
| The first `syncOnce` after seeding (37 rows up) | 107 to 126 ms |
| Sync rounds until every node agrees, when two replicas hold unsynced changes | 2 (the device that synced first must sync once more to learn the other's change) |
| Sync rounds when only one replica holds changes | 1 |

A "round" is one `syncOnce` per replica. So after an offline collision the device that reconnects first does not show the conflict until its second sync.

## Decisions this forces

1. **A freed cell reclaims itself, and the child's board must hold it back (T6).** The plan says the app shows the reclaim "as a new word arriving at a safe moment". In one merge the archived tile leaves the cell and the waiting tile enters it, so `reconcileSnapshot` reports `replaced` and puts it under `needsAdult`. That is the safe reading: a cell the child knows would change meaning. The talker must not auto-apply it. The reclaim also happens on the archiving adult's own device the instant they archive, with no sync, so the editor will show the waiting word jump into the cell as the old one is removed.

2. **A demoted member's pending edits are dropped without a word (T8 stale).** Nothing throws and no status reports it. The rows stay on that device looking saved. If Chorus ever changes or removes a member's role, the app has to find these itself (for example: after a sync shows the role is now read-only, list local rows this user authored that the server never acknowledged). Until there is a demote or remove feature this cannot happen; neither endpoint exists today.

3. **A write outside `transactionForUser` makes the word disappear (T9).** No error, no row on screen, not even on the author's device. The plan's description ("lands in the personal space and nobody else sees it") undersells it for tiles and edits, and matches only when a whole board is written unwrapped. One code path for writes (the plan's `ReplicaService` queue) is therefore required, not just tidy. A cheap guard: after every write, re-read the row by id and treat "not found" as a bug.

4. **Seeding twice is safe across devices but throws on one device (T7).** Two devices seeding the same circle merge into one clean board. The same device seeding twice gets a `DatabaseQueryException`. The app should check that the home board row exists before seeding, and catch that type as "already seeded".

5. **Catch by type when placing a tile (T2).** `DatabaseUniqueViolationException` on insert or update means "cell taken": retry with `trayKey(id)`. The transaction that threw has rolled back, so the retry needs a new one.

## What differed from the briefing

- **The generated test tools do not configure the sync engine.** `withServerpod` builds a plain `Serverpod`, not the generated subclass. A test that touches the sync engine or `CircleEndpoint` must pass `databaseInterceptor: offlineSyncDatabaseInterceptor` and call `session.serverpod.initializeOfflineSync(syncTables: syncTables)` itself; otherwise `session.offlineSync` throws `StateError`. With that, the spaces API and `CircleEndpoint` work in the test tools, including inside the default rolled-back transaction.

- **A Postgres server and a SQLite replica cannot share one isolate without help.** `serverpod_database` 4.0.4 keeps one process-wide `ValueEncoder` and replaces it whenever a `Database` is constructed: on every server request (Postgres) and every client database open (SQLite). Query expressions read it when rendered. Following the module's own test pattern unchanged, the first run failed with `operator does not exist: uuid = bit` on the server and `UNIQUE constraint failed: offline_sync_spaces.uuidSpaceId` on the client. `test/sync/replicas.dart` works around it with an encoder that picks the dialect by zone. This is a test-only hazard: the app's client is a separate process. It is worth a line in `docs/feedback-log.md`.

- **The reserved marker is narrower than "contains".** Read from the source, not tested beyond one case: the engine refuses unique text values that **end** in `__conflict__<UUID>`, `__hidden__<UUID>` or `__park__<UUID>`. `chorus_shared`'s `assertAuthorable` refuses the markers anywhere, which is stricter and fine.

- **`__hidden__` is a fourth key form that really occurs** (T9), though only on rows ordinary reads leave out. `CellKey.parse` already maps it to `UnknownCell`.

- **Role refusals happen on the device, not the server**, for a device whose view of its role is current. The server-side refusal exists but is silent (T8 stale).

Everything else in the briefing's sync facts held as stated where a scenario touched it: `createSyncSession` with `persistentUserId`, `transactionForUser(me, fn, spaceId:)`, `transaction: tx` on every call, narrowed `columns`, null `spaceId` on reads, membership needing one sync, and `syncOnce`.

## Not covered

- `syncContinuously`, reconnect and backoff (spike S6).
- Clock drift over a minute (`ClockDriftException` exists in the source; no scenario sets a clock forward).
- Revoking a member. Only a change from read-write to read-only was tried.
- Archive on one device against an edit of the same tile on another.
- The web replica (single connection). These tests use native SQLite files.
- Android. Everything here ran on macOS.
- Whether the server records the dropped write of T8 stale in its integrity-violation table. The test checks only that the row is absent and that no error is raised.

## Endpoint tests

`chorus_server/test/integration/circle_endpoint_test.dart`, 13 tests, all passing: unauthenticated calls refused; create circle (guardian, read-write space, name clean-up); `myCircles` order and isolation; invite code format; teacher and therapist mapped to read-write, partner to read-only; wrong code (`inviteInvalid`); used code (`inviteUsed`, and the same person using it again changes nothing); expired code (`inviteExpired`, seven-day lifetime); guardian-only inviting (`notAllowed` for a member, `notAMember` for a stranger); a member accepting a second invitation keeps their role.

One behaviour to know about: when an existing member accepts an invitation for a different role, the role is kept **and that code is spent** on them. A guardian who sends a "promotion" code to a partner loses the code and changes nothing.
