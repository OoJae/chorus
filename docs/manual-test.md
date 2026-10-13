# Manual tests

Three things live here: the deployed smoke test and its results, the checklist to finish before submitting, and a two-minute script a judge can follow.

Placeholders to fill once the build is deployed:

- Web app: `TODO: hosted web app URL`
- APK: `TODO: public APK link (GitHub Release)`
- Demo parent: `TODO: email` / Demo therapist: `TODO: email` / Demo partner: `TODO: email`
- How a demo account signs in: `TODO: describe (emailed code, fixed code or password) once sign-in is built`

## 1. Deployed smoke test

Run after every deploy, and every morning until judging ends on 20 October 2026, 17:00 CEST. Run it against the deployed build, never a local server. Log every run below, including failures.

1. **Parent adds a word.** In a clean browser profile, open the web app, sign in as the demo parent and add a word to an empty cell.
   Pass: the word appears on the board and the status chip reads as up to date.
2. **Therapist receives it on the phone.** Uninstall Chorus from the phone, download the APK from its public link, install it and sign in as the demo therapist.
   Pass: the parent's word appears within 20 seconds. Then add a word back from the phone.
3. **Partner sees both and cannot edit.** In a second browser profile, sign in as the demo partner.
   Pass: both new words are visible, and no way to add, change or remove a word is offered or works.
4. **A new person can register.** Register with a fresh email address.
   Pass: the emailed code arrives and signs the person in.

After the run, remove the two test words (or use a fresh demo circle) so the next person finds a clean board.

### Results

One row per run. Result is `pass`, or `fail` plus what was seen. "Seconds" is the stopwatch time for the word to appear in step 2.

| Date | Time (UTC) | Build (tag or commit) | 1 Parent adds | 2 APK receives (seconds) | 3 Partner read-only | 4 Emailed code | Run by | Notes |
|---|---|---|---|---|---|---|---|---|
| | | | | | | | | |

## 2. Before submitting

Tick each line against the deployed build. A line that cannot be ticked removes its sentence from the video and the description.

**The beats, on the physical phone, with a stopwatch**

- [ ] Beat 1, first run: the phone speaks a sentence; airplane mode on; it still speaks. Time to first word: `TODO` s
- [ ] Beat 1, second run. Time to first word: `TODO` s
- [ ] Beat 2, first run: a word added on another device shows "1 word waiting", lands at a safe moment and is spoken. Time from add to waiting: `TODO` s
- [ ] Beat 2, second run. Time: `TODO` s
- [ ] Beat 3, first run: two adults offline fill the same empty cell; after reconnect one word holds the cell, the other is under "Needs a home", and no existing button moved. Time from reconnect to tray: `TODO` s
- [ ] Beat 3, second run. Time: `TODO` s
- [ ] Cold start in airplane mode: with airplane mode on, force-stop the app, open it, tap a word, hear it.

Notes for running the beats:

- The phone must reach the server by the Cloud URL (or a LAN address), never through a USB tunnel: airplane mode does not cut a USB tunnel, so the test would pass without proving anything.
- Use OS airplane mode. If a device's airplane mode does not cut the connection, use the in-app "Work offline" switch only if it exists in the build, and say on screen that it is being used.

**Claims**

- [ ] `docs/claims.md`: every sentence in the video and the description has a row, and every row reads `verified on <date>` against the running app.
- [ ] Every bracketed sentence in `docs/DESCRIPTION.md` is either verified and unbracketed, or deleted.
- [ ] The limits list appears in the description and the README.

**Video**

- [ ] Public when signed out (checked in a private window).
- [ ] Under 2:00.
- [ ] The persona caption is over the first 7 seconds and again on the end card.
- [ ] No cut inside a take; a clock is visible on every surface.
- [ ] No music, no logos, no product names other than Serverpod and Chorus, no real child.

**Repo and access**

- [ ] The repo is public, or shared with viktor@serverpod.dev, alexander@serverpod.dev and isak@serverpod.dev.
- [ ] The APK link works when signed out, and the installed APK reaches the Cloud server.
- [ ] The web app link and the three demo accounts work from a clean browser profile.
- [ ] "Start a fresh demo circle" gives a clean board.
- [ ] The smoke test passed today and is logged above.
- [ ] The submitted build is tagged `submission-v1` (or the later tag that was actually deployed).

## 3. Two-minute script for judges

You need two people's worth of devices. Either:

- **Two browser profiles** (for example a normal window and a second profile or another browser; two tabs in one profile share a sign-in and will not work as two adults), or
- **One browser plus the Android APK.**

Going offline:

- In a browser: open developer tools, Network tab, set throttling to "Offline". Or turn off the computer's Wi-Fi if both profiles are on it.
- On the phone: airplane mode.

Steps:

1. **Sign in twice.** Device A: sign in as the demo parent. Device B: sign in as the demo therapist. For a board nobody else has touched, choose "Start a fresh demo circle" on A first. `TODO: how the second person joins a fresh circle, once built.`
2. **Add a word.** On A, open the editor, tap an empty cell and add a word. Watch it appear on B. In talker mode it first shows "1 word waiting" and lands when the board is idle.
3. **Go offline in both.** Take A and B offline. The status chip on each should say it is offline and that changes are saved on the device.
4. **Fill the same empty cell.** On A, add "park" to an empty cell. On B, add "swing" to that same cell. Each device shows its own word in the cell.
5. **Reconnect.** Bring both back online. If the chip does not return to up to date within about 20 seconds, press "Sync now".
6. **See "Needs a home".** On both devices one word holds the cell and the other is listed under "Needs a home". No other tile has moved. Tap the waiting word and then an empty cell to give it a home.

What you should not see: either word disappearing, or any tile that was on the board before step 4 in a different cell afterwards.

If something does not match this script, that is a bug we want to hear about: `TODO: contact or issue link`.
