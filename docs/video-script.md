# Chorus demo film: rules and shot list

The film is a 1:50 motion-designed film with a voice-over. Its words, scene by scene, are in [`voiceover.md`](voiceover.md). It is put together with HyperFrames from real captures of the live app. The HyperFrames composition is made outside this repository and is not committed; only its rules and its shot list are kept here.

This file replaces the earlier plan for three uncut takes with no voice-over. That plan is no longer used.

## Rules the film keeps

1. **Real captures only.** Every app behaviour on screen comes from a capture of the live Cloud build (`https://chorus.serverpod.space/app/`) or the release APK on the phone. Nothing is drawn or mocked up to look like the app. Device frames, pulses between devices, the diagram and the mark are motion design, and look like it.
2. **Cuts are allowed; a shortened wait is labelled.** A shot may be trimmed or cut to the next one. A wait that is shortened inside a shot says so on screen, for example "sped up ×4". A wait is never hidden to make the app look faster.
3. **Only what the device log shows.** A shot goes in only if [`device-log.md`](device-log.md) has a row for that behaviour on the deployed build. A narration line over a shot that cannot be captured is cut, or the scene is re-recorded without it.
4. **Names.** The narration and the captions name only Chorus and Serverpod. Device frames carry no maker's or store's mark.
5. **Sound.** No music. The only sounds are the voice-over, the phone's own speech, and short tap sounds.
6. **People.** Maya is a persona, and so are the adults. No real child appears. The film makes no clinical claim.
7. **Labels.** A caption that quotes the app quotes its label exactly, as in the code.
8. **Upload text.** It does not say "uncut". It may say that the film is made from real captures of the live app, with shortened waits labelled.

## Shot list

"In the device log" means the behaviour has a row in `device-log.md`. "Not in the device log" means it must be checked and logged on the deployed build before its capture is used, or the line over it is cut.

The phone ran the 13:02 UTC build during the late-afternoon checks. Every capture of a feature added on 14 October that is shown on the phone needs the new APK first.

### Scene 0 · 0:00 to 0:07 · cold open

