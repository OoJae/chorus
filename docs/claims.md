# Claims ledger

Chorus is an offline-first talking picture board for a non-speaking child. The child taps words and the device speaks them. Adults edit the board from their own devices, and Serverpod 4.0.4 with the experimental `serverpod_offline_sync` module 0.0.10 keeps the copies in step.

This file lists what the public documents of Chorus say, and what proves each statement. It was rewritten on 13 October 2026 at about 19:50 UTC, against commit `46f3f13` and the working copies of the six documents below. On the morning of 14 October the rows for the labels and steps changed that night were brought up to date (R9, R18, R40a, R43, D12, T4, T6a, T6b, T10a, T15, T15a, T19, T32, T41, T41a, T42, T43a, V23 and check 7); the rest were not re-checked.

No child, parent or clinician has used Chorus. The child in its story, Maya, is a persona. Nothing in the project is a clinical claim.

## How to read it

There is one table per public document. Each row quotes a claim, names the evidence, and gives one status.

| Status | Meaning |
|---|---|
| device-verified | A person saw it on real hardware against the deployed server. It has a row in [`device-log.md`](device-log.md). |
| automated-test only | A named automated test exercises it. Nobody has seen it on a device. |
| code only | It was read from the source, the configuration or another first-hand record during this check (a file in this repository, the public site, a package's source, a tool's own version output). No test is named and nobody has seen it on a device. |
| unverified | No first-hand record was found. It is the author's own statement, a plan, or something not yet tried. |
| false | A first-hand record contradicts it as written. |

Where a claim was seen on one device and is written about another (seen on the phone, described in a browser), the evidence column says so.

In the documents, [square brackets] wrap a sentence that depends on something not yet seen on a device. The quotes below keep those brackets.

"Sync tests" are in `chorus_server/test/sync/`. They run a real server on an embedded PostgreSQL and one SQLite replica file per device. T1 to T10 are the scenarios described in [`spike-results.md`](spike-results.md).

### How the check was done

- Every source file of this repository named as evidence was opened and read. Package sources named as evidence were searched for the lines in question. Every test named as evidence was found in its file under that name.
- Every quoted screen label was compared with the widget source. Each was also found in the hosted web build (`https://chorus.serverpod.space/main.dart.js`, fetched at 19:48 UTC).
- Each public link was requested once.
- Tests were counted from their declarations, including tests made in loops. No test was run locally. The server suite was compared with GitHub Actions run 38456926421 on commit `46f3f13`, the only suite CI runs.
- No server was started and no device was touched. One scratch script called the app's own `shrinkToJpeg` function to test the photo metadata claim.

## Found false or broken in this check

1. **Photo location data.** The README says re-encoding a photo on the device "drops location data". It does not: `shrinkToJpeg` keeps the photo's EXIF block, GPS position included. Row R57.
2. **Build from a fresh clone.** `chorus_server/config/passwords.yaml` is not in the repository, and the server needs three secrets from it. The README's build steps do not say so. On GitHub Actions the latest commit shows 89 server tests passed and one test file failed to load for the same reason. Rows R39 and R42.
3. **Android APK link.** `https://github.com/OoJae/chorus/releases/latest` leads to an empty releases page. No release exists. Rows R8, D32, T3 and T28.
4. **Documents not yet public.** `docs/TRY-IT.md`, `docs/video-script.md`, `docs/feedback-form.md` and `docs/post-draft.md` were not on the public branch at check time, so links to them return 404. Row D34.
5. **"Hold to leave" in a browser.** The judge script states the result in a desktop browser without brackets. The device log records that it failed there in the first build and that the fix was checked on the phone only. Row T10.
6. **"Pinned: Flutter 3.47.7".** Nothing pins it: the pubspec allows 3.44.4 or later and the three CI workflows run 3.44.4. Row R36.

## Must be verified on a device before the video is recorded

The video may show only what the devices did. Each check gets a dated row in `device-log.md` before its take is recorded.

1. **Speech is heard.** A person in the room hears single words and a whole sentence from the phone. So far the log shows the speech service opening audio output; nobody listened.
2. **Airplane mode.** With the airplane icon showing, the phone builds and speaks a sentence. The child's screen shows no crossed-out speaker icon. The USB mirror stays up.
3. **"My words" on the child's screen.** The tab opens on the phone's child screen and the sentence strip keeps its words. So far the tabs were seen in the editor only.
4. **Invitation.** A "Teacher" code made on the phone lets a second adult join in a browser, who then sees "Maya's board" and "Up to date".
5. **Adding a word in a browser.** So far a word was added on the phone only.
6. **Live arrival.** A word added in the browser reaches the phone while its child's screen is open. "1 waiting" shows while the strip has words. The word lands 2 to 2.5 seconds after the strip is cleared, and speaks when tapped. Time it from "Add to board" to the pill; the script allows about six seconds.
7. **Adding a word offline, both ways.** On the phone in real airplane mode (chip: "Offline, saved on this device"), and in a browser with "Work offline" on.
8. **Upload on reconnect.** The browser's word leaves when "Work offline" is switched off. The phone's word leaves when airplane mode goes off. Time it from airplane mode off to "Up to date"; the script allows about eight seconds.
9. **The same-cell collision.** The earlier word holds the cell on every device. The later word is listed under "Needs a home (1)" on both adults' editors, with "Added by Mum" and "Added while offline; Ms Lee's word got this spot first".
10. **The child's board during the collision.** It gains one word. "mango", "guava" and "juice" do not move. No waiting pill with an adult icon appears.
11. **Phone layout of the child's screen.** The strip takes the full width with three buttons beneath it. The earlier layout had problems on this phone.

Not needed for the video, but needed before the judge script and the description lose their brackets:

12. **"Hold to leave" in a desktop browser.**
13. **Each newer feature, by hand, on the deployed build:** (a) family photo and recorded voice, (b) pointing at a word, (c) "Replaced changes" with restore, (d) paper copy, (e) suggested word, which needs the server password `anthropicApiKey`, (f) "Share what is said", (g) demo sign-ins, which need the server password `demoPassword`, (h) a read-only partner.

## Sentences to delete if not verified by the deadline

The submission form freezes on 14 October 2026 at 23:59 CEST. If a check above has not passed by then, delete the sentences beside it. If it has passed and has a row in the device log, remove their brackets.

