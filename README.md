# Chorus

**A talking picture board for a non-speaking child that works offline, which the adults in the child's circle edit from their own devices. When two adults fill the same empty spot offline, both words survive, and no word the child knows ever moves.**

Built on Serverpod 4.0.4 and its experimental offline sync module, hosted on Serverpod Cloud. Maya, the child in the demo, and every adult in it are personas. No child, parent or clinician has used Chorus, and it makes no clinical claims.

Chorus is an AAC (augmentative and alternative communication) board. Mature AAC apps exist, such as CoughDrop, AsTeRICS Grid, Proloquo2Go and TD Snap. We have not found one that shows what happens when two adults change the same board offline, or that lets one device try it.

## Try it in a few minutes

1. Open https://chorus.serverpod.space/ with the sound on and click "Open Chorus". The first visit can take a while to load. We have tried it only in Microsoft Edge on macOS.
2. Click "Make a board for my child" (if you see "Sign In with email" instead, click "Sign up"). Type your email address, without "+" in it (that is not accepted), and click "Continue". Type the code you are emailed and click "Verify"; if it has not come after a minute, look in your spam folder. Choose a password and click "Sign up". On "Who is the board for?", click "Try a demo board". (Or click "I already have one" and use a [demo sign-in](#demo-sign-ins). Every judge shares that board.)
3. On home, wait until "Edit words" can be clicked, then click it.
4. Open the board menu (the ⋮ button, "More for this board") and choose "Try a clash".
5. Follow the card above the board:
   1. The device switches itself to "Work offline", like a phone with no signal.
   2. The practice partner puts a word in an empty spot, and the spot glows. The practice partner is a stand-in for a second adult that lives on the server: it has a role in your circle's sync space, but no account, and it is not one of the circle's members. Click the glowing spot, type a word of your own and click "Add to board".
   3. Click "Turn Work offline off".

**What you will see.** A few seconds later (12 seconds when we checked on 14 October) the card says "Both words are safe." The word put in the spot first keeps it (first by the write's clock, not by which reached the server first). The other waits under "Needs a home", on every adult's device. Its card shows both words, both names and both times, with "Choose a new spot" and "Put it away". Nothing else on the board moves.

If the card says "Every spot is taken", add a board with "+" and try again. On the shared demo circle the partner may say "The practice partner needs a rest. Try again in an hour." If it does, sign up with your own email address and you get a circle of your own. If you see "Chorus is open in another tab", click "Use Chorus in this tab".

To see the child's side, go back home and click "Open Maya's board". Tap words to hear them. To leave, press and hold "Hold to leave" for two seconds.

## Links

- Landing page: https://chorus.serverpod.space/
- Web app: https://chorus.serverpod.space/app/
- Android APK: https://github.com/OoJae/chorus/releases/latest (release `submission-v1`, file `chorus.apk`; debug-signed, Android 7.0 or later).
- Video (1:39, with a voice-over): https://youtu.be/NV1OloM1HX4.
- Code: https://github.com/OoJae/chorus
- A longer walkthrough, with two adults in two windows: [docs/TRY-IT.md](docs/TRY-IT.md)
- What was checked on real devices: [docs/device-log.md](docs/device-log.md)

## Demo sign-ins

| Sign-in | Shown as | Role | What it can do |
|---|---|---|---|
| `demo.parent@chorus.example` | Maya's mum | Guardian | Everything, including the word log and sharing |
| `demo.therapist@chorus.example` | Speech therapist | Therapist | Change the board, including "Try a clash" |
| `demo.partner@chorus.example` | Grandad | Partner | View the board and "Suggest a word" |

The password is in the submission text, never in this repository.

- All three share one circle, so other judges' words may already be on it. Use any empty spot.
- The demo board is made by the demo parent's first sign-in, which we do before submitting. If the therapist or partner sign-in shows "There is no board here yet", sign in once as `demo.parent@chorus.example` (in another window, or after signing out), then click "Retry".
- The demo parent's sign-in was checked on Cloud on 14 October at 17:45 UTC: "Maya's board" opened and reached "Everyone's up to date", which made the shared demo board. The therapist and partner sign-ins have automated tests only. If one fails, sign up with your own email address instead.

## What it demonstrates

1. **The board lives on the device.** The child's screen reads a local SQLite replica and uses the device's own speech engine. On 14 October, with airplane mode on and Wi-Fi off, the phone spoke each word that was tapped, and the board came back after the app was closed and reopened.
2. **Changes land between sentences.** A word from another adult waits as "1 word waiting" ("1 waiting" on a phone). It lands only when the sentence strip is empty, nothing is speaking and the board has been left alone for two seconds. Checked on the phone on 14 October: "juice" waited until the strip was cleared, then appeared within 3.5 seconds. A property test checks that automatic changes never put a different word in a cell that already holds one. That waits for an adult to confirm "Update the board?".
3. **A same-spot clash keeps both words.** One word keeps the spot. The other waits under "Needs a home" until an adult places it. Checked between the phone and a browser on 13 and 14 October, with one account signed in on both. Automated sync tests on real replicas cover three orderings.
4. **One device is enough to see it.** "Try a clash" adds a practice partner on the server, which fills the spot while your device works offline. Checked in a browser on Cloud on 14 October.

## What the circle gets

Each item says how far it was checked. "Checked" means it was seen working on a real device against the Cloud deployment, as recorded in the [device log](docs/device-log.md). "Built and tested" means automated tests cover it but nobody has checked it on a device yet. Most of these features were checked in a browser only; the phone got the final build late on 14 October, and only some were checked there.

**Trust and repair, for the adults**

- **"What changed" with one-tap "Undo".** Every change to a word is listed with the adult's name and the local time. An undo is saved as a new change, so nothing is wiped. Home counts what came in while you were away ("Since you last looked: 26 changes"). Checked.
- **"Needs a home" in plain words.** A parked word shows both words, both adults and both times. The tray never uses the word "conflict"; only "Under the hood" shows the engine's raw key. Checked.
- **Sync status in words.** The chip reads "Everyone's up to date", or "Working offline, 1 change waiting to send". Checked. "Who is up to date" lists the circle's devices and when each last synced. It was checked for the browser only. A line naming who else is looking at the board was checked: the editor in Edge showed it while the phone had the board open.
- **"Under the hood".** It shows the rows in this device's replica for each table, the changes waiting, the last sync, the circle's space id and the module's version. Checked.
- **Named copies.** "Save a copy" keeps a board under a name, such as "Before the school trip". "Copies" lists the saved copies. Saving and listing were checked. "Put back" sends a word from a copy back through "Needs a home". It is built and tested.
- **"Replaced changes".** When two adults change the same field of a word offline, the replaced label, spoken text or colour is listed with a one-tap restore. Built and tested.

**On the child's board**

- **A picture on every core word.** All 36 words of the Home board have one: 28 from Mulberry Symbols, and 8 drawn for Chorus in the same style. Checked.
- **Word endings, quick phrases and a keyboard.** "Word endings" changes the last word: "dog" offered "dogs" and "dog's", among others. It knows the common irregular verbs. "Quick phrases" opens six whole phrases ("Stop", "Help", "I'm hurt", "Toilet", "All done", "I need a break"), and adults can change them for everyone. Changing the phrases is built and tested. "Keyboard" spells with prediction: "ju" offered "jump" and "juice". All three were checked in a browser. On a phone, a long press on the sentence strip offers them instead of keys. That is built and tested.
- **"Hide for now" and "Show everything".** An adult can hide a word in place: its cell goes blank and every other word stays where it is. "Show everything" brings the hidden words back until the adult leaves the board. Checked.
- **A second language on the same cells.** "Second language" on a word adds its label in the family's other language. A switch on the child's board then shows that label in the same cell, with the same picture. Checked with Yoruba labels. Speech in Yoruba was not checked.
- **Picture scenes.** "Make a scene from a photo" turns a family photo into a scene with spots that speak. Checked, with the photo given to the page's file input by script rather than through the file dialog.
- **Ready-made boards.** "Add a ready-made board" offers Food, People, Places, Feelings, Actions and Describing words, with 24 words each. Checked with Feelings.

**Touch, switches and voice ("This device")**

- **Touch settings.** "Hold time", "Ignore repeat taps" and "Select on release" are kept on the device. The page was seen, but the settings were not tried in use.
- **Switch scanning.** "Scanning" offers "One switch" or "Two switches". A ring moves row by row, then along the chosen row, and the grid never moves. Two switches were checked in a browser, using Space and Enter.
- **Keyguard.** "Keyguard mode" keeps the board at one size and in one place, with nothing appearing above it. "Keyguard template" draws the grid in millimetres as an SVG, for a plastic keyguard. Built and tested.
- **The circle's voice.** "Which voice", speed and pitch are chosen once for the circle. Every device and the view-only page then use them. The page was seen. The voice reaching another device was not checked.
- **Share a sentence.** "Share the sentence" opens the share sheet where the device has one, or copies the sentence. "Recent" lists the sentences said this session and keeps them in memory only. Built and tested.

**Modelling: adults show words on the board as they talk**

- **"Show words on the board".** An adult taps words in the editor and they glow on the child's board over the live stream. These taps count as modelled, not said. Counting was checked. The same glow, sent from the word finder, reached the phone on Cloud on 14 October.
- **Word finder.** "Find a word": typing "help" gave "Home board · row 2, column 5" with a small map. "Show on Maya's board" made "help" glow on the phone's board a moment later (checked on Cloud, 14 October).
- **Modelled and said.** With the word log on, "This week" counts the words adults modelled apart from the words the child said, for example "help: modelled 1 · said 1". Checked.
- **Focus words.** Up to three "Focus words" a week, each with a tip for the adults ("At snack time: 'help open?'"), shown as "Words of the week". Checked. Each Thursday at 09:00 UTC, a note on home names a focus word nobody has modelled yet that week. The note is built and tested, and the first one is due on Thursday 15 October.
- **"Listen".** An adult turns on "Listen" and talks, and the words on the board glow as they are said. It works in the web app only, using the browser's speech recognition. Built and tested.
- **"Progress report".** A one-page report behind a link, `/report/<token>`, with counts only. It says "No sentences are kept", and the link lasts 30 days. Checked.

**Photos, sharing and files**

- **Photo ideas.** "Suggest a word from the photo" sends the photo to the suggestion service, which offers 3 to 6 words coloured by word type. For a photo of a ball: "Ideas for this photo. Tap one to use it: ball, red, roll, bounce, round, throw". A tap fills in the adult's form, and "Add all to Needs a home" puts the words in the tray. Nothing goes on the board until an adult places it, and the AI never speaks for the child. Checked with Xiaomi MiMo's `mimo-v2.6-pro`, through its Anthropic-compatible API. The server can call Anthropic's API instead.
- **Photos on words.** A photo is uploaded straight to Cloud storage. Checked. Recorded voices are built and tested.
- **A view-only board for a sitter.** "Share a view-only board" makes a link that opens with no sign-in, speaks when tapped and lasts 7 days. Checked. While the word log is on, a sitter's taps show up in "What changed". That part is built and tested.
- **Paper copy and Open Board Format.** "Print a paper copy" gives a printable page at `/print/<token>`. It was checked on Cloud. The fix for a fault seen then (empty rows printed as thin lines) is in this build, but has not been checked again. "Export this board (.obf)" and "Import a board (.obf)" move a board to and from other tools. Both were checked on Cloud with Chorus's own files; no file from another tool has been tried.
- **Word log and "This week".** The word log is off until a guardian chooses "Keep a word log". "This week" then shows taps, words, the most used words and first-time words. Checked.
- **Removing someone from the circle.** "Remove from circle" is built, but it is switched off for the deadline because a code review found a problem in it.

## How it uses Serverpod

| Serverpod feature | Where | What Chorus does with it |
|---|---|---|
| Offline sync module 0.0.10 (`databaseSync`, `database: sync`) | [`generator.yaml`](chorus_server/config/generator.yaml), [`boards/`](chorus_server/lib/src/boards/) | A SQLite replica of the circle's board on every device. Three synced tables, `board`, `tile` and `tile_edit`, unchanged since the first deploy. |
| Unique index per space, field-level merge, parked conflicts | [`tile.spy.yaml`](chorus_server/lib/src/boards/tile.spy.yaml), [`tray.dart`](chorus_shared/lib/src/tray.dart) | `cellKey` is unique per space, so a clash keeps both rows. Every update names its columns. The parked row is shown as "Needs a home". |
| Shared spaces and roles | [`circle_endpoint.dart`](chorus_server/lib/src/circles/circle_endpoint.dart), [`membership_guard.dart`](chorus_server/lib/src/circles/membership_guard.dart) | One space per child. Guardian, therapist and teacher can write; a partner can only read. Our endpoints check the role on every call. |
| `spaces.grant` and `transactionForUser` on the server | [`practice_endpoint.dart`](chorus_server/lib/src/practice/practice_endpoint.dart) | The practice partner of "Try a clash": a server-side stand-in with a role in the circle's sync space, which writes into it the way an adult's device would. |
| Sync client | [`replica_service.dart`](chorus_flutter/lib/src/sync/replica_service.dart), [`sync_supervisor.dart`](chorus_flutter/lib/src/sync/sync_supervisor.dart) | One `transactionForUser` write queue. Around it, Chorus adds reconnect with backoff, a clock check before sync (the module refuses drift over one minute; Chorus warns at 45 seconds) and the status chip. |
| Auth with emailed codes | [`server.dart`](chorus_server/lib/server.dart) | Sign-up with a code sent through Serverpod Cloud's email. |
| Endpoints | [`lib/src/`](chorus_server/lib/src/) | Circles and invitations, members, the word log, suggestions, practice, devices ([`device_seen_endpoint.dart`](chorus_server/lib/src/trust/device_seen_endpoint.dart)), scenes, copies, voices, quick phrases, languages and word settings, focus words and reports. |
| Streaming method | [`live_endpoint.dart`](chorus_server/lib/src/live/live_endpoint.dart) | Live pointing, presence and shared sentences, relayed between members and never stored. The glow and the presence line were checked between Edge and the phone on Cloud on 14 October; shared sentences were not. |
| File storage | [`media_endpoint.dart`](chorus_server/lib/src/media/media_endpoint.dart) | Photos and recorded voices, held in private storage. Each file is named by its SHA-256 and checked on the server. |
| Future calls | [`scheduled_jobs.dart`](chorus_server/lib/src/jobs/scheduled_jobs.dart) | The weekly summary (Mondays 02:00 UTC), the Thursday focus-word note (09:00 UTC) and a daily clean-up of expired links (03:30 UTC). They need a Cloud plan that runs future calls; the live project's Starter plan does not, so none runs there. Without the jobs, a week's summary is worked out when it is asked for and the Thursday note is written when home first asks after 09:00. The clean-up has no such fallback, but an expired link is refused either way. |
| Web server routes | [`app_route.dart`](chorus_server/lib/src/web/app_route.dart), [`app_config_route.dart`](chorus_server/lib/src/web/routes/app_config_route.dart), [`print_routes.dart`](chorus_server/lib/src/printing/print_routes.dart), [`sharing_routes.dart`](chorus_server/lib/src/sharing/sharing_routes.dart), [`progress_routes.dart`](chorus_server/lib/src/progress/progress_routes.dart) | The landing page at `/`, the Flutter app at `/app/`, and four token pages: `/print/<token>`, `/b/<token>` (view-only), `/export/<token>` (.obf) and `/report/<token>`. |
| Passwords | [`suggest_service.dart`](chorus_server/lib/src/suggest/suggest_service.dart), [`demo_seed.dart`](chorus_server/lib/src/demo/demo_seed.dart) | `anthropicApiKey`, `suggestModel` and `suggestBaseUrl` for photo ideas. `demoPassword` creates the demo sign-ins. |
| Serverpod Cloud | [`scloud.yaml`](chorus_server/scloud.yaml) | Hosts the server, Postgres, the web pages and email, on the Starter plan (Europe; 256 MB compute, a small database with 2 GB of storage). |

Every table added after the first deploy is server-only: 21 of them, 18 on 14 October. The gaps we worked around are logged in [docs/feedback-log.md](docs/feedback-log.md).

## The conflict design

A word's position is one string, `cellKey`, which is unique within a space ([`tile.spy.yaml`](chorus_server/lib/src/boards/tile.spy.yaml)). It has three forms:

- `<boardId>:<row>:<col>`: on the board.
- `tray:<tileId>`: not placed, or archived. Written by the app.
- `<boardId>:<row>:<col>__conflict__<rowId>`: written only by the sync engine.

When two devices that have not synced insert different words with the same placed key, the engine keeps both rows. The earlier claim keeps the cell, and the later one gets the suffix. No event fires, so after every merge `trayOf` ([`tray.dart`](chorus_shared/lib/src/tray.dart)) reads the keys and lists the suffixed words under "Needs a home". The app never moves a word from one cell to another.

"Earlier" means the lower hybrid logical clock on the `cellKey` write, not the first to reach the server. So a later word can sync first, show on the child's screen, and then lose the cell when the earlier write arrives. The same swap happens when the word holding a contested cell is removed: the engine hands the cell to the waiting word (sync test T6). `reconcileSnapshot` ([`reconcile_snapshot.dart`](chorus_shared/lib/src/reconcile_snapshot.dart)) treats both cases as `replaced` and keeps them out of the automatic changes. The child's screen keeps the old word and marks the waiting count with an adult icon. An adult holds it for two seconds and confirms "Update the board?". This is built and tested. The held snapshot lives in memory, so closing and reopening the child's screen shows the board as synced.

Every update names its columns, so edits to different fields of one word both survive. Edits to the same field are last-writer-wins. Each edit is also written to `tile_edit`, which is what "Replaced changes", "What changed" and "Undo" are built on.

"Try a clash" uses only the frozen tables, in the order sync test T1 already covers. The practice partner's word is written on the server; your word is written on your device while it is offline.

These rules have automated tests in [`chorus_server/test/sync/`](chorus_server/test/sync/), which run against an embedded PostgreSQL and real SQLite replicas. That includes [`practice_clash_test.dart`](chorus_server/test/sync/practice_clash_test.dart) for "Try a clash". Results: [docs/spike-results.md](docs/spike-results.md).

## What we learned on serverpod_offline_sync

Chorus is built on version 0.0.10 of an experimental module. These are the lessons that shaped the code, for whoever builds on it next.

- **Design the schema for the engine before writing the app.** The tile's position, `cellKey`, is unique per space (`unique(per=spaceId)`). The engine resolves clashes on that index, so we put there the one thing that must never be lost: what each cell on the child's board means. The relation from tile to board is `deferred`, so a tile and its board can arrive in either order.
- **Once deployed, the synced schema is frozen.** Clients compare a schema hash when they connect, so any change to a synced model would lock every installed app out of sync. Everything added after the first deploy went into ordinary server-only tables: the word log, voices, focus words, scenes and the rest. Only `board`, `tile` and `tile_edit` are synced.
- **Parked conflicts became a feature.** The engine keeps both rows of a unique clash and marks the later claim with a `__conflict__` suffix. We parse that suffix ([`tray.dart`](chorus_shared/lib/src/tray.dart)) into the "Needs a home" tray. The tray never uses the word "conflict"; only "Under the hood" shows the engine's raw key. A parent sees two words, two names and two times, and nothing lost.
- **"Earlier" means the hybrid logical clock, not arrival.** A later word can sync first and briefly hold the cell. Our snapshot rules ([`reconcile_snapshot.dart`](chorus_shared/lib/src/reconcile_snapshot.dart)) treat that swap as a replacement, which the child's screen never applies by itself.
- **The module has two roles; people have more.** It knows `readWrite` and `readOnly`. Guardian, therapist, teacher and partner are mapped onto those in our own endpoints ([`circle_endpoint.dart`](chorus_server/lib/src/circles/circle_endpoint.dart)), which check the role on every call.
- **Every shared write needs `transactionForUser(..., spaceId:)`.** A write without it lands in the user's personal space and silently disappears from everyone else's view, even its author's (draft issue 5). Every query also filters on our own `circleId` column, because reads span all of a user's spaces.
- **Name the columns in every update.** `updateRow(columns: ...)` keeps the merge field-level, so two adults changing different properties of one word both win. We also log every change in `tile_edit`, which is what makes "Replaced changes", "What changed" and "Undo" possible.
- **The server can be a member of a space too.** `spaces.grant` gives any id a role in a space, and `transactionForUser` then writes as that member. The practice partner of "Try a clash" is a UUID derived from the circle's space id. It has a sync role and nothing else: no account and no circle membership. On Cloud its word was written in about 4 seconds.
- **What we had to build around the module:**
  - a supervisor with reconnect, backoff and a clock check (the module refuses more than a minute of drift);
  - a status chip, and "Under the hood" to show the replica itself;
  - a held snapshot, so the child's screen changes only between sentences;
  - a rule of one tab per browser profile, because two tabs of one profile share one SQLite file. On 13 October two tabs made "Work offline" leak and hid a clash until a reload; with one tab the next morning, both worked.

We wrote the gaps up as six draft issues with repro tests in [docs/upstream-issues.md](docs/upstream-issues.md), drawn from the full log in [docs/feedback-log.md](docs/feedback-log.md).

## Checked on real devices

Every check below was made against the Serverpod Cloud deployment. The devices were Microsoft Edge on macOS and a Xiaomi phone (2409BRN2CA, Android 16, release APK). One account was signed in on both. The full record, with times and what was seen, is in [docs/device-log.md](docs/device-log.md).

| When (UTC) | Build | Where | Seen working |
|---|---|---|---|
| 13 Oct, afternoon | first Cloud build | Edge, phone | Sign-up with an emailed code. "Try a demo board", heard speaking in the browser. A board made in the browser reached the phone through sync. The talker and "Hold to leave" on the phone. Adding a word online and with "Work offline" on. |
| 13 Oct, 20:15–21:00 | `46f3f13` | phone and Edge | A word added offline reached the other device after "Work offline" went off. A word from Edge reached the open phone in 9.2 s. The same-spot clash on the phone: one word in the spot, the other under "Needs a home". A photo uploaded through Cloud storage. After a server restart, the chip recovered by itself. |
| 14 Oct, 08:15–08:45 | `46f3f13` | phone and Edge (one tab) | "Work offline" held. The clash showed on both devices with no reload (4.8 s). With airplane mode on and Wi-Fi off, the phone spoke each tapped word and reopened its board, and the chip came back by itself once Wi-Fi was on. |
| 14 Oct, 12:50–13:20 | `2b38bd7` | phone and Edge | The redesign with Mulberry pictures. The photo suggestion through MiMo. The word log and "This week". The view-only board, opened in a browser with no account. Export and import of .obf files (the import reached the phone). Adding, renaming and archiving a board. The paper copy. A new word held back on the phone ("1 waiting") until the strip was cleared. The clash between the phone and Edge again. |
| 14 Oct, 15:25–16:20 | `b41ac5c` | Edge only | The landing page at `/` and the app at `/app/`. A picture on every core word. "Try a clash". "What changed" and "Undo". The chip's words, "Who is up to date" for this device, and "Under the hood". The word finder. "Hide for now" and "Show everything". Quick phrases, word endings and the keyboard. The ready-made Feelings board. Named copies. Yoruba labels. Two-switch scanning. Modelled and said, and focus words. The progress report, picture scenes and photo ideas. |
| 14 Oct, 16:35–17:20 | `e6e924a` | phone and Edge | The fixed build. The new APK on the phone: its status row and a picture on every word. The word finder's glow reached the phone; the presence line read "Parent is looking at the board". A word added in Edge waited behind "1 waiting" on the phone until the strip was cleared, then landed. The phone and Edge, both working offline, filled the same spot: after reconnecting, one word kept it and the other waited under "Needs a home · 7" on both. |

Not yet checked on any device (built and tested only):

- Two different accounts on two devices. Every check used one account. Joining with an invitation code is covered by endpoint tests and sync test T8 only.
- The demo therapist and partner sign-ins on Cloud (the demo parent's was checked).
- An offline word uploading after a real loss of network. That was checked only with "Work offline".
- Other devices in "Who is up to date", recorded voices, and "Replaced changes" with restore.
- On the phone: hiding a word, a second language, the word tools, scanning and scenes (each was checked in Edge; the phone's new status row was seen).
- The Thursday note, the circle's voice on another device, the touch settings in use, keyguard mode and its template, "Share the sentence" and "Recent", a sitter's taps in "What changed", "Listen", "Put back" from a copy, and speech in Yoruba.
- One-switch scanning (two switches were checked), changing the quick phrases, the five ready-made boards other than Feelings, the word tools behind a long press on a phone, and a read-only partner's "Suggest a word".
- Placing a waiting word from the tray on Cloud. It was checked only on a local server.
- A touch long press on a board tab. Right-click was used in the browser.

A code review after the afternoon checks found six faults, listed in the device log before its evening section. The build deployed at 16:35 UTC fixes five of them, with automated tests, and switches "Remove from circle" off. The evening checks ran on that build, but none of them tried these fixes.

## Build and run

Built and checked with Flutter 3.47.7, and CI uses the same version. Pinned exactly: Serverpod CLI and packages 4.0.4, and `serverpod_offline_sync_server` and `serverpod_offline_sync_client` 0.0.10. Do not run `pub upgrade`, because module 0.0.11 needs a Serverpod 4.1 beta.

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

- Run locally, the server sends no email: the sign-up code is printed in the server log.
- There is no Docker: `config/development.yaml` sets `database.dataPath`, so Serverpod runs an embedded PostgreSQL.
- Optional passwords: `demoPassword` creates the three demo sign-ins. `anthropicApiKey` turns on photo ideas. `suggestModel` and `suggestBaseUrl` point the photo ideas at another model, or at any service that speaks Anthropic's Messages API.
- For a second adult, use a private window. Chorus runs in one tab per browser profile, and a second tab says "Chorus is open in another tab".

**The hosted site.** `serverpod run flutter_build` builds the web app with `--base-href /app/` into `chorus_server/web/app`. The server then serves:

- the landing page from `web/landing` at `/`;
- the app at `/app/` (`/app` redirects there);
- `/app/assets/assets/config.json` from its own route ([`app_config_route.dart`](chorus_server/lib/src/web/routes/app_config_route.dart)), with the server's public API address.

So the hosted app needs no build define. Locally the web server is on port 8082.

**Release APK**, from `chorus_flutter`:

```sh
flutter build apk --release --dart-define=SERVER_URL=https://chorus.api.serverpod.space/
```

Deploy with `serverpod cloud deploy` from `chorus_server`. [`scloud.yaml`](chorus_server/scloud.yaml) runs `serverpod generate` and `serverpod run flutter_build` first. More in [docs/BUILD.md](docs/BUILD.md).

## Tests

| Suite | Command | Tests |
|---|---|---|
| Server: endpoints, sync, routes, jobs | `cd chorus_server && dart test --concurrency=1` | 243 |
| Shared rules | `cd chorus_shared && dart test` | 397 |
| Screens | `cd chorus_ui && flutter test` | 828 |
| App | `cd chorus_flutter && flutter test` | 556 |

These counts are from 14 October 2026, on the merged tree, and every suite passes. The server suite runs on an embedded PostgreSQL. It needs the `test:` passwords from the build steps above, or the same values as environment variables (CI sets them that way); without them `demo_seed_test.dart` does not load. The sync tests run against real SQLite replicas. CI analyses and tests the server package only.

## Limits

- No clinical validation and no real users.
- The sync module is experimental. Chorus pins 0.0.10.
- "Remove from circle" is switched off for the deadline. A role cannot be changed either.
- The practice partner adds real words. Every adult in the circle sees them until someone removes them. The partner also has an hourly limit per circle, which a shared demo circle can use up.
- When a board is added, its tab takes the first empty place or goes at the end, and the child's tabs share the row again: each one narrows and shifts a little. The tabs keep their order, and an archived board leaves its place empty.
- A spot goes to the earlier write, even when that write syncs last. A word already on the child's screen can then be replaced, once an adult accepts the update or the child's screen is reopened.
- When two adults edit the same field offline, the last writer wins. "Replaced changes" covers label, spoken text and colour, but not photos or recordings.
- "Everyone's up to date" means this device is connected and has nothing waiting to send. It is not a receipt for each edit. Other devices appear in "Who is up to date" only once they run this build.
- The Cloud project is on the Starter plan, which does not run future calls. The weekly summary and the Thursday note are therefore written when an adult's app first asks for them (the same code the scheduled jobs call); on a plan with future calls they also run on schedule.
- Speech in a second language depends on the device having a voice for it. Nobody has heard Yoruba speech on any device yet.
- "Listen" works only in a browser with speech recognition. On a phone, the word tools are behind a long press on the sentence strip.
- The live session (pointing, presence and shared sentences) works on one server instance only.
- The APK is signed with the debug key and keeps the scaffold's id, `com.example.chorus_flutter`.
- The synced `Tile` table has two columns kept for features that were not built: `linkBoardId` is never set and `noLog` is always false. The synced schema is frozen, so they stay.
- Most new features have not been tried on the phone. On the final build it showed the status row, a picture on every core word, the word finder's glow, a held-back word and the same-spot clash. The phone layout notes from earlier builds are in the device log.

## Privacy

- The child's sentences are not stored. The word log is off until a guardian turns it on. It keeps only which word was spoken and when, never a label or a sentence, and it shows counts, not transcripts. "Delete the word log" removes it, with the weeks worked out from it, the words a sitter tapped and every progress-report link.
- "Private" on the child's board pauses the word log and sharing on that device.
- Sentences leave the device only while a guardian has "Share what is said" on for it, or when an adult presses "Share the sentence", which hands the sentence to the share sheet or copies it. Shared with "Share what is said", they are relayed to the members who are connected and are never stored. "Recent" sentences stay in memory until the app closes.
- Photos are shrunk on the device (512 pixels for a word, 1280 for a scene) and saved again as JPEG. EXIF data, including any location, is removed. They sit in private storage behind links that last five minutes.
- A photo goes to the suggestion service only when an adult presses "Suggest a word from the photo". On the live site that service is Xiaomi MiMo's `mimo-v2.6-pro`.
- A sitter's taps on the view-only page are kept only while the circle's word log is on, and only as the word and the time.
- Links shown outside the circle give the child's name and words to anyone who has them. The view-only board lasts 7 days and can be withdrawn with "Stop sharing". The paper copy lasts 30 days. The progress report lasts 30 days and holds counts only.
- The server holds each adult's email address and display name, the child's name as typed, and the board, and, where used: photos and recorded voices, scenes, board copies, the word log and weekly summaries, focus words, quick phrases, translations, word suggestions, device names and sync times, a sitter's taps, and the copies of the board and of the report behind shared links. Every member, including a read-only partner, can read the whole board.
- The landing page and the view-only page load nothing from any other site. There is no analytics or advertising code.

## Credits and licences

- **Code:** MIT, copyright 2026 OoJae ([LICENSE](LICENSE)).
- **Starter board:** the 36 words of the Universal Core vocabulary, created by the Center for Literacy and Disability Studies, University of North Carolina at Chapel Hill, licensed [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). Source: https://www.project-core.com/. Chorus adapted it as colour-coded tiles without the original Universal Core symbols, and shares the adapted board under the same licence. Chorus is not affiliated with or endorsed by the Center or the University. See [STARTER_BOARD_LICENSE.md](chorus_shared/STARTER_BOARD_LICENSE.md) and the in-app [Credits screen](chorus_ui/lib/credits/credits_screen.dart).
- **Mulberry Symbols:** pictures for 28 of the 36 starter words, for the ready-made boards and for the landing page are from [Mulberry Symbols](https://mulberrysymbols.org) by Steve Lee, licensed [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). The drawings are unchanged, only rendered as PNG files. See [chorus_ui/assets/symbols/LICENSE.md](chorus_ui/assets/symbols/LICENSE.md). The source SVG files are in [docs/brand/mulberry](docs/brand/mulberry) and [chorus_ui/symbols_src](chorus_ui/symbols_src/), with [SOURCES.txt](chorus_ui/symbols_src/mulberry/SOURCES.txt) naming the Mulberry file behind each ready-made board word.
- **Symbols drawn for Chorus:** can, different, do, here, it, stop, that and you, drawn in the Mulberry style by the Chorus authors because Mulberry has no picture a child would read as those words. CC BY-SA 4.0. They are in [chorus_ui/symbols_src/chorus](chorus_ui/symbols_src/chorus/).
- **Ready-made boards:** the six word lists (Food, People, Places, Feelings, Actions, Describing words) were written for Chorus by the Chorus authors and are shared as Open Board Format files under CC BY-SA 4.0, in [chorus_ui/assets/boards](chorus_ui/assets/boards/). The keyboard's word list was also written for Chorus.
- **Typefaces:** Fraunces, Atkinson Hyperlegible Next and IBM Plex Mono, under the SIL Open Font License 1.1. The licence texts are in [chorus_ui/assets/fonts](chorus_ui/assets/fonts/), and for the landing page in [chorus_server/web/landing/fonts](chorus_server/web/landing/fonts/).
- **Browser database files:** unmodified release files of the `sqlite3` and `sqlite_async` Dart packages.
