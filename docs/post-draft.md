<!--
Draft for the "Best Hackathon Post" side prize. Three versions follow: a long
one for a blog or dev.to, a short one for LinkedIn, and one for X. Delete this
comment before publishing.

TODO(owner): tag Serverpod's own account on each platform when posting.

Status of every statement: 13 Oct 2026, evening UTC. Facts come from
docs/device-log.md, docs/spike-results.md and the tests in chorus_server/test/.

[Square brackets] mark a sentence that depends on something not yet checked on
a device. After the device check, remove the brackets or delete the sentence.

These sentences say "not yet" and go stale after the device check:
- Long version, "Two claims on one cell": "I have not yet run the two-device
  collision by hand; docs/device-log.md lists what I have checked on
  hardware." Keep either this sentence or the bracketed one after it, never
  both.
- Long version, "Nothing moves under a finger": "These are rule and widget
  tests. I have not yet watched a new word wait on the child's screen of a
  real device."
- Short version: "I have not yet run the collision on two physical devices.",
  and the opening words "In the app's tests" of the snapshot sentence.
- X version: "Not yet confirmed on two devices." Delete it once the
  collision has a device-log row with two accounts.

In the text, TODO(owner) appears twice, both at the end of the long version.

The code excerpts are copied unchanged, indentation included, from
chorus_server/lib/src/boards/tile.spy.yaml (lines 12 to 18),
chorus_server/test/sync/cell_conflict_test.dart (lines 105 and 106) and
chorus_shared/lib/src/reconcile_snapshot.dart (lines 240 to 246).
-->

# Two offline adults, one cell

## Long version (blog or dev.to)

I built Chorus for "Build Something Real: The Serverpod Hackathon". It is an offline-first talking picture board for a non-speaking child, written in Flutter on Serverpod 4.0.4 and the experimental `serverpod_offline_sync` module, 0.0.10. The child taps words on a grid and the device speaks them. Adults around her edit the board from their own devices.

The child is a persona. No child, family or clinician has used Chorus, and I make no clinical claims. Mature tools in this space already offer offline boards with cloud sync; the README names two. I have not found a tool that shows what happens when two adults change the same board offline.

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

I have not yet run the two-device collision by hand; `docs/device-log.md` lists what I have checked on hardware. [I have now run it on a phone and a browser, and the losing word showed under "Needs a home" on both.]

### From a suffix to a tray

The engine reports the collision only by rewriting the key; I found no event for it in 0.0.10. So after every merge the app re-reads the tiles and parses each key as placed, contested, tray or unknown. The editor lists contested words under "Needs a home" (`trayOf` in `tray.dart`), says whose word got the spot first, and lets an adult give it a free spot or remove it. Nobody sees an error, and the word that won does not move.

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

These are rule and widget tests. I have not yet watched a new word wait on the child's screen of a real device.

One merge I had not planned for: when the word holding a contested cell is removed, the engine gives the freed cell to the waiting word by itself. To the child that is a cell changing meaning, so the snapshot holds it for an adult.

One limit: two adults editing the same label offline is last-writer-wins by field. [A "Replaced changes" panel in the editor shows the overwritten value and can restore it.]

### What I would tell the next person

Three behaviours surprised me. Each is a passing test in `chorus_server/test/sync/`.

1. A tile for a shared board written outside `transactionForUser` vanishes without an error. Its key becomes `<cell>__hidden__<id>` and ordinary reads leave it out, even on the author's device. Send every write through one function.
2. A member made read-only while holding an unsynced write gets no error. `syncOnce` completes, the server never takes the row, and it stays on the author's device looking saved.
3. On the SQLite replica, a cell already taken on that device throws `DatabaseUniqueViolationException`; the app catches it and uses the tray. A duplicate primary key throws the base `DatabaseQueryException`, so an idempotent insert must catch both.

### Links

- Web app, on Serverpod Cloud: https://chorus.serverpod.space
- Source, MIT: https://github.com/OoJae/chorus
- Demo video: TODO(owner): link

The starter board is adapted from the 36-word Universal Core vocabulary, Center for Literacy and Disability Studies, UNC-Chapel Hill, CC BY-SA 4.0. I built Chorus with Claude Code. TODO(owner): say in one sentence what you did by hand.

## Short version (LinkedIn)

Two offline adults, one cell.

For "Build Something Real: The Serverpod Hackathon" I built Chorus, an offline-first talking picture board for a non-speaking child, in Flutter. On a board like this a word is found by where it is, so one tile per cell is a real rule. In Serverpod it is one string column, unique per sync space.

Two adults, both offline, fill the same empty cell. In my tests against real Postgres and SQLite replicas, the offline sync module keeps both rows. The earlier write keeps the cell. The later row's key gets a `__conflict__` suffix, and the app lists that word under "Needs a home" instead of showing an error. In the app's tests the child's screen holds a snapshot and swaps only at a safe moment, so nothing moves under a finger.

Plainly: the child is a persona, no family or clinician has used it, and mature tools exist in this space. I have not yet run the collision on two physical devices. Built with Claude Code.

Code: https://github.com/OoJae/chorus
Try it: https://chorus.serverpod.space

#Serverpod #Flutter #Dart

## X version (278 characters with the link counted as 23)

For "Build Something Real: The Serverpod Hackathon" I built Chorus, a talking picture board for a non-speaking child. In my tests, when two adults fill the same empty cell offline, both words survive. Not yet confirmed on two devices. https://github.com/OoJae/chorus #Serverpod #Flutter
