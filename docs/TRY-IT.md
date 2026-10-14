<!--
Judge script. Every quoted label was taken from chorus_ui/lib,
chorus_flutter/lib and chorus_server/web/landing as they stood on
14 October 2026 (branch wave6, deployed at 15:25 UTC); the sign-up labels are
the defaults of serverpod_auth_idp_flutter 4.0.4. "Checked" in a status line
means there is a line for it in docs/device-log.md. Anything else described
here is built and has automated tests, and says so where it matters.

Before the submission tag:
- resolve the TODO(owner) markers: the APK release (two places), the film
  link and the demo password in the submission text;
- sign in once as demo.parent@chorus.example, so the demo board exists;
- when phone checks of the new APK are logged in device-log.md, update the
  status lines of parts C and D.
Then delete this comment.
-->

# Try Chorus

Chorus is a talking picture board for a non-speaking child. The child taps words and the device speaks them, even with no signal. The adults around the child change the board from their own devices, and Serverpod's offline sync module keeps every copy in step. When two adults fill the same empty spot while offline, both words are kept: one holds the spot, the other waits under "Needs a home", and no word the child already uses ever moves.

Maya, the child in the demo, is a persona. No child, parent or clinician has used Chorus.

- Landing page: https://chorus.serverpod.space/
- Web app: https://chorus.serverpod.space/app/
- Android APK: https://github.com/OoJae/chorus/releases/latest. TODO(owner): the release is published on the evening of 14 October; until then this page has no APK.
- Film (1:50): TODO(owner): link.
- Demo sign-ins: `demo.parent@chorus.example` (guardian), `demo.therapist@chorus.example` (therapist, can edit), `demo.partner@chorus.example` (read-only partner: views the board and can suggest a word). The password is in our submission text. TODO(owner): put the demo password in the submission text.
- What was checked on real hardware, and what was not: [`device-log.md`](device-log.md)

Part A needs one desktop browser and takes about three minutes, not counting the wait for the emailed code. We have tried it only in Microsoft Edge on macOS. Other browsers, and the web app in a phone's browser, have not been tried. Part B is the collision the project is about, with two adults in two windows. Parts C and D are optional.

The app shows its sync state in words, in a small chip at the top. When all is well it reads "Everyone's up to date". If something looks wrong, see the table at the end.

## Part A. One browser

Status at 16:20 UTC on 14 October 2026: the landing page, the child's board, adding a word, "Try a clash" to the end, the "Needs a home" card, "What changed" with Undo, "Under the hood" and "Who is up to date" were checked in Microsoft Edge on macOS against the deployed build. Sign-up was last checked on 13 October, before the app moved to `/app/`. Placing a waiting word from the tray was last checked on a local server. The demo sign-ins have not yet been tried on Serverpod Cloud.

1. **Open the landing page.** Go to https://chorus.serverpod.space/ with the sound on. Try the small board at the top if you like, then click "Open Chorus". The first visit to the app can take a little while to load.

2. **Sign up, or use a demo sign-in.**
   - *Your own board* (best, as nobody else uses it): click "Make a board for my child". If you see "Sign In with email" instead, click "Sign up". Type your email address (one without "+"; the form answers "Email aliases are not allowed") and click "Continue". If the code has not come after a minute, look in your spam folder. On "Verify account", type the code from the email and click "Verify". On "Set account password", choose a password that meets the rules shown and click "Sign up". On "Who is the board for?", click "Try a demo board".
   - *Demo sign-in*: click "I already have one", type `demo.parent@chorus.example` and the demo password, and click "Sign in". Every judge shares this board, so other judges' words may be on it: use any empty spot in place of the ones named below. Where this script says "Parent", your name on the board is "Maya's mum".

   You see "Maya's board", with the board drawn in 3D, and the chip settles on "Everyone's up to date". Wait until "Open Maya's board" can be clicked.

3. **The child's board speaks.** Click "Open Maya's board". This is the child's screen: the "Home" board, 36 everyday words in a six by six grid, each with a picture, and a second tab, "My words". Click "I", "want", "more". You hear each word, and it joins the sentence at the top. Click "Speak" to hear the sentence, then "Clear". To leave, press and hold "Hold to leave" for two seconds. A short click does nothing, so a child does not leave by accident.

