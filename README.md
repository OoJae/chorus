# Chorus

A talking picture board that a non-speaking child's whole circle keeps in step from their own devices, and that still speaks with no signal.

> **Honest status**
>
> - Hackathon project, built for "Build Something Real: The Serverpod Hackathon" (October 2026).
> - No child, parent or clinician has used Chorus. The child in the video is a persona. Nothing here is clinically validated, and Chorus is not a replacement for an established communication tool.
> - It depends on Serverpod's offline sync module, which is experimental. Chorus pins one released version.
> - Mature tools exist. CoughDrop and AsTeRICS Grid already offer offline boards with cloud sync, and others sync across devices. We have not found a tool that shows what happens when two adults change the same board offline; that is the narrow thing Chorus explores. TODO: list the tools looked at and the date.
> - What is deployed: TODO, list the phases actually deployed at the submission tag. Anything else in this repository is work in progress on `main`.

## What it does

- The child taps words on a 6×6 board of core words. A sentence strip fills and the device speaks it, using on-device speech. No network is needed.
- Adults in the child's circle (guardian, therapist, teacher) add words from their own devices. A new word shows on the child's board as "1 word waiting" and lands only at a safe moment: the strip is empty, nothing is being spoken, and nobody has touched the board for two seconds.
- No button the child already uses ever changes place.
- When two adults fill the same empty cell offline, both words survive. One holds the cell; the other waits in a "Needs a home" tray until an adult gives it an empty cell.

## Try it in two minutes

- Web app: TODO link
- Android APK: TODO link
- Demo accounts: TODO parent, TODO therapist, TODO partner (read-only). Or choose "Start a fresh demo circle" for a board nobody else has touched.

Short version: sign in as two different adults on two devices (two browser profiles, or a browser and the APK), add a word on one and watch it arrive on the other, take both offline, put different words in the same empty cell, reconnect, and look for "Needs a home". The full script is in [`docs/manual-test.md`](docs/manual-test.md).

## Feature to code

Paths checked against the tree on 2026-10-13. Rows marked TODO are for code that was still being written that day; fill in the path or delete the row before the submission tag.

| Feature | Where it lives | Notes |
|---|---|---|
| Cell keys: the three forms, and the guard that stops the app writing an engine marker | `chorus_shared/lib/src/cell_key.dart` | `CellKey.parse`, `placedKey`, `trayKey`, `assertAuthorable` |
| Who holds each cell, and who needs a home | `chorus_shared/lib/src/tray.dart` | `gridOf`, `trayOf`, `emptyCells` |
| Held snapshot: what may change under the child, and when | `chorus_shared/lib/src/reconcile_snapshot.dart` | `BoardSnapshot`, `reconcileSnapshot`, `isSafePoint` |
| Starter board, Universal Core 36, deterministic ids | `chorus_shared/lib/src/starter_board.dart` | `starterBoard`, `starterTiles`, `deterministicId`, `colorForKey` |
| Reconnect backoff | `chorus_shared/lib/src/backoff.dart` | `backoffDelay` |
| Plain value types the rules work on | `chorus_shared/lib/src/facts.dart` | `BoardFacts`, `TileFacts` |
| Synced tables | `chorus_server/lib/src/boards/{board,tile,tile_edit}.spy.yaml` | all `database: sync`; `cellKey` is `unique(per=spaceId)` |
| Sync module switched on | `chorus_server/config/generator.yaml` | module entry plus `experimental_features: databaseSync: true` |
| Circles, spaces, roles and invitations | `chorus_server/lib/src/circles/circle_endpoint.dart` | `createCircle`, `myCircles`, `createInvite`, `acceptInvite` |
| Server time, for the clock-skew check, and minimum build | `chorus_server/lib/src/circles/status_endpoint.dart` | `info` |
| Screen contracts and in-memory fakes | `chorus_ui/lib/contracts.dart`, `chorus_ui/lib/fakes.dart` | `BoardStore`, `SpeechService`, `SyncStatus`, `CircleRole` |
| Talker screen and controller | `chorus_ui/lib/talker/` | `TalkerController`, `TalkerScreen` |
| Editor, add-word sheet, "Needs a home" tray | `chorus_ui/lib/editor/` | `EditorScreen`, `showAddWordSheet`, `TrayPanel` |
| Status chip | `chorus_ui/lib/widgets/sync_chip.dart` | plain-words state plus "Sync now" |
| Credits and licences screen | `chorus_ui/lib/credits/credits_screen.dart` | |
| Local replica and write queue | TODO: path under `chorus_flutter/lib/` | the real `BoardStore` |
| Reconnect, clock-skew check, status | TODO: path under `chorus_flutter/lib/` | |
| Speech | TODO: path of the `SpeechService` implementation | on-device text-to-speech, warmed at start |
| Web database files | `chorus_flutter/web/sqlite3.wasm`, `chorus_flutter/web/db_worker.js` | versions and hashes in [`docs/BUILD.md`](docs/BUILD.md) |

