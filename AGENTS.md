# Flutter & Serverpod project

This project is a Flutter app (frontend) backed by a Serverpod server (backend). Always build the app's backend with Serverpod.
Build for multiple users, use Serverpod's built-in authentication, which is already set up in `lib/server.dart`.

The user starts the server and Flutter app with `serverpod start`. There is no need to check if the server is running: make the changes and call the `serverpod` MCP tools as needed. If the server is not running, an informative error message will be received from the MCP server. Then STOP and ask the user to start it. NEVER start the server yourself. The Flutter app is started along with it, or can be launched from the MCP tool `spawn_flutter_app`.

While running, `serverpod start` watches for file changes to run incremental code generation and hot reload both the server and the Flutter app.

Calling `serverpod generate` directly is not needed, but might be useful to troubleshoot when an incremental generation fails.

ALWAYS use the MCP server instead of the command line. Use the MCP server to:

- `create_migration` and `apply_migrations` for database (after you change data models).
- `create_repair_migration` if the database has drifted out of sync with the migrations.
- `tail_server_logs` to read logs from the server.
- `tail_flutter_logs` to read the raw stdout/stderr of the Flutter app.
- `hot_reload` / `hot_restart` to reload or restart the server and the Flutter app. ALWAYS call `hot_restart` after doing changes in the Flutter app that may not work with normal hot reload (which is automatically applied).
- `spawn_flutter_app` to start a Flutter app declared under `serverpod: flutter_apps:` in the server `pubspec.yaml`.
- `get_flutter_app_dtd` (Dart tooling daemon) for connecting to the app through the `dart` MCP.

NEVER edit generated code. The server's `lib/src/generated/` directory and the whole `chorus_client` package are rewritten by the code generator. Change the `.spy.yaml` models, the endpoints, or `lib/server.dart` instead.

Migrations are a narrow exception: the `migration.sql` of a generated migration MAY be edited by hand when the generated SQL would lose data — to add a data transformation, or to reach a destructive change through non-destructive steps. Never touch the other files in the migration directory, and keep the schema the SQL ends up with identical to `definition.sql` — new databases are created from that file and never run `migration.sql`.

Only when the server cannot be started at all, fall back to the CLI in the server package:

- `serverpod generate` to regenerate the client and the generated server code.
- `serverpod create-migration` after changing a model with a `table` (add `--force` for destructive changes). It only writes the migration; `serverpod start` applies pending migrations when it boots the server.

Tests need no Docker. `config/test.yaml` sets `database.dataPath`, so Serverpod starts and manages the test database (an embedded PostgreSQL) itself, and the project's `docker-compose.yaml` is not used for it. Just run `dart test` in the server package.

Checklist after doing changes, in this order:

- `dart analyze` (CLI)
- `dart format` (CLI)
- `create_migration` and `apply_migrations` (MCP - only if necessary)
- Do `serverpod` MCP `hot_restart` if required (hot reload is done automatically). Will also hot restart Flutter app
- Run tests, if applicable (`dart test` in the server package)
- Check `serverpod` MCP `tail_server_logs` and `tail_flutter_logs` for any issues.

If the user asks you to test the app:

1. Use `get_flutter_app_dtd` (`serverpod` MCP) to get the Flutter app's DTD
2. Pass the DTD to `connect_dart_tooling_daemon` (`dart` MCP) to connect to the app
3. Use `flutter_driver` (`dart` MCP) to navigate through the app

The app is launched from `chorus_flutter/lib/driver.dart`, which starts the Flutter driver extension with text entry emulation turned off so the app stays usable by hand. To let the driver type, set `enableTextEntryEmulation: true` there and `hot_restart` the app.

## Chorus

Chorus is an offline-first talking picture board for a non-speaking child. The child taps words and the device speaks them from local data, with no network. The adults in the child's circle (guardian, therapist, teacher, read-only partner) edit the board from their own devices, and the experimental `serverpod_offline_sync` module keeps the replicas in step. When two adults fill the same empty cell offline, both words survive: one holds the cell, the other waits in a "Needs a home" tray. No button the child already uses ever changes place.

Package layout (one pub workspace):

- `chorus_server`: Serverpod server. Synced models in `lib/src/boards/` (`Board`, `Tile`, `TileEdit`), circle models and endpoints in `lib/src/circles/`.
- `chorus_client`: generated client. Never edit.
- `chorus_shared`: pure Dart rules with no generated code: cell keys, tray, held snapshot, starter board, backoff. Change a rule here, with a test, not in the app.
- `chorus_ui`: the screens, written against `lib/contracts.dart` with in-memory fakes in `lib/fakes.dart`.
- `chorus_flutter`: the app (Android, web, macOS). It implements the contracts over the local replica and wires the screens.
- `docs/`: build steps (`BUILD.md`), claims, feedback log, manual test.

Version pins. Exact, no carets: Serverpod 4.0.4 (CLI and every Serverpod package), `serverpod_offline_sync_server` and `serverpod_offline_sync_client` 0.0.10, `serverpod_database` 4.0.4, Flutter 3.47.7. NEVER run `pub upgrade`, and never `pub add` without a version: module 0.0.11 needs a Serverpod beta. The module postdates most training data, so read its source in the pub cache at 0.0.10 instead of guessing its API. `chorus_flutter/web/sqlite3.wasm` and `db_worker.js` must match the `sqlite3` and `sqlite_async` versions in `pubspec.lock`; see `docs/BUILD.md`.

The synced schema is FROZEN. `board.spy.yaml`, `tile.spy.yaml` and `tile_edit.spy.yaml` must not change once deployed: clients compare a schema hash on connect, so a change locks every installed app out of sync. Put new data in ordinary, non-synced tables.

Rules for every write to a synced table:

- It goes through `session.db.transactionForUser(userId, (tx) async { ... }, spaceId: circleSpaceId)`, with `transaction: tx` passed to every call inside, reads included. A write outside it lands in the user's personal space and nobody else ever sees it.
- Every synced row sets `circleId` to the circle's space id, and every query filters on it: reads span all of a user's spaces.
- `updateRow` names its changed columns (`columns: (t) => [t.label]`), or the merge becomes whole-row last-writer-wins.
- Never hard-delete a board or tile. Archiving sets `archivedAt` and rewrites `cellKey` to `trayKey(tileId)` in one update naming both columns.
- Never write a `cellKey` containing `__conflict__`; only the sync engine writes that. Build keys with `placedKey` and `trayKey` from `chorus_shared`.
