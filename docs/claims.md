# Claims

Every public sentence we intend to make, mapped to the evidence for it. The rule: a sentence stays in the video or the description only if its row here is `verified on <date>` against the deployed build. A row still at `not yet` at submission time means the sentence is deleted, not softened.

Nothing below is verified yet. Nothing has been built or run.

## How to use this file

- **Proof** is either an automated test (file and test name) or a manual check (a step in `docs/manual-test.md`). "It worked on my machine once" is not a proof.
- Test names marked TODO are the scenarios named in the plan. Replace each with the real file and test name once the test exists and passes.
- **Status** is `not yet` or `verified on <date>`. Re-verify after every deploy that touches the feature, and update the date.
- When the final captions and the final description are written, add one row per sentence that is not already covered. A sentence with no row does not ship.

## The three beats (video)

| # | Claim | Where it is said | Proof | Status |
|---|---|---|---|---|
| B1a | The phone speaks a sentence. | Video 0:00-0:30, first 3 seconds | Manual: before-submitting check "beat 1, twice, on the physical phone, with a stopwatch". TODO measure: seconds from first frame to first spoken word (target under 3). | not yet |
| B1b | With airplane mode on, it still speaks. | Video 0:00-0:30; description, flow | Manual: beat 1 with OS airplane mode on and the airplane icon visible; cold start in airplane mode (kill the app, start it, tap, hear speech). Spike S2 ("cold start offline works") and S7 (offline voice installed). Run the cold start on the phone and, separately, in the browser: the web app keeps the circle list in the browser's local storage, which a private window or blocked site data switches off. Say "the phone" in the sentence unless the browser check also passes. | not yet |
| B2a | An adult on another device adds a word and it arrives on the child's board. | Video 0:30-1:02; description, flow | Manual: smoke test steps 1 and 2 (word appears within 20 s). TODO measure: seconds from "add" on the web app to "1 word waiting" on the phone. | not yet |
| B2b | The new word lands at a safe moment, between sentences: the board shows "1 word waiting" first. | Video 0:30-1:02; description, flow | Unit: `chorus_shared` tests for `isSafePoint` (strip empty, not speaking, 2 s since last touch) and `reconcileSnapshot` (an added tile into an empty cell is an auto change). TODO test names. Manual: beat 2 twice on the physical phone. | not yet |
| B2c | The new word is spoken when tapped. | Video 0:30-1:02 | Manual: beat 2, tap the arrived word, hear it. | not yet |
| B3a | Two adults, both offline, put different words in the same empty cell. After reconnect both words exist. | Video 1:02-1:40; description, flow | Sync test: `chorus_server/test/sync/cell_conflict_test.dart`, scenario "same cell" (two offline inserts of one cell give one clean row and one suffixed row on every replica). TODO test name. Spike S4. Manual: judge script in `docs/manual-test.md`. | not yet |
| B3b | One word holds the cell; the other waits in a visible "Needs a home" tray. | Video 1:02-1:40; description, flow | Unit: `trayOf` returns the suffixed tile with reason `contested` and `wanted` set to the cell it lost; `gridOf` returns the winner. TODO test names. Manual: beat 3 twice; the tray shows the losing word on both adult devices and on the observer. | not yet |
| B3c | No existing button moved. | Video 1:02-1:40 | Unit, property test on `reconcileSnapshot`: for every cell occupied before, the next snapshot holds the same tile id or nothing, and no tile id appears in a different cell. TODO test name. Manual: compare the board before and after reconnect in the take. | not yet |
| B3d | The wait on reconnect shown in the video is real (no cut inside the take). | Video 1:02-1:40, visible clock on every surface | Manual: the take is continuous and every surface shows a clock. Spike S6 (10 of 10 airplane toggles converge within 20 s). TODO measure: seconds from airplane mode off to the tray appearing, on the filmed take. | not yet |

## Version-one wording

These are the only forms in which the core promise may be stated until the edit log is deployed and verified.

