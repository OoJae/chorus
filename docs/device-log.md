# Device log: what was checked on real hardware, and what was not

Each entry says who did the check, on what, against which server, and what was seen. "Driven over adb" means the taps were sent to the phone from the Mac and the result was read from a screen capture; nobody heard the audio in those entries.

Server for every entry: Serverpod Cloud, project `chorus` (`https://chorus.serverpod.space`, API `https://chorus.api.serverpod.space`), Serverpod 4.0.4, `serverpod_offline_sync` 0.0.10.

## 13 October 2026

### Serverpod Cloud

| Check | Result |
|---|---|
| `serverpod cloud launch` of the scaffold with the sync module and its migrations | Built and rolled out on the first attempt. |
| Hosted web build finds the API by itself (`/assets/assets/config.json`) | Returns `https://chorus.api.serverpod.space`. |
| Our own endpoint on Cloud (`status/info`) | Returns the server time. |
| `sqlite3.wasm` and `db_worker.js` served from the hosted build | Both 200 (758 KB and 227 KB). |
| Emailed sign-up code on Cloud | Arrived; the participant signed up with it in a desktop browser. |

### Desktop browser (Microsoft Edge on macOS), hosted web build

| Check | Result |
|---|---|
| Sign-up, then "Try a demo board" | Board created and seeded; the participant heard it speak. |
| Sign-in survives a page reload | Yes: the home screen came back with the board. |
| Local database persists across reloads | Yes: `chorus_<user id>.sqlite` in IndexedDB. |
| Talker renders the 36-word board | Yes. |
| Leaving the talker (first build: a small lock icon held for 3 s) | Failed: nothing happened and there was no visible way out. Fixed the same day: a labelled "Hold to leave" control, 2 s, completed by a timer. Not yet re-checked in the browser. |
| Home screen straight after a reload | Showed "There is no board here yet" for more than ten seconds before the board appeared. Cause: sync started before the first local read, and in the browser the database has one connection. Fixed the same day; not yet re-checked in the browser. |
| Two tabs of one browser profile signed in as the same person | One tab was signed out: the server logged `RefreshTokenNotFoundException`. Refresh tokens rotate, and both tabs share one stored token. Use a normal window and a private window for two sign-ins. |

### Android phone (Xiaomi 2409BRN2CA, Android 16, arm64), release build from `flutter build apk --release`

| Check | How | Result |
|---|---|---|
| The release build installs and starts | Installed by the participant, later over adb | Yes. |
| Sync delivers a circle created in the browser | Driven over adb | The home screen showed "Maya's board" and the chip read "Up to date". The board had been created in the desktop browser, so it reached the phone through the sync module. This is the first run of the module on Android that we know of; upstream's example has no Android target. |
| Talker speaks | Driven over adb | Tapping "I", "want", "more" built the sentence, and the device log showed Google's speech service opening audio output at each tap. Nobody listened during this run; the participant had heard speech in the browser earlier. |
| "Hold to leave" | Driven over adb | A 2.7 s press returned to the home screen. |
| Second board | Driven over adb | The editor showed the "Home" and "My words" tabs. |
| Add a word while online | Driven over adb | "mango" appeared in the first cell of "My words"; the chip returned to "Up to date". |
| Add a word with "Work offline" on | Driven over adb | The chip read "Working offline, saved on this phone"; "guava" appeared in the next cell. |

### Layout problems seen on the phone (afternoon build)

- Portrait: the sentence strip is squeezed to about a third of the width by its three buttons.
- Tile labels use a different font size on each tile.
- Landscape: the strip and status row leave thin slivers for the tiles.

All three were fixed in the evening build and seen fixed on the phone (see below).

## 13 October 2026, evening (20:15 to 21:00 UTC)

