<!--
Draft for the "Best Hackathon Post" side prize. Three versions follow: a long
one for a blog or dev.to, a short one for LinkedIn, and one for X. Delete this
comment before publishing. When posting, tag Serverpod's own account on each
platform.

Status of every statement: 14 Oct 2026, 16:20 UTC. Facts come from
docs/device-log.md, docs/spike-results.md and the tests in chorus_server/test/.
A behaviour is called "checked by hand" only where the device log has a row
for it. Every check so far used one account on both devices; two different
accounts on two devices are not yet in the log.

These sentences go stale if the log changes:
- Long version, "Two claims on one cell": "Every run so far used one account
  on both devices." Delete it once the device log has the collision with two
  accounts.
- Short version: "(one account on both)". Delete it at the same time.

In the text, TODO(owner) appears twice, both at the end of the long version.

The code excerpts are copied unchanged, indentation included, from
chorus_server/lib/src/boards/tile.spy.yaml (lines 12 to 18),
chorus_server/test/sync/cell_conflict_test.dart (lines 105 and 106) and
chorus_shared/lib/src/reconcile_snapshot.dart (lines 254 to 260).
-->

# Two offline adults, one cell

## Long version (blog or dev.to)

I built Chorus for "Build Something Real: The Serverpod Hackathon". It is an offline-first talking picture board for a non-speaking child, written in Flutter on Serverpod 4.0.4 and the experimental `serverpod_offline_sync` module, 0.0.10. The child taps words on a grid and the device speaks them. Adults around her edit the board from their own devices.

The child is a persona. No child, family or clinician has used Chorus, and I make no clinical claims. Mature AAC apps exist, among them CoughDrop, AsTeRICS Grid, Proloquo2Go and TD Snap. I have not found one that shows what happens when two adults change the same board offline, or that lets you try it on one device.

### Position is meaning

The premise: a word on a picture board is found by where it is, like a key on a keyboard. A tile that moves is a word to find again, so "one tile per cell" is a real rule.

In Serverpod the rule is one string column, unique per sync space (`tile.spy.yaml`):

```yaml
  ### The only place a tile's position lives. Three forms:
  ### `<boardId>:<row>:<col>` (on the board), `tray:<tileId>` (unplaced or
  ### archived, written by the app), and `<boardId>:<row>:<col>__conflict__<id>`
  ### (written only by the sync engine to the loser of an offline collision).
  ### The unique index is what turns two offline claims on one cell into a
  ### visible "needs a home" item instead of a silent overwrite.
  cellKey: String, unique(per=spaceId)
```

### Two claims on one cell

A guardian and a teacher are both offline. Each puts a different word in the same empty cell.

When they sync, the engine keeps both rows. The earlier write keeps the cell, whichever device syncs first. The later row's key gets a `__conflict__` suffix and its own row id. My test uses real Postgres and SQLite replica files and checks the server and both replicas. In `cell_conflict_test.dart`, `keys` maps tile id to `cellKey` and `contested` is the suffixed key:

```dart
          expect(keys[c.earlier.id!.uuid], c.cell, reason: where);
          expect(keys[c.later.id!.uuid], contested, reason: where);
```

I have also run it by hand on Serverpod Cloud, with an Android phone and a desktop browser, both with the app's "Work offline" switch on. One word kept the cell and the other showed under "Needs a home" on both. Every run so far used one account on both devices. `docs/device-log.md` lists what I have checked on hardware.

### From a suffix to a tray

The engine reports the collision only by rewriting the key; I found no event for it in 0.0.10. So after every merge the app re-reads the tiles and parses each key as placed, contested, tray or unknown. The editor lists contested words under "Needs a home" (`trayOf` in `tray.dart`), with both words, both adults and both times, and lets an adult give the waiting word a new spot or put it away. Nobody sees an error, and the word that won does not move.

### Nothing moves under a finger

The child's screen renders from a held snapshot, not from the replica. `reconcileSnapshot` compares the two and splits the difference. A new word in an empty cell, a change to a tile in place, and a removal that leaves a gap apply by themselves. A different tile in an occupied cell, or a visible tile in another cell, waits for an adult. Even the automatic ones wait for this (`reconcile_snapshot.dart`):

