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

### Not yet checked on a device

- That the offline word ("guava") reaches the server when the phone resumes sync.
- A word added on one device arriving on another while both are open.
- Two devices filling the same empty cell while both are offline, and the "Needs a home" tray on both afterwards. (Proven in automated tests against real Postgres and SQLite replicas; see `docs/spike-results.md`.)
- Real airplane mode on the phone: speech with no network, a cold start with no network, and sync resuming afterwards. The phone was reached over Wi-Fi debugging, which airplane mode cuts.
- Anything from wave 3 (photos and recorded voices, live modelling, paper copy, word suggestion).

### Layout problems seen on the phone

- Portrait: the sentence strip is squeezed to about a third of the width by its three buttons.
- Tile labels use a different font size on each tile.
- Landscape: the strip and status row leave thin slivers for the tiles.