| If this check has not passed | Delete |
|---|---|
| 1, speech is heard | TRY-IT: "You hear each word." in part C step 3; say instead that the phone's speech service starts at each tap. Video: beat 1 cannot open on a spoken sentence. |
| 3, "My words" on the child's screen | DESCRIPTION: "and an empty "My words" board" as something the child sees. TRY-IT: "and a second tab, "My words"" in part A step 4. Video: beat 2, step 2. |
| 12, "Hold to leave" in a browser | TRY-IT: "A bar fills while you hold, then you are back on the home screen." in part A step 5; keep the note under "If something looks wrong". |
| 2, airplane mode | Video: captions "Airplane mode on, by hand.", "[No network. The board is read from the replica ...]", "[It still speaks. ...]"; beat 1 is not shown as written; beat 3 uses the fallback captions. Upload text: "0:00 [The phone speaks, then speaks again in airplane mode.]". TRY-IT: part C steps 4 and 5. |
| 4, invitation | Video: every caption that names a teacher (0:30, 0:36, 1:02, 1:18). TRY-IT: part B steps 1 and 2. DESCRIPTION: the words "invitation codes". |
| 5 and 6, live arrival | DESCRIPTION: "[New words show "1 word waiting" and land between sentences.]". README: "What it demonstrates", item 2, up to the property-test sentence. Video: captions 0:30 to 0:48; upload text "0:30 [...]". TRY-IT: part B step 3. |
| 7 and 8, offline add and upload | Video: captions 1:10, 1:18, 1:24; card line "[In the third take ...]". TRY-IT: the bracketed sentence in part B step 6, part C step 5, "[Switch it off and the word reaches the other devices.]", and the bracketed tip under "If something looks wrong". Feedback form: "[On the phone, sync resumed by itself after the network came back.]". |
| 9 and 10, the collision | Video: captions 1:02 to 1:31; upload text "1:02 [...]". The core sentence at 1:36 would then stand over no footage, so the screen must say that it rests on automated tests. TRY-IT: part B steps 7 and 8. Post draft: "[I have now run it on a phone and a browser ...]" (keep the "not yet" sentence instead). |
| 13a, photo and voice | DESCRIPTION: "[File storage: ...]". README: the file storage row and the photo line under Privacy. TRY-IT: part D, first item. |
| 13b, pointing | DESCRIPTION: "[Streaming endpoint: ...]". README: the streaming row, "[The live session works on one server instance.]", the presence line under Privacy. TRY-IT: part D, second item. |
| 13c, Replaced changes | DESCRIPTION: "[A "Replaced changes" list restores the overwritten value.]". README: "[Each edit is also logged ...]" and "["Replaced changes" covers ...]". TRY-IT: part D, third item. Post draft: "[A "Replaced changes" panel ...]". |
| 13d, paper copy | DESCRIPTION: "[A route serves a printable paper copy.]". README: "[`/print/<token>`: ...]" and the paper-copy line under Privacy. TRY-IT: part D, fourth item. |
| 13e, suggested word | README: the `anthropicApiKey` half of the Passwords row, the Anthropic line under Privacy, the bracketed sentence under AI disclosure. TRY-IT: part D, fifth item. DESCRIPTION: reword the Claude API sentence so it says the feature has not been run. |
| 13f, sharing what is said | README: the second sentence of the presence line under Privacy. TRY-IT: part D, sixth item. |
| 13g, demo sign-ins | DESCRIPTION: "[Demo accounts: ...]". README: "[Demo sign-ins: ...]" and the `demoPassword` half of the Passwords row. TRY-IT: both demo-account paragraphs. |
| 13h, read-only partner | TRY-IT: "[To see the read-only role, ...]". DESCRIPTION: the words "read-only partners". |

## README.md

