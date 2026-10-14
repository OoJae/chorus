/// Modelling and "Listen" for one circle, made for the app's
/// `CircleServices`.
library;

import 'package:chorus_client/chorus_client.dart' hide CircleRole;
import 'package:chorus_ui/contracts.dart' show SyncStatus;
import 'package:chorus_ui/contracts_modelling.dart';
import 'package:chorus_ui/contracts_wordlog.dart';

import '../sync/adapters.dart' show roleOf;
import 'browser_speech_listener.dart';
import 'server_modelling.dart';

/// What [openModelling] made for one circle and adult.
typedef ModellingParts = ({ModellingSource source, SpeechListener speech});

/// Modelling over [client] for [circle] and the adult signed in as
/// [userId], logging modelled taps only while [log] is on and not private.
/// Holds no timer, so it needs no closing.
ModellingParts openModelling(
  Client client, {
  required CircleInfo circle,
  required String userId,
  WordLog? log,
  SyncStatus? sync,
}) => (
  source: ServerModelling(
    client: client,
    space: circle.spaceUuid,
    userId: userId,
    role: roleOf(circle.myRole),
    log: log,
    sync: sync,
  ),
  speech: browserSpeechListener(),
);
