/// What the app shell needs from the server and from the local replica.
///
/// The screens are written against these two interfaces so widget tests can
/// run them on small fakes. The real implementations live in `app.dart`.
library;

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_ui/contracts.dart' show BoardStore, SyncStatus;
import 'package:chorus_ui/contracts_boards.dart';
import 'package:chorus_ui/contracts_copies.dart' show BoardCopies;
import 'package:chorus_ui/contracts_hidden.dart';
import 'package:chorus_ui/contracts_language.dart';
import 'package:chorus_ui/contracts_media.dart';
import 'package:chorus_ui/contracts_modelling.dart';
import 'package:chorus_ui/contracts_scenes.dart' show SceneBook;
import 'package:chorus_ui/contracts_quick_phrases.dart';
import 'package:chorus_ui/contracts_sharing.dart';
import 'package:chorus_ui/contracts_suggest.dart';
import 'package:chorus_ui/contracts_voice.dart';
import 'package:chorus_ui/contracts_wordlog.dart';

import '../src/live/chorus_live_session.dart';
import '../src/trust/trust_services.dart';

/// The circle calls on the server, plus the circles remembered on this
/// device for a start with no signal.
abstract class CircleGateway {
  /// Every circle the signed-in adult belongs to. Needs the network.
  Future<List<CircleInfo>> myCircles();

  /// The circles this device saw last time. Never throws; empty when
  /// nothing was saved.
  Future<List<CircleInfo>> rememberedCircles();

  Future<CircleInfo> createCircle({
    required String childName,
    required String displayName,
  });

  Future<CircleInfo> acceptInvite({
    required String code,
    required String displayName,
  });

  /// A single-use code that lets one more adult join [circle] as [role].
  Future<String> createInvite(CircleInfo circle, CircleRole role);

  Future<void> signOut();
}

/// The signed-in adult's local replica, already syncing.
abstract class Workspace {
  SyncStatus get sync;

  /// Waits until this device may write into [circle]'s boards, and seeds the
  /// starter board when asked and none exists.
  Future<void> ensureCircleReady(CircleInfo circle, {bool seedIfEmpty = false});

  BoardStore boardStore(CircleInfo circle);

  /// What [circle] offers beyond its board, or null for a workspace with
  /// none of it. Cheap to call again: the same circle and role get the same
  /// object.
  CircleServices? servicesFor(CircleInfo circle);

  /// Stops sync and closes the replica.
  Future<void> close();
}

/// What one circle offers beyond its board: photos and voices, the live
/// session, a suggested word, a paper copy, the word log and "This week",
/// sharing a board outside the circle, and managing the circle's boards.
///
/// Every part is optional and the screens work without any of them, so a
/// part that cannot be made on this device is simply left out.
class CircleServices {
  const CircleServices({
    required this.userId,
    this.media,
    this.speaker,
    this.capture,
    this.live,
    this.suggester,
    this.publishBoard,
    this.wordLog,
    this.summary,
    this.sharing,
    this.boards,
    this.trust,
    this.modelling,
    this.speech,
    this.scenes,
    this.copies,
    this.hiddenWords,
    this.languages,
    this.languageVoice,
    this.voice,
    this.quickPhrases,
    this.wordCounts,
  });

  /// UUID of the signed-in adult; names their settings on this device.
  final String userId;

  /// The circle's photos and clips on this device.
  final MediaStore? media;

  /// Says a word in its recorded voice when the clip is on this device.
  final TileSpeaker? speaker;

  /// Camera, photo library and microphone. Null for a read-only partner.
  final MediaCapture? capture;

  /// Makes a live session for one screen, which starts and disposes it.
  /// Only the talker's session may share what is said, and only for a
  /// guardian.
  final ChorusLiveSession Function({required bool forTalker})? live;

  /// Suggests a word for a picked photo. Null for a read-only partner.
  final WordSuggester? suggester;

  /// Sends a snapshot of the board (see `printSnapshotJson`) to be kept as
  /// a printable page and completes with the page's address. Needs the
  /// network; throws when the page could not be made.
  final Future<String> Function(String boardJson)? publishBoard;

  /// The circle's opt-in word log on this device: the child's board calls
  /// `noteSpoken` on it, "Word log" shows and changes it, and its
  /// `private` flag pauses it and "Share what is said" for the session.
  final WordLog? wordLog;

  /// "This week" from the word log. Null where the adult's role may not
  /// see it (guardians and therapists may).
  final WeekSummarySource? summary;

  /// View-only links and .obf exports of a board. Null for a read-only
  /// partner.
  final BoardSharing? sharing;

  /// Adding, renaming, archiving and importing boards. Null for a read-only
  /// partner. The circle's `ReplicaBoardStore` is a [BoardManager] too, so
  /// a screen holding the store may use that instead; both write the same
  /// replica.
  final BoardManager? boards;

  /// "Try a clash", "Who is up to date" and "Under the hood".
  final TrustServices? trust;

  /// Modelled taps, focus words, the Thursday nudge and the progress
  /// report. Null leaves them out.
  final ModellingSource? modelling;

  /// The browser's speech recognition for "Listen" in model mode.
  final SpeechListener? speech;

  /// The circle's picture scenes, kept on this device. Null leaves
  /// "Scenes" out, on home and on the child's board.
  final SceneBook? scenes;

  /// Named board copies. Null leaves "Save a copy" and "Copies" out of the
  /// editor's board menu.
  final BoardCopies? copies;

  /// Words hidden from the child's board for now, kept on this device.
  final HiddenWords? hiddenWords;

  /// The circle's second language and its words, kept on this device.
  final HomeLanguages? languages;

  /// The device's voices for the second language.
  final LanguageVoice? languageVoice;

  /// The circle's voice, speed and pitch, kept on this device. Null leaves
  /// "Voice" out of "This device".
  final VoiceChoice? voice;

  /// The circle's quick phrases, kept on this device for use offline.
  /// Every role reads them; only editing roles change them.
  final QuickPhraseBook? quickPhrases;

  /// How often this device has spoken each word, for the keyboard's
  /// predictions. Kept on this device only.
  final SpokenWordCounts? wordCounts;
}

typedef WorkspaceOpener = Future<Workspace> Function();