## Architecture in words

**Five packages in one pub workspace.** `chorus_server` (Serverpod: models, endpoints, tests), `chorus_client` (generated), `chorus_flutter` (the app: Android, web, macOS), `chorus_ui` (the screens, written against small contracts with in-memory fakes so they run and are tested with no server) and `chorus_shared`, a pure Dart package holding the rules that the app, the server and the tests all use. The rules have no dependency on generated code, so they are unit-tested with nothing but the Dart SDK.

**One synced space per child.** Guardian, therapist and teacher are read-write; a partner is read-only. The talker is a guardian account in a locked mode that writes no synced rows. Every synced row also carries the app's own `circleId`, because reads span all of a user's spaces and the engine returns its own space id as null.

**Three small synced tables.** `Board` (name, rows, cols, archived), `Tile` (board, `cellKey`, label, speech, image hash, audio hash, colour key, archived, author) and `TileEdit` (an append-only log; TODO: say here whether it is in use at the submission tag).

**A tile's position is one string.** `cellKey` is unique within a space and has exactly three forms:

- `<boardId>:<row>:<col>`: on the board.
- `tray:<tileId>`: unplaced or archived. Written by the app.
- `<boardId>:<row>:<col>__conflict__<rowId>`: written only by the sync engine, to the loser of a collision. The app never writes it; the shared code throws if it tries.

**What happens on a collision.** Two offline inserts into the same cell both survive. The earliest claim keeps the cell and the engine suffixes the other. No event fires, so after every merge the shared `trayOf` function finds the tray and contested tiles. A local insert into a cell that is already occupied on that device throws; the app retries with the tray form.

**Allowed moves.** From the tray or a conflict into an empty cell, and from the board to the tray. Never from one cell to another. Archiving sets the flag and rewrites `cellKey` to the tray form in one update, because the flag alone does not free the cell. When a cell is freed, the engine hands it to the oldest waiting loser on every device, and the app shows that as a new word arriving.

**Two write rules.** Every update names its changed columns; otherwise the merge becomes whole-row last-writer-wins. Every write goes through `transactionForUser(userId, fn, spaceId: circleSpaceId)`; a write outside it lands in the user's personal space and nobody else ever sees it.

**Seeding.** The starter board is seeded once, by the creating guardian's client, after its first sync, with deterministic ids, so a retried seed merges into the same rows.

**On the device.** `ReplicaService` keeps one SQLite file per signed-in user, sends all writes through one queue, and refuses writes until a sync has delivered the circle's space. `SyncSupervisor` restarts sync with backoff on connectivity change and app resume (the module has no auto-reconnect), checks clock skew first and stops sync if it is over a minute, and drives the status chip.

**The held snapshot.** The child's board renders from a snapshot, not from the live replica. Incoming changes are counted as "N words waiting" and applied only at a safe moment. A new word in an empty cell, a content change to a tile in place, and a removal that leaves a gap are applied automatically then. Anything that would show a different tile in an occupied cell, or an existing tile in a different cell, is never applied automatically; it waits for an adult.

**Privacy default.** Nothing the child says is stored or sent. Every member of a circle can read the whole board, and the app says so.

## Run locally

Pins. Exact versions, no carets, lockfiles committed:

