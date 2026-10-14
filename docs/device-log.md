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

### Not yet checked on a device

- An offline word uploading after a real loss of network (checked only with "Work offline"; see the evening section).
- Two different accounts on two devices on Cloud (every check above used one account).
- A new word held back on the phone's child screen. One attempt was inconclusive: the word was added to "My words" while the phone showed "Home".
- Live pointing ("Show words on the board") reaching the phone, recorded voices, "Replaced changes" with restore, the paper copy, and the demo sign-ins, all on Cloud.
