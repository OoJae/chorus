# Chorus

Chorus is an offline-first talking picture board for a non-speaking child. The child taps words and the device speaks them from local data. Adults edit the board from their own devices, and Serverpod's experimental offline sync module keeps the copies in step. No button the child already uses ever changes place. When two adults fill the same empty cell offline, both words survive.

Mature tools exist: CoughDrop and AsTeRICS Grid already offer offline boards with cloud sync. We have not found a tool that shows what happens when two adults change the same board offline. No child, parent or clinician has used Chorus; the child in the story is a persona.

[Square brackets] mark features that pass automated tests but are not yet checked on a real device.

## See it

- Web app: https://chorus.serverpod.space. Click "Sign up", enter your email address and the emailed code, set a password, then click "Try a demo board".
- Android APK: https://github.com/OoJae/chorus/releases/latest. TODO(owner): publish the release; none exists yet.
- Video: TODO(owner): link.
- Two-device walkthrough: [docs/TRY-IT.md](docs/TRY-IT.md).
- [Demo sign-ins: `demo.parent@chorus.example`, `demo.therapist@chorus.example`, `demo.partner@chorus.example` (read-only).] TODO(owner): how judges get the password.

## What it demonstrates

1. **The board lives on the device.** The child's screen reads a local SQLite replica and uses the device's own speech engine.
2. **Changes land between sentences.** [A word from another device shows on the child's screen as "1 word waiting" ("1 waiting" on a phone). It lands only when the sentence strip is empty, nothing is speaking and the board has been untouched for two seconds.] A property test checks that an occupied cell never changes meaning.
3. **A same-cell collision keeps both words.** One holds the cell. The other waits in a "Needs a home" tray until an adult places it. This passes automated sync tests on real replicas, in three orderings. It has not yet been confirmed by hand with two accounts on two devices.

## How it uses Serverpod

| Feature | Where | Job |
|---|---|---|
| Offline sync, `database: sync` | [`generator.yaml`](chorus_server/config/generator.yaml), [`boards/`](chorus_server/lib/src/boards/) | Three synced tables; a SQLite replica on every device. |
| Shared spaces, roles | [`circle_endpoint.dart`](chorus_server/lib/src/circles/circle_endpoint.dart) | One space per child; its guardian writes. [An invited therapist or teacher writes too; a partner only reads.] |
| Sync client | [`replica_service.dart`](chorus_flutter/lib/src/sync/replica_service.dart), [`sync_supervisor.dart`](chorus_flutter/lib/src/sync/sync_supervisor.dart) | One `transactionForUser` write queue, and what the app adds around the module: reconnect with backoff, a clock check before sync (the module refuses drift over one minute; Chorus warns at 45 seconds), and the status chip. |
| Auth | [`server.dart`](chorus_server/lib/server.dart) | Sign-up with a code emailed by Serverpod Cloud. |
| Streaming method | [`live_endpoint.dart`](chorus_server/lib/src/live/live_endpoint.dart) | [An adult taps a word and it glows on the child's board.] |
| File storage | [`media_endpoint.dart`](chorus_server/lib/src/media/media_endpoint.dart) | [Family photos and recorded voices, private, named by SHA-256 and verified on the server.] |
| Web server | [`app_config_route.dart`](chorus_server/lib/src/web/routes/app_config_route.dart), [`print_routes.dart`](chorus_server/lib/src/printing/print_routes.dart) | Serves the web app and its API address. [`/print/<token>`: a printable paper copy.] |
| Passwords | [`suggest_service.dart`](chorus_server/lib/src/suggest/suggest_service.dart), [`demo_seed.dart`](chorus_server/lib/src/demo/demo_seed.dart) | [`anthropicApiKey` enables the photo-to-word suggestion; `demoPassword` creates the demo sign-ins.] |
| Serverpod Cloud | [`scloud.yaml`](chorus_server/scloud.yaml) | Hosts server, database and web app. TODO(owner): plan name. |

Gaps we worked around are logged for the Serverpod team in [docs/feedback-log.md](docs/feedback-log.md).

## The conflict design

A tile's position is one string, `cellKey`, unique within a space ([`tile.spy.yaml`](chorus_server/lib/src/boards/tile.spy.yaml)). It has three forms:

- `<boardId>:<row>:<col>`: on the board.
- `tray:<tileId>`: unplaced or archived. Written by the app.
- `<boardId>:<row>:<col>__conflict__<rowId>`: written only by the sync engine.

When two unsynced devices insert different tiles with the same placed key, the engine keeps both rows. The earlier claim keeps the cell; the later one gets the suffix. No event fires, so after every merge `trayOf` ([`tray.dart`](chorus_shared/lib/src/tray.dart)) parses the keys and lists suffixed tiles under "Needs a home". The app never moves a tile from one cell to another.

Earlier means the lower hybrid logical clock on the `cellKey` write, not the first to reach the server. A later word can therefore sync first, show on the child's screen, and lose the cell when the earlier write arrives. The same swap happens when the holder of a contested cell is removed: the engine hands the cell to the waiting word (T6). `reconcileSnapshot` classes both as `replaced` and keeps them out of the automatic changes. [The child's screen keeps the old word and marks the waiting count with an adult icon; an adult holds it for two seconds and confirms "Update the board?".] The held snapshot lives in memory, so closing and reopening the child's screen shows the board as synced.

Every update names its columns, so edits to different fields of one tile both survive. Edits to the same field are last-writer-wins. [Each edit is also logged in `TileEdit`, and the editor lists a replaced label, spoken text or colour under "Replaced changes" with a one-tap restore.]

Automated in [`chorus_server/test/sync/`](chorus_server/test/sync/) against an embedded PostgreSQL and real SQLite replicas. Results: [docs/spike-results.md](docs/spike-results.md).

## Checked on real devices

Checked on 13 October 2026 against the Cloud deployment. Full record: [docs/device-log.md](docs/device-log.md).

Seen working:

- Desktop browser (Edge on macOS): sign-up with an emailed code; "Try a demo board" seeded the board and the tester heard it speak.
- Android phone (Xiaomi, Android 16, release APK): a board created in the browser arrived through sync; the talker built "I want more" and the speech service opened audio output at each tap (driven over adb, nobody listening); "Hold to leave"; the second board, "My words"; adding a word online; adding a word with "Work offline" on.

Not yet checked on any device:

- The offline word reaching the server when sync resumes.
- A word arriving on another open device.
- A second adult joining a board with an invitation code. Covered by endpoint tests and sync test T8 only.
- Two devices filling the same empty cell offline, then the tray. Proven in the automated sync tests only.
- Real airplane mode.
- Photos and recorded voices, live modelling, "Replaced changes", the paper copy, the photo-to-word suggestion, the demo sign-ins. The last two also need server passwords that are not set yet.

## Build and run

Built and checked with Flutter 3.47.7; the pubspec allows 3.44.4 or later and CI runs 3.44.4. Pinned exactly: Serverpod CLI and packages 4.0.4, `serverpod_offline_sync_server` and `serverpod_offline_sync_client` 0.0.10. Do not run `pub upgrade`: module 0.0.11 needs a Serverpod 4.1 beta.

```sh
dart install serverpod_cli@4.0.4
flutter pub get        # repository root, one pub workspace
cd chorus_server
# config/passwords.yaml is not in the repository. Create it once.
# Any long random strings will do on your own machine.
cat > config/passwords.yaml <<'EOF'
development:
  database: 'local-dev-database-password'
  serviceSecret: 'local-dev-service-secret-0123456789'
  emailSecretHashPepper: 'local-dev-email-pepper-0123456789abcdef'
  jwtHmacSha512PrivateKey: 'local-dev-jwt-key-0123456789abcdef0123456789abcdef'
  jwtRefreshTokenHashPepper: 'local-dev-refresh-pepper-0123456789abcdef'
test:
  database: 'local-test-database-password'
  emailSecretHashPepper: 'local-test-email-pepper-0123456789abcdef'
  jwtHmacSha512PrivateKey: 'local-test-jwt-key-0123456789abcdef0123456789abcdef'
  jwtRefreshTokenHashPepper: 'local-test-refresh-pepper-0123456789abcdef'
EOF
serverpod start        # generates code, applies migrations, API on port 8080, opens the app
```

Run locally, the server sends no email: the sign-up code is printed in the server log.

No Docker: `config/development.yaml` sets `database.dataPath`, so Serverpod runs an embedded PostgreSQL. For a second adult use a private window: Chorus runs in one tab per browser profile, and a second tab says "Chorus is open in another tab".

Release APK, from `chorus_flutter`:

```sh
flutter build apk --release --dart-define=SERVER_URL=https://chorus.api.serverpod.space/
```

Deploy with `scloud deploy`; [`scloud.yaml`](chorus_server/scloud.yaml) runs `serverpod generate` and `serverpod run flutter_build` first. More in [docs/BUILD.md](docs/BUILD.md).

## Tests

| Suite | Command | Tests |
|---|---|---|
| Server: endpoints, sync | `cd chorus_server && dart test --concurrency=1` | 95 |
| Shared rules | `cd chorus_shared && dart test` | 150 |
| Screens | `cd chorus_ui && flutter test` | 154 |
| App | `cd chorus_flutter && flutter test` | 301 |

Counts are from 14 October 2026. The server suite runs on an embedded PostgreSQL and needs `config/passwords.yaml` from the build steps above; without it `demo_seed_test.dart` does not load and 89 of the 95 run. The sync test files ask for `--concurrency=1`. CI runs the server suite only.

## Limits

- No clinical validation and no real users.
- The sync module is experimental; Chorus pins 0.0.10.
- Two adults editing the same field offline is last-writer-wins. ["Replaced changes" covers label, spoken text and colour, not photos or recordings.]
- A member cannot be removed and a role cannot be changed.
- "Up to date" means the last sync finished without an error, not a receipt for each edit.
- A cell goes to the earlier write, even when it syncs last. A word already on the child's screen can then be replaced, once an adult accepts the update or the child's screen is reopened.
- [The live session works on one server instance.]
- No scheduled jobs (future calls) are used.
- The APK is debug-signed.
- The synced `Tile` table has two columns no code uses, `linkBoardId` and `noLog`. They were reserved for features that were not built, and the synced schema is frozen once deployed. Chorus has no tap logging.
- Phone layout problems are in the device log; the fix has not been seen on a device.

## Privacy

- The sentences the child builds are not stored. The child's screen only reads the board.
- [While the child's board is open online, connected members see that account as present. Sentences are sent only while a guardian has "Share what is said" on for that device: relayed to connected members, never stored.]
- The server holds each adult's email and display name, the child's name as typed, and the board. Every member, including a read-only partner, can read the whole board.
- [Photos are shrunk to 512 pixels and re-encoded on the device, and sit in private storage behind five-minute links. Re-encoding does not yet remove location data stored inside a photo file.]
- [A photo goes to Anthropic's API only when an adult presses "Suggest a word from the photo".]
- [A paper-copy link shows the child's name and words to anyone who has it, for 30 days.]
- No analytics or advertising code.

## Credits and licences

- **Code:** MIT, copyright 2026 OoJae ([LICENSE](LICENSE)).
- **Starter board:** the 36 words of the Universal Core vocabulary, created by the Center for Literacy and Disability Studies, University of North Carolina at Chapel Hill, licensed [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). Source: https://www.project-core.com/. Chorus adapted it as colour-coded text tiles, without the original symbols, and shares the adapted board under the same licence. Chorus is not affiliated with or endorsed by the Center or the University. See [STARTER_BOARD_LICENSE.md](chorus_shared/STARTER_BOARD_LICENSE.md) and the in-app [Credits screen](chorus_ui/lib/credits/credits_screen.dart).
- **Browser database files:** unmodified release files of the `sqlite3` and `sqlite_async` Dart packages. No symbol set is bundled.

