import 'dart:async';

import 'package:serverpod/serverpod.dart';

import '../circles/membership_guard.dart';
import '../generated/protocol.dart';

/// `text` of a presence event: the sender has just joined.
const presenceJoined = 'joined';

/// `text` of a presence event: the sender was already here. Sent in answer
/// to someone joining, and whenever a client sends a presence event itself.
const presenceHere = 'here';

/// `text` of a presence event: the sender's stream has closed.
const presenceLeft = 'left';

/// Longest `said` text relayed; anything longer is cut.
const maxSaidLength = 500;

/// The server-event channel of one circle's live session.
String liveChannel(UuidValue circleSpace) => 'chorus-live-${circleSpace.uuid}';

/// A live session between the members of a circle who are online together.
///
/// Everything here is ephemeral: events are relayed and never stored.
///
/// Events travel over Serverpod's server events, posted with local scope,
/// so this works on a single server instance without Redis. Members
/// connected to different instances would not see each other; running more
/// than one instance needs Redis and a different way to drop a sender's own
/// echo.
class LiveEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Joins the circle's live session.
  ///
  /// Each event the caller sends on [outgoing] is relayed to the other
  /// members currently joined, and theirs arrive on the returned stream. The
  /// server stamps `fromUser`, `fromName` and `at`; the caller's own values
  /// for those are ignored. Members only.
  ///
  /// "Other" means every other connection, so two devices signed in to the
  /// same account (a guardian's own device and the child's talker) do see
  /// each other's events.
  ///
  /// Presence events carry [presenceJoined], [presenceHere] or
  /// [presenceLeft] in `text`. The session lasts until the caller cancels
  /// the returned stream or disconnects; closing [outgoing] alone only stops
  /// the caller from sending.
  Stream<LiveEvent> join(
    Session session,
    UuidValue circleSpace,
    Stream<LiveEvent> outgoing,
  ) async* {
    final membership = await requireMember(session, circleSpace);
    final me = membership.userId;
    final name = membership.displayName;
    final channel = liveChannel(circleSpace);
    final central = session.server.messageCentral;

    final incoming = StreamController<LiveEvent>();
    // The event this connection is posting right now. Local delivery is
    // synchronous and hands every listener the same object, so this is how
    // a connection recognises its own echo.
    LiveEvent? posting;
    var closed = false;

    void post(LiveKind kind, {UuidValue? tileId, String? text}) {
      final event = LiveEvent(
        kind: kind,
        tileId: tileId,
        text: text,
        fromUser: me,
        fromName: name,
        at: DateTime.now().toUtc(),
      );
      posting = event;
      try {
        // Local scope completes synchronously; there is nothing to await.
        unawaited(
          central.postMessage(channel, event, scope: MessageScope.local),
        );
      } finally {
        posting = null;
      }
    }

    void onEvent(dynamic message) {
      if (closed || message is! LiveEvent || identical(message, posting)) {
        return;
      }
      incoming.add(message);
      if (message.kind != LiveKind.presence) return;
      // Tell a newcomer who is already here. And if another device of this
      // same member just left, say this one is still here.
      final joined = message.text == presenceJoined;
      final myOtherDeviceLeft =
          message.text == presenceLeft && message.fromUser == me;
      if (joined || myOtherDeviceLeft) {
        // After the current delivery has finished, never in the middle of it.
        scheduleMicrotask(() {
          if (!closed) post(LiveKind.presence, text: presenceHere);
        });
      }
    }

    /// Relays one event from the caller, keeping only what its kind needs.
    void relay(LiveEvent event) {
      if (closed) return;
      switch (event.kind) {
        case LiveKind.pulse:
          final tileId = event.tileId;
          if (tileId != null) post(LiveKind.pulse, tileId: tileId);
        case LiveKind.said:
          // Relayed exactly when the client chose to send it; the client
          // owns the sharing switch. Never logged, never stored.
          final text = event.text?.trim() ?? '';
          if (text.isEmpty) return;
          post(
            LiveKind.said,
            text: text.length > maxSaidLength
                ? text.substring(0, maxSaidLength)
                : text,
          );
        case LiveKind.presence:
          post(LiveKind.presence, text: presenceHere);
      }
    }

    session.messages.addListener(channel, onEvent);
    final sending = outgoing.listen(relay, onError: (Object _) {});

    Future<void> leave() async {
      if (closed) return;
      closed = true;
      session.messages.removeListener(channel, onEvent);
      await sending.cancel();
      post(LiveKind.presence, text: presenceLeft);
      unawaited(incoming.close());
    }

    incoming.onCancel = leave;
    post(LiveKind.presence, text: presenceJoined);
    try {
      yield* incoming.stream;
    } finally {
      await leave();
    }
  }
}
