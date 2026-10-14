<!--
Submission description: the text pasted into the hackathon form (about 440
words without this comment). Written against the code and docs/device-log.md
on the evening of 14 October 2026; do not strengthen "What is real" without a
new log entry.

Before pasting: replace <demo password> with the demo password (in the form
only, never in this repository), then delete this comment.
-->

# Chorus

Chorus is an offline-first talking picture board for a non-speaking child, built on Serverpod's offline sync module. Adults add words from their own devices. When two adults fill one empty spot offline, both words survive, and no word the child knows ever moves.

**Who it is for.** Children who talk by tapping pictures, and the adults around them. Maya and every adult shown are personas: no child, parent or clinician has used Chorus. It makes no clinical claims.

**What exists.** Mature AAC apps exist: CoughDrop, AsTeRICS Grid, Proloquo2Go, TD Snap and others. We have not found one that shows what happens when two adults change one board offline, or lets one device try it.

**The flow.** The board lives on the device. Another adult's word waits, then lands between sentences. Two words for one spot: one keeps it, the other waits under "Needs a home". "Try a clash" shows this on one device, with a practice partner on the server.

**What is real.** Checked on Serverpod Cloud on 13–14 October, in a browser and on an Android phone (https://github.com/OoJae/chorus/blob/main/docs/device-log.md): emailed-code sign-up, speech with no network, "Work offline" words syncing later, a new word waiting until the sentence was cleared, the same-spot clash between phone and browser, the word finder's glow reaching the phone, the phone's presence showing in the browser, and the demo parent's sign-in. In the browser: "Try a clash", "What changed" with Undo, "Under the hood", switch scanning with keys and photo ideas. Anything not logged, including most new features on the phone, two different accounts and the other demo sign-ins, is built and tested only.

**Serverpod at work.**

- Offline sync 0.0.10: a SQLite replica per device, a space per child, field-level merge; a unique index per space turns a clash into "Needs a home".
- `spaces.grant` and `transactionForUser` let the practice partner write from the server.
- Emailed-code auth, streaming, file storage, web routes and passwords. Future calls are written, but the Starter plan does not run them.
- The three synced tables have been frozen since the first deploy; everything added since lives in 21 server-only tables.
- Serverpod Cloud (Starter plan): server, Postgres, web, email.

**Limits.** The sync module is experimental. If two adults rename one word offline, the later change wins. Removing a member is switched off for now.

**Try it.**

- Landing page: https://chorus.serverpod.space/
- App: https://chorus.serverpod.space/app/ ("Make a board for my child", then "Try a demo board")
- Android APK: https://github.com/OoJae/chorus/releases/latest
- Code: https://github.com/OoJae/chorus
- Walkthrough: https://github.com/OoJae/chorus/blob/main/docs/TRY-IT.md
- Video (1:35): https://youtu.be/JDv5pPvsrA8
- Demo sign-ins: demo.parent@chorus.example (guardian), demo.therapist@chorus.example (therapist), demo.partner@chorus.example (read-only). Password: <demo password>. Judges share this circle, so others' words may show.