```dart
bool isSafePoint(
  TalkerActivity activity, {
  Duration quiet = const Duration(seconds: 2),
}) =>
    activity.stripEmpty &&
    !activity.speaking &&
    activity.sinceLastTouch >= quiet;
```

On the phone I watched it happen: with two words in the sentence strip, a word added in the browser showed as "1 waiting" and did not land. When the strip was cleared, it appeared in its cell within a few seconds, and nothing else moved.

One merge I had not planned for: when the word holding a contested cell is removed, the engine gives the freed cell to the waiting word by itself. To the child that is a cell changing meaning, so the snapshot holds it for an adult.

One limit: two adults editing the same label offline is last-writer-wins by field. A "Replaced changes" panel in the editor shows the overwritten value and can restore it; it has automated tests, but I have not checked it on a device.

### Trying it on one device

Judges have one device, so "Try a clash" stages the collision for them. The server joins the circle's sync space as a practice partner: `spaces.grant` gives a stable id, derived from the circle, the read-write role, and the server writes the partner's word through `transactionForUser`, exactly as another adult's device would. The judge's device works offline, puts its own word in the same cell, and reconnects. I checked it on Serverpod Cloud in a browser: the partner's word was on the server in about four seconds, and both words were safe on reconnect.

### What I would tell the next person

Three behaviours surprised me. Each is a passing test in `chorus_server/test/sync/`.

1. A tile for a shared board written outside `transactionForUser` vanishes without an error. Its key becomes `<cell>__hidden__<id>` and ordinary reads leave it out, even on the author's device. Send every write through one function.
2. A member made read-only while holding an unsynced write gets no error. `syncOnce` completes, the server never takes the row, and it stays on the author's device looking saved.
3. On the SQLite replica, a cell already taken on that device throws `DatabaseUniqueViolationException`; the app catches it and uses the tray. A duplicate primary key throws the base `DatabaseQueryException`, so an idempotent insert must catch both.

The first two, and four more gaps, are written up as draft issues for the Serverpod team in `docs/upstream-issues.md`, most with a test that reproduces them.

### Links

- Chorus on Serverpod Cloud: https://chorus.serverpod.space (the web app is at https://chorus.serverpod.space/app/)
- Source, MIT: https://github.com/OoJae/chorus
- Demo video: TODO(owner): link

The starter board is adapted from the 36-word Universal Core vocabulary, Center for Literacy and Disability Studies, UNC-Chapel Hill, CC BY-SA 4.0. I built Chorus with Claude Code. TODO(owner): say in one sentence what you did by hand.

## Short version (LinkedIn)

Two offline adults, one cell.

For "Build Something Real: The Serverpod Hackathon" I built Chorus, an offline-first talking picture board for a non-speaking child, in Flutter. On a board like this a word is found by where it is, so one tile per cell is a real rule. In Serverpod it is one string column, unique per sync space.

Two adults, both offline, fill the same empty cell. The offline sync module keeps both rows. The earlier write keeps the cell. The later row's key gets a `__conflict__` suffix, and the app lists that word under "Needs a home" instead of showing an error. The child's screen holds a snapshot and swaps only at a safe moment, so nothing moves under a finger. My tests run against real Postgres and SQLite replicas, and I have checked both behaviours by hand on a phone and a browser on Serverpod Cloud (one account on both). "Try a clash" lets you see it on one device.

Plainly: the child is a persona, no family or clinician has used it, and mature tools exist in this space. Built with Claude Code.

Code: https://github.com/OoJae/chorus
Try it: https://chorus.serverpod.space

#Serverpod #Flutter #Dart

## X version (273 characters with the link counted as 23)

For "Build Something Real: The Serverpod Hackathon" I built Chorus, a talking picture board for a non-speaking child. When two adults fill the same empty cell offline, both words survive. Checked by hand on a phone and a browser. https://github.com/OoJae/chorus #Serverpod #Flutter
