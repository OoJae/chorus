<!--
Submission description: the text pasted into the hackathon form.
Target 380 to 450 words, counted without this comment. It is near the top of
that range now, so adding a sentence means removing one.
Written against the code and docs/device-log.md as they stood on the evening
of 13 October 2026 (UTC).

[Square brackets] mark a sentence that depends on something not yet checked on
a real device. After the device check, for each bracketed sentence: remove the
brackets if it passed on the deployed build and has a line in
docs/device-log.md, otherwise delete the whole sentence.

Sentences outside brackets rest on docs/device-log.md, or on the automated
tests they name. Do not strengthen them without a new log entry. The sentence
in "What is real" that begins "Not yet checked on devices" is today's truth:
shorten it as items pass, and delete it when none are left.

TODO(owner) marks what only you can supply:
- the video link;
- how judges get the demo account password (the accounts exist only once the
  server password "demoPassword" is set; delete the sentence if it is not);
- your own wording of the AI disclosure. Keep the Claude API sentence for as
  long as the suggestion code is in the repo. Once check 13e in
  docs/claims.md passes, change "would call ... once" to "calls ... when";
- the Cloud plan name, in the Serverpod Cloud line;
- publish the GitHub release with the APK, or delete the APK item; commit and
  push docs/TRY-IT.md so the script link resolves.

If a bracketed sentence is deleted, the room it frees can go to a sentence on
craft in "The flow", for example: "A property test checks that an occupied
cell never changes meaning; N automated tests in all." Recount N from the
README test table first.

Left out for length, and stated in the README and in the app: every member of
a circle can read the whole board.

Before pasting: no "[" and no "TODO" may be left. Delete this comment.
-->

# Chorus

Chorus is an offline-first talking picture board for a non-speaking child, built on Serverpod 4.0.4 and its offline sync module. The child taps words and the device speaks them; adults add words from their own devices. The premise: words on a picture board are found by position. No button the child already uses ever changes place. When two adults fill the same empty cell offline, both words survive.

**Who it is for.** Children who talk by tapping words, their families and therapists. The child shown is a persona: no child, parent or clinician has used Chorus. No clinical claims.

**What exists.** CoughDrop and AsTeRICS Grid already offer offline boards with cloud sync. We have not found a tool that shows what happens when two adults change the same board offline.

**The flow.** The child sees a full "Home" board (36-word Universal Core vocabulary, Center for Literacy and Disability Studies, UNC-Chapel Hill, CC BY-SA 4.0) and an empty "My words" board. The editor adds words and cannot move one. [A new word waits, then lands between sentences.]

**What is real.** Checked on hardware (13 October 2026, Serverpod Cloud): emailed-code sign-up, the demo board, speech in a browser, browser-to-Android sync, the talker on a physical phone, adding words online and with the app's "Work offline" switch on. The same-cell outcome passes automated tests on Serverpod's embedded PostgreSQL and SQLite replicas, in three orderings. Not yet checked on devices: joining by invitation code, uploading offline words, the same-cell collision, live arrival on another device, airplane mode.

**Serverpod at work.**

- Offline sync module: SQLite replica per device, shared space per child. [Read-only partners.]
- Unique index per space: a word's place is one string. The earlier claim keeps the cell, even if it syncs last; the other waits under "Needs a home".
- Field-level merge: updates name their columns, so edits to different properties both survive (sync test T3).
- Auth: emailed-code sign-up.
- Endpoints: circles. [Invitation codes.]
- Web server: the Flutter web app. [A route serves a printable copy.]
- [Streaming endpoint: an adult's tap glows on the child's board.]
- [File storage: private family photos and recorded voices.]
- Serverpod Cloud (TODO(owner): plan name): server, database, web app, email.

**Limits.** The sync module is experimental, pinned to 0.0.10. Two adults editing one label offline is last-writer-wins by field. [A "Replaced changes" list restores the overwritten value.]

**Try it.** Web: https://chorus.serverpod.space. APK: TODO(owner): publish the release, then https://github.com/OoJae/chorus/releases/latest. Source: https://github.com/OoJae/chorus. Script: https://github.com/OoJae/chorus/blob/main/docs/TRY-IT.md. Video: TODO(owner): link. [Demo accounts: `demo.parent@chorus.example`, `demo.therapist@chorus.example`; TODO(owner): password delivery.]

**AI disclosure.** TODO(owner): confirm. Built with Claude Code (Anthropic), which wrote most of the code, tests and documents under the author's direction. The optional photo-to-word suggestion would call Anthropic's Claude API once the server has a key.
