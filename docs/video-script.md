# Chorus demo video: shooting script

Chorus is an offline-first talking picture board for a non-speaking child, built on Serverpod 4.0.4 and the experimental `serverpod_offline_sync` module 0.0.10. The child taps words and the device speaks them. Adults edit the board from their own devices.

This file is the plan for the demo video. It says what each second shows, which labels the app puts on screen, how the footage is captured and joined, and what evidence exists today for each claim the video makes.

Status on 13 October 2026: the video has not been recorded. Much of what it shows has passed automated tests but has not yet been seen on a real device. Section 12 lists every such item.

How to read the marks:

- [Square brackets] wrap a sentence that will appear in public (a caption, the closing card, the upload text) and that depends on something not yet seen on a device. After the device check each one is unbracketed or deleted. No bracket may reach the video.
- In the step tables, the last column says whether that step has been seen on a device, with the row of `docs/device-log.md` that records it.
- `TODO(owner)` marks something only the repository owner can supply.
- In the shell command blocks, brackets are ffmpeg syntax, not marks. In the caption, card and description text blocks they are marks.

## 1. Shape and rules

| Part | Time | Length | Surfaces |
|---|---|---|---|
| Beat 1 | 0:00 to 0:26 | 26 s | The physical phone |
| Beat 2 | 0:26 to 0:58 | 32 s | The phone and the hosted web app |
| Beat 3 | 0:58 to 1:40 | 42 s | The phone and two browser windows |
| Closing card | 1:40 to 1:52 | 12 s | Text only |

Planned length 1:52. This script allows 1:55 at most. The hackathon limit is 2:00.

Rules for every take:

1. Each beat is one continuous take. Only its head and tail are trimmed. Nothing between the first and last kept frame is removed, sped up, frozen or replaced.
2. Every surface shows a clock: the phone's status bar, and a clock window on the Mac.
3. If a step stalls, wait, then use the app's own retry ("Sync now"). Never fake a result and never cut around a wait. A take that runs past its length is shot again. If a behaviour does not happen on the devices, its caption is deleted and the beat is not shown as written.
4. There is no voice-over and no music. The only voice in the video is the phone's text-to-speech.
5. Captions name only Serverpod and Chorus. Nothing on screen carries any other product name or logo.
6. The child is a persona. No child, parent or clinician has used Chorus. The video makes no clinical claim.

## 2. Cast, accounts and board

Equipment: one Android phone (Xiaomi, Android 16, 720 x 1640), one Apple Silicon Mac, the hosted web app at `https://chorus.serverpod.space`.

Use two accounts made for the recording, so that each home screen shows exactly one board.

| Who | App name | Role in the app | Signed in on |
|---|---|---|---|
| Parent | Mum | Parent or guardian | The phone, and browser B |
| Teacher | Ms Lee | Teacher | Browser A |

The child is called Maya, a persona. The phone is the child's board in beats 1 and 2. In beat 3 the parent picks the phone up to edit, and browser B stands in as the child's board.

Setting up, once, before any take:

1. On the phone, sign up as the parent. Choose "Start a board for my child". Child's name: Maya. Your name: Mum.
2. On the phone, choose "Invite someone", select "Teacher", then "Make a code".
3. In browser A, sign up as the teacher. Choose "Join with a code". Enter the code. Your name: Ms Lee.
4. In browser B, sign in as the parent again. Browsers A and B must be separate browser profiles: Chorus runs in one tab per profile, and a second tab shows "Chorus is open in another tab" instead of the board.
5. On the phone, open "Edit board", choose the "My words" tab, and add "mango" and then "guava" in the first two cells of row 1.
6. Wait until all three surfaces show both words and read "Up to date".

The home board holds the 36 starter words and has no empty cell. New words go on the second board, "My words". This matters in beat 2: the child's board only announces a waiting word for the board it is showing.

State of "My words" before each beat:

| Before | Row 1 holds | Cell used in the beat |
|---|---|---|
| Beat 1 | mango, guava | none |
| Beat 2 | mango, guava | row 1, column 3 ("juice") |
| Beat 3 | mango, guava, juice | row 1, column 4 ("swing" and "park") |

For a retake, use the next empty cell and a spare word (beat 2: milk, bread; beat 3: bus and train, ball and kite). Before a beat 3 retake, clear the tray with "Place in next free spot" so that "Needs a home" reads "No words are waiting." on both editors.

Device settings for every take:

- Phone: do-not-disturb on, auto-rotate off, media volume at three quarters, Bluetooth and NFC off so their symbols are not in the status bar, battery above half, connected to the Mac by USB cable.
- Phone quick settings panel: open it once and read every tile. Remove any tile that carries a brand name or brand symbol. Leave the airplane tile in the first row.
- Phone speech: an offline voice for US English is installed. The check is in the app: the status row of the child's board must not show the crossed-out speaker icon (its label is "No offline voice on this device").
- Phone and Mac clocks: both set automatically, and agreeing to within a second. Beat 3 depends on which word was written first.
- Mac: a focus mode that silences notifications, Dock hidden, desktop set to plain black with no icons or widgets, sound output loud enough that the phone's voice is clear in a test recording.
- The phone runs the release build made from the same commit as the deployed server.

