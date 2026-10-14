<!--
Judge script. Written against the screens in chorus_ui/lib and
chorus_flutter/lib/screens and against docs/device-log.md, as they stood on
the evening of 13 October 2026 (UTC). Labels were brought up to the code of
the morning of 14 October. Every quoted label is the label in the code; the
sign-up labels are the defaults of serverpod_auth_idp_flutter 4.0.4.

[Square brackets] mark a step or sentence whose result has not yet been seen
on a real device. After the device check: remove the brackets if it passed on
the deployed build and has a line in docs/device-log.md; otherwise delete the
sentence, or leave it bracketed so the judge knows. When no brackets are left,
delete the line under the links that explains them. Update the "Status" line
at the top of parts A, B, C and D as checks pass, and delete it when the whole
part has been checked.

TODO(owner) marks what only you can supply. There are two kinds here: the APK
release, and how judges get the demo account password. The three demo
accounts exist only once the server password "demoPassword" is set. If it is
not set, delete the two bracketed demo-account paragraphs (parts A and B).

Check by hand before publishing, because this file cannot know:
- the APK is attached to the latest GitHub release and reaches the Cloud API;
- GitHub issues are open on the repository (linked at the end);
- part D matches the build that is deployed (it describes wave 3);
- the deployed build has the 14 October changes: its sync chip says "this
  device", not "this phone", and a second tab says "Chorus is open in another
  tab".

Delete this comment before the submission tag.
-->

# Try Chorus

Chorus is a talking picture board for a non-speaking child. The child taps words and the device speaks them. Adults add words from their own devices, and Serverpod's offline sync module keeps the copies in step.

Part A needs one desktop browser and takes about three minutes, not counting the wait for the emailed code. Part B is the collision this project is about: two adults fill the same empty cell while offline. It needs a private window (Incognito in Chrome, InPrivate in Edge) or a second browser, and a second email address, and takes about five minutes. Parts C and D are optional.

- Web app: https://chorus.serverpod.space
- Android APK: TODO(owner): attach the APK to a GitHub release. https://github.com/OoJae/chorus/releases/latest shows no release today.
- What was checked on real hardware, and what was not: [`device-log.md`](device-log.md)

Text in [square brackets] describes something we have not yet checked by hand on a real device.

The app shows its sync state in a small chip, in words. When all is well it reads "Up to date". The child in the demo, Maya, is a persona. No child, parent or clinician has used Chorus.

## Part A. One browser

Status on 13 October 2026: steps 1 to 4 were done by hand in a desktop browser (Edge on macOS), and steps 5 to 7 on the Android phone. In the hosted web app, step 5 failed in the first build, and its fix has not been re-checked there.

1. **Open the app.** Go to https://chorus.serverpod.space with the sound on. You see a form titled "Sign In with email". [Above it are the name "Chorus", a line on what it is, and a line on how to start. If the first visit is slow, the loading page says "Loading. The first visit takes a little longer."]