4. **Add a word.** Click "Edit words". You see the same grid and the line "Tap an empty spot to add a word. Tap a word to change or remove it. Words never move, so Maya always finds them in the same place." There is no way to move a word to another spot. "Home" is full on purpose, so click the "My words" tab, then the empty spot at the top left. In "Add a word", type "mango" under "Word" and click "Add to board".

5. **Try a clash.** Still in the editor, open the menu "More for this board" (the three dots at the top right) and choose "Try a clash". A card above the board takes you through three steps:
   - "Try a clash · 1 of 3": "Getting ready. This device is switching to Work offline, like a phone with no signal." The chip reads "Working offline, saved on this device".
   - "Try a clash · 2 of 3", a few seconds later: "The practice partner just put "bubbles" here on their own device. Now put your own word in the glowing spot." The word may differ. The practice partner is a stand-in for a second adult. The server gives it a role in your circle's sync space with `spaces.grant` (it has no account and is not listed among the circle's members) and has written its word into that spot on the server through `transactionForUser`. This device is offline, so the spot still looks empty here. Click the glowing spot, type "kite" and click "Add to board". The chip reads "Working offline, 1 change waiting to send".
   - "Try a clash · 3 of 3": "Your word is saved on this device. Now turn Work offline off." Click "Turn Work offline off". The card reads "Sending your word and bringing in theirs…", then, within seconds (12 in our run): "Both words are safe. "bubbles" got to the spot first, so it keeps it. "kite" waits under Needs a home, on every adult's device. Nothing was lost: choose a new spot for it whenever you like. Tap a practice word to remove it when you are done."

   Click "Done".

6. **Needs a home.** Beside the board (in a narrow window, in a sheet along the bottom that you drag up), "Needs a home · 1" shows the two words side by side: "In the spot", "bubbles", "Practice partner" and the time; "Waiting", "kite", "Parent" and the time. Under them: "Practice partner and Parent both put a word in this spot while offline. Nothing was lost." Click "Place in next free spot". You see `"kite" is on the board.` and "No words are waiting." The other choices are "Choose a new spot" and "Put it away". None of them moves a word that is already in a spot.

7. **What changed, and Undo.** Click the back arrow to the home screen, then "What changed" in the list ("Who added, renamed or put away a word"). Each line says who did what, and when, newest first: for example "Parent added 'kite'". On the line "Parent added 'mango'", click "Undo". You see "Undone. It is written as a new change.", "mango" leaves the board, and a new line at the top reads "Parent put 'mango' away". Click "Undo" on that line: "Parent brought 'mango' back". An undo is a new change, synced like any other. If a word's old spot has been taken in the meantime, it waits under "Needs a home" and nothing else moves.

8. **Under the hood.** Back on the home screen, click "Under the hood". It shows what the copy of the board on this device holds: the rows in the replica ("board", "tile", "tile_edit"), the sync state, "Changes waiting to send", "Last successful sync", the circle's space id, the version of `serverpod_offline_sync` (0.0.10) and the server's address. "Words parked by the sync engine" lists any word that is waiting under "Needs a home", with the cell key the engine gave it. "Who is up to date", in the same list, shows each device that has checked in, such as "This device: up to date".

## Part B. Two adults, one board

This is the collision Chorus is built around: two adults put a word in the same empty spot while both are offline.

Status at 16:20 UTC on 14 October 2026: the same-cell result was checked on Serverpod Cloud between an Android phone and Edge, signed in as the same adult on both (13 and 14 October), and with three demo sign-ins on a local server. Two different accounts, the invitation code and the demo sign-ins have not yet been tried on Cloud. The invitation rules have endpoint tests, and the same-cell rule has automated tests against real PostgreSQL and real SQLite replica files (scenario T1 in [`spike-results.md`](spike-results.md)).

