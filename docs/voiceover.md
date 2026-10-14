# Chorus demo film: voice-over script

Version 2, 14 October 2026, 16:35 UTC. Every scene is final. Each line of scene 5 names a feature checked on the live Cloud build on 14 October (docs/device-log.md, "late afternoon"). One phrase, "and make it glow on Maya's board", is checked on the phone before recording; if it fails, say the shorter scene 5 text instead.

The finished film runs 1:35; the scene times below are from the 1:50 plan. The narration is about 215 words at a calm pace. Every line describes something shown in a real capture from the live app.

## How to make the audio in Clipchamp

1. Open Clipchamp and start a new video. Go to **Record & create**, then **Text to speech**.
2. Make **one text-to-speech clip per scene**: paste the text in the "Say" box of each scene below. Do not paste the scene numbers or the notes.
3. Settings for every clip:
   - Language: English.
   - Voice: one calm, warm adult voice. Use the same voice for every clip.
   - Speed: normal (1x).
   - Pitch: normal.
4. Put the clips on the timeline in scene order, with **about one second of silence between clips**. Exact gaps don't matter: I split the track at the silences and fit each scene's pictures to its audio.
5. Export at 1080p. If Clipchamp offers audio only, that's fine too. Send me the file's path, for example `~/Downloads/chorus-voice.mp4`.
6. Scene 0 has no narration. Start with scene 1.

If a word comes out wrong, here is what the text does about it:
- "Postgres" is written that way on purpose; it reads better than "PostgreSQL".
- "Serverpod" is said "SER-ver-pod".

## Scenes

### Scene 0 · 0:00 to 0:07 · cold open

**Say:** nothing.

**On screen:** the four tiles of the Chorus mark fall into place in 3D. They become Maya's board on the phone, and the phone itself says "I want juice."

### Scene 1 · 0:07 to 0:20 · who this is for

**Say:**
> This is Maya. She doesn't speak yet, so she talks by tapping pictures. Mum, her therapist and her teacher all add words to her board, often with no signal.

**On screen:** the board and its sentence strip; three adults' devices drift into place around it. Caption: "One board. Many hands."

### Scene 2 · 0:20 to 0:38 · beat 1, no network

**Say:**
> Chorus keeps Maya's whole board on her own device. With no network at all, she still taps, and it still speaks. Every word she knows stays exactly where her hand expects it.

**On screen:** the phone with Wi-Fi off; a hand taps "I", "want", "more"; the phone speaks. Caption: "No network. Still speaks."

### Scene 3 · 0:38 to 0:58 · beat 2, a word waits for a pause

**Say:**
> When Mum adds "juice" from work, it reaches Maya's board. But Chorus holds it while she's in the middle of a sentence. It waits for a pause, then lands in an empty spot. Nothing she already uses ever moves.

**On screen:** the web editor adds "juice"; a pulse travels to the phone; the phone shows "1 waiting" until the strip is clear, then the word lands. Caption: "New words wait for a pause."

### Scene 4 · 0:58 to 1:16 · beat 3, the same empty spot

**Say:**
> Now the hard part. Mum and Ms Lee are both offline, and both fill the same empty spot. When they reconnect, nothing is lost. One word keeps the spot. The other waits under "Needs a home", on every device.

**On screen:** two devices, both offline, put different words into one cell. They reconnect; one word holds the cell and the other appears under "Needs a home" on both. Caption: "Both words survive."

### Scene 5 · 1:16 to 1:36 · what the circle gets

**Say:**
> You can try that clash on one device. Every change shows who made it, with one-tap undo. Ms Lee can find a word and make it glow on Maya's board, see what was modelled and what Maya said herself, and switch on scanning or a second language.

**Shorter text, only if the glow is not confirmed on the phone:**
> You can try that clash on one device. Every change shows who made it, with one-tap undo. Ms Lee can find any word, see what was modelled and what Maya said herself, and switch on scanning or a second language.

**On screen:** quick cuts, one per feature, all real captures of the live app: "Try a clash" ending with both words safe; "What changed" with Undo; the word finder; "This week" with "modelled 1 · said 1"; two-switch scanning; the Yoruba switch on the same buttons; photo ideas from a photo; a picture scene.

### Scene 6 · 1:36 to 1:44 · built on Serverpod

**Say:**
> It's all built on Serverpod: the offline sync module, Postgres on Serverpod Cloud, live updates and scheduled jobs.

**On screen:** a diagram draws itself: each device's own copy of the board, the sync module, the database on Serverpod Cloud, live updates and scheduled jobs.

### Scene 7 · 1:44 to 1:50 · closing card

**Say:**
> Chorus. Many hands on one board, and every word stays hers.

**On screen:** the Chorus mark and wordmark, chorus.serverpod.space, "Android app and code: github.com/OoJae/chorus".

## Rules the film keeps

- Every app behaviour in the film comes from a real capture of the live Cloud build or the release APK. A wait that is shortened is marked on screen, for example "sped up ×4".
- Apart from Postgres (scene 6) and the GitHub address on the closing card, the narration and captions name only Chorus and Serverpod.
- Maya is a persona, and so are the adults. No real child appears, and there are no clinical claims.
- No music. The only sounds are this voice-over, the phone's own speech and soft tap sounds.