| # | Claim | Evidence | Status |
|---|---|---|---|
| R1 | "The child taps words and the device speaks them from local data." | `chorus_ui/lib/talker/talker_controller.dart` reads the board store only; `chorus_flutter/lib/src/sync/replica_board_store.dart` reads the local SQLite replica; `chorus_flutter/lib/src/speech/tts_speech_service.dart` uses the device's speech engine. Device log: speech heard in a desktop browser; on the phone the speech service opened audio output at each tap. Not yet tried with the network off. | device-verified |
| R2 | "Serverpod's experimental offline sync module keeps the copies in step." | Device log, Android table: a board made in the browser reached the phone. One direction, one pair of devices. | device-verified |
| R3 | "No button the child already uses ever changes place." | `chorus_shared/test/reconcile_snapshot_test.dart`, "property: a plan never changes what an occupied cell means" (600 random rounds). `chorus_flutter/test/sync/replica_board_store_test.dart`, group "placeTile", "never moves a tile that already has a cell". The editor has no move action (`chorus_ui/lib/editor/editor_screen.dart`). Not watched across a merge on a device. | automated-test only |
| R4 | "When two adults fill the same empty cell offline, both words survive." | Sync test `cell_conflict_test.dart`, T1, three orderings, checked on the server and both replicas. Passed in CI run 38456926421. Device log: not yet tried. | automated-test only |
| R5 | "CoughDrop and AsTeRICS Grid already offer offline boards with cloud sync." | Outside the repository. Read on 13 October 2026: the CoughDrop home page says "Work offline with backup in the cloud"; the AsTeRICS Grid README lists "Offline capable" and "Optional cloud sync". | code only |
| R6 | "We have not found a tool that shows what happens when two adults change the same board offline." | A statement about the author's own search. The repository does not record which tools were looked at, or when. | unverified |
| R7 | "No child, parent or clinician has used Chorus; the child in the story is a persona." | The author's statement. The app says the same of the persona and of clinical use (`chorus_ui/lib/credits/credits_screen.dart`). | code only |
| R8 | "Android APK: https://github.com/OoJae/chorus/releases/latest" | The link redirects to an empty releases page; GitHub lists no release. The README carries a TODO for it. | false |
| R9 | "Web app: https://chorus.serverpod.space. Click "Sign up", enter your email address and the emailed code, set a password, then click "Try a demo board"." | Sign-up with an emailed code and "Try a demo board": device log, Cloud and desktop browser tables, in the build where the first form was sign-up. The first form is now sign-in with a "Sign up" link: `sign_in_screen_test.dart`, "the first form is sign-in, with sign-up one tap away"; not yet seen on the deployed build. | automated-test only |
| R10 | "[Demo sign-ins: `demo.parent@chorus.example`, `demo.therapist@chorus.example`, `demo.partner@chorus.example` (read-only).]" | `chorus_server/lib/src/demo/demo_seed.dart`; `chorus_server/test/integration/demo_seed_test.dart` (6 tests, which run only where `config/passwords.yaml` exists; see R42). `demoPassword` is not set on the deployed server. | automated-test only |
| R11 | "The child's screen reads a local SQLite replica and uses the device's own speech engine." | Device log: `chorus_<user id>.sqlite` in the browser's IndexedDB; the phone's speech service opened audio output. | device-verified |
| R12 | "A word from another device shows as "1 word waiting"." (not bracketed) | `chorus_ui/lib/talker/talker_screen.dart`, `_WaitingPill`: "1 word waiting" on a screen at least 600 wide and 480 high, "1 waiting" on a phone. `chorus_ui/test/talker_controller_test.dart`, "a merged word waits while the strip has words in it". Device log: a word arriving on another open device is not yet checked. | automated-test only |
| R13 | "It lands only when the sentence strip is empty, nothing is speaking and the board has been untouched for two seconds." (not bracketed) | `isSafePoint` in `chorus_shared/lib/src/reconcile_snapshot.dart`; `checkSafePoint` in the talker controller also waits for every finger to lift. Tests: group "isSafePoint"; "a merged word waits while speech is playing"; "the timer applies a waiting change once it is safe". | automated-test only |
| R14 | "A property test checks that an occupied cell never changes meaning." | The test exists, as named in R3. | automated-test only |
| R15 | "A same-cell collision keeps both words. One holds the cell. The other waits in a "Needs a home" tray until an adult places it." | T1 and T5; `chorus_shared/test/tray_test.dart`, "contested: an engine-suffixed key, with the cell it lost"; `chorus_ui/lib/editor/tray_panel.dart`. | automated-test only |
| R16 | "Three synced tables; a SQLite replica on every device." | `board.spy.yaml`, `tile.spy.yaml`, `tile_edit.spy.yaml` each say `database: sync`; `chorus_server/config/generator.yaml` turns on `databaseSync`. Device log: a replica in the browser and on the phone. | device-verified |
| R17 | "One space per child. Guardian, therapist and teacher write; a partner only reads." | `chorus_server/lib/src/circles/circle_endpoint.dart`; `circle_endpoint_test.dart` (teacher and therapist read-write, partner read-only); sync test T8 (a partner's write is refused on the device). No invited adult has signed in on a device. | automated-test only |
| R18 | "One `transactionForUser` write queue, plus what the module lacks: reconnect, backoff, clock check, status chip." | `replica_service.dart`, `sync_supervisor.dart`; `chorus_flutter/test/sync/sync_supervisor_test.dart` (32 tests on a fake clock). On the phone the chip read "Up to date" and "Working offline, saved on this phone" (the wording before 14 October). A reconnect after a real loss of network has not been seen. | automated-test only |
| R19 | "Sign-up with a code emailed by Serverpod Cloud." | `chorus_server/lib/server.dart` (`ServerpodCloudEmailIdpConfig`). Device log, Cloud table. | device-verified |
| R20 | "[An adult taps a word and it glows on the child's board.]" | `live_endpoint.dart` (a streaming method, `join`); `chorus_flutter/lib/src/live/chorus_live_session.dart`; `_Glow` in the talker screen. Tests: `live_endpoint_test.dart` (10), `chorus_live_session_test.dart` (30), `live_talker_test.dart` "a pulse glows, then fades after livePulseFor". | automated-test only |
| R21 | "[Family photos and recorded voices, private, named by SHA-256 and verified on the server.]" | `media_endpoint.dart`, `media_files.dart` (`verifyStoredMedia`); `media_endpoint_test.dart` (12). In those tests the upload over HTTP is simulated. | automated-test only |
| R22 | "Serves the web app and its API address." | `server.dart` (`FlutterRoute`, `AppConfigRoute`). Device log: `/assets/assets/config.json` returns the API address. Same answer at check time. | device-verified |
| R23 | "[`/print/<token>`: a printable paper copy.]" | `chorus_server/lib/src/printing/print_routes.dart`; `print_test.dart` (16). At check time the deployed server answered an unknown token with 410, the route's "not here" answer. No page has been made by hand. | automated-test only |
| R24 | "[`anthropicApiKey` enables the photo-to-word suggestion; `demoPassword` creates the demo sign-ins.]" | `suggest_service.dart` (`SuggestSettings.fromPasswords`); `demo_seed.dart` (`scheduleDemoSeed`). `suggest_endpoint_test.dart` (16) answers the model call with a fake; the real service has never been called. Neither password is set on the deployed server. | automated-test only |
| R25 | "Serverpod Cloud ... Hosts server, database and web app." | `chorus_server/scloud.yaml` (project `chorus`). Device log, Cloud table. | device-verified |
| R26 | "A tile's position is one string, `cellKey`, unique within a space." | `tile.spy.yaml`: `cellKey: String, unique(per=spaceId)`. Sync test T2 (a second tile in a held cell is refused on one replica). | automated-test only |
| R27 | The three forms of `cellKey`. | `chorus_shared/lib/src/cell_key.dart`; `cell_key_test.dart` (41 tests). | automated-test only |
| R28 | "The earlier claim keeps the cell; the later one gets the suffix." | T1. | automated-test only |
| R29 | "No event fires, so after every merge `trayOf` parses the keys and lists suffixed tiles under "Needs a home"." | Read in the module source at 0.0.10: `onMergeSuccess` receives a space id and a clock value, and `CrdtProjectionReason` is documented as "Diagnostic-only". `tray_panel.dart` calls `trayOf` on every store change. | code only |
| R30 | "The app never moves a tile from one cell to another." | `placeTile` in `replica_board_store.dart` refuses a tile that holds a cell; test named in R3. | automated-test only |
| R31 | "Every update names its columns, so edits to different fields of one tile both survive." | Every `updateRow` in `replica_board_store.dart` passes `columns`; test group "updates name only the columns they change"; sync test T3. | automated-test only |
| R32 | "Edits to the same field are last-writer-wins." | Sync test `merge_test.dart`, T4, three orderings. | automated-test only |
| R33 | "[Each edit is also logged in `TileEdit`, and the editor lists a replaced label, spoken text or colour under "Replaced changes" with a one-tap restore.]" | `_log` in `replica_board_store.dart`; `chorus_shared/lib/src/detect_overwrites.dart`; `chorus_ui/lib/editor/replaced_changes_panel.dart`. Tests: `detect_overwrites_test.dart` (38), `replaced_changes_test.dart` (13), `edit_log_store_test.dart` (12). No test runs the panel against two replicas. | automated-test only |
| R34 | "Automated in `chorus_server/test/sync/` against an embedded PostgreSQL and real SQLite replicas." | `chorus_server/test/sync/replicas.dart`. All 21 sync tests passed in CI run 38456926421. | automated-test only |
| R35 | "Checked on real devices": the "Seen working" list and the "Not yet checked" list. | Both lists match `device-log.md`. | device-verified |
| R36 | "Pinned: Flutter 3.47.7" | Flutter 3.47.7 is installed on the build machine. `chorus_flutter/pubspec.yaml` allows `^3.44.4`, and `.github/workflows/tests.yml`, `analyze.yml` and `format.yml` run 3.44.4. Nothing pins 3.47.7. | false |
| R37 | "Serverpod CLI and packages 4.0.4, `serverpod_offline_sync_server` and `serverpod_offline_sync_client` 0.0.10." | Exact versions in `chorus_server/pubspec.yaml` and `chorus_flutter/pubspec.yaml`; `pubspec.lock`. | code only |
| R38 | "module 0.0.11 needs a Serverpod 4.1 beta." | pub.dev API, read at check time: 0.0.10 needs `serverpod >=4.0.4 <4.1.0`; 0.0.11, published two hours later, needs `^4.1.0-beta.3`. | code only |
| R39 | The four build commands, ending in `serverpod start`. | `dart install serverpod_cli@4.0.4` is the command CI uses. `flutter pub get` at the root fits the pub workspace. `serverpod start` cannot start the server on a fresh clone: `config/passwords.yaml` is git-ignored, and `JwtConfigFromPasswords()` in `server.dart` throws without `jwtHmacSha512PrivateKey` and `jwtRefreshTokenHashPepper`; the email provider needs `emailSecretHashPepper`. Not run on a fresh clone in this check; the same constructor fails this way in CI (R42). | false |
| R40 | "No Docker: `config/development.yaml` sets `database.dataPath`." | `chorus_server/config/development.yaml`, line 38. | code only |
| R40a | "For a second adult use a private window: Chorus runs in one tab per browser profile, and a second tab says "Chorus is open in another tab"." | As T15. | automated-test only |
| R41 | "`flutter build apk --release --dart-define=SERVER_URL=https://chorus.api.serverpod.space/`" | `chorus_flutter/lib/client.dart` (`getServerUrl()`); `docs/BUILD.md`. Device log: a release build made this way installed and synced. | device-verified |
| R42 | "Server: endpoints, sync ... `cd chorus_server && dart test --concurrency=1` ... 95" | 95 tests are declared. In CI run 38456926421 on a clean checkout, 89 passed and `demo_seed_test.dart` (6 tests) failed to load: "jwtRefreshTokenHashPepper was not found in config/passwords.yaml". The count is right; the command gives it only where the passwords file exists. | false |
| R43 | "Shared rules ... 150", "Screens ... 154", "App ... 301" | Run on 14 October 2026 against the working copy: 150, 154 and 301 passed. The browser-only app tests are not run by `flutter test`. These three suites are not run in CI. | code only |
| R44 | "Deploy with `scloud deploy`; `scloud.yaml` runs `serverpod generate` and `serverpod run flutter_build` first." | `chorus_server/scloud.yaml`. | code only |
| R45 | "No clinical validation and no real users." | The author's statement; Credits screen. | code only |
| R46 | "A member cannot be removed and a role cannot be changed." | `circle_endpoint.dart` has four methods: create a circle, list circles, create an invitation, accept one. | code only |
| R47 | ""Up to date" means the last sync finished without an error, not a receipt for each edit." | `chorus_ui/lib/widgets/sync_chip.dart`; `sync_supervisor.dart`. | code only |
| R48 | "[The live session works on one server instance.]" | `live_endpoint.dart` posts events with `MessageScope.local`. | code only |
| R49 | "No scheduled jobs (future calls) are used." | No future call is registered or scheduled anywhere under `chorus_server/lib`. | code only |
| R50 | "The APK is debug-signed." | `chorus_flutter/android/app/build.gradle.kts`, line 36. No APK is published yet. | code only |
| R51 | "Phone layout problems are in the device log; the fix has not been seen on a device." | Device log, "Layout problems seen on the phone". The new layout is covered by `chorus_ui/test/talker_layout_test.dart`. | device-verified |
| R52 | "The sentences the child builds are not stored. The child's screen only reads the board." | `talker_controller_test.dart`, "never writes to the store". No model in the server holds sentences. | automated-test only |
| R53 | "[While the child's board is open online, connected members see that account as present. Sentences are sent only while a guardian has "Share what is said" on for that device: relayed to connected members, never stored.]" | `chorus_live_session_test.dart`: "shareSaid is off by default and then nothing is sent", "only a guardian can turn sharing on". `live_endpoint.dart` writes to no table. | automated-test only |
| R54 | "The server holds each adult's email and display name, the child's name as typed, and the board." | `circle.spy.yaml`, `membership.spy.yaml`, the three synced models. The server also holds invitation codes and, for the bracketed features, paper-copy snapshots, a record per photo or recording, and a daily count of suggestions. | code only |
| R55 | "Every member, including a read-only partner, can read the whole board." | Sync test T8: all three members receive both tiles. | automated-test only |
| R56 | "No analytics or advertising code." | The four `pubspec.yaml` files list none. `google_fonts` is listed in `chorus_flutter/pubspec.yaml` and imported nowhere. | code only |
| R57 | "[Photos are re-encoded on the device, which drops location data, and sit in private storage behind five-minute links.]" | Re-encoding, private storage and five-minute links: `image_shrink.dart`, `media_files.dart`. Location data: `shrinkToJpeg` was called on a JPEG carrying a GPS position and a camera make, and the output still carried both. The `image` package 4.12.0 copies the EXIF block through `bakeOrientation`, `copyResize` and `encodeJpg`. No test covers metadata. | false |
| R58 | "[A photo goes to Anthropic's API only when an adult presses "Suggest a word from the photo".]" | The only caller of the HTTPS transport is `suggestFromPhoto`, reached from the sheet's button. `chorus_ui/test/wiring_test.dart`, "is offered only once a photo is picked ...". | automated-test only |
| R59 | "[A paper-copy link shows the child's name and words to anyone who has it, for 30 days.]" | `printing_endpoint.dart` (`printLinkLifetime`); `print_test.dart`, "when the link has expired then the page is gone ...". | automated-test only |
| R60 | "Code: MIT, copyright 2026 OoJae." | `LICENSE`; GitHub reports MIT. | code only |
| R61 | Starter board credit: Universal Core vocabulary, Center for Literacy and Disability Studies, University of North Carolina at Chapel Hill, CC BY-SA 4.0. | `chorus_shared/STARTER_BOARD_LICENSE.md`; `chorus_shared/lib/src/starter_board.dart` (36 words); the Credits screen. The licence terms were not re-read at the source in this check. | code only |
| R62 | "Browser database files: unmodified release files of the `sqlite3` and `sqlite_async` Dart packages." | The SHA-256 of both files in `chorus_flutter/web/` equals the values in `docs/BUILD.md`, which says they equal the upstream release digests. The hosted site serves the same byte counts. The upstream files were not downloaded again. | code only |
| R63 | "Chorus was built with Claude Code, Anthropic's AI coding tool." | The author's statement; `AGENTS.md` holds the coding agent's instructions. | unverified |
| R64 | "[The optional photo-to-word suggestion calls Anthropic's Claude API; an adult approves every suggestion.]" | `vision_transport.dart` posts to `api.anthropic.com`; a suggestion only fills in the form (`add_word_sheet.dart`, `_useIdea`). Tests use a fake transport. | automated-test only |

## docs/DESCRIPTION.md

| # | Claim | Evidence | Status |
|---|---|---|---|
| D1 | "built on Serverpod 4.0.4 and its offline sync module: the child taps words and the device speaks them, while adults edit the board from their own devices." | Version pins (R37). Device log: speech in a browser; the talker on the phone; a word added on the phone; a board made in the browser reaching the phone. | device-verified |
| D2 | "No button the child already uses ever changes place" | As R3. | automated-test only |
| D3 | "when two adults fill the same empty cell offline, both words survive." | As R4. | automated-test only |
| D4 | "Children who talk by tapping words, their families and therapists." | A statement of intent. Nobody in these groups has tried Chorus. | unverified |
| D5 | "The child shown is a persona: no child, parent or clinician has used Chorus. No clinical claims." | As R7. | code only |
| D6 | "Children find words by position, so a moved button is a lost word." | No source is given. It is the project's design premise, stated as a fact about children. | unverified |
| D7 | "CoughDrop and AsTeRICS Grid already offer offline boards with cloud sync." | As R5. | code only |
| D8 | "We have not found a tool that shows what happens when two adults change the same board offline." | As R6. | unverified |
| D9 | "The child sees a full "Home" board (36-word Universal Core vocabulary ...) and an empty "My words" board" | `starter_board.dart`. Device log: the child's screen showed the 36-word board in a browser; the "My words" tab was seen on the phone in the editor, not yet on the child's screen. | device-verified |
| D10 | "adults exit with "Hold to leave"." | Device log, Android table: a 2.7 second press returned to the home screen. In a desktop browser the first build failed and the fix has not been re-checked. | device-verified |
| D11 | "The editor adds words and cannot move one." | Adding: device log, "Add a word while online". No move: as R30. | device-verified |
| D12 | "A chip shows sync state; "Work offline" pauses sync." | Device log: the chip read "Up to date" and, with the switch on, "Working offline, saved on this phone" (the wording before 14 October). That the switch stops sync: `setWorkingOffline` in `sync_supervisor.dart` and its tests. A sync round already under way finishes: see V23. | device-verified |
| D13 | "[New words show "1 word waiting" and land between sentences.]" | As R12 and R13. On a phone the label is "1 waiting". | automated-test only |
| D14 | "Checked on hardware (13 October 2026, Serverpod Cloud): emailed-code sign-up, the demo board, speech in a browser, browser-to-Android sync, the talker on a physical phone, adding words online and with "Work offline" on." | Each item has a row in the device log. On the phone the talker was driven from a computer and nobody listened. | device-verified |
| D15 | "Automated tests on real PostgreSQL and SQLite replicas prove the same-cell outcome." | T1, as R4. | automated-test only |
| D16 | "Unchecked on devices: offline words uploading afterwards, that collision, live arrival on another device, airplane mode." | Accurate: the same four items are under "Not yet checked on a device" in the device log, which also lists every newer feature. | code only |
| D17 | "Offline sync module: SQLite replica per device, shared space per child, read-only partners." | Replica and shared space: device log (R2, R11). Read-only partners: tests only (R17). | automated-test only |
| D18 | "Unique-per-space index and conflict flagging: one word per cell; the loser waits under "Needs a home"." | As R15 and R26. | automated-test only |
| D19 | "Field-level merge: edits to different properties both survive." | Sync test T3. | automated-test only |
| D20 | "Auth: emailed-code sign-up." | As R19. | device-verified |
| D21 | "Endpoints: circles, invitation codes." | Circles: making the demo board creates one (device log). Invitation codes: `circle_endpoint_test.dart` (13 tests); no code has been used on a device. | automated-test only |
| D22 | "Web server: the Flutter web app." | As R22. | device-verified |
| D23 | "[A route serves a printable paper copy.]" | As R23. | automated-test only |
| D24 | "[Streaming endpoint: an adult's tap glows on the child's board.]" | As R20. | automated-test only |
| D25 | "[File storage: private family photos and recorded voices.]" | As R21. | automated-test only |
| D26 | "Serverpod Cloud: server, database, web app, email." | Device log, Cloud table. | device-verified |
| D27 | "Embedded PostgreSQL test tools: no Docker." | `chorus_server/config/test.yaml` sets `database.dataPath`; the CI job starts no database service. | code only |
| D28 | "MCP server and agent skills: configured for the coding agent." | `AGENTS.md`, which is in the repository. The configuration files themselves (`.mcp.json`, `.dart_skills/`) exist on the author's machine and are git-ignored. | code only |
| D29 | "The sync module is experimental, pinned to 0.0.10." | As R37. | code only |
| D30 | "Two adults editing one label offline is last-writer-wins by field." | As R32. | automated-test only |
| D31 | "[A "Replaced changes" list restores the overwritten value.]" | As R33. | automated-test only |
| D32 | "APK: https://github.com/OoJae/chorus/releases/latest." | As R8. | false |
| D33 | "Web: https://chorus.serverpod.space." and "Source: https://github.com/OoJae/chorus." | Both answered 200 at check time. GitHub reports the repository public, MIT, with issues enabled. The web address is also in the device log. | code only |
| D34 | "Script: `docs/TRY-IT.md`." | The file is not on the public branch: its raw address returned 404 at check time. | false |
| D35 | "[Demo accounts: ...]" | As R10. | automated-test only |
| D36 | "Built with Claude Code (Anthropic), which wrote most of the code, tests and documents under the author's direction." | The author's statement, marked for the author to confirm. | unverified |
| D37 | "The optional photo-to-word suggestion calls Anthropic's Claude API when the server has a key." | As R64. No key is set on the deployed server and the real service has not been called. | automated-test only |

## docs/TRY-IT.md

| # | Claim | Evidence | Status |
|---|---|---|---|
| T1 | "The child taps words and the device speaks them. Adults add words from their own devices, and Serverpod's offline sync module keeps the copies in step." | As D1 and R2. | device-verified |
| T2 | "Part A needs one desktop browser and takes about two minutes once the sign-up code has arrived." | No timing is recorded. | unverified |
| T3 | "Android APK: https://github.com/OoJae/chorus/releases/latest" | As R8. | false |
| T4 | "The app shows its sync state in a small chip, in words. When all is well it reads "Up to date"." | `sync_chip.dart`. Device log: "Up to date" on the phone. | device-verified |
| T5 | "The child in the demo, Maya, is a persona." | `first_run_screen.dart` ("a pretend child called Maya"); Credits screen. | code only |
| T6 | A1: "You see a form titled "Sign In with email"." | Default title of `serverpod_auth_idp_flutter` 4.0.4 (`email_sign_in_texts.dart`). Device log: sign-up was done in a desktop browser. | device-verified |
| T6a | [A1: "Above it are the name "Chorus", a line on what it is, and a line on how to start."] | `SignInHeading` in `sign_in_screen.dart`; `sign_in_screen_test.dart`, "the heading says what Chorus is and how to start, and shows no address". | automated-test only |
| T6b | [A1: "If the first visit is slow, the loading page says "Loading. The first visit takes a little longer."] | `chorus_flutter/web/index.html`: the line is filled in after four seconds and removed with the loading screen. Checked once with a scratch script that is not in the repository; no committed test. | code only |
| T7 | A2: "Sign up", "Continue", "Verify account", "Set account password", "Sign up", then "Welcome to Chorus". | The same package defaults; `chorus_flutter/lib/screens/first_run_screen.dart`. Device log: emailed code arrived; sign-up completed. | device-verified |
| T8 | A3: "Click "Try a demo board". You see a home screen headed "Maya's board", and the chip at the top right settles on "Up to date"." | `first_run_screen.dart`, `home_screen.dart`. Device log: board created and seeded in a browser. | device-verified |
| T9 | A4: "a board called "Home" with 36 words in a six by six grid, and a second tab, "My words". ... You hear each word ... Click the sentence to hear it whole." | Device log: the 36-word board rendered and was heard in a browser. The log's browser rows do not mention a second tab; on the phone the tabs were seen in the editor. The "My words" tab on the child's screen rests on `chorus_ui/test/two_boards_test.dart`. Tapping the sentence: `talker_controller_test.dart`, "speakStrip speaks the whole sentence ...". | device-verified |
| T10 | A5: "A bar fills while you hold, then you are back on the home screen." (in a desktop browser, not bracketed) | Device log, desktop browser table: in the first build nothing happened; the fix is "not yet re-checked in the browser". On the phone a 2.7 second press worked. | unverified |
| T10a | [A5: "With a keyboard: press Tab until "Hold to leave" is marked, hold Enter or Space for two seconds, then let go."] | `talker_screen.dart`; `chorus_ui/test/wiring_test.dart`, "the keyboard leaves too: Tab reaches "Hold to leave", and Enter (and Space) held for 2 seconds leaves when it is let go". | automated-test only |
| T11 | A6: the editor line "Tap an empty spot to add a word. ... Words never move, so Maya always finds them in the same place." and "There is no way to move a word to another cell." | `editor_screen.dart`. Device log: the editor was opened on the phone, not in a browser. | device-verified |
| T12 | A7: "In the sheet "Add a word", type "mango" under "Word" and click "Add to board". You see "mango" in that cell and the chip at "Up to date". In the column beside the grid (under it in a narrow window), ... "No words are waiting."" | `add_word_sheet.dart`, `tray_panel.dart`. Where the tray sits: `editor_layout_test.dart`, the "side by side" group (900 wide and more) and "on a phone the board and the tray are one page as before". Device log, Android table: "mango" appeared in the first cell of "My words" and the chip returned to "Up to date". Not yet done in a browser. | device-verified |
| T13 | [A2 and part B: demo accounts; "the parent's device makes the starter board".] | `demo_seed.dart`; `signed_in_shell.dart` (only a guardian's device seeds). `home_screen_test.dart`, "an invited member does not seed the starter board". | automated-test only |
| T14 | Part B status line: "not yet run by hand on two devices. The invitation rules have endpoint tests. The same-cell result is proven by automated tests ...: scenario T1". | Accurate. `circle_endpoint_test.dart`; `cell_conflict_test.dart`. | automated-test only |
| T15 | "Another tab in window A's browser profile cannot be the second adult ... Chorus runs in only one of them at a time. [A second tab says "Chorus is open in another tab" and offers "Use Chorus in this tab".]" | `one_tab_gate.dart`, `tab_seat_web.dart` (Web Locks), `other_tab_screen.dart`. Tests: `one_tab_gate_test.dart`, "a seat held by another tab shows the notice, and the app is never started". The web seat ran only under Node's Web Locks; `one_tab_seat_web_test.dart` needs `--platform chrome` and was not run. Not yet seen in a browser. | automated-test only |
| T15a | "an address with "+" in it is not accepted." | `serverpod_auth_idp_flutter` 4.0.4, `email_auth_controller.dart` (`validateEmail`: `allowEmailAliases` is false by default); `sign_in_screen.dart` passes no `emailValidation`. | code only |
| T16 | [B1: "Invite someone", "Therapist" selected, "Make a code", "an eight-character code", "Copy code".] | `invite_screen.dart` (the first choice is "Therapist"); `circle_endpoint.dart` (`_newCode`). Tests: "when a guardian invites then the code is 8 characters ..."; `home_screen_test.dart`, "inviting shows the code large with a copy button". | automated-test only |
| T17 | [B2: "Join with a code", "Code", "Your name", "Join"; "There is no board here yet", "Retry".] | `first_run_screen.dart`, `home_screen.dart`. Tests: `circle_endpoint_test.dart`; `home_screen_test.dart`, "a ready circle with no board yet explains and offers Retry". | automated-test only |
| T18 | [B3: "You see "juice" appear in the same cell in window B within a few seconds, with no reload."] | Sync test T8 moves words between replicas with one-shot syncs. No test has two live clients, and no timing is recorded. | automated-test only |
| T19 | B4: "switch on "Work offline". The chip in each reads "Working offline, saved on this device"." | Device log, Android table: seen with the wording before 14 October, "Working offline, saved on this phone". The new wording: `sync_chip_test.dart`, 'the chip says "this device", never "this phone"'. Not yet done in a browser. | automated-test only |
| T20 | B5: "Each window shows its own word in the corner." | Device log: with the switch on, "guava" appeared on the phone. One device, not two. | device-verified |
| T21 | [B6: "The chip in each returns to "Up to date"."] | `sync_supervisor_test.dart`, "a write made offline is sent by the next one-shot sync". | automated-test only |
| T22 | [B7: ""park" holds the corner, because it was added first. "swing" is listed under "Needs a home (1)" with the line "Added while offline; Parent's word got this spot first""] | T1; `tray_panel.dart` (`trayReasonText`). "Parent" is the name "Try a demo board" gives the first adult. With the demo sign-ins the line would read "Maya's mum's word". | automated-test only |
| T23 | [B8: "Place in next free spot" ... `"swing" is on the board.` ... "No words are waiting."] | `tray_panel.dart`; sync test T5; `replica_board_store_test.dart`, group "placeTile". | automated-test only |
| T24 | "What you should not see: either word gone, or any word in a different cell" | T1 checks the grid on the server and each replica. | automated-test only |
| T25 | [Read-only role: "Family or friend who can view", "View board", "You can view this board. Only the family and therapist can change it."] | `messages.dart`, `home_screen.dart`, `editor_screen.dart`; `home_screen_test.dart`, "a partner can view but is not offered editing or inviting". | automated-test only |
| T26 | Part C status line: "a release build was installed and steps 2 and 3 were checked on one phone, a Xiaomi on Android 16. ... nobody listened". | Matches the device log, Android table. | device-verified |
| T27 | "The build needs Android 7.0 or later." | `minSdk = flutter.minSdkVersion`, which `docs/BUILD.md` gives as 24. | code only |
| T28 | C1: "open https://github.com/OoJae/chorus/releases/latest, download the APK" | As R8. The phone in the device log was given the build directly, not from a release page. | false |
| T29 | C2: "You see "Maya's board" and the chip at "Up to date". The board was made in the browser and reached the phone's own SQLite database through the sync module." | Device log, Android table. | device-verified |
| T30 | C3: "Tap "Talker", then "I", "want", "more". You hear each word." | Device log: the sentence was built and audio output opened at each tap. Nobody listened. | device-verified |
| T31 | [C4: airplane mode; the crossed-out speaker icon.] | `tts_speech_service.dart` (`_hasOfflineVoice`); `talker_screen.dart`. Device log: airplane mode not yet checked. | code only |
| T32 | [C5: a word added with no network; "Offline, saved on this device"; then "Up to date" and the word in the browser.] | `sync_supervisor_test.dart`: "an unreachable server is offline and retried with backoff", "a write made offline is sent by the next one-shot sync". | automated-test only |
| T33 | "The in-app switch is the offline path we have checked on our phone ..." | Device log, Android table. | device-verified |
| T34 | Part D status line: "everything here was added that day and has automated tests, but has not yet been tried on a real device." | Accurate. The hosted web build contained every part D label at check time. | automated-test only |
| T35 | [D: photo and voice. "Choose a photo", "Take or choose a photo", "Hold to record", "up to five seconds".] | `add_word_sheet.dart`; `maxClipLength` in `chorus_ui/lib/contracts_media.dart`. Tests: `media_widgets_test.dart` (21); `wiring_test.dart`, "a tapped word goes to the clip speaker, a sentence to the voice". | automated-test only |
| T36 | [D: pointing. "Show words on the board"; "A blue ring glows round it for about two and a half seconds".] | `model_mode_bar.dart`; `livePulseFor` (2.5 seconds); `_Glow`. Tests as R20; `wiring_test.dart`, "in model mode a tap points at the word and opens nothing". | automated-test only |
| T37 | [D: "Replaced changes (1)" with a "Restore" button.] | As R33. | automated-test only |
| T38 | [D: "Print a paper copy"; "The page needs no sign-in and stops working after 30 days."] | `home_screen.dart`; as R23 and R59; `home_screen_test.dart`, "a paper copy sends the board on this device and shows the link". | automated-test only |
| T39 | [D: "Suggest a word from the photo"; "No suggestion this time. Type the word instead."] | `add_word_sheet.dart`; `server_word_suggester.dart`; `suggest_endpoint_test.dart`, "when no key is configured then it fails as notConfigured ...". After that answer the button is not offered again in the session. | automated-test only |
| T40 | [D: "Share what is said"; the bar "Sharing what is said"; a tap turns it off.] | `live_scope.dart`, `talker_screen.dart`. Tests: `home_screen_test.dart`, "only a guardian is offered the sharing switch"; `live_talker_test.dart`, "the sharing bar shows while on and a tap turns it off". | automated-test only |
| T41 | The chip table: ten labels and what each means, including "more than 45 seconds". | `sync_chip.dart`; `sync_supervisor.dart` (`maxSkew`, `_classify`). Tests: "failures map to the state the chip shows", "a stream the server ends with an error is reconnecting, not offline", "a device clock 46 s off stops before any sync", "a server that wants a newer build is needsUpdate"; `sync_chip_test.dart`. Two labels have been seen on a device, before the wording changed on 14 October: "Up to date" and "Working offline, saved on this phone". | automated-test only |
| T41a | Clock row: "new changes are refused ("Nothing was changed") for about as long as it was ahead. It recovers by itself; nothing already saved is lost." | Read in the module source at 0.0.10 (`hlc.dart`): `increment` keeps a stamp stored while the clock was ahead, and refuses a new write while that stamp is more than a minute ahead of the wall clock; the server's merge refuses the same stamps. No test, and not tried on a device. | code only |
| T42 | ""Sync now" is inside the chip only while it reads "Reconnecting", "Offline, saved on this device" or "Check this device's clock"." | `offersSyncNow` in `sync_chip.dart`; `sync_chip_test.dart`, one test per state. | automated-test only |
| T43 | [Tip: switching "Work offline" on and off "starts a fresh sync".] | `setWorkingOffline` in `sync_supervisor.dart`; test "stop while live cancels the stream; start runs it again". | automated-test only |
| T43a | ["Chorus is open in another tab": "Click "Use Chorus in this tab" to move it here, even if the other tab is closed; a tab still open then says "Chorus moved to another tab"."] | `one_tab_gate_test.dart`, ""Use Chorus in this tab" takes the seat over and shows the app", "a seat taken by another tab closes the app and says where Chorus went". A closed tab: `tab_seat_web.dart` takes the seat with a Web Lock `steal`, which does not need the other tab. Not yet seen in a browser. | automated-test only |
| T44 | "Reload the page: you come back to the home screen, still signed in." | Device log: sign-in survives a page reload. | device-verified |
| T45 | "The child's screen looks cramped on a small phone. Its layout was changed on 13 October ... and has not been re-checked on a device." | Device log, layout problems; `talker_layout_test.dart`. | device-verified |
| T46 | "https://github.com/OoJae/chorus/issues" | Answered 200; GitHub reports issues enabled. | code only |

## docs/video-script.md

The video has not been recorded. Rows about what a take shows are plans until it is.

| # | Claim | Evidence | Status |
|---|---|---|---|
| V1 | "Captions name only Serverpod and Chorus." "There is no voice-over and no music." | All 15 captions, both fallback captions and the closing card were read: no other product or company is named. The upload text names the authors of the starter vocabulary, as its licence requires, and no product. | code only |
| V2 | Setup labels: "Start a board for my child", "Invite someone", "Teacher", "Make a code", "Join with a code", "Parent or guardian". | `first_run_screen.dart`, `invite_screen.dart`, `messages.dart`. The invitation steps have not been done on a device. | code only |
| V3 | "The home board holds the 36 starter words and has no empty cell. New words go on the second board, "My words"." | `starter_board.dart`. Device log: the 36-word board; "mango" in "My words". | device-verified |
| V4 | "the child's board only announces a waiting word for the board it is showing." | `talker_controller.dart`; `two_boards_test.dart`, "showBoard keeps one held snapshot per board ...". | automated-test only |
| V5 | "Equipment: one Android phone (Xiaomi, Android 16, 720 x 1640)". | The device log names the phone and Android 16. The screen size is not recorded. | unverified |
| V6 | "3024 x 1964 pixels ... the bottom 850 points, starting 132 points from the top." | The Mac reports 3024 x 1964. 1512 x 9 / 16 is 850.5, and 982 less 850 is 132. | code only |
| V7 | Beat 1, step 1: the speaker button, labelled "Speak", says "I want more". | `talker_screen.dart`. Device log: the sentence was built and audio opened; nobody listened. | device-verified |
| V8 | Beat 1, step 3: "the round status icon changes from a tick to a phone outline." | `sync_chip.dart` (`_icon`); `sync_supervisor_test.dart`, "a live stream over a dead network is found by the probe". | automated-test only |
| V9 | Beat 1, steps 4 to 6: words and a sentence are spoken in airplane mode. | Nothing in the tap path uses the network (`talker_controller.dart`, `tts_speech_service.dart`). Device log: not yet checked. | unverified |
| V10 | Caption 0:00: "The child in this story is a persona. No child, parent or clinician has used Chorus." | As R7. | code only |
| V11 | Caption 0:07: "Airplane mode on, by hand." (not bracketed) | A plan for the take. It depends on check 2. | unverified |
| V12 | Caption 0:12: "[No network. The board is read from the replica that Serverpod offline sync keeps on the phone.]" | `replica_board_store.dart`; `replica_board_store_test.dart` (39 tests). Device log: the phone holds the board; not yet with the network off. | automated-test only |
| V13 | Caption 0:21: "[It still speaks. The voice is the phone's own text-to-speech.]" | The voice: `tts_speech_service.dart`; device log names the phone's speech service. Speaking with no network: not yet checked. | unverified |
| V14 | Beat 2, step 2: the "My words" tab on the child's screen shows "mango" and "guava"; the strip keeps "I want". | `showBoard` in `talker_controller.dart`; `two_boards_test.dart`, "the other board is shown at once ...". | automated-test only |
| V15 | Beat 2, step 3: a word added in the browser; the chip reads "Sending changes", then "Up to date". | Device log has this on the phone only. `sync_supervisor_test.dart`, "a local write is unsent until a later merge". | device-verified |
| V16 | Beat 2, steps 4 to 7: "1 waiting" appears; the cell stays empty; "juice" lands two to two and a half seconds after the last touch. | `_WaitingPill` (compact wording on a phone); `isSafePoint` (2 seconds) and the half-second recheck timer. Tests as R12 and R13. | automated-test only |
| V17 | Beat 2, step 8: the new word speaks when tapped. | `talker_controller_test.dart`, "tap adds to the strip and speaks the spoken text". | automated-test only |
| V18 | Caption 0:30: "[Online again. A teacher has the same board open in the web app on Serverpod Cloud.]" | The web app on Cloud: device log. A second adult joined by invitation: tests only (R17). | automated-test only |
| V19 | Caption 0:36: "[She adds a word. It is saved in her browser's replica, then Serverpod offline sync sends it.]" | `addTile` in `replica_board_store.dart` writes to the replica through `ReplicaService.write`. Seen on the phone, not in a browser. | automated-test only |
| V20 | Caption 0:42: "[The phone's open sync stream receives it. The child is mid-sentence, so the board waits: "1 waiting".]" | `syncContinuously` in `sync_supervisor.dart`; the pill as V16. Delivery between two live devices is not yet checked. | automated-test only |
| V21 | Caption 0:48: "[Strip empty, nothing playing, no touch for two seconds. Now the word lands.]" | As R13. | automated-test only |
| V22 | Caption 0:55: "No button the child already uses ever changes place." | As R3. | automated-test only |
| V23 | "The switch stops the sync loop and closes the sync stream, as a lost connection does." | `setWorkingOffline` calls `stop()`; test "stop cancels the stream and releases anyone waiting". A one-shot sync already under way is not stopped (`syncOnce` cannot be cancelled in 0.0.10) and finishes its round: a word saved in the first second or so after the switch, before the server's first answer, can still be sent. | automated-test only |
| V24 | "In the automated tests the earlier write keeps the cell whichever device reconnects first (`cell_conflict_test.dart`, T1)." | T1, three orderings. | automated-test only |
| V25 | Beat 3, steps 1 to 4: each adult adds a word offline to the same cell; the child's board stays empty there. | On the phone with "Work offline": device log. In airplane mode and in a browser: not yet. | unverified |
| V26 | Beat 3, steps 5 to 7: the chips go "Connecting", then "Up to date"; "swing" reaches the child's board; the phone's cell changes from "park" to "swing". | `sync_supervisor_test.dart` (R18); T1 for which word wins. | automated-test only |
| V27 | Beat 3, steps 8 and 9: "Needs a home (1)"; "Added by Mum"; "Added while offline; Ms Lee's word got this spot first"; "Place in next free spot", "Choose a spot", "Remove". | `tray_panel.dart`; T1; `tray_test.dart`. | automated-test only |
| V28 | Beat 3, step 10: "The child's board shows "swing" and does not show "park"." | `BoardSnapshot.of` leaves contested tiles out (`reconcile_snapshot.dart`); T1 checks the grid on every replica. | automated-test only |
| V29 | Captions 1:02 to 1:31 (bracketed): the three surfaces; both adults fill the cell; the teacher reconnects first; "This wait is real". | Plans for the take. They depend on checks 2, 4, 7, 8 and 9. | unverified |
| V30 | Caption 1:31: "[One word holds the cell. The other waits in "Needs a home". Serverpod offline sync kept both rows.]" | As R15. | automated-test only |
| V31 | Caption 1:36: "When two adults fill the same empty cell offline, both words survive." | As R4. | automated-test only |
| V32 | Card: "Serverpod 4.0.4 on Serverpod Cloud." "chorus.serverpod.space" | Device log header; R37. | device-verified |
| V33 | Card: "[In this video: Serverpod offline sync 0.0.10 (a replica on every device, one shared space per child, one unique index per space, streaming sync) and email sign-in.]" | Version and index: R26, R37. The module's `sync` endpoint is a streaming method. No beat shows a sign-in: the accounts are made before recording. | unverified |
| V34 | Card: "The sync module is experimental and pinned to one version. Two adults changing the same label offline: the later change wins." | R32, R37. | automated-test only |
| V35 | Card: "[In the third take the browser was paused with the app's own switch.]" | A fact about a take not yet made. | unverified |
| V36 | Upload text: "deployed on Serverpod Cloud"; "Try it: https://chorus.serverpod.space". | Device log. | device-verified |
| V37 | Upload text: "Mature tools already offer offline boards with cloud sync." | As R5; no product is named here. | code only |
| V38 | Upload text: "Three uncut takes on one physical phone and the hosted web app". | A plan. | unverified |
| V39 | Upload text: the three bracketed lines at 0:00, 0:30 and 1:02, and the bracketed limit. | Plans; they depend on checks 2, 6, 9 and 7. | unverified |
| V40 | Upload text: "Starter vocabulary: the 36-word Universal Core vocabulary, Center for Literacy and Disability Studies, UNC-Chapel Hill, CC BY-SA 4.0." | As R61. | code only |
| V41 | "scrcpy 4.0 and ffmpeg 8.1.1 are installed. That ffmpeg build has no `subtitles` and no `drawtext` filter". | Both tools report those versions; `ffmpeg -filters` lists neither filter. | code only |
| V42 | "Homebrew's `ffmpeg-full` has both." | The formula exists. It was not installed on the recording Mac at check time, so its filters were not listed. | unverified |
| V43 | "Today it is attached to adb over wireless debugging, which airplane mode cuts". | `adb devices` listed the phone over a wireless connection. Device log says the same. | code only |
| V44 | "`adb reverse --list` must print nothing". | Not tried. scrcpy opens a reverse tunnel of its own while it mirrors, so the list is empty only before scrcpy starts. | unverified |
| V45 | "The app notices a lost network on a connectivity event or at its next 20-second check." | `deviceKicks` and `probeEvery` in `sync_supervisor.dart`; tests as V8. | automated-test only |
| V46 | "On a phone the pill reads "1 waiting". The longer wording ... (at least 600 points wide and 480 high)." | `talkerLayoutFor` in `talker_screen.dart`; `talker_layout_test.dart`, "the layout follows the room there is". | automated-test only |
| V47 | "keep it under 900 points wide so the editor stays a single column." | `editor_screen.dart` (`constraints.maxWidth < 900`). | code only |
| V48 | Section 12: the test names and files given as proof. | Each test exists under the name and in the file given. | code only |
| V49 | Section 12, row 1: "The app's Credits screen says the same." | The Credits screen says the child is a persona and that Chorus "has not been used or validated clinically". It does not use the caption's words. | code only |

## docs/feedback-form.md

| # | Claim | Evidence | Status |
|---|---|---|---|
| F1 | Summary: built on Serverpod 4.0.4, `serverpod_offline_sync` 0.0.10 and Flutter 3.47.7; "has been run in a desktop browser and on a physical Android phone". | R37; the build machine has Flutter 3.47.7; device log. | device-verified |
| F2 | "`serverpod cloud launch` built and rolled out the scaffold, the sync module and its migrations on the first attempt." "Emailed sign-up codes worked on Cloud with no configuration." | Device log, Cloud table. | device-verified |
| F3 | "The module ran on a physical Android phone (arm64, release build) and in a browser, where the SQLite replica persists in IndexedDB." | Device log. | device-verified |
| F4 | Finding 1: a write outside `transactionForUser` disappears; the key becomes `<value>__hidden__<id>`. | Sync test `spaces_test.dart`, T9. Passed in CI. | automated-test only |
| F5 | Finding 2: `updateRow` without `columns` is whole-row last-writer-wins. | `merge_test.dart`, "T3 control". The module README says "Field-level merges". | automated-test only |
| F6 | Finding 3: reads span every space, and `spaceId` is null on rows. | `spaces_test.dart`, T10. | automated-test only |
| F7 | Finding 4: no reconnect, no status, `syncOnce` cannot be cancelled; "a 700-line supervisor". | Read in the module's `client_sync.dart` and `engine.dart`, as the form says; no test. `sync_supervisor.dart` has 697 lines. | code only |
| F8 | "[On the phone, sync resumed by itself after the network came back.]" | Device log: not yet checked. | unverified |
| F9 | Finding 5: a unique conflict raises no event; `CrdtProjectionReason.uniqueConflict` is diagnostic-only; the first device to sync needs a second sync. | Module source (the enum's own comment); `spike-results.md`, timings. | code only |
| F10 | Finding 6: a demoted member's pending edits are dropped silently. | `spaces_test.dart`, "T8 when a member is made read-only on the server while holding an ...". The explanation is read from `space_state.dart`. | automated-test only |
| F11 | Finding 7: generated test tools do not wire the sync engine; `ValueEncoder` is a process-wide static. | `circle_endpoint_test.dart` (the two extra lines); `serverpod_database` 4.0.4, `value_encoder.dart`; `chorus_server/test/sync/replicas.dart`. | code only |
| F12 | Finding 8: `sqlite3.wasm` and `db_worker.js` are named nowhere in the module README or the Serverpod packages used; versions 3.7.1 and 0.14.5. | Searched the module README, the three module packages and four Serverpod packages at these versions: no match. The names are `sqlite_async`'s defaults (`sqlite_options.dart`). `pubspec.lock`. | code only |
| F13 | Finding 9: 0.0.11 was published two hours after 0.0.10 and needs `serverpod: ^4.1.0-beta.3`. | pub.dev API at check time: 0.0.10 on 9 October 2026 at 02:36 UTC, 0.0.11 at 04:42 UTC. | code only |
| F14 | Finding 10: a duplicate primary key on SQLite raises `DatabaseQueryException`, code 1555; the adapter maps only 2067. | `merge_test.dart`, "T7 when a device that already holds the starter board seeds again ..."; `sqlite_error_codes.dart` in `serverpod_database` 4.0.4. | automated-test only |
| F15 | Finding 11: two tabs of one browser profile sign each other out. "Seen once, in Edge." | Device log, desktop browser table. The cause is read from `jwt_admin.dart`, and the form says so. | device-verified |

## docs/post-draft.md

| # | Claim | Evidence | Status |
|---|---|---|---|
| P1 | "written in Flutter on Serverpod 4.0.4 and the experimental `serverpod_offline_sync` module, 0.0.10." | R37. | code only |
| P2 | "The child is a persona. No child, family or clinician has used Chorus, and I make no clinical claims." | As R7. | code only |
| P3 | "Mature tools in this space already offer offline boards with cloud sync; the README names two." | The README names CoughDrop and AsTeRICS Grid (R5). | code only |
| P4 | The `tile.spy.yaml` excerpt, "lines 12 to 18". | Identical to lines 12 to 18 of `chorus_server/lib/src/boards/tile.spy.yaml`. | code only |
| P5 | "the engine keeps both rows. The earlier write keeps the cell, whichever device syncs first." "My test uses real Postgres and SQLite replica files and checks the server and both replicas." | T1, as R4. | automated-test only |
| P6 | The `cell_conflict_test.dart` excerpt, "lines 105 and 106". | Identical to those two lines. | code only |
| P7 | "I have not yet run the two-device collision by hand". | Accurate: device log, "Not yet checked on a device". | code only |
| P8 | "[I have now run it on a phone and a browser, and the losing word showed under "Needs a home" on both.]" | Not yet done. | unverified |
| P9 | "I found no event for it in 0.0.10. So after every merge the app re-reads the tiles and parses each key as placed, contested, tray or unknown." | As R29; `cell_key.dart` has those four forms. | code only |
| P10 | "says whose word got the spot first, and lets an adult give it a free spot or remove it." | `tray_panel.dart`. | code only |
| P11 | The `isSafePoint` excerpt, "lines 240 to 246". | Identical to lines 240 to 246 of `chorus_shared/lib/src/reconcile_snapshot.dart`. | code only |
| P12 | "A new word in an empty cell, a change to a tile in place, and a removal that leaves a gap apply by themselves. A different tile in an occupied cell, or a visible tile in another cell, waits for an adult." | `reconcileSnapshot`; `reconcile_snapshot_test.dart` (23 tests). | automated-test only |
| P13 | "when the word holding a contested cell is removed, the engine gives the freed cell to the waiting word by itself." | Sync test T6. | automated-test only |
| P14 | "[A "Replaced changes" panel in the editor shows the overwritten value and can restore it.]" | As R33. | automated-test only |
| P15 | The three surprises: the vanishing write, the silent drop for a demoted member, the two exception types. | Sync tests T9, T8 (made read-only), T2 and T7 (seeds again). All passed in CI run 38456926421. | automated-test only |
| P16 | Links to the web app and the source; "Source, MIT". | Both answered 200; `LICENSE`. | code only |
| P17 | "I built Chorus with Claude Code." | The author's statement. | unverified |

## Sentences Chorus does not say

None of the six documents contains them. This was checked by search.

| Not said | Why |
|---|---|
| "Nothing is lost." "No edit is hidden." "Every overwritten edit is recoverable." | Two adults editing the same label offline is last-writer-wins. The "Replaced changes" list covers label, spoken text and colour only, and has not been seen on a device. |
| "No tool does this." "The first." "The only." | A negative about a whole field cannot be proven. The documents say "we have not found". |
| Any clinical or outcome claim. | No child, parent or clinician has used Chorus. |
| Any product name other than Serverpod and Chorus, in the video. | The video carries no third-party trademarks. Other tools are named in the description and the README only. |

One sentence inside the app comes close to the first row. The "Replaced changes" panel says "Nothing was thrown away." (`chorus_ui/lib/editor/replaced_changes_panel.dart`). That holds for label, spoken text and colour, and not for a replaced photo or recording.