2. **Sign up.** Click "Sign up", type your email address and click "Continue". Type the emailed code on the "Verify account" screen. On "Set account password", choose a password that meets the rules shown, and click "Sign up". You see "Welcome to Chorus".

   [Or use a demo account: on "Sign In with email" type `demo.parent@chorus.example` and the demo password, click "Sign in", and go to step 4. TODO(owner): say here how judges get the demo password. The demo accounts share one board, so other judges' words may be on it. Use any empty cell in place of the ones named below. If "My words" has no empty cell, click a word and choose "Remove from board" first.]

3. **Make a board.** Click "Try a demo board". You see a home screen headed "Maya's board", and the chip at the top right settles on "Up to date". Wait until the "Talker" button is active.

4. **Make it speak.** Click "Talker". This is the child's screen: a board called "Home" with 36 words in a six by six grid, and a second tab, "My words". Click "I", "want", "more". You hear each word, and it joins the sentence at the top. Click the sentence to hear it whole.

5. **Leave the child's screen.** Press and hold "Hold to leave" for two seconds. It is on the right, under the sentence. [A bar fills while you hold, then you are back on the home screen.] If nothing happens, reload the page: you return to the home screen, still signed in. A short click does nothing, so a child does not leave by accident. [With a keyboard: press Tab until "Hold to leave" is marked, hold Enter or Space for two seconds, then let go.]

6. **Open the editor.** Click "Edit board". You see the same grid and, beside it (above it in a narrow window), the line "Tap an empty spot to add a word. Tap a word to change or remove it. Words never move, so Maya always finds them in the same place." There is no way to move a word to another cell.

7. **Add a word.** The "Home" board is full on purpose, so click the "My words" tab. Click the top-left cell, marked with a plus. In the sheet "Add a word", type "mango" under "Word" and click "Add to board". You see "mango" in that cell and the chip at "Up to date". In the column beside the grid (under it in a narrow window), "Needs a home" reads "No words are waiting."

## Part B. Two adults, one board

This part sends a word from one adult to another, then has both put a word in the same empty cell while offline.

Status on 13 October 2026: not yet run by hand on two devices. The invitation rules have endpoint tests. The same-cell result is proven by automated tests against real PostgreSQL and real SQLite replica files: scenario T1 in [`spike-results.md`](spike-results.md).

Use two sign-ins that do not share browser storage: a normal window (A, from part A) and a private window (B; Incognito in Chrome, InPrivate in Edge), or two browsers. Another tab in window A's browser profile cannot be the second adult: those tabs share one copy of the board, so Chorus runs in only one of them at a time. [A second tab says "Chorus is open in another tab" and offers "Use Chorus in this tab".] The second adult needs a second email address; an address with "+" in it is not accepted.

[With demo accounts no second address and no invitation are needed. Sign in as `demo.parent@chorus.example` in window A first, because the parent's device makes the starter board. Then sign in as `demo.therapist@chorus.example` in window B and start at step 3. TODO(owner): the demo password, as in part A.]

1. [**Invite.** In window A, on the home screen, click "Invite someone". Leave "Therapist" selected and click "Make a code". You see an eight-character code. Click "Copy code".]

2. [**Join.** In window B, open the web app and sign up with the second address. On "Welcome to Chorus" click "Join with a code", fill in "Code" and "Your name", and click "Join". You see "Maya's board". Wait until the chip reads "Up to date" and "Edit board" is active. If you see "There is no board here yet", click "Retry".]

3. [**Send a word across.** In both windows click "Edit board", then "My words". Window B already shows "mango". In window A add "juice" in an empty cell of the top row. You see "juice" appear in the same cell in window B within a few seconds, with no reload.]

4. **Go offline in both.** In both windows click the back arrow to the home screen and switch on "Work offline". The chip in each reads "Working offline, saved on this device".

5. **Fill the same empty cell.** In both windows click "Edit board", then "My words", and pick the same empty cell: the bottom-right corner is easy to find. In window A add "park" there. Then in window B add "swing" there. Each window shows its own word in the corner.

6. **Reconnect.** In both windows go back to the home screen and switch "Work offline" off. [The chip in each returns to "Up to date".]

7. [**See both words.** In both windows click "Edit board", then "My words". Both show the same thing. "park" holds the corner, because it was added first. "swing" is listed under "Needs a home (1)" with the line "Added while offline; Parent's word got this spot first" ("Parent" is the name "Try a demo board" gives window A; with the demo sign-ins the line reads "Maya's mum's word got this spot first"). "mango" and "juice" have not moved.]

8. [**Give the waiting word a home.** On the "swing" card click "Place in next free spot". You see the message `"swing" is on the board.` and, in both windows, "No words are waiting."]

What you should not see: either word gone, or any word in a different cell from the one it had before step 5.

[To see the read-only role, invite a third sign-in as "Family or friend who can view". Their home screen offers "View board" in place of "Edit board", and the editor reads "You can view this board. Only the family and therapist can change it."]

## Part C. Android phone

Status on 13 October 2026: a release build was installed and steps 2 and 3 were checked on one phone, a Xiaomi on Android 16. The taps were sent from a computer and nobody listened to the phone during that run; its log showed the speech service starting at each tap. Airplane mode was not checked. The build needs Android 7.0 or later.

1. **Install.** On the phone, open https://github.com/OoJae/chorus/releases/latest, download the APK and install it. Android asks you to allow this: the build is signed with a debug key and does not come from a store. Open Chorus. You see the same sign-in form as in the browser.

2. **Sign in.** Use the email address and password from part A. You see "Maya's board" and the chip at "Up to date". The board was made in the browser and reached the phone's own SQLite database through the sync module.

3. **Make it speak.** Tap "Talker", then "I", "want", "more". You hear each word.

4. [**Airplane mode.** Turn on airplane mode and tap more words. You still hear them: the board and the voice are both on the phone. If a crossed-out speaker icon shows beside "Hold to leave", the phone has no offline English voice installed and stays silent without a network.]

5. [**Add a word with no network.** Still in airplane mode, hold "Hold to leave", tap "Edit board", then "My words", and add a word. You see it at once, and the chip reads "Offline, saved on this device". Turn airplane mode off. The chip returns to "Up to date" and the word appears in the browser.]

The in-app switch is the offline path we have checked on our phone: with "Work offline" on, a word added on "My words" appears on the board and the chip reads "Working offline, saved on this device". [Switch it off and the word reaches the other devices.]

## Part D. Newer features

Status on 13 October 2026: everything here was added that day and has automated tests, but has not yet been tried on a real device.

- [**Family photo and recorded voice.** In "Add a word" or "Change this word", click "Choose a photo" (on a phone, "Take or choose a photo"), and hold "Hold to record" while you say the word, for up to five seconds. The cell shows the photo, and a tap on the word in "Talker" plays the recording.]
- [**Pointing at a word.** In the editor switch on "Show words on the board" and click a word. A blue ring glows round it for about two and a half seconds on every other device that has "Talker" open on that board. Nothing on the board changes.]
- [**Replaced changes.** With "Work offline" on in both windows, click the same word in each, type a different word under "Change this word" and click "Save". Switch "Work offline" off in both. One label stays. The other is listed in the editor under "Replaced changes (1)" with a "Restore" button.]
- [**Paper copy.** On the home screen click "Print a paper copy". A dialog shows a link to a page with the board's words and colours. The page needs no sign-in and stops working after 30 days.]
- [**Suggested word.** In "Add a word", after choosing a photo, click "Suggest a word from the photo". This sends the photo to the server. Clicking a suggested word fills in the form; nothing reaches the board until you click "Add to board". If the server has no API key the sheet reads "No suggestion this time. Type the word instead."]
- [**Share what is said.** A parent or guardian can switch on "Share what is said" on the home screen. While "Talker" is open on that device, each spoken sentence is shown to adults who have "Show words on the board" on, and is stored nowhere. The child's screen shows a bar, "Sharing what is said"; a tap on it turns sharing off.]

## If something looks wrong

Read the chip first.

| The chip reads | It means | What to do |
|---|---|---|
| "Up to date" | The last sync finished without an error. | Nothing. |
| "Sending changes" | A change made here is on its way to the server. | Wait a few seconds. |
| "Connecting" | The device is trying to reach the server. | Wait a few seconds. |
| "Reconnecting" | The last try failed, and the device tries again shortly. | Wait, or click "Sync now". |
| "Offline, saved on this device" | The server cannot be reached. Changes are kept on the device. | Check the network, then click "Sync now". |
| "Working offline, saved on this device" | "Work offline" is on. Sync is paused on purpose. | Switch it off on the home screen. |
| "Check this device's clock" | The device clock is more than 45 seconds from the server's, so sync is held back. | Turn on automatic date and time, then click "Sync now". If words were added or changed while the clock was more than a minute ahead, new changes are refused ("Nothing was changed") for about as long as it was ahead. It recovers by itself; nothing already saved is lost. |
| "Update the app to sync" | This build no longer matches the server. | Reload the page, or install the latest APK. |
| "Signed out, saved on this device" | The sign-in has ended. | Sign out and sign in again. |
| "No longer shared with you" | The server refused this account access to the board. | Tell us, at the link below. |

"Sync now" is inside the chip only while it reads "Reconnecting", "Offline, saved on this device" or "Check this device's clock". Where the chip is an icon only, tap the icon.

- **"Chorus is open in another tab".** Chorus runs in one tab of a browser profile at a time. [Click "Use Chorus in this tab" to move it here, even if the other tab is closed; a tab still open then says "Chorus moved to another tab".] For a second adult, use a private window (Incognito in Chrome, InPrivate in Edge) or another browser.
- **One window was signed out.** Sign in again. In the build checked on 13 October, two tabs of one browser profile signed each other out; two adults need a normal window and a private window, or two browsers.
- **"There is no board here yet."** The invited adult's device is ahead of the one that makes the starter board. Click "Retry", or wait for the board to sync.
- **A change has not arrived and both chips read "Up to date".** [Switch "Work offline" on and off again in the window that is behind. That starts a fresh sync.]
- **"Hold to leave" does not respond in a desktop browser.** Reload the page: you come back to the home screen, still signed in. The hold was checked on the Android phone. The first browser build failed here, and the fix has not been re-checked in a browser.
- **No sound in the browser.** Check that the tab is not muted. Speech uses the voice built into the browser or device; a browser with no speech voice stays silent.
- **The child's screen looks cramped on a small phone.** Its layout was changed on 13 October after problems were seen on the test phone, and has not been re-checked on a device.

If something does not match this script, that is a bug we want to hear about: https://github.com/OoJae/chorus/issues