| # | Claim (exact wording) | Where it is said | Proof | Status |
|---|---|---|---|---|
| W1 | "No button the child already uses ever changes place." | Video captions; description; README | Same as B3c (property test on `reconcileSnapshot`). Also: the store offers no cell-to-cell move (allowed moves are tray or contested tile into an empty cell, and board to tray). TODO: test that `placeTile` refuses a tile that already holds a cell. | not yet |
| W2 | "When two adults fill the same empty cell offline, both words survive." | Video captions; description; README | Same as B3a and B3b. | not yet |
| W3 | "Established apps already sync boards." | Video (no product names in the video) | Wording check only: this sentence concedes, it does not claim. Named in the description and README as CoughDrop and AsTeRICS Grid. TODO before submitting: re-open both products' own pages and confirm "offline boards with cloud sync" is still how they describe themselves. | not yet |
| W4 | "We have not found a tool that shows what happens when two adults change the same board offline." | Description; README | A statement about our search, not about the field. TODO: record in the README which tools were looked at and on what date. | not yet |
| W5 | "The child in this story is a persona. No child, parent or clinician has used Chorus." | Video caption over the first 7 seconds; end card; description; README | True by construction as of 2026-10-13. If a real reaction is collected before submitting, reword this sentence and add a row for the quote, with the person's consent. | not yet |
| W6 | Each Serverpod feature named in a caption fires at that moment in the take. | Video captions; end card | TODO: list the final captions here, one row each, with the code path that runs. Captions name only Serverpod and Chorus. | not yet |

### Sentences we do not say

| Do not say | Why | Becomes sayable when |
|---|---|---|
| "No edit is hidden." | Two adults editing the same label offline is last-writer-wins; the losing edit is gone from view. | The edit log with restore (Phase 2) is deployed and verified. |
| "Nothing is lost." | Same reason. | Same. |
| "Every overwritten edit is recoverable." | Needs the edit log and one-tap restore. | Phase 2 deployed and verified. |
| "No tool does this." / "The first..." / "The only..." | We cannot prove a negative about the field. Use W4. | Never. |
| Any clinical or outcome claim ("helps children communicate better", "recommended by therapists"). | No child, parent or clinician has used Chorus. | Never without evidence we do not have. |
| Any product name other than Serverpod and Chorus, in the video. | Video rules: no third-party trademarks. | Never in the video. Established tools are named in the description and README only. |

## Other sentences in the description

| # | Claim | Where it is said | Proof | Status |
|---|---|---|---|---|
| D1 | The board is a 6x6 grid of the 36-word Universal Core vocabulary. | Description; README | Unit: `universalCore36` has 36 entries in row-major order; `starterTiles` yields 36 tiles. TODO test names. Manual: check the labels against the published Universal Core list. | not yet |
| D2 | Speech is on-device and needs no network. | Description | Same as B1b. | not yet |
| D3 | Guardian, therapist and teacher can edit; a partner can read but not edit. | Description; README | Sync test: "three identities with a read-only member" (read-only cannot write). Endpoint test: role matrix. Manual: smoke test step 3. TODO test names. | not yet |
| D4 | A word added offline reaches the other devices after reconnect, without restarting the app. | Description | Spike S2 (within 15 s of reconnect, both directions) and S6. Manual: judge script. | not yet |
| D5 | Seeding the starter board twice gives 36 tiles and an empty tray. | README (tests table) | Sync test: "double seeding". Unit: `deterministicId` is stable. TODO test names. | not yet |
| D6 | When the tile holding a cell is removed, the oldest waiting word takes the cell. | Description or README, only if stated | Sync test: "freed cell reclaimed" (archiving the winner hands the cell to the loser). TODO test name. | not yet |
| D7 | Nothing the child says is stored or sent. | Description; README | Code check: talker mode writes no synced rows and calls no endpoint on tap or speak. TODO: a test that drives `TalkerController` against a store that fails on any write. | not yet |
| D8 | The app shows its sync state in plain words and offers "Sync now". | Description | Manual: status chip reads correctly in airplane mode, while reconnecting and when live. | not yet |
| D9 | The server runs on Serverpod Cloud. | Description; end card | Manual: smoke test against the Cloud URL. Spike S5. | not yet |
| D10 | A new person can register and receives an emailed code. | Description (testing access) | Manual: smoke test step 4. | not yet |
| D11 | Each judge can start a fresh demo circle. | Description (testing access) | Manual: "Start a fresh demo circle" gives a clean starter board that other demo users do not see. | not yet |
| D12 | The demo accounts (parent, therapist, partner) work. | Description (testing access) | Manual: smoke test steps 1 to 3. | not yet |
| D13 | Built with Claude Code. | Description; README | True by construction. | not yet |

Sentences that depend on phases 2 to 7 (edit log, photos and voices, AI suggestion, live session, print and export, symbols) are in square brackets in `docs/DESCRIPTION.md`. Add a row here for each one only when its phase is deployed; otherwise delete the sentence.

## Wave 3: edit log, photos and voices, live session, paper copy, suggested word