| What | Version |
|---|---|
| Serverpod CLI and every Serverpod package | 4.0.4 |
| `serverpod_offline_sync_server`, `serverpod_offline_sync_client` | 0.0.10 |
| `serverpod_database` (client) | 4.0.4 |
| Flutter | 3.47.7 |

Do not run `pub upgrade`, and do not `pub add` without a version: the latest module release on pub.dev is 0.0.11, which needs a Serverpod beta. Read the module's docs at its `0.0.10` tag; its main branch documents 0.0.11.

Steps. Full detail, including the phone and the Cloud build, is in [`docs/BUILD.md`](docs/BUILD.md).

1. Install Flutter 3.47.7.
2. Install the Serverpod CLI: `dart install serverpod_cli@4.0.4`.
3. At the repository root: `dart pub get`.
4. Start the server and the app: in `chorus_server`, run `serverpod start`. It generates code, starts the server on port 8080, applies pending migrations and opens the app in the browser. No Docker is needed: `config/development.yaml` sets `database.dataPath`, so Serverpod runs its own embedded PostgreSQL.
5. For a second adult, open the same address in another browser profile, or in `chorus_flutter` run `flutter run -d chrome` or `flutter run -d macos`.
6. On a phone, pass the server address: `flutter run -d <device id> --dart-define=SERVER_URL=http://<address>:8080/`. `chorus_flutter/assets/config.json` points at `localhost`, which on a phone is the phone; the define wins over that file.

The web database needs `sqlite3.wasm` and `db_worker.js` in `chorus_flutter/web/`, matching `pubspec.lock`. Both are committed; [`docs/BUILD.md`](docs/BUILD.md) records where they came from and their hashes.

TODO: run these steps on a clean checkout before the submission tag.

## Tests and what each proves

| Suite | Command | Last run |
|---|---|---|
| Shared rules | `cd chorus_shared && dart test` | 2026-10-13: 108 passed, 0 failed |
| Screens and talker controller | `cd chorus_ui && flutter test` | 2026-10-13: 33 passed, 0 failed |
| Server: endpoints and sync scenarios | `cd chorus_server && dart test --concurrency=1` | TODO: date, passed, failed |
| App | `cd chorus_flutter && flutter test` | TODO: date, passed, failed |

The server tests need no Docker; `config/test.yaml` sets `database.dataPath`, so Serverpod starts an embedded PostgreSQL for them. The sync tests must not run in parallel, hence `--concurrency=1`.

TODO: delete rows below for tests that do not exist at the submission tag, and give the real file names.

**Shared rules** (`chorus_shared/test/`, plain Dart, no server):

| Test | What it proves |
|---|---|
| `cell_key_test.dart` | Each of the three forms parses to the right type; anything else is unknown; the app cannot author an engine marker |
| `tray_test.dart` | Contested, unplaced and off-grid tiles are found after a merge; one tile holds each cell |
| `reconcile_snapshot_test.dart`, with property tests | No tile the child can already see ever changes cell, and no occupied cell ever shows a different tile, without an adult |
| `reconcile_snapshot_test.dart`, safe point | A swap happens only with the strip empty, nothing speaking and two seconds since the last touch |
| `starter_board_test.dart` | 36 words, row-major, with ids that are the same on every run |
| `backoff_test.dart` | Reconnect delays grow and stay within their cap |

**Sync scenarios** (TODO: confirm the directory; planned as `chorus_server/test/sync/`, real Postgres and real SQLite replicas):

| Scenario | What it proves |
|---|---|
| Same cell | Two offline inserts of one cell give one clean row and one suffixed row on every replica |
| Locally occupied cell | A local duplicate throws, and the tile goes to the tray |
| Different properties | Offline edits to different columns of one tile both survive |
| Same property | Offline edits to the same column are last-writer-wins (a stated limit) |
| Archive versus edit | TODO: state the expected outcome once the test is written |
| Freed cell reclaimed | Archiving the winner hands the cell to the waiting loser |
| Double seeding | Seeding twice yields 36 tiles and an empty tray |
| Three identities with a read-only member | A read-only member receives the board and cannot write |
| Revoke | TODO: state what the test shows; see the limit on removed members |
| Clock two minutes ahead | TODO: state the expected outcome once the test is written |