You need two sign-ins that do not share browser storage: a normal window (A, from part A) and a private window (B; Incognito in Chrome, InPrivate in Edge), or two browsers. A second tab in window A's browser cannot be the second adult: tabs of one browser profile share one copy of the board, so Chorus runs in only one of them at a time.

*With your own accounts* you need a second email address. An address with "+" in it is not accepted.

*With one address*, sign in to the same account in window B and start at step 3. Your name in both windows is then "Parent". The Cloud checks used this setup, with a phone and a browser in place of two windows.

1. **Invite.** In window A, on the home screen, click "Invite someone". "Therapist" is already chosen; click "Make a code". You see an eight-character code. Click "Copy code".

2. **Join.** In window B, open https://chorus.serverpod.space/app/ and sign up with the second address, as in part A. On "Who is the board for?", click "Join with a code", fill in "Code" and "Your name", and click "Join". You see "Maya's board". Wait until the chip reads "Everyone's up to date" and "Edit words" can be clicked. If you see "There is no board here yet", click "Retry".

*With the demo sign-ins* no second address or invitation is needed. Sign in as `demo.parent@chorus.example` in window A and as `demo.therapist@chorus.example` in window B, with the demo password, and start at step 3.

3. **Send a word across.** In both windows click "Edit words", then "My words". In window A, add "juice" in an empty spot. Within a few seconds it appears in the same spot in window B, with no reload.

4. **Go offline in both.** In both windows, click the back arrow to the home screen and switch on "Work offline". Each chip reads "Working offline, saved on this device".

5. **Fill the same empty spot.** In both windows click "Edit words", then "My words", and pick the same empty spot: the bottom-right corner is easy to find. On the shared demo board it may be taken: use any spot that is empty in both windows. If "My words" is full, add a board with "+" in step 3, before going offline. Add "park" there in window A first, then "swing" there in window B. Each window shows its own word in the corner.

6. **Reconnect.** In both windows, go back to the home screen and switch "Work offline" off. Each chip returns to "Everyone's up to date".

7. **See both words.** In both windows click "Edit words", then "My words". Both show the same thing. "park" holds the corner, because it was put there first. "swing" waits under "Needs a home · 1", shown beside "park" with the line "Parent and Ms Lee both put a word in this spot while offline. Nothing was lost." (with the name typed in window B for "Ms Lee"). With the demo sign-ins the line reads "Maya's mum and Speech therapist both put a word in this spot while offline. Nothing was lost.", and other judges' words may make the count higher. With one address in both windows it reads "Parent put two words in this spot from two devices while offline. Nothing was lost." "mango" and "juice" have not moved.

8. **Give the waiting word a home.** On the "swing" card click "Place in next free spot". You see `"swing" is on the board.` and, in both windows, "No words are waiting."

What you should not see: either word gone, or any word in a different spot from the one it had before step 5.

To see the view-only role, sign in as `demo.partner@chorus.example`, or invite a third sign-in as "Family or friend who can view". Their home screen offers "View Maya's board" and no "Edit words". This was checked on a local server, not yet on Cloud.

## Part C. The child's board tools

Use the board you made in part A: these steps change the board, and the demo board is shared.

Status at 16:20 UTC on 14 October 2026: hiding a word and "Show everything", word endings, quick phrases, the keyboard, two-switch scanning with a computer keyboard, a second language and scenes were each checked in Microsoft Edge on macOS against the deployed build. The second language was checked with Yoruba words on screen; speech in Yoruba was not checked. For scenes, the photo was given to the page's file input by script, not through the file dialog. None of part C has been tried on a phone yet.

In a wide window, the keys for word endings, quick phrases and the keyboard sit beside the sentence. On a phone, or in a narrow window, they are reached by holding the sentence for half a second instead: built and tested, not yet checked on a phone.

1. **Hide a word for now, then "Show everything".** Click "Edit words", then "different" on "Home". In "Change this word", click "Hide for now". You see `"different" is hidden for now. Its spot stays the same.`, and the word is dimmed in the editor. Go back and click "Open Maya's board": its spot is blank and every other word is where it was. Click "Show everything" (an eye, in the row above the board): the word is back until you leave the board. Afterwards, click the word in the editor and choose "Show on the board again".

