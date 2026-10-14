<!--
Submission description: the text pasted into the hackathon form.
Target 380 to 450 words, counted without this comment. It is about 440 now,
with the TODOs in place, so your AI disclosure wording has little room:
adding a sentence means removing one.

Written against the code and docs/device-log.md as they stood at 16:20 UTC on
14 October 2026. "What is real" names only what the device log records as
checked on Serverpod Cloud; do not strengthen it without a new log entry. If
phone checks of the new features are logged tonight, they may join "What is
real", and "the newest features on the phone" leaves the last sentence.

TODO(owner) marks what only you can supply:
- Video: paste the link to the 1:50 film.
- Demo password: say how judges get it, in the submission text only. Never
  write it in this file or anywhere in the repository. Sign in once as
  demo.parent before submitting, or the demo board does not exist.
- Cloud plan name: in the Serverpod Cloud bullet.
- AI disclosure: your own wording. Keep its facts: the code was written with
  Claude Code under your direction; the optional photo suggestion uses
  Xiaomi MiMo (mimo-v2.6-pro) through its Anthropic-compatible API (the
  server's code can also call Anthropic's API).

Also check: the walkthrough link resolves once docs/TRY-IT.md is on main; if
"Remove from circle" is switched back on, delete that limit.

Before pasting: no TODO left, delete this comment.
-->

# Chorus

Chorus is an offline-first talking picture board for a non-speaking child, built on Serverpod's offline sync module. Adults add words from their own devices. When two adults fill one empty spot offline, both words survive, and no button the child knows ever moves.

**Who it is for.** Children who talk by tapping pictures, and the adults around them. Maya and every adult shown are personas: no child, parent or clinician has used Chorus. It makes no clinical claims.

**What exists.** Mature AAC apps exist: CoughDrop, AsTeRICS Grid, Proloquo2Go, TD Snap and others. We have not found one that shows what happens when two adults change one board offline, or lets one device try it.

**The flow.** The board lives on the device. Another adult's word waits, then lands between sentences. Two words for one spot: one keeps it, the other waits under "Needs a home". "Try a clash" shows this on one device, with a practice partner on the server.

**What is real.** Checked on Serverpod Cloud on 13–14 October, in a browser and on an Android phone (docs/device-log.md): emailed-code sign-up, speech with no network, "Work offline" words syncing later, a new word waiting until the sentence was cleared, the same-spot clash between phone and browser. In the browser: "Try a clash", "What changed" with Undo, "Under the hood", switch scanning with keys and photo ideas. Anything not logged, including the newest features on the phone, two different accounts and the demo sign-ins, is built and tested only.

**Serverpod at work.**

- Offline sync 0.0.10: a SQLite replica per device, a space per child, field-level merge; a unique index per space turns a clash into "Needs a home".
- `spaces.grant` and `transactionForUser` let the practice partner write from the server.
- Emailed-code auth, streaming, file storage, future calls, web routes and passwords.
- Synced tables frozen since the first deploy; 21 server-only tables added.
- Serverpod Cloud (TODO(owner): plan name): server, Postgres, web, email.

**Limits.** The sync module is experimental. If two adults rename one word offline, the later change wins. Removing a member is switched off for now.

**Try it.**

- Landing page: https://chorus.serverpod.space/
- App: https://chorus.serverpod.space/app/ ("Make a board for my child", then "Try a demo board")
- Android APK: https://github.com/OoJae/chorus/releases/latest
- Code: https://github.com/OoJae/chorus
- Walkthrough: https://github.com/OoJae/chorus/blob/main/docs/TRY-IT.md
- Video: TODO(owner): link
- Demo sign-ins: demo.parent@chorus.example (guardian), demo.therapist@chorus.example (therapist), demo.partner@chorus.example (read-only). Password: TODO(owner): how judges get it. Judges share this circle, so others' words may show.

**AI disclosure.** TODO(owner): your wording. The code was written with Claude Code under the author's direction. The optional photo suggestion uses Xiaomi MiMo (mimo-v2.6-pro) through its Anthropic-compatible API. It only suggests to the adult; it never speaks for the child.