| Shot | Capture | Status |
|---|---|---|
| The four tiles of the mark fall into place in 3D | Motion design | No capture needed |
| They become Maya's board on the phone | Phone screen capture of the child's board | In the device log (14 October, afternoon: the child's board on the phone) |
| The phone says "I want juice." | Phone capture with its sound: "I", "want" on "Home", then "juice" on "My words", then the speaker button | Speech heard on the phone: in the device log (14 October morning). The exact sentence is a new capture. |

### Scene 1 · 0:07 to 0:20 · who this is for

| Shot | Capture | Status |
|---|---|---|
| The board and its sentence strip | A still or a slow pan of the child's board, from the phone or Edge | In the device log |
| Three adults' devices drift into place around it | Device frames are motion design; any app screen inside them is a capture of the editor or home screen | In the device log (editor and home in Edge) |
| Caption "One board. Many hands." | Motion design | No capture needed |

No line in `voiceover.md` says that Maya is a persona. Add a short caption here, such as "Maya and the adults are personas.", so rule 6 is on screen and not only in this file.

### Scene 2 · 0:20 to 0:38 · no network

| Shot | Capture | Status |
|---|---|---|
| The phone with Wi-Fi off and airplane mode on, status bar in view | Phone capture. The phone is mirrored over a USB cable, because Wi-Fi debugging stops when Wi-Fi is off. No TCP port may be forwarded to the phone while recording. | In the device log (14 October, 08:40 UTC, done by hand) |
| A hand taps "I", "want", "more"; the phone speaks | Phone capture with its sound | In the device log: the participant heard each word with no network |
| Caption "No network. Still speaks." | Motion design | No capture needed |

### Scene 3 · 0:38 to 0:58 · a word waits for a pause

| Shot | Capture | Status |
|---|---|---|
| The web editor adds "juice" | Edge capture of "Add a word" on "My words", then "Add to board" | In the device log (14 October, afternoon) |
| A pulse travels to the phone | Motion design | No capture needed |
| The phone shows "1 waiting" while the strip has words, then the word lands once the strip is cleared | Phone capture of the child's board on "My words" | In the device log (14 October, afternoon: "juice" landed within 3.5 s of clearing the strip). Label any shortened wait. |
| Caption "New words wait for a pause." | Motion design | No capture needed |

### Scene 4 · 0:58 to 1:16 · the same empty spot

| Shot | Capture | Status |
|---|---|---|
| Two devices, both with "Work offline" on, put different words in one empty cell | Phone and Edge captures, with the switch in view | In the device log (four runs on 13 and 14 October) |
| They reconnect; one word holds the cell, the other shows under "Needs a home" on both | Phone and Edge captures | In the device log. Label the wait if it is shortened. |
| Caption "Both words survive." | Motion design | No capture needed |

The narration names Mum and Ms Lee. Every logged run used one account on both devices, so the tray reads "Parent". Either capture this scene with two accounts (which is not yet in the device log) or keep the names out of any caption and make sure no capture shows a name that contradicts the narration.

### Scene 5 · 1:16 to 1:36 · what the circle gets

The narration of this scene is still a draft in `voiceover.md`. Each line stays only if its shot is in the device log.

| Shot | Capture | Status |
|---|---|---|
| "Try a clash" on one device | Edge capture of the guide's three steps and the tray card | In the device log (14 October, late afternoon) |
| "What changed" with Undo | Edge capture of the feed and one Undo | In the device log |
| The word finder | Edge capture of "Find a word" giving the board, row, column and the small map | In the device log |
| The found word glowing on Maya's board on another device | Edge and phone captures | Not in the device log. Until it is, cut "make it glow on Maya's board" or show the finder only. |
| "This week" with modelled and said | Edge capture | In the device log |
| Switch scanning | Edge capture, driven by the Space and Enter keys | In the device log (in Edge with the keyboard; not on the phone) |
| The second-language switch | Edge capture of the child's board with the "Yoruba" switch flipping labels | In the device log for the labels. Speech in Yoruba is not, so this shot carries no Yoruba speech. |
| Quick cuts of the rest | Edge captures of: hide and "Show everything", quick phrases, word endings, the keyboard, a ready-made board ("Feelings"), picture scenes, photo ideas, a named copy ("Save a copy" and "Copies"), the progress report, "Under the hood" | Each in the device log (14 October, late afternoon) |

The draft gives modelled and said to Ms Lee. If Ms Lee is the teacher, the server refuses her "This week" (only guardians and therapists see it), so give that line to Maya's therapist, or capture it signed in as the guardian or therapist.

Not to be shown, because they are not in the device log: the presence line, the Thursday nudge, the circle voice, keyguard mode and its template, sharing a sentence and "Recent", the sitter link reporting back, removing a member (being switched off for the deadline), "Listen", "Put back" from a copy, and touch settings in use.

### Scene 6 · 1:36 to 1:44 · built on Serverpod

| Shot | Capture | Status |
|---|---|---|
| A diagram draws itself: each device's own copy of the board, the sync module, the database on Serverpod Cloud, live updates and scheduled jobs | Motion design | No capture needed. Each box matches the code: the offline sync module 0.0.10, PostgreSQL on Serverpod Cloud, the streaming endpoint, and future calls (`chorus_server/lib/src/jobs/`). |
| Optional: "Under the hood" | Edge capture | In the device log |

The narration of this scene says "Postgres", which breaks rule 4 as written. Say "the database on Serverpod Cloud" instead, or narrow rule 4 to "no other product is promoted".

### Scene 7 · 1:44 to 1:50 · closing card

| Shot | Capture | Status |
|---|---|---|
| The mark and wordmark, `chorus.serverpod.space`, "Android app and code on GitHub" | Motion design | TODO(owner): the Android release. Until it is published, the card does not mention the Android app. |

"Android" and "GitHub" on the card also break rule 4 as written. The address alone is enough: the landing page links to the Android app and the code.

## Before the film is shared

- Watch it whole against [`claims.md`](claims.md), section "docs/voiceover.md and the film".
- Check each capture against its row in `device-log.md`.
- Check that every shortened wait carries its label, and that no music and no other product name is heard or seen.
- TODO(owner): the video link, in the README, `docs/DESCRIPTION.md` and the submission form.
