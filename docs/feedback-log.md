# Feedback log

Running log of gaps we hit in Serverpod 4, the `serverpod_offline_sync` module, Serverpod Cloud and their docs while building Chorus. It becomes the hackathon's "Most Valuable Feedback" form.

Pins this log is written against: Serverpod 4.0.4, `serverpod_offline_sync_server` / `serverpod_offline_sync_client` 0.0.10, Flutter 3.47.7.

## How to use this log

- Add a row the moment something costs us time. Do not wait for a fix.
- **Status** has two values:
  - `observed in docs, not yet reproduced`: read in the docs, README, source or pricing page; we have not run code that shows it.
  - `reproduced`: we ran it. Add the date, the spike or test that shows it, and the exact error text or behaviour.
- Never move a row to `reproduced` from memory. If a spike shows the docs were right and we were wrong, strike the row through and say so; do not delete it.
- Before filing: drop every row still marked "not yet reproduced" unless the form makes clear it is a docs observation, and attach a link (file and tag, or page URL) to each remaining row.

## Observed before building

| # | Date | Area | What we hit | Why it matters | Suggested fix | Status |
|---|---|---|---|---|---|---|
| F01 | 2026-10-13 | Offline sync: versions | The module README on `main` documents 0.0.11, which needs a Serverpod 4.1 beta. There is no compatibility table for people on stable Serverpod. | A stable 4.0.x user who follows the README, or runs `pub add` without a version, gets a release that does not match their Serverpod. The working docs are only at the `0.0.10` tag, which nothing points to. | A compatibility table at the top of the README (module version, Serverpod version, link to the docs at that tag), and a note on pub.dev. | observed in docs, not yet reproduced |
| F02 | 2026-10-13 | Offline sync: platforms | No statement of Android or iOS support, and the example app has no `android` folder. | Offline sync matters most on phones. Without a statement, a team cannot tell whether mobile is supported, untested or known broken before committing to it. | A platform support table (Android, iOS, web, macOS, Windows, Linux: supported / untested / not supported) and an Android target in the example app. | observed in docs, not yet reproduced |
| F03 | 2026-10-13 | Offline sync: client API | No sync-status or connectivity API, and no auto-reconnect. | Every app must write its own supervisor (restart on connectivity change and on resume, backoff) and its own status indicator, and cannot honestly show "up to date" without guessing. | A status stream on the client (connecting, live, backoff, last merge time, unsent changes) and built-in reconnect with backoff, or a documented recipe. | observed in docs, not yet reproduced |
| F04 | 2026-10-13 | Offline sync: conflicts | The loser of a unique-index conflict can be detected only by string-matching a `__conflict__` suffix in the column value. | The conflict is the most interesting thing the engine does, and apps can reach it only by parsing an undocumented string format that could change between versions. | A typed flag on the row or a typed conflict event (table, column, winner id, loser id), and a documented, stable suffix format in the meantime. | observed in docs, not yet reproduced |
| F05 | 2026-10-13 | Offline sync: server | The server is not notified when a client's changes merge. | Server-side reactions to synced data (live views, notifications, derived rows) need a second channel: a streaming endpoint or a syncing client. | A server-side hook or stream fired after a merge commits, carrying the space, the user and the changed tables. | observed in docs, not yet reproduced |
| F06 | 2026-10-13 | Offline sync: docs | The README's server snippet, which calls `session.db.transactionForUser`, does not compile. | It is the first thing a reader copies for server-side writes into synced tables. A broken snippet leaves no documented way to do it. | Fix the snippet and compile the README's code in CI. Show the accessor that works, and how to exercise it in the generated test tools. | observed in docs, not yet reproduced |
| F07 | 2026-10-13 | Offline sync: spaces | Reads span every space the user belongs to, and `spaceId` comes back null on rows. | An app with more than one shared space cannot tell which space a row belongs to, so it has to add and maintain its own column (ours is `circleId`) on every synced table. | Return `spaceId` on read, and allow a query to be scoped to one space. | observed in docs, not yet reproduced |
| F08 | 2026-10-13 | Offline sync: access | Read-only members read everything in the space, and revoking a member leaves the rows already on their device. | Apps holding personal data must tell users plainly that removal does not recall data. There is no narrower read scope to offer. | Document both behaviours prominently. Consider wiping a space's rows from the local replica when access is revoked, or an event the app can act on. | observed in docs, not yet reproduced |
| F09 | 2026-10-13 | Offline sync: client API | No hook to defer applying a merge. | Some screens must not change under the user (in our case, a child mid-sentence on a picture board). The app has to render from its own held snapshot and reconcile by hand. | An option to pause and resume applying incoming changes, or a pending-changes stream the app applies when it chooses. | observed in docs, not yet reproduced |
| F10 | 2026-10-13 | Offline sync: web setup | `sqlite3.wasm` and `db_worker.js` for web are a manual step, and the files must match the versions in `pubspec.lock`. | Without the first file the database cannot open in a browser. Getting the versions right is manual and easy to get wrong after any dependency change. | A CLI command or build step that fetches the matching files, or a check at start-up that names the expected version. | observed in docs, not yet reproduced |
| F11 | 2026-10-13 | Serverpod Cloud: plans | The Starter plan disables future calls. This is shown on the pricing page but not in the docs. | An app that relies on scheduled jobs deploys cleanly on Starter and then its jobs never run. A reader of the future-calls docs is not warned. | A note in the future-calls docs and the Cloud deploy docs, and a warning from `serverpod cloud` when the project registers future calls on a plan without them. | observed in docs, not yet reproduced |
| F12 | 2026-10-13 | Offline sync: examples | No worked example of a shared space with several users. The example app shows only a personal space. | Shared spaces are the reason to choose the module for collaborative apps. The pattern has to be pieced together from `docs/shared-spaces.md` and the module's tests. | An example with two or three users in one shared space, including a read-only member and a unique-index conflict. | observed in docs, not yet reproduced |

## Found while building

Add rows here as spikes S1 to S7 and the phases run. Continue the numbering from F13.

| # | Date | Area | What we hit | Why it matters | Suggested fix | Status |
|---|---|---|---|---|---|---|
| | | | | | | |