2. **Word endings.** On the child's board, click "I", then "go", then the "+s" key beside the sentence. "Word endings" offers "going", "went" and "goes". Click "went": it takes the place of "go" in the sentence.

3. **Quick phrases.** Click the "Quick phrases" key (a megaphone). Six phrases fill the screen: "Stop", "Help", "I'm hurt", "Toilet", "All done", "I need a break". Click "Help": it is spoken and goes into the sentence.

4. **Keyboard.** Click the "Keyboard" key and type "ju", on the screen or on your own keyboard. Predictions such as "jump" and "juice" appear above the letters. Click one, then "Add to sentence". "Speak" says the word without adding it.

5. **Switch scanning.** Leave the board with "Hold to leave". On the home screen, click "This device" ("Touch, switches, voice and keyguard"). Under "Switch access", set "Scanning" to "Two switches". Go back and click "Open Maya's board". Press Space: a thick ring moves down the board a row at a time. Press Enter to choose the row. Space then moves along it a word at a time, and Enter puts the word in the sentence. Nothing on the board moves. Most Bluetooth switches send Space and Enter; we checked with a computer keyboard, not a switch. Set "Scanning" back to "Off" afterwards. It applies to this device only. The same page has "Hold time", "Ignore repeat taps" and "Select on release": built and tested, shown on the page, but not yet tried in use.

6. **A second language.** Click "Edit words", then "more" on "Home". In "Change this word", click "Second language". Choose a language under "Language" (Yoruba is first in the list), type the word in that language under "Word" (for Spanish, "más"), and click "Save". Open Maya's board: a switch with the language's name appears in the row above the board (in a narrow window, a translation icon). Click it, and "more" shows the word in that language, in the same spot, with the same picture. Words with no second-language word stay as they are. Click the switch again to go back. Whether the word is spoken in that language depends on the voices your browser has.

7. **Scenes.** On the home screen, click "Scenes", then "Make a scene from a photo", and pick any photo. Give it a name, such as "Playtime", and click "Save". Drag on the photo to draw a spot round something in it, type its word under "What does this spot say?" and click "Save". Open Maya's board: a "Scenes" button appears in the row above the board (in a narrower window, a photo icon). Click it, choose your scene, and click the spot: it is outlined and its word goes into the sentence. "Back to the board" takes you back.

## Part D. Android phone

Status at 16:20 UTC on 14 October 2026: on one phone (a Xiaomi on Android 16), earlier builds were installed, received a board made in the browser through the sync module, and spoke with no network at all (airplane mode on and Wi-Fi off), also after the app was closed and opened again (13 and 14 October). The APK in the release is a later build and has not yet been checked on a phone.

1. **Install.** On the phone, open https://github.com/OoJae/chorus/releases/latest and download the APK. TODO(owner): until the release is up, this page has no APK; delete this sentence once it is. Android asks you to allow installs from this source: the build is signed with a debug key and does not come from a store. It needs Android 7.0 or later. If Google Play Protect warns about the app, look in its dialog for the choice to install anyway.

2. **Sign in.** Open Chorus and tap "I already have one". Sign in with the email address and password from part A, or with a demo sign-in. No account yet? Tap "Make a board for my child" and sign up as in part A step 2 (sign-up has been checked in a browser, not yet on a phone). You see "Maya's board", and the chip settles on "Everyone's up to date". The board was made in the browser and reached the phone's own SQLite database through the sync module.

3. **Make it speak.** Tap "Open Maya's board", then "I", "want", "more". You hear each word.

4. **No network.** Turn on airplane mode, and turn Wi-Fi off as well if it stays on (on our test phone it did). Tap more words: you still hear them, because the board and the voice are both on the phone (if the phone has an offline voice: see the table at the end). Close Chorus completely and open it again: the board comes up and speaks. Turn the network back on, and the chip returns to "Everyone's up to date" by itself.

5. **Optional: Try a clash.** Tap "Edit words", then the ⋮ menu ("More for this board"), then "Try a clash", as in part A step 5. On a phone, "Needs a home" is a sheet along the bottom that you drag up. Built and tested, not yet checked on a phone.