Controls from the newer build that happen to be on screen are not touched and not captioned: the "Show words on the board" switch in the editor, the photo and recording rows in the "Add a word" sheet, and a small live mark on the child's board.

## 3. The frame

The stage is the bottom 16:9 part of the Mac's screen. Everything is one screen recording: the phone mirror, the browser windows, the live view of the hand, and the clock. Captions are burned in afterwards.

On the Mac used here (3024 x 1964 pixels, shown as 1512 x 982 points at the default display setting) the stage is the full width and the bottom 850 points, starting 132 points from the top. On another screen the top of the stage is the screen height minus nine sixteenths of its width.

| Column | Points from the left | Beat 1 | Beat 2 | Beat 3 |
|---|---|---|---|---|
| 1 | 0 to 373 | Phone mirror | Phone mirror | Phone mirror (parent, editing) |
| 2 | 381 to 754 | Hand view, large | Browser A (teacher) | Browser A (teacher) |
| 3 | 762 to 1135 | (hand view continues) | Hand view, upright | Browser B (the child's board) |
| 4 | 1143 to 1512 | Clock, captions | Clock, captions | Clock, hand view, captions |

Each browser window is as narrow as a phone on purpose. At that width the editor is a single column, and the grid and the "Needs a home" tray are on screen together after a short scroll.

## 4. Beat 1: the phone speaks, then speaks with no network (0:00 to 0:26)

Before pressing record:

- Airplane mode off. The phone is on the child's board: home screen, "Talker". The "Home" tab is selected and shows 36 words.
- The round status icon beside "Hold to leave" is a tick.
- Tap "I", "want", "more" so the sentence strip reads "I want more".
- The hand view shows the hand and the phone.

| # | Time | Action on the phone | Expected | Seen on a device |
|---|---|---|---|---|
| 1 | 0:01 | Tap the black speaker button under the strip (its accessibility label is "Speak"). | The phone says "I want more". Finished by 0:03. | Partly. Device log, Android table, "Talker speaks": the sentence was built and audio output opened, but nobody listened. |
| 2 | 0:04 | Tap the X button (label "Clear"). | The strip is empty. | Not logged. |
| 3 | 0:06 | Swipe the quick settings panel down, tap the airplane tile, swipe the panel away. The hand is visible doing it. | The airplane icon shows in the status bar and stays. Within a few seconds the round status icon changes from a tick to a phone outline. | Not yet. |
| 4 | 0:13 | Tap "I", "can", "do", "it". Let each word finish. | Each word is spoken as it is tapped. The strip reads "I can do it". | Not yet in airplane mode. |
| 5 | 0:20 | Tap the speaker button. | The phone says "I can do it" as one sentence. | Not yet. |
| 6 | 0:23 to 0:26 | Hands off. | The airplane icon is still showing. | Not yet. |

Captions:

| Time | Caption |
|---|---|
| 0:00 to 0:06 | Chorus is a talking picture board for a child who does not speak. |
| 0:06 to 0:12 | [Airplane mode on, by hand.] |
| 0:12 to 0:20 | [No network. The board comes from the replica that Serverpod offline sync keeps on the phone. The voice is the phone's own.] |
| 0:20 to 0:26 | The child in this story is a persona. No child, parent or clinician has used Chorus. |

The persona line comes last, over the end of the beat, so the video opens on what Chorus is.

Voice-over: none.

If a step stalls:

- Silent at step 1: stop. Check the media volume and the crossed-out speaker icon. Start the take again.
- Silent after airplane mode: the phone has no offline voice. Install one in the system text-to-speech settings. Until the phone speaks in airplane mode, beat 1 cannot be recorded.
- The status icon is still a tick after ten seconds: carry on. The app notices a lost network on a connectivity event or at its next 20-second check. The airplane icon is the proof, and no caption mentions the status icon.

After the take, switch airplane mode off and wait for the tick.

## 5. Beat 2: a word from another device lands at a safe moment (0:26 to 0:58)

Before pressing record:

- Phone: airplane mode off. Leave the child's board with "Hold to leave" (hold for two seconds) and open "Talker" again, so it starts fresh on "Home" with an empty strip. Status icon: tick.
- Browser A (Ms Lee): "Edit board", "My words" tab. The title reads "Maya's board". The chip reads "Up to date". Row 1, column 3 is an empty spot with a plus sign.

| # | Time | Surface | Action | Expected | Seen on a device |
|---|---|---|---|---|---|
| 1 | 0:26 | Phone | Tap "I", "want". | Each word is spoken. The strip reads "I want". | Partly, as beat 1, step 1: built on the phone, audio opened, nobody listened. |
| 2 | 0:29 | Phone | Tap the "My words" tab. | The board shows "mango" and "guava". The strip still reads "I want". | Tabs seen in the editor only (device log, "Second board"). |
| 3 | 0:31 | Browser A | Click the empty spot in row 1, column 3. Type "juice" in the "Word" field. Click "Add to board". | The sheet "Add a word" opens and closes. "juice" is in the cell. The chip reads "Sending changes", then "Up to date". | Not yet in a browser. On the phone: device log, "Add a word while online". |
| 4 | 0:37 | Phone | Hands off. | A black pill reading "1 waiting" appears at the left of the status row. The cell in row 1, column 3 is still empty. | Not yet. |
| 5 | 0:41 | Phone | Tap the speaker button. Let it finish. | The phone says "I want". | As step 1. |
| 6 | 0:44 | Phone | Tap the X button. Hands off. | The strip is empty. | Not logged. |
| 7 | 0:46 to 0:48 | Phone | Nothing. | Two to two and a half seconds after the last touch, "juice" appears in row 1, column 3 and the pill goes. "mango" and "guava" have not moved. | Not yet. |
| 8 | 0:50 | Phone | Tap "juice". | The phone says "juice". | Not yet. |
| 9 | 0:52 to 0:58 | Both | Hands off. | Both boards show mango, guava, juice in the same three cells. | Not yet. |

On a phone the pill reads "1 waiting". The longer wording, "1 word waiting", is used only on a tablet or a desktop window (at least 600 points wide and 480 high). The caption quotes what the phone shows.

Captions:

| Time | Caption |
|---|---|
| 0:26 to 0:32 | [Online again. A teacher has the same board open in the web app on Serverpod Cloud.] |
| 0:32 to 0:38 | [She adds a word. It is saved in her browser's replica, then Serverpod offline sync sends it.] |
| 0:38 to 0:44 | [The phone's open sync stream receives it. The child is mid-sentence, so the board waits: "1 waiting".] |
| 0:44 to 0:51 | [Strip empty, nothing playing, no touch for two seconds. Now the word lands.] |
| 0:51 to 0:58 | No button the child already uses ever changes place. |

Voice-over: none.

If a step stalls:

- Browser A's chip shows "Offline, saved on this device" or "Reconnecting": click "Sync now" in the chip. If it stays on "Sending changes", wait: the chip offers no retry while it is connected.
- No pill on the phone ten seconds after step 3: keep recording to the end of the beat's length, then stop. The take is void. Find the cause off camera. Do not leave and reopen the child's board during a take: a reopened board shows the word at once, and the wait is the point of the beat.
- The word lands before step 5: the strip was empty. The take is void.

## 6. Beat 3: two adults, both offline, one empty cell (0:58 to 1:40)

Who plays what:

- Primary. The phone is the parent, offline through real airplane mode. Browser A is the teacher, offline through the app's own "Work offline" switch. A desktop browser has no airplane mode, and cutting the Mac's network would also cut the child's board, so the browser uses the switch. The switch stops the sync loop and closes the sync stream, as a lost connection does. The caption and the closing card say that the switch was used.
- Fallback. Both the phone and browser A use "Work offline". Use it if the phone's airplane mode fails its device check, or if its reconnect takes more than about ten seconds every time. The captions change as shown below.
- Third surface. Browser B is the child's board: the parent's account, "Talker", "My words" tab, online for the whole take and never touched. It shows what the child would see: one new word arrives in the empty cell, and nothing that was already there moves.

Order matters. In the automated tests the earlier write keeps the cell whichever device reconnects first (`cell_conflict_test.dart`, T1). The teacher writes first and reconnects first. The parent writes at least five seconds later and reconnects last. The child's board then receives the winning word first, and the phone's real radio wait is the last thing on screen.

Before pressing record:

- Browser A (Ms Lee): on the home screen switch "Work offline" on. Open "Edit board", "My words". The chip reads "Working offline, saved on this device".
- Phone (Mum): open "Edit board", "My words". Then switch airplane mode on and wait until the chip reads "Offline, saved on this device". The airplane icon is in the status bar.
- Browser B (Mum): "Talker", "My words" tab. Strip empty. Status icon: tick. It shows mango, guava, juice.
- On both editors row 1, column 4 is an empty spot, and "Needs a home" reads "No words are waiting."

| # | Time | Surface | Action | Expected | Seen on a device |
|---|---|---|---|---|---|
| 1 | 0:58 | All | Hands off for two seconds. | Phone: airplane icon, chip "Offline, saved on this device". Browser A: chip "Working offline, saved on this device". Browser B: the child's board, row 1, column 4 empty. | Not yet. |
| 2 | 1:00 | Browser A | Click the empty spot in row 1, column 4. Type "swing". Click "Add to board". | "swing" is in the cell in browser A only. | Not yet in a browser. |
| 3 | 1:06 | Phone | Tap the same empty spot. Type "park" on the phone's keyboard. Close the keyboard with the back gesture and tap "Add to board". | "park" is in the cell on the phone only. | With "Work offline": device log, "Add a word with 'Work offline' on". With airplane mode: not yet. |
| 4 | 1:12 | All | Hands off for one second. | The same cell reads "swing" in browser A and "park" on the phone. On the child's board it is empty. | Not yet. |
| 5 | 1:13 | Browser A | Click the back arrow. Switch "Work offline" off. Click "Edit board". Click "My words". | The chip reads "Connecting", then "Up to date". On the child's board "swing" appears in row 1, column 4. | Not yet. |
| 6 | 1:19 | Phone | Swipe the panel down, tap the airplane tile, swipe the panel away. | The airplane icon goes. | Not yet. |
| 7 | 1:23 to 1:31 | Phone | Nothing. This is the real wait. | The chip reads "Offline, saved on this device", then "Connecting", then "Up to date". The cell changes from "park" to "swing". | Not yet. |
| 8 | 1:31 | Phone | Scroll down a little. | "Needs a home (1)". The card reads "park", "Added by Mum", "Added while offline; Ms Lee's word got this spot first", with the buttons "Place in next free spot", "Choose a spot" and "Remove". | Not yet. |
| 9 | 1:33 | Browser A | Scroll down a little. | The same heading and the same card. The cell still reads "swing". | Not yet. |
| 10 | 1:35 to 1:40 | All | Hands off. | On all three surfaces mango, guava and juice are where they were. The child's board shows "swing" and does not show "park". | Not yet. |

The child's board never shows "park" in that cell. The parent's word was written later, so the sync engine renames its claim, and Chorus lists it under "Needs a home" instead of on the grid. On the parent's own phone the cell changes from "park" to "swing" in step 7: that is the editor catching up, on a word the child never saw.

Captions, primary:

| Time | Caption |
|---|---|
| 0:58 to 1:06 | [The phone is now a parent's, in airplane mode. Middle: a teacher's browser, paused with "Work offline". Right: the child's board.] |
| 1:06 to 1:13 | [Both adults put a different word in the same empty cell: top row, fourth from the left.] |
| 1:13 to 1:19 | [The teacher reconnects first. Her word reaches the child's board.] |
| 1:19 to 1:31 | [Airplane mode off. The phone syncs. The teacher's word was written first, so it keeps the cell.] |
| 1:31 to 1:36 | [One word holds the cell. The other waits in "Needs a home". Serverpod offline sync kept both rows.] |
| 1:36 to 1:40 | When two adults fill the same empty cell offline, both words survive. |

Captions, fallback. Only these two change:

| Time | Caption |
|---|---|
| 0:58 to 1:06 | [The phone is now a parent's. Middle: a teacher's browser. Both paused with "Work offline". Right: the child's board.] |
| 1:19 to 1:31 | ["Work offline" off. The phone syncs. The teacher's word was written first, so it keeps the cell.] |

In the fallback, steps 6 and 7 on the phone become: tap the back arrow, switch "Work offline" off, tap "Edit board", tap "My words". Before recording, the phone is put offline with the same switch instead of airplane mode.

Voice-over: none.

If a step stalls:

- The phone's chip still reads "Offline, saved on this device" ten seconds after step 6: tap "Sync now" in the chip.
- Browser A's chip shows "Reconnecting": click "Sync now". While it reads "Connecting" the chip offers no button: wait, and it moves on to "Up to date" or to a state that offers "Sync now".
- A chip reads "Up to date" but the tray has not appeared on that device after ten seconds: the chip offers no "Sync now" while it is up to date. Go back to the home screen, switch "Work offline" on and off again, and return to "My words". This runs a fresh sync. Keep recording.
- The child's board shows a waiting pill with an adult icon: the later word reached the server first, or the two clocks disagree. The take is void. Check the clocks and the order, and shoot again.
- Any of these makes the take longer than 42 seconds: shoot again. Do not trim inside the take.

## 7. Closing card (1:40 to 1:52)

White text on black, no sound, twelve seconds. The text, to be saved as `build/card.txt`:

```text
Chorus

Serverpod 4.0.4 and Serverpod offline sync 0.0.10, on Serverpod Cloud.

Limits. The sync module is experimental.
Two adults changing the same label offline: the later change wins.
[In the third take the browser was paused with the app's own switch.]

The child in this story is a persona.
No child, parent or clinician has used Chorus.

chorus.serverpod.space
```

In the fallback the bracketed line reads: [In the third take both devices were paused with the app's own switch.]

The repository address is left off the card because it contains another company's name. It goes in the submission form.

## 8. Captions file

Save as `build/captions.srt` once every bracket is resolved. The times are the plan. After the takes are chosen, move each cue to the event it names. The beat boundaries stay at 0:26, 0:58 and 1:40 if the takes are trimmed to 26, 32 and 42 seconds.

```text
1
00:00:00,300 --> 00:00:06,000
Chorus is a talking picture board for a child who does not speak.

2
00:00:06,300 --> 00:00:12,000
[Airplane mode on, by hand.]

3
00:00:12,300 --> 00:00:20,000
[No network. The board comes from the replica that Serverpod offline sync keeps on the phone. The voice is the phone's own.]

4
00:00:20,300 --> 00:00:25,700
The child in this story is a persona. No child, parent or clinician has used Chorus.

5
00:00:26,300 --> 00:00:32,000
[Online again. A teacher has the same board open in the web app on Serverpod Cloud.]

6
00:00:32,300 --> 00:00:38,000
[She adds a word. It is saved in her browser's replica, then Serverpod offline sync sends it.]

7
00:00:38,300 --> 00:00:44,000
[The phone's open sync stream receives it. The child is mid-sentence, so the board waits: "1 waiting".]

8
00:00:44,300 --> 00:00:51,000
[Strip empty, nothing playing, no touch for two seconds. Now the word lands.]

9
00:00:51,300 --> 00:00:57,700
No button the child already uses ever changes place.

10
00:00:58,300 --> 00:01:06,000
[The phone is now a parent's, in airplane mode. Middle: a teacher's browser, paused with "Work offline". Right: the child's board.]

11
00:01:06,300 --> 00:01:13,000
[Both adults put a different word in the same empty cell: top row, fourth from the left.]

12
00:01:13,300 --> 00:01:19,000
[The teacher reconnects first. Her word reaches the child's board.]

13
00:01:19,300 --> 00:01:31,000
[Airplane mode off. The phone syncs. The teacher's word was written first, so it keeps the cell.]

14
00:01:31,300 --> 00:01:36,000
[One word holds the cell. The other waits in "Needs a home". Serverpod offline sync kept both rows.]

15
00:01:36,300 --> 00:01:39,700
When two adults fill the same empty cell offline, both words survive.
```

## 9. Capture

Checked on the recording Mac on 13 October 2026: scrcpy 4.0 and ffmpeg 8.1.1 are installed. That ffmpeg build has no `subtitles` and no `drawtext` filter, so it cannot burn in captions or draw the clock and the card. Homebrew's `ffmpeg-full` has both. It is used below for everything except the screen recording.

```sh
brew install ffmpeg-full
FFDIR="$(brew --prefix ffmpeg-full)/bin"; FF="$FFDIR/ffmpeg"; FFPROBE="$FFDIR/ffprobe"; FFPLAY="$FFDIR/ffplay"
"$FF" -hide_banner -filters | grep -E ' (subtitles|drawtext) '      # both lines must print
mkdir -p ~/chorus-video/takes ~/chorus-video/build && cd ~/chorus-video
ffmpeg -hide_banner -f avfoundation -list_devices true -i "" 2>&1 | grep -E '\[[0-9]+\]'
SCREEN=2; CAM=0; MIC=1        # replace with the indexes printed: "Capture screen 0", the webcam, the Mac's microphone
```

What must not be in the frame: music, logos, a browser tab bar or address bar, the phone's launcher, store icons, notifications, the Mac's menu bar and Dock, and any app name other than Chorus. The phone's own maker logo must not be in the hand view.

### The phone

The phone is mirrored over USB. Today it is attached to adb over wireless debugging, which airplane mode cuts, so the cable is required. `-d` selects the USB connection. No port is forwarded to the phone. Before scrcpy starts, `adb reverse --list` must print nothing. While scrcpy runs, the only entry allowed is its own, whose phone side is `localabstract:scrcpy_...`. An entry whose phone side is a TCP port, such as `tcp:8080`, would let the phone reach the Mac, and airplane mode would prove nothing.

```sh
scrcpy -d --mouse=disabled --keyboard=disabled --show-touches --stay-awake --disable-screensaver \
  --window-borderless --window-x=0 --window-y=132 --window-width=373 --window-height=850 \
  --record=takes/beat1-phone.mkv
```

- scrcpy forwards the phone's audio to the Mac and plays it there. The phone's own speaker is silent while it runs.
- `--show-touches` draws a dot where the finger lands, so the mirror shows each tap.
- Mouse and keyboard input from the Mac are disabled, so nothing but the hand drives the phone. scrcpy refuses `--no-control` together with `--stay-awake`, which is why the two inputs are disabled one by one.
- In beat 3 the word "park" is typed on the phone's own keyboard. Check first that the keyboard shows no maker's logo. If it does, run that take with `--keyboard=uhid` and type on the Mac's keyboard after one click on the mirror; the phone then shows no on-screen keyboard. On this phone that needs the developer option "USB debugging (Security settings)".
- Change the file name for each beat and each take.

### The browser windows

Each window is a separate profile opened in app mode, which has no tab bar and no address bar. Any Chromium-based browser takes the same flags.

```sh
open -na "Microsoft Edge" --args --user-data-dir="$HOME/chorus-video/profile-a" --no-first-run \
  --app=https://chorus.serverpod.space --window-position=381,104 --window-size=373,878
open -na "Microsoft Edge" --args --user-data-dir="$HOME/chorus-video/profile-b" --no-first-run \
  --app=https://chorus.serverpod.space --window-position=762,104 --window-size=373,878
```

The window's title bar sits just above the stage and is cropped off. Open each profile once beforehand, sign in, and dismiss anything the browser asks on first run. If a window opens at another size, drag it to its column. If the browser will not go that narrow, keep it under 900 points wide so the editor stays a single column.

### The hand and the clock

The hand view is a live window of the webcam, on the stage, so it is part of the same recording. Point the webcam at the phone: a webcam looking down at the desk, or the phone held up to the Mac's own camera. The frame shows the hand and the phone and nothing else.

```sh
# Beat 1: large, columns 2 and 3
"$FFPLAY" -hide_banner -loglevel error -f avfoundation -framerate 30 -video_size 1280x720 -i "$CAM:none" -an \
  -fflags nobuffer -flags low_delay -framedrop -vf "crop=960:720" -noborder -alwaysontop -left 381 -top 274 -x 754 -y 566
# Beat 2, upright, column 3: the same command with  -vf "crop=540:720" -left 762  -top 132 -x 373 -y 497
# Beat 3, small, column 4:   the same command with  -vf "crop=960:720" -left 1143 -top 188 -x 369 -y 277

# The clock, column 4, every beat
"$FFPLAY" -hide_banner -loglevel error -f lavfi \
  -i "color=c=black:s=738x96:r=10,drawtext=text='%{localtime\:%T}':fontcolor=white:fontsize=64:x=(w-tw)/2:y=(h-th)/2" \
  -noborder -alwaysontop -left 1143 -top 132 -x 369 -y 48
```

### The screen recording

The recording takes the whole screen and the Mac's microphone. The microphone hears the phone's voice from the Mac's speakers, so picture and sound are one file and cannot drift. The recording stops by itself after `-t` seconds. Keep the terminal in the strip above the stage, or minimise it.

```sh
GEOM="crop=iw:trunc(iw*9/32)*2:0:ih-oh,scale=1920:1080:flags=lanczos,setsar=1,fps=30,format=yuv420p"

# One frame, to check the layout before every take
ffmpeg -hide_banner -y -f avfoundation -framerate 30 -pixel_format nv12 -capture_cursor 1 -i "$SCREEN:none" \
  -frames:v 1 -update 1 -vf "$GEOM" build/layout-test.png

# The take
sleep 5; ffmpeg -hide_banner -f avfoundation -framerate 30 -pixel_format nv12 -capture_cursor 1 -capture_mouse_clicks 1 \
  -i "$SCREEN:$MIC" -t 75 -c:v h264_videotoolbox -b:v 50M -c:a aac -b:a 192k takes/beat1-screen.mkv
```

Order for each take: start scrcpy, the hand view and the clock; check the layout frame; do the "before pressing record" list; start the recording; wait five seconds; perform the beat against the clock; hold two seconds at the end. Record a five-second test first and play it back: the terminal needs screen recording, camera and microphone permission, and the voice must be clear.

## 10. Assembly

Trim and scale each take. The second argument is the first kept second, read off the take by eye (the values shown are examples). The third is the length kept.

```sh
norm() {   # norm <take> <first kept second> <seconds kept> <output>
  "$FF" -y -ss "$2" -t "$3" -i "$1" -vf "$GEOM" -af "aresample=48000,aformat=channel_layouts=stereo" \
    -c:v libx264 -preset slow -crf 16 -c:a aac -b:a 192k "$4"
}
norm takes/beat1-screen.mkv 6.0 26 build/b1.mp4
norm takes/beat2-screen.mkv 5.0 32 build/b2.mp4
norm takes/beat3-screen.mkv 4.0 42 build/b3.mp4
```

Make the closing card from `build/card.txt`:

```sh
"$FF" -y -f lavfi -i "color=c=black:s=1920x1080:r=30:d=12" -f lavfi -t 12 -i "anullsrc=r=48000:cl=stereo" \
  -vf "drawtext=textfile=build/card.txt:expansion=none:font='Helvetica Neue':fontsize=40:fontcolor=white:line_spacing=16:x=140:y=(h-text_h)/2,format=yuv420p" \
  -c:v libx264 -preset slow -crf 16 -c:a aac -b:a 192k -shortest build/card.mp4
```

Join the four parts and burn in the captions in one pass. The style puts the captions at the bottom of column 4, clear of every app surface.

```sh
grep -n '[][]' build/captions.srt build/card.txt && echo "Brackets left. Resolve them before going on."

"$FF" -y -i build/b1.mp4 -i build/b2.mp4 -i build/b3.mp4 -i build/card.mp4 -filter_complex \
 "[0:v][0:a][1:v][1:a][2:v][2:a][3:v][3:a]concat=n=4:v=1:a=1[v0][a];[v0]subtitles=build/captions.srt:force_style='FontName=Helvetica Neue,FontSize=9,PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000,BorderStyle=1,Outline=0.6,Shadow=0,Alignment=1,MarginL=292,MarginR=6,MarginV=12'[v]" \
 -map "[v]" -map "[a]" -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -r 30 -c:a aac -b:a 192k -movflags +faststart chorus-demo.mp4
```

Check the result:

```sh
"$FFPROBE" -v error -select_streams v:0 -show_entries stream=codec_name,width,height,avg_frame_rate:format=duration -of default=nw=1 chorus-demo.mp4
D=$("$FFPROBE" -v error -show_entries format=duration -of csv=p=0 chorus-demo.mp4)
awk -v d="$D" 'BEGIN { if (d <= 115) print "length ok: " d " s"; else { print "TOO LONG: " d " s"; exit 1 } }'
"$FF" -y -ss 100 -i chorus-demo.mp4 -frames:v 1 -update 1 build/check-0140.png      # card, first frame
```

Expected: `width=1920`, `height=1080`, `avg_frame_rate=30/1`, duration 112 seconds and never above 115. Then watch it once from start to end with sound. Check that no caption covers a board, that the persona caption is up at the end of beat 1, and that every wait is still there.

Cleaner sound, optional. scrcpy's own recording holds the phone's audio without the room. To use it, find the same spoken word in both files: `S` is its time in the screen take, `P` its time in the phone take.

```sh
onset() { "$FF" -hide_banner -nostats -i "$1" -map 0:a:0 -af "silencedetect=noise=$2:d=0.2" -f null - 2>&1 | sed -n 's/.*silence_end: \([0-9.]*\).*/\1/p' | head -1; }
S=$(onset takes/beat1-screen.mkv -30dB); P=$(onset takes/beat1-phone.mkv -50dB)
"$FF" -y -ss 6.0 -t 26 -i takes/beat1-screen.mkv -ss "$(awk -v a=6.0 -v s="$S" -v p="$P" 'BEGIN { printf "%.3f", a - s + p }')" -t 26 -i takes/beat1-phone.mkv \
  -map 0:v -map 1:a -vf "$GEOM" -af "aresample=48000,aformat=channel_layouts=stereo" -c:v libx264 -preset slow -crf 16 -c:a aac -b:a 192k build/b1.mp4
```

`onset` prints the time of the first sound in a file. The phone file starts earlier than the screen take, so its first sound can be an earlier tap. Play both files at `S` and `P` and confirm they are the same word; if not, read `P` off by ear. In a noisy room the detected `S` is wrong too. If the voice and the touch dots do not line up in the result, keep the room sound. Beat 3 has no speech to line up on; it keeps its room sound.

## 11. Upload checklist

1. The file is `chorus-demo.mp4`: H.264, 1920 x 1080, 30 frames a second, under 1:55.
2. Visibility is Public. Not Private and not Unlisted. No age restriction. Audience: not made for children; the video is addressed to adults.
3. Embedding is allowed.
4. Nothing is added in the upload tool: no music, no end screen, no cards.
5. Wait until the 1080p version has finished processing.
6. Open the link in a private window with no account signed in. Watch it to the end with sound. It plays without a sign-in, offers 1080p, runs under 2:00, and shows no bracket.
7. The link stays public until judging ends on 20 October 2026, 17:00 CEST.
8. TODO(owner): paste the public video link here, in the README and in the submission form.

Title:

```text
Chorus: an offline-first talking picture board built on Serverpod
```

Description:

```text
Chorus is an offline-first talking picture board for a non-speaking child, built on Serverpod 4.0.4 and its experimental offline sync module, and deployed on Serverpod Cloud.

The child in this story is a persona. No child, parent or clinician has used Chorus. No clinical claim is made.

Mature tools already offer offline boards with cloud sync. We have not found a tool that shows what happens when two adults change the same board offline.

Three uncut takes on one physical phone and the hosted web app:
0:00 [The phone speaks, then speaks again in airplane mode.]
0:26 [An adult adds a word in the web app. The child's board takes it only at a safe moment.]
0:58 [Two adults, both offline, fill the same empty cell. One word holds the cell. The other waits in "Needs a home".]
1:40 What was used, and the limits.

No button the child already uses ever changes place. When two adults fill the same empty cell offline, both words survive.

Limits: the sync module is experimental and pinned to one version. Two adults changing the same label offline: the later change wins. [In the third take the browser was taken offline with the app's own "Work offline" switch.]

Try it: https://chorus.serverpod.space

Starter vocabulary: the 36-word Universal Core vocabulary, Center for Literacy and Disability Studies, UNC-Chapel Hill, CC BY-SA 4.0.
```

The last line is the licence credit for the 36 words on the board. The licence requires it wherever the words are published. It is the only place the upload text names anyone other than Serverpod and Chorus. The repository link is not in the description, for the same reason it is not on the card.

## 12. Pre-flight: every on-screen claim and its proof

"Device log" is `docs/device-log.md`, 13 October 2026. Sync tests are in `chorus_server/test/sync/` and run against an embedded PostgreSQL and real SQLite replica files; their results are in `docs/spike-results.md`. A row marked "must be verified on device before recording" has no device evidence today. Each check gets a dated row in the device log before its take is recorded.

| # | On-screen claim | Where | Proof today | Before recording |
|---|---|---|---|---|
| 1 | The child is a persona; nobody has used Chorus. | Caption 0:20, card | True by construction. The app's Credits screen says the same. | Nothing. |
| 2 | The phone speaks a sentence in the first three seconds. | Beat 1, step 1 | Device log, Android table, "Talker speaks": driven over adb, audio output opened at each tap, nobody listened. | Listen to it on the phone, in the room. |
| 3 | The airplane icon is on and the phone still builds and speaks a sentence. | Beat 1, steps 3 to 6 | None. Device log, "Not yet checked": real airplane mode. | Must be verified on device before recording. Includes an installed offline voice and the mirror staying up over USB. |
| 4 | The board is read from the replica that Serverpod offline sync keeps on the phone. | Caption 0:12 | Device log, Android table: "Sync delivers a circle created in the browser" and "Add a word with 'Work offline' on". App tests: `chorus_flutter/test/sync/replica_board_store_test.dart`. | With the network really off: must be verified on device before recording (same check as row 3). |
| 5 | The voice is the phone's own text-to-speech. | Caption 0:12 | Code: `chorus_flutter/lib/src/speech/tts_speech_service.dart`. Device log, "Talker speaks". | Nothing more. |
| 6 | The web app runs on Serverpod Cloud. | Caption 0:26, card | Device log, Serverpod Cloud table and desktop browser table. | Nothing. |
| 7 | A second adult, a teacher, shares the board. | Beats 2 and 3 | Server test `circle_endpoint_test.dart`, "when a teacher accepts an invitation then they join with ...". Sync test `spaces_test.dart`, T8. No device row. | Must be verified on device before recording: make a code on the phone, join with it in browser A. |
| 8 | The teacher adds a word in the browser. | Beat 2, step 3 | Device log has this on the phone only: "Add a word while online". | Must be verified on device before recording, in the browser. |
| 9 | The word reaches the phone while its board is open. | Beat 2, step 4 | None on a device. Device log, "Not yet checked": a word arriving on another open device. Sync test T8 moves words between replicas with one-shot syncs. | Must be verified on device before recording. Time it. |
| 10 | The phone shows "1 waiting" and takes the word only when the strip is empty, nothing is playing and two seconds pass with no touch. | Beat 2, steps 4 to 7 | Rule tests `chorus_shared/test/reconcile_snapshot_test.dart`: group "isSafePoint", "added: a new tile fills an empty cell automatically". Screen tests `chorus_ui/test/talker_controller_test.dart`: "a merged word waits while the strip has words in it", "a merged word waits while speech is playing", "the timer applies a waiting change once it is safe". | Must be verified on device before recording. |
| 11 | The new word is spoken when tapped. | Beat 2, step 8 | As row 2. | Must be verified on device before recording (follows row 9). |
| 12 | No button the child already uses ever changes place. | Caption 0:51; beats 2 and 3 | Rule test `reconcile_snapshot_test.dart`: "property: a plan never changes what an occupied cell means". App test `replica_board_store_test.dart`, group "placeTile": "never moves a tile that already has a cell". The editor offers no way to move a placed word. | Watch mango, guava and juice in both takes. Must be verified on device before recording. |
| 13 | An adult can add a word while offline, on the phone and in the browser. | Beat 3, steps 2 and 3 | Phone with "Work offline": device log, "Add a word with 'Work offline' on". Widget test `home_screen_test.dart`: "Work offline sits with the extras, pauses sync ...". | Phone in airplane mode: must be verified on device before recording. Browser with "Work offline": must be verified on device before recording. |
| 14 | Words written offline are sent on reconnect. | Beat 3, steps 5 to 7 | App test `sync_supervisor_test.dart`: "a write made offline is sent by the next one-shot sync". Device log, "Not yet checked": the offline word reaching the server. | Must be verified on device before recording. Time the wait after airplane mode goes off. |
| 15 | Both words survive. One holds the cell, the other is under "Needs a home", on both adults' devices. | Beat 3, steps 7 to 9; caption 1:36 | Sync test `cell_conflict_test.dart`, T1, three orderings, checked on the server and on each replica. Rule test `chorus_shared/test/tray_test.dart`: "contested: an engine-suffixed key, with the cell it lost". Results: `docs/spike-results.md`, row T1. | Must be verified on device before recording. |
| 16 | The child's board gains one word and nothing already on it moves. | Beat 3, browser B | T1 checks the grid on every replica. Rule test as row 12. | Must be verified on device before recording. |
| 17 | The takes are uncut. | Upload description | True if rule 1 of section 1 is kept: one take, clocks visible, head and tail trims only. | Check when assembling. |
| 18 | Serverpod 4.0.4 and Serverpod offline sync 0.0.10, on Serverpod Cloud. | Card | Version pins in `AGENTS.md`. Device log, Serverpod Cloud tables. | Nothing. |
| 19 | Two adults changing the same label offline: the later change wins. | Card | Sync test `merge_test.dart`, T4, three orderings. | Nothing. It is a limit, stated as one. |
| 20 | In the third take the browser was paused with the app's own switch. | Card, caption 0:58, upload description | A fact about the take. | Reword all three if the fallback is shot. |
| 21 | Chorus is a talking picture board for a child who does not speak. | Caption 0:00 | What the app is (README). | Nothing. |
| 22 | The teacher's word was written first, so it keeps the cell. | Caption 1:19 | Sync test `cell_conflict_test.dart`, T1: the earlier claim keeps the cell in all three orderings, including the one where it syncs last. | Must be verified on device before recording, with row 15. |

Also to check on the phone before recording, though no caption depends on them:

- The upright layout of the child's board: strip across the full width, three buttons in a row beneath it. The device log records the problems of the earlier layout. The new one is covered by `chorus_ui/test/talker_layout_test.dart` and has not been seen on a device.
- The quick settings panel and the keyboard show no brand.
- Two stopwatch times, written into the device log: from "Add to board" in the browser to "1 waiting" on the phone, and from airplane mode off to "Up to date" on the phone. Beat 2 allows about six seconds for the first and beat 3 about eight for the second.

If a row cannot be verified, its caption is deleted and its beat is not shown as written. The video shows only what the devices did.

If the same-cell collision cannot be shown on the devices before recording, beat 3 is one uncut take of a terminal in `chorus_server` running `dart test test/sync/cell_conflict_test.dart --concurrency=1`, with two captions: "Not yet shown on two devices. Automated sync tests on a real server database and replica files, three orderings." and then "When two adults fill the same empty cell offline, both words survive." Rule 5 still holds: the captions name no other product, and the terminal's title bar is cropped off. The 0:58 line of the upload description and the card are reworded to say the same.
