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
| B1b | With airplane mode on, it still speaks. | Video 0:00-0:30; description, flow | Manual: beat 1 with OS airplane mode on and the airplane icon visible; cold start in airplane mode (kill the app, start it, tap, hear speech). Spike S2 ("cold start offline works") and S7 (offline voice installed). | not yet |
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

## Limits we state

These are said in the description and README, and the short ones on the video's end card. They are claims too: each must stay true and stay stated.

- The offline sync module is experimental. Chorus pins one released version of it and may break on another.
- No clinical validation. No child, parent or clinician has used Chorus.
- The child in the story is a persona.
- Two adults editing the same label offline is last-writer-wins until the edit log ships. The losing edit is not shown or recoverable.
- Every member of a circle can read the whole board, including read-only members. The app says so.
- A removed member keeps what was already downloaded to their device.