Added on 2026-10-13 when the wave-3 branch was integrated. Every row is **not yet verified on a device**: the proofs named are automated tests that pass on the build machine against fakes, a local SQLite replica or the embedded test database. Nothing in this section has run on a phone, in a browser against a started server, or against the deployed build. A sentence from this section goes in the video or the description only after its manual check is done and the status is changed.

"Server test" means a file under `chorus_server/test/integration/`, "app test" one under `chorus_flutter/test/`, "screen test" one under `chorus_ui/test/`, "rule test" one under `chorus_shared/test/`.

| # | Claim | Proof | Status |
|---|---|---|---|
| E1 | When two adults change the same word's label, spoken text or colour without seeing each other's change, the editor lists the replaced change under "Replaced changes" and one tap puts it back. | Rule test `detect_overwrites_test.dart` (38 cases: concurrent tips, restore then edit, clocks ahead, null bases). Screen test `replaced_changes_test.dart`. App tests `sync/edit_log_store_test.dart` (real replica, the other adult's edit row inserted by hand) and `sync/replica_board_store_test.dart` "the edit log is read with the tiles, and a restore is logged as one". Sync test T4 (both `TileEdit` rows survive a label collision). Manual: phone checklist item 6 in the integration report. | not yet verified on a device |
| E2 | A restore is an ordinary edit: same single write path, narrowed columns, logged with reason `restore`, so it can itself be undone. | App test `sync/replica_board_store_test.dart`: "the edit log ...", and "updates name only the columns they change: updateTile". | not yet verified on a device |
| E3 | Scope of E1: label, spoken text and colour only. A replaced photo or recording is logged but not listed and not restorable. No two-replica run of the panel exists; the merge is simulated on one replica. | Stated as a limit. | not yet verified on a device |
| M1 | An adult can give a word a family photo and a recording of up to five seconds in their own voice. | Screen test `media_widgets_test.dart` (21 cases) and `wiring_test.dart` "a word with a photo shows it in the grid ...". App tests under `media/` and `sync/replica_board_store_test.dart` group "setTileMedia". Manual: checklist items 2 to 4. | not yet verified on a device |
| M2 | Photos and recordings work with no connection: they are kept on the device first and sent when the connection returns. | App test `media/cached_media_store_test.dart`: "adding with no connection", "files go up when the connection returns, oldest first", "unsent files survive a restart of the app". Manual: checklist item 4. | not yet verified on a device |
| M3 | On the child's board a tapped word plays the family's recording when it is on the device, and the device's voice otherwise. A whole sentence is always spoken in the device's voice. | App test `media/clip_tile_speaker_test.dart`. Screen test `wiring_test.dart`: "a tapped word goes to the clip speaker, a sentence to the voice". App test `app/home_screen_test.dart`: "the talker and the editor each open a live session ..." (the talker is handed the speaker and the media store). Manual: checklist item 3. No device has played a clip. | not yet verified on a device |
| M4 | A photo is shrunk to at most 512 pixels and re-encoded before it leaves the device, which drops the original's location and camera details. | App test `media/image_shrink_test.dart`. | not yet verified on a device |
| M5 | A picked photo or a recording that is not saved is kept nowhere and sent nowhere. Exception, stated on screen: pressing "Suggest a word from the photo" sends that photo. | Screen test `media_widgets_test.dart`: "closing the sheet keeps and sends nothing", "closing the sheet mid-recording throws the recording away". Screen test `wiring_test.dart`: "is offered only once a photo is picked ..." (offering sends nothing). | not yet verified on a device |
| M6 | The server stores a file only for members of the circle, only after checking its bytes against its hash, and hands out links that last five minutes. Another circle learns nothing about a hash it does not hold. | Server test `media_endpoint_test.dart` (12 cases, names begin "when a guardian uploads a photo ...", "when the uploaded bytes do not match the hash ...", "when another circle asks for the same hash ..."). The upload over HTTP is simulated in those tests; a real `FileUploader` round trip has not run. | not yet verified on a device |
| L1 | An adult can turn on "Show words on the board" in the editor and tap a word; it glows for about 2.5 seconds on the other devices in the circle that are connected, including the child's board. Nothing on any board changes. | Server test `live_endpoint_test.dart` (10 cases, including "when two devices share one account then each still gets the other's events"). App test `live/chorus_live_session_test.dart`. Screen tests `live_talker_test.dart`, `live_model_mode_bar_test.dart`, `wiring_test.dart` "in model mode a tap points at the word and opens nothing". Manual: checklist item 7. The client has never been connected to the real endpoint. | not yet verified on a device |
| L2 | Nothing the child says is sent unless a guardian has turned on "Share what is said" on that device. While it is on the child's board shows a bar saying so, and a tap on the bar turns it off. | App test `live/chorus_live_session_test.dart`: "shareSaid is off by default and then nothing is sent", "only a guardian can turn sharing on". Screen test `live_talker_test.dart`: "no sharing bar while sharing is off", "the sharing bar shows while on and a tap turns it off". App test `app/home_screen_test.dart`: "only a guardian is offered the sharing switch". Manual: checklist item 8. | not yet verified on a device |
| L3 | The live session stores nothing: the server relays events and keeps none, and the app keeps the last shared sentence only in memory while the screen is open. | Server test `live_endpoint_test.dart`; code: `LiveEndpoint` writes to no table. | not yet verified on a device |
| L4 | While the child's board is joined to the circle's live session it shows a mark saying so. | Screen test `wiring_test.dart`: "says so for as long as it is joined to the circle". | not yet verified on a device |
| P1 | "Print a paper copy" makes a page of the board as it is on this device and shows a link to it. The page shows words and colours only, needs no sign-in, and stops working after 30 days. | Rule test `print_snapshot_test.dart`. Server test `print_test.dart` (17 cases). App test `app/home_screen_test.dart`: "a paper copy sends the board on this device and shows the link", "a paper copy that cannot be made says so and nothing else". Manual: checklist items 9 and 10. The link's host comes from the server's web-server settings, which have only been read in the test configuration. | not yet verified on a device |
| S1 | Optional: after picking a photo for a new word, an adult who is online can ask for a suggested word. The suggestion only fills in the form; nothing reaches the board until the adult adds the word. | Screen test `wiring_test.dart` group "Suggest a word from the photo" (6 cases). App test `suggest/server_word_suggester_test.dart`. Server test `suggest_endpoint_test.dart` (16 cases, all through a fake transport). Manual: checklist item 11. The model service has never been called; the feature is off until the key is set on the server, and then the app does not offer it again after the first "not set up" answer. | not yet verified on a device |
| S2 | A circle can ask for a limited number of suggestions per day. | Server test `suggest_endpoint_test.dart`: "when a circle has used its daily budget then it is over budget until the next day ...". | not yet verified on a device |

### Sentences this wave makes sayable, once verified

- "Every overwritten edit is recoverable" stays unsayable. The sayable form is E1 with its scope: "When two adults change the same word's label, spoken text or colour, the replaced change is listed and can be put back." Only after E1 is verified on the deployed build, and the limit "last-writer-wins until the edit log ships" below is rewritten in the same commit.
- "No edit is hidden" and "Nothing is lost" stay unsayable: a replaced photo or recording is not listed (E3).

### Limits added by this wave

- Recorded voices: a clip recorded in a browser that has no AAC encoder is stored as Opus or WAV. The macOS and iOS apps may not play Opus; those devices then speak the word in the device's voice.
- A photo redraws its tile on the child's board as soon as it arrives on the device, not at a safe moment. The tile does not move; its label gets smaller and the picture appears.
- A new word with a photo or recording is written in two steps. If the second fails, the word exists without its photo and the app says so.
- The live session works on one server instance only. A member removed from a circle while joined would keep receiving until their connection closed; Chorus has no way to remove a member today.
- Two devices signed in as the same adult show as one name under "Here now".
- The paper copy's link is public to anyone who has it for 30 days. It carries the child's name, the board's name and the words.
- Asking for a suggested word uploads the photo to the circle's private storage even if the word is then not saved.
- Files the server will never accept from this adult (a read-only role, or a file over the size limit) are dropped from the upload queue without a message; the local copy stays on the device.

## Limits we state

These are said in the description and README, and the short ones on the video's end card. They are claims too: each must stay true and stay stated.

- The offline sync module is experimental. Chorus pins one released version of it and may break on another.
- No clinical validation. No child, parent or clinician has used Chorus.
- The child in the story is a persona.
- Two adults editing the same label offline is last-writer-wins until the edit log ships. The losing edit is not shown or recoverable.
- Every member of a circle can read the whole board, including read-only members. The app says so.
- A removed member keeps what was already downloaded to their device.
- An edit made offline by a member whose role was then reduced to read-only is dropped by the server without an error, and still looks saved on that member's device (spike T8 stale). Chorus has no way to change or remove a member's role today, so this cannot happen yet. Revisit this line, and the "Sending changes" status, before adding one.
- "Up to date" in the status chip means the last sync finished without an error. It is not a receipt for each edit.
- A cold start with no signal opens the board only on a device that has opened it before while connected.