Build under test: `main` at `46f3f13` (photos, recorded voices, live pointing, "Replaced changes", paper copy, word suggestion), deployed to Serverpod Cloud at 19:47 UTC; release APK of the same commit installed on the phone at 20:21 UTC. One account ("Parent") was signed in on both the phone and Microsoft Edge on the Mac for every check in this section, so "two devices" here means two devices of one person. The phone was driven over adb and read from screen captures; Edge was driven through its automation extension.

### Serverpod Cloud

| Check | Result |
|---|---|
| Deploy of the evening build | Built and rolled out; migration `20261013180422859` applied on start. |
| Server restart under open clients (`serverpod cloud deploy --redeploy`) | Edge's chip went to "Connecting" and came back to "Up to date" by itself. |
| `demoPassword` set by the participant, then a redeploy | Done. The three demo sign-ins have not been tried on Cloud yet. |

### Phone and browser together

| Check | Result |
|---|---|
| A word added on the phone with "Work offline" on reaches the server after the switch goes off | Yes, twice: "guava" (afternoon build) and "yak" (evening build) both appeared in Edge. While the phone's switch was on, "yak" did not reach Edge. |
| A word added in Edge arrives on the open phone | "kiwi" appeared in the phone's editor 9.2 s after "Add to board" was pressed in Edge. |
| Two devices fill the same empty cell while both have "Work offline" on | Run twice. First: phone "park", then Edge "playground" a minute later, same cell; phone back online first. Seconds after Edge went back online the phone showed "park" in the cell and "Needs a home (1)": "playground", "Added by Parent", "Added while offline; Parent's word got this spot first", with "Place in next free spot", "Choose a spot" and "Remove". Second: phone "swing", Edge "slide"; the phone then showed "Needs a home (2)". Every other word stayed in its cell. |
| The same clash as seen from Edge | Wrong until a reload. For more than two minutes after going back online Edge kept its own word in the cell and did not list it under "Needs a home"; after a page reload it showed the same result as the phone. |
| "Work offline" in Edge | Did not hold: a word added in Edge 14 s after its switch went on reached the phone within 9 s. |
| Cause of the two Edge results above | Most likely a second copy of the app in the same Edge profile (the participant's own signed-in tab beside the automated one). The browser's lock table showed several clients on the app's database. Two tabs of one profile share one local database: the other tab kept syncing what the "offline" tab wrote, and merged the clash result without this tab's screens being told. The same clash run on a local server with one tab per sign-in converged on both sides in under two seconds. Not yet re-run on Cloud with a single tab. A rule of one tab per browser profile is being added. |
| Photo on a word, added in the hosted web app | The browser's upload went straight to Cloud storage and was accepted (`media/requestUpload` 200, `PUT storage.googleapis.com/...` 200, `media/confirmUpload` 200). The word "ball" with its picture then showed on the phone's board. The picture was given to the app's file input by script, not through the system file dialog. |
| Word suggestion with no key set on the server | The offer was shown; pressing it gave "No suggestion this time. Type the word instead." and nothing else changed. |
| New layouts on the phone | Seen in portrait and landscape: full-width sentence box, three buttons under it in portrait, board tabs, one label size per board. In landscape the vertical tab cuts "My words" to "My wor…". |

### Desktop browser, demo-data build (no server)

| Check | Result |
|---|---|
| "Hold to leave" with a mouse in Chromium | A 2.5 s press returned to the home screen; a short click did not. |
| Phone-sized window (360x820 and 820x360) | Child's screen, editor with a clash in "Needs a home", add-word sheet with photo, voice and suggestion, and "Show words on the board" all rendered without overflow. |

### Local development server, three demo sign-ins in one browser on three origins

Run by an automated tester; see `docs/manual-test.md` for the steps. Twelve of twelve core checks passed: sign-in, first open seeds 36 words, child's screen, add a word, arrival on the second sign-in (1.95 s), a new word held back while the sentence strip is in use ("1 word waiting", shown 2.05 s after the strip was cleared), the offline same-cell clash converging on both sides, placing the waiting word from the tray, the read-only partner, reload showing the board at once from local data, and removing a word.

## 14 October 2026, morning (08:15 to 08:45 UTC)

Same build as the evening section (`46f3f13` on Cloud and on the phone). Same single account on both devices. The participant first closed the extra Chorus tabs in Edge, so exactly one copy of the app was open in that browser profile; the browser's lock table showed one client.

| Check | Result |
|---|---|
| "Work offline" in Edge, one tab | Holds. "fish", added in Edge 50 s after its switch went on, did not reach the phone in the next 45 s. It arrived when the switch went off. |
| Two devices fill the same empty cell offline, one tab in Edge | Phone "frog" first, then Edge "cat" in the same cell; phone back online first, then Edge. Edge showed the result by itself 4.8 s after its switch went off, with no reload: "frog" in the cell and "cat" under "Needs a home (3)" with "Added while offline; Parent's word got this spot first". The phone showed the same. |
| Closing the extra tabs | Signed the remaining tab out, as two tabs of one profile did on 13 October; the participant signed in again (email and password, from the "Sign in" link under the first form). |
| Phone chip after the night | Read "Offline, saved on this ph…" with "Sync now" once; "Sync now" brought it back to "Up to date" within 8 s. |

This confirms the cause given in the evening section: the two Edge failures came from several tabs of one browser profile sharing one database, not from the sync engine.

### No network at all, done by hand by the participant (about 08:40 UTC)

On this phone airplane mode leaves Wi-Fi on (it remembers that Wi-Fi was switched back on), so the participant turned Wi-Fi off as well, with airplane mode on. No mobile data, no Wi-Fi.

| Check | Result |
|---|---|
| Talker speaks with no network | Yes. The participant heard each tapped word and the sentence from the speaker button. The phone's log shows the system voice loading its on-device voice files at 08:41 UTC. |
| Add a word with no network | Done ("cake"); no error. The participant removed the word again afterwards, so its upload was not checked. |
| Close the app completely and reopen it with no network | The board came up and spoke. |
| Wi-Fi back on | The chip returned to "Up to date" by itself. |
| Errors | None seen. |

## 14 October 2026, afternoon (12:50 to 13:20 UTC): the redesign on Cloud

Build under test: branch `wave5` at `2b38bd7` (the redesign, the word log, "This week", the view-only board, Open Board Format export and import, more boards, Mulberry symbols, the photo suggestion through Xiaomi MiMo), deployed to Serverpod Cloud at 12:49 UTC; release APK of the same commit installed on the phone at 13:02 UTC. Same single account on the phone and in Edge, one Edge tab. The suggestion service was set to `mimo-v2.6-pro` through its Anthropic-compatible endpoint, with the participant's own key.

| Check | Where | Result |
|---|---|---|
| Launch reveal, then home with the board as a 3D object | Edge (dark mode) and phone (dark mode) | Yes. Edge's first frame came 1.6 s after a reload. Dragging across the board tilted it in perspective; it settled back on release. |
| "Open Maya's board" | Edge | The child's board opened with Mulberry symbols on 23 words, "Private", the live mark and "Hold to leave". "I", "want", "more" built the sentence; "Hold to leave" returned home. |
| Photo suggestion through MiMo | Edge | For a photo of a red ball: "Suggested. Tap one to use it: ball, circle, red", 9.4 s after the request. Nothing went on the board until chosen. |
| Word log | Edge | Off by default. Turned on by the guardian ("On for Maya's board, on every device in the circle"); five taps on the child's board. |
| "This week" | Edge | "5 taps · 4 words"; most used "more ×2", then go, help, want; first-time words and words added this week listed. |
| View-only board for a babysitter | Edge, then a second browser with no account | Link made, expiry 21 October. The page opened with no sign-in, made no request to any other site, and spoke "want" and "more" when tapped. Response headers: `Content-Security-Policy: default-src 'none'; ... script-src 'unsafe-inline'; img-src data:` and `Cache-Control: private, no-store`. |
| Open Board Format export | curl | `/export/<token>`: HTTP 200, `Home.obf` as an attachment, format `open-board-0.1`, 6 x 6, 36 buttons with colours, licence block. |
| Add, rename and archive a board | Edge | "+" added "Board 3"; right-click on its tab opened "Rename this board" and "Archive this board"; rename saved; archive asked "Maya will no longer see this board. Nothing is deleted." and removed the tab. "Archive this board" is greyed out for Home. A long press with a mouse did not open the menu (right-click does). |
| Import an Open Board Format file | Edge | A four-word .obf file (given to the file input by script) became a new board "Snacks": "4 words are on the new board", in their positions. It reached the phone's child board as a new tab. |
| Paper copy | Edge, then a second browser | The link opened (HTTP 200) with the new mark, colours and credits. Fault found: rows with no words printed as thin lines. Fixed in `be2a08e` (each empty cell keeps its full-height box), not yet deployed at the time of writing. |
| A new word held back on the child's board | Phone and Edge | Phone on "My words" with "mango guava" in the strip; Edge added "juice". The phone showed "1 waiting" and did not place the word. After the strip was cleared, "juice" appeared in its cell within 3.5 s and the notice went. Nothing else moved. |
| Two devices fill the same empty cell while working offline | Phone and Edge | Phone "cookie" first, Edge "cake" a minute later, same cell, both with "Work offline" on. Phone back online first, then Edge. Edge showed "cookie" in the cell and "cake" under "Needs a home · 4" within 15 s, with no reload; the phone showed the same in its bottom sheet. |
| Phone layout of "Work offline" on home | Phone | The explanation was squeezed into a narrow column. Fixed in `be2a08e`, as for "Share what is said". |

### Not yet checked on a device

- An offline word uploading after a real loss of network (checked only with "Work offline").
- Two different accounts on two devices on Cloud (every check above used one account).
- Live pointing ("Show words on the board") reaching the phone, recorded voices, "Replaced changes" with restore, and the demo sign-ins, all on Cloud.
- A touch long press on a board tab on the phone (right-click was used in the browser).

## 14 October 2026, late afternoon (15:25 to 16:20 UTC): the research-led features on Cloud

Build under test: branch `wave6` at `b41ac5c` (the nine feature branches merged, one combined migration, the landing page at `/` and the app at `/app/`), deployed to Serverpod Cloud at 15:25 UTC. Checked in Edge on the Mac with the participant's account, one tab. The phone still ran the 13:02 APK during these checks, so nothing below was checked on the phone.

| Check | Where | Result |
|---|---|---|
| Landing page and its headers | curl, then Edge | `/` HTTP 200 with its own CSP (`script-src 'self'`, no third party), `no-cache`, `nosniff`, a referrer policy; HEAD 200. The board's tiles built "I want" in the strip and announced each word. "Open Chorus" played the board flight and arrived at `/app/`. Console errors only from the browser's own extensions. |
| The app at `/app/` | curl, then Edge | `/app` answers 301 to `/app/`; `/app/main.dart.js`, `/app/flutter_bootstrap.js`, `/app/sqlite3.wasm`, `/app/db_worker.js` 200; `/app/assets/assets/config.json` gives `{"apiUrl":"https://chorus.api.serverpod.space"}`. The session from the root survived the move (same origin): Edge opened home already signed in, with every board. Unknown root paths give a plain 404; bad `/b/`, `/print/`, `/export/`, `/report/` tokens give their own 404 or 410. |
| A picture on every core word | Edge, home and the child's board | All 36 words of the Home board have a symbol, including the 13 that were text only (like, not, he, she, that, it, here, all, can, stop, you, do, different). |
| "What changed" and Undo | Edge | The feed listed the day's changes by name and local time ("Parent added 'cake' · 14:14", "Parent put 'cake' away · 09:39", "Parent recorded a voice for 'cake'"). Undo on "added 'cake'" wrote "Parent put 'cake' away · 16:32"; Undo on that wrote "Parent brought 'cake' back · 16:32". Its old spot was taken by then, so "cake" went to "Needs a home", as the rule says. The banner on home read "Since you last looked: 26 changes". |
| Try a clash on one device | Edge | Board menu, "Try a clash": step 1 switched the device to "Working offline, saved on this device"; step 2 said "The practice partner just put 'bubbles' here on their own device", with the empty spot glowing on "My words" (the practice partner's word was written on the server through `transactionForUser` in about 4 s); I added "slide" in the glowing spot; the chip read "Working offline, 1 change waiting to send"; step 3, "Turn Work offline off". Within 12 s the guide said "Both words are safe. 'bubbles' got to the spot first, so it keeps it. 'slide' waits under Needs a home, on every adult's device. Nothing was lost." The tray card showed both words, "Practice partner · 16:33" and "Parent · 16:35", with "Choose a new spot" and "Put it away". |
| Status chip words | Edge | "Everyone's up to date" when nothing waits; "Working offline, 1 change waiting to send" in Work offline with one unsent change. Once, at 15:44 UTC, the sync connection dropped ("Offline, saved on this device · Sync now"); "Sync now" brought it back to "Everyone's up to date". The Cloud log shows one failed websocket upgrade at that minute. |
| Who is up to date; Under the hood | Edge | "This device: up to date" (the phone, on the old APK, does not report yet). Under the hood: board 4, tile 61, tile_edit 60 rows in the device's replica; sync live; 0 waiting; last sync 1 minute ago; the circle's space id; serverpod_offline_sync 0.0.10; the API address. |
| Word finder | Edge | "help": "Home board · row 2, column 5" with a small map and "Show on Maya's board". The glow on another device was not checked. |
| Hide for now; Show everything | Edge, editor and the child's board | '"yak" is hidden for now. Its spot stays the same.'; dimmed with a mark in the editor. On the child's board its cell was blank and everything else in place; "Show everything" brought it back with "Every word is showing until you leave the board". |
| Quick phrases, word endings, keyboard | Edge, the child's board | Quick phrases opened six phrases; "Help" went into the strip. "dog" then "+s" offered dogs, dogging, dogged, dog's; "dogs" replaced the word. The keyboard gave "jump" and "juice" for "ju". |
| A ready-made board | Edge | "Add a ready-made board", "Feelings": "24 words are on the new board", with Mulberry pictures on happy, sad, angry, scared, excited, calm, worried, hot, quiet, hug and others. |
| Named copies | Edge | "Save a copy" of Feelings as "Before the school trip"; "Copies" listed "Feelings · 24 words · Parent, 14 Oct 2026, 16:42". |
| A second language | Edge | The word sheet's "Second language" (Yoruba offered first); "happy" given "ayọ̀". On the child's board a "Yoruba" switch appeared in the status row; on, "happy" read "ayọ̀" in the same cell with the same picture. Speech in Yoruba was not checked. |
| This device: touch, scanning, voice | Edge | The page shows hold time, ignore repeat taps, select on release, scanning (off, one switch, two switches) and the circle's voice. Two switches: Space moved a thick ring row by row, Enter chose the row, Space moved along it, Enter put "he" in the strip; the grid did not move. Scanning was set back to off. |
| Word log, "This week", modelled and said, focus words, progress report | Edge | With the log on, "This week" showed "9 taps · 8 words". In "Show words on the board", tapping "go" and "help" logged them as modelled; "This week" then read "go: modelled 1 · said 1" and "help: modelled 1 · said 1". Focus words: "help" pinned with the tip "At snack time: 'help open?'", shown as "Words of the week" in the model bar and as a ring in the editor. The report link opened `/report/<token>` titled "Maya: progress, week of 12 October 2026": counts only, "No sentences are kept", expiry 13 November. |
| Picture scenes | Edge | "Make a scene from a photo" (the photo given to the file input by script), named "Playtime"; a spot drawn round the ball and named "ball". On the child's board a "Scenes" button appeared in the status row; the scene opened full screen and tapping the spot outlined it and put "ball" in the strip. |
| Photo ideas | Edge | For the ball photo, "Ideas for this photo. Tap one to use it: ball, red, roll, bounce, round, throw", coloured by word type, with "Add all to Needs a home". Nothing went on the board. |

A code review after these checks found the following, fixed and deployed at 16:35 UTC (commit `e6e924a`): switch scanning could still reach a hidden word; the second-language voice read non-translated words; "Recent" sentences carried over between circles; the practice limit was too low for a shared demo circle; "Delete the word log" left the sitter's taps and report copies; "Remove from circle" was switched off for the deadline.

## 14 October 2026, evening (16:35 to 17:20 UTC): the fixed build on Cloud and the phone

Build under test: branch `wave6` at `e6e924a` (the research-led features plus the fixes from the code review), deployed to Serverpod Cloud at 16:35 UTC; release APK of the same commit installed on the phone by the participant at 16:39 UTC (downloaded over the local network and installed from the browser, because the phone refused an install over adb). Same single account on the phone and in Edge.

| Check | Where | Result |
|---|---|---|
| The new app on the phone | Phone | Home showed "Everyone's up to date", a picture on every core word and "Since you last looked: 56 changes". The child's board showed the new status row: share, recent, the up-to-date mark, live, "Show everything", the language switch, "Private" and "Hold to leave". No "Scenes" button appeared on this narrow screen. |
| Word finder glow reaches the child's board | Edge to phone | Edge: "Find a word", "help", "Show on Maya's board" ("'help' is glowing. If Maya is on another board, the Home tab glows too."). The phone's next screenshot, about 2 s later, showed "help" with the glow ring; it faded within a few seconds. |
| Presence line | Edge with the phone's board open | The editor showed "Parent is looking at the board" while the phone had Maya's board open. |
| Speech with no network at all | Phone, recorded by the participant with the phone's own screen recorder | Airplane mode on and Wi-Fi off (the status bar shows both). On Maya's board: "I", "want", then "My words", "juice"; then "I", "want", "more". Each word was spoken by the phone; the recording has the sound. |
| A new word held back, then placed | Phone and Edge, recorded | Phone on "My words" with "mango guava" in the strip; Edge added "juice" to an empty spot. The phone showed "1 waiting" about 8 s later and did not place it. When the strip was cleared, "juice" appeared in its spot about 2 s later and the notice went; nothing else moved. (The first recording attempt was stopped by the recording script's own front-app check; the behaviour was the same.) |
| Two devices fill the same empty spot while working offline | Phone and Edge, recorded | Both with "Work offline" on. Phone added "outside" to "My words" row 3, column 5 at 17:15 UTC; Edge added "home" to the same spot a minute later ("Working offline, 1 change waiting to send"). Phone back online first ("Connecting", then "Everyone's up to date"), then Edge. Edge then showed "outside" in the spot and "Needs a home · 7" with "home" waiting; the phone's editor showed "Needs a home · 7" too. |
| Brief loss of the API from the browser | Edge | Twice (about 16:08 and 17:12 UTC) the browser's calls to the API failed for under a minute as CORS errors, and once the chip read "Offline, saved on this device"; "Sync now" or the app's own retry recovered. The Cloud log showed no server error at those times and every direct request answered. |

## 14 October 2026, about 17:45 UTC: the demo sign-in on Cloud

Done by the participant in an Edge InPrivate window, on the deployed `e6e924a`: "I already have one", then `demo.parent@chorus.example` and the demo password (set on Cloud with `serverpod cloud password set demoPassword`). "Maya's board" opened and the chip reached "Everyone's up to date", which makes the shared demo board on the server. The therapist and partner demo sign-ins were not tried.
