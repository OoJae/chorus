# Draft issues for the Serverpod team

These are drafts. Nothing here has been filed. The participant decides whether to file each one, and where (the `serverpod` repository or the offline sync module's).

Each draft:
- comes from an entry in [feedback-log.md](feedback-log.md);
- names the versions Chorus pins: Serverpod 4.0.4 and `serverpod_offline_sync` 0.0.10;
- points at a test in this repository that reproduces it.

---

## 1. Offline sync: expose unique-index conflicts as typed data, not a string suffix

**Versions:** Serverpod 4.0.4, `serverpod_offline_sync_server` / `_client` 0.0.10.

**What happens:**
1. Two replicas insert different rows with the same value in a column that is unique per space, both offline.
2. The engine keeps both rows, which is a great design.
3. It marks the later claim by rewriting the column to `<value>__conflict__<rowId>`.
4. Nothing else tells the app this happened: no flag on the row, no event, no documented format.

**Why it matters:** this is the most valuable thing the engine does for collaborative apps, and the only way to reach it is to parse an undocumented string that could change between versions. Chorus turns these rows into a "Needs a home" tray for a child's picture board. It finds them with a regular expression (`chorus_shared/lib/src/tray.dart`).

**Repro:** `chorus_server/test/sync/cell_conflict_test.dart` (T1, three orderings). It runs against an embedded PostgreSQL and real SQLite replicas.

**Suggestion:**
- A typed conflict marker readable on the row, or a typed conflict event: table, column, kept row id, parked row id.
- Until then, document the suffix format as stable.

(Feedback log F04.)

---

## 2. Offline sync: a way to defer applying incoming changes

**Versions:** as above.

**What happens:** merged changes reach the local database as soon as they arrive. There is no way to hold them.

**Why it matters:** some screens must not change under the user. A child building a sentence on a picture board is one. Chorus renders the child's screen from its own held snapshot and reconciles by hand when it is safe: strip empty, nothing speaking, two seconds without a touch. That logic is `chorus_shared/lib/src/reconcile_snapshot.dart` and `chorus_ui/lib/talker/talker_controller.dart`, with property tests. Every app with a "don't move under my finger" screen will rewrite this.

**Suggestion:** a client option to pause applying merges and resume, or a pending-changes stream the app applies when it chooses.

(Feedback log F09.)

---

## 3. Database: one process-wide `ValueEncoder` breaks server and replica tests in one isolate

**Versions:** `serverpod_database` 4.0.4.

**What happens:** `serverpod_database` keeps one `ValueEncoder` for the whole process. It is replaced whenever a `Database` is constructed. With a PostgreSQL server database and a SQLite replica in the same isolate, each renders SQL in the other's dialect. This is the pattern the module's own tests suggest. The failures:
- `operator does not exist: uuid = bit` on the server;
- `UNIQUE constraint failed: offline_sync_spaces.uuidSpaceId` on the replica.

**Repro:** see the workaround in `chorus_server/test/sync/replicas.dart`. It imports two `serverpod_database/src` files to swap the encoder per call. Remove the workaround and every test in `chorus_server/test/sync/` fails.

**Suggestion:** make the encoder a property of the database or session, not a global.

(Feedback log F13.)

---

## 4. Offline sync: a write refused by the server is silent on the client

**Versions:** as in issue 1.

**What happens:**
1. A member holds an unsynced write.
2. The server makes that member read-only.
3. `syncOnce` returns with no error.
4. The server never takes the row, and it stays on the author's device looking saved.

**Why it matters:** an app cannot tell its user that an edit was refused, which is the worst kind of data loss.

**Repro:** `chorus_server/test/sync/spaces_test.dart`, scenario "T8 stale".

**Suggestion:** report refused changes to the client, as an exception or a callback naming the rows.

(Feedback log F15.)

---

## 5. Offline sync: a write outside `transactionForUser` silently hides a shared row

**Versions:** as in issue 1.

**What happens:**
1. A client writes a row belonging to a shared space without `transactionForUser(..., spaceId:)`. It is the most natural mistake.
2. The write lands in the personal space.
3. The unique key becomes `<value>__hidden__<id>`.
4. Ordinary reads omit the row, even for its author.

There is no error.

**Repro:** `chorus_server/test/sync/spaces_test.dart`, scenario T9.

**Suggestion:** throw, or log a warning in debug mode, when a write lands in the personal space but references a row in a shared one.

(Feedback log F16.)

---

## 6. Generated test tools: wire the sync module into `withServerpod`

**Versions:** Serverpod 4.0.4 with `databaseSync` on.

**What happens:** `withServerpod` builds a server without the sync engine. As a result, `session.offlineSync` throws `StateError` in every endpoint test of an app that uses shared spaces. The fix is for the test to pass `databaseInterceptor: offlineSyncDatabaseInterceptor` and call `initializeOfflineSync(syncTables: ...)` itself.

**Repro:** `chorus_server/test/integration/circle_endpoint_test.dart`. Remove its setup lines and the tests throw.

**Suggestion:** have the generator wire the module into the test tools when `databaseSync` is on.

(Feedback log F14.)