## More, if you have time

Each of these was checked in Microsoft Edge on the deployed build. The photo was given to the page's file input by script.

- **Find a word.** In the editor, click the magnifier ("Find a word") and type "help". You see "Home board · row 2, column 5" with a small map.
- **A ready-made board.** In the editor's "More for this board", choose "Add a ready-made board", then "Feelings". You see "24 words are on the new board".
- **A named copy.** In the same menu, choose "Save a copy" and name it, such as "Before the school trip". "Copies" lists it.
- **Photo ideas.** In "Add a word", click "Choose a photo" and pick a photo, then click "Suggest a word from the photo". This sends the photo to our server, which asks Xiaomi MiMo's `mimo-v2.6-pro` model to describe it. You get "Ideas for this photo. Tap one to use it:" and up to six words, coloured by word type. Nothing goes on the board until you choose a word, or "Add all to Needs a home". The AI only fills in the adult's form or the tray; it never speaks for the child.

## If something looks wrong

| What you see | What to do |
|---|---|
| "Everyone's up to date" | Nothing: this device has sent everything and its last sync worked. |
| "1 change waiting to send" (or a higher number) | Wait a few seconds: a change made here is on its way. |
| "Connecting" or "Reconnecting" | Wait a few seconds, or click "Sync now" if the chip offers it. |
| "Offline, saved on this device" | The server cannot be reached, and changes are kept on the device. Check the network, then click "Sync now" in the chip. |
| "Working offline, saved on this device" | "Work offline" is on, so sync is paused on purpose ("Try a clash" turns it on). Switch it off on the home screen, or finish or close the guide. |
| "Check this device's clock" | Turn on automatic date and time, then click "Sync now". |
| "Update the app to sync" | This build no longer matches the server. Reload the page, or install the latest APK. |
| "Signed out, saved on this device" | Sign out and sign in again. |
| "No longer shared with you" | The server refused this account access to the board. Tell us at the link below. |
| "Chorus is open in another tab" | Chorus runs in one tab of a browser profile at a time. Click "Use Chorus in this tab". For a second adult, use a private window or another browser. |
| "The practice partner needs a rest. Try again in an hour." | The practice partner adds a limited number of words to each circle per hour (5 in the build checked on 14 October, 30 after the final fixes), and on the shared demo circle every judge's tries count. Wait, sign up with your own email address for a circle of your own, or make the clash yourself with a second window (part B). |
| "Every spot is taken. Remove a word, or add a board with +, then try again." | Do one of those, then choose "Try a clash" again. |
| "The practice partner's word arrived first, because Work offline was turned off before your word went in." | Click "Try again", and add your word before turning "Work offline" off. |
| "This needs a connection for a moment." | Check the connection, then click "Try again". |
| "This board has not reached the others yet. Turn Work offline off for a moment, then try again." | The new board has not reached the server yet. Wait until the chip reads "Everyone's up to date", then click "Try again". |
| "There is no board here yet." | The device that starts the board has not connected yet. Click "Retry", or wait. With the demo sign-ins, one sign-in as `demo.parent@chorus.example` makes the board. |
| The first visit is slow ("Loading. The first visit takes a little longer.") | Wait: the app is downloading. Later visits are quicker. |
| A window signed out by itself | Sign in again. Two tabs of one browser profile share one sign-in and can sign each other out; for two adults, use a normal window and a private window, or two browsers. |
| No sound in the browser | Check that the tab is not muted. Speech uses the voice built into the browser; a browser with no speech voice stays silent. |
| A crossed-out speaker in the row above the child's board ("No offline voice on this device") | The device has no voice that works offline, so it stays silent without a network. |

"Sync now" is in the chip only while it reads "Reconnecting", "Offline, saved on this device" (or "Offline" with a number of changes waiting) or "Check this device's clock". Where the chip is an icon only, as on the child's board, tap the icon.

If something does not match this script, that is a bug we want to hear about: https://github.com/OoJae/chorus/issues
