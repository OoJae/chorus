<!--
Submission description. Target about 400 words including bracketed sentences.
[Square brackets] mark a sentence that depends on a feature beyond Phase 1.
Before submitting: for each bracketed sentence, either the feature is deployed
and its row in docs/claims.md is verified (remove the brackets), or delete the
sentence. Replace every TODO. Delete this comment.
-->

# Chorus

A talking picture board that a non-speaking child's whole circle keeps in step, and that still speaks with no signal.

**Who it is for.** A child who talks by tapping words on a grid, and the adults around her. The child in our video is a persona. No child, parent or clinician has used Chorus, and we make no clinical claims.

**The problem.** Children find words by position, so a button that moves is a word lost. Yet several adults add words from their own devices, often offline. Established apps such as CoughDrop and AsTeRICS Grid already offer offline boards with cloud sync. We have not found a tool that shows what happens when two adults change the same board offline.

**The flow.** The child taps words on a 6×6 core-word board and the phone speaks them, in airplane mode too. An adult adds a word from another device. The child's board shows "1 word waiting" and takes the word only at a safe moment: sentence strip empty, nothing playing, no touch for two seconds. When two adults fill the same empty cell offline, both words survive: one holds the cell, the other waits in a "Needs a home" tray. No button the child already uses ever changes place.

**What is real.** The video shows the deployed build on a physical Android phone and the hosted web app, in uncut takes. Nothing the child says is stored or sent. [Families can record words in their own voices and use their own photos, cached for offline.] [An adult can photograph an object and approve an AI-suggested word.] [An adult can tap a word and it glows on the child's board.] [Boards can be printed as a paper backup and exported in an open board format.]

**Serverpod at work.**

- Offline sync: a SQLite replica on every device, one shared space per child. A unique-per-space index is the one-tile-per-cell rule; the engine's conflict handling keeps both rows.
- Space roles: guardian, therapist and teacher write; a partner only reads.
- Auth: email sign-in.
- Endpoints: the server creates each circle's space.
- Serverpod Cloud: hosts server, database and web app.
- [An append-only edit log makes every overwritten edit recoverable in one tap.]
- [File storage holds photos and voice clips privately, behind signed links.]
- [A streaming endpoint carries the live session.]

**Limits.** The sync module is experimental and pinned to one version. Two adults editing the same label offline is last-writer-wins. Every member of a circle can read the whole board. A removed member keeps what was already downloaded.

**Try it.** Web: TODO link. Android APK: TODO link. Demo accounts: TODO parent, TODO therapist, TODO partner (read-only), or start a fresh demo circle. Two-minute script: `docs/manual-test.md`.

**AI disclosure.** Built with Claude Code. TODO: one sentence, confirmed by the author, on what it was used for.

**Cloud plan.** TODO: Starter or Growth.