**Endpoints**: role matrix. TODO: list the others that exist at the submission tag.

**Manual**: the deployed smoke test and its dated results are in [`docs/manual-test.md`](docs/manual-test.md). Every public sentence is mapped to its proof in [`docs/claims.md`](docs/claims.md).

## Limitations

Of Chorus:

- No clinical validation; no real user has tested it; the child in the video is a persona.
- Two adults editing the same label offline is last-writer-wins. The losing edit is not shown and cannot be restored until the edit log ships.
- Every member of a circle, including a read-only partner, can read the whole board.
- A removed member keeps what was already downloaded to their device.
- Text tiles only at the submission tag. TODO: confirm, and list anything else not deployed.
- TODO: platforms actually tested (Android model and version, browsers).

From the released sync module, and how Chorus works around each. Our notes for the Serverpod team are in [`docs/feedback-log.md`](docs/feedback-log.md). TODO: link the upstream issue for each line where one exists, and mark which of these we reproduced rather than read in the docs.

| Upstream behaviour at 0.0.10 | What Chorus does |
|---|---|
| The module is experimental; shared spaces have an open correctness issue whose fix is unreleased and breaking. TODO: issue link | Pins exact versions; tests three identities in one space |
| No auto-reconnect and no sync-status API | `SyncSupervisor`, a status chip and a "Sync now" button |
| A unique-conflict loser is marked only by a `__conflict__` suffix; no event fires | One parser in `chorus_shared`; `trayOf` runs after every merge |
| No hook to defer applying a merge | The held snapshot |
| Reads span all spaces and `spaceId` comes back null | An app `circleId` column on every synced row |
| Read-only members read everything; revocation leaves rows on the device | Stated in the app and above |
| The server is not told when a client's changes merge | Nothing on the server depends on it at the submission tag |
| The documented server-side write snippet does not compile | Synced rows are written by clients; spaces are created and managed on the server |
| Web needs `sqlite3.wasm` and `db_worker.js` placed by hand | Both are in `chorus_flutter/web/`, matched to `pubspec.lock`; see [`docs/BUILD.md`](docs/BUILD.md) |
| No statement of Android support | TODO: what we observed on our phone |

## Licences and attributions

- **Starter vocabulary**: the word list and layout of the home board are adapted from the 36-word Universal Core vocabulary, copyright Center for Literacy and Disability Studies, University of North Carolina at Chapel Hill, licensed CC BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/). Source: https://www.project-core.com/. Changes made: the words are shown as text tiles rather than with the original symbols, and each tile carries a part-of-speech colour key. The adaptation is released under the same licence. Chorus is not affiliated with or endorsed by the Center. The full note is in [`chorus_shared/STARTER_BOARD_LICENSE.md`](chorus_shared/STARTER_BOARD_LICENSE.md), and the same attribution is on the in-app credits screen. TODO: confirm the exact attribution wording the Center asks for.
- No ARASAAC, Sclera or proprietary symbol set is bundled.
- **Chorus's own code**: MIT, copyright 2026 OoJae. See [`LICENSE`](LICENSE). The one exception is the starter-board data in `chorus_shared/lib/src/starter_board.dart`, which is an adaptation of the vocabulary and so is CC BY-SA 4.0.
- **Web database files**: `chorus_flutter/web/sqlite3.wasm` is a build of SQLite (public domain) from the `sqlite3` Dart package (MIT); `chorus_flutter/web/db_worker.js` is from the `sqlite_async` Dart package (MIT). Both are unmodified release files; sources and hashes are in [`docs/BUILD.md`](docs/BUILD.md).
- **Dependencies**: every package and its exact version is in `pubspec.lock`. TODO: list the direct ones and their licences at the submission tag.

## AI disclosure

Chorus was built with Claude Code. TODO: one or two sentences, confirmed by the author, on what it was used for (planning, code, tests, these documents) and what the author did by hand. TODO: if the AI photo-to-word feature is deployed, name the provider here and say that an adult approves every suggestion; otherwise say the app itself uses no AI.
