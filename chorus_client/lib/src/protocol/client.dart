/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _ida;
import 'package:chorus_client/src/protocol/circles/circle_info.dart'
    as _icfd3qx2;
import 'package:chorus_client/src/protocol/circles/circle_role.dart'
    as _ixctvk32;
import 'package:chorus_client/src/protocol/circles/member_info.dart'
    as _iw7jhh88;
import 'package:chorus_client/src/protocol/circles/server_info.dart'
    as _i01ishb8;
import 'package:chorus_client/src/protocol/copies/board_copy_info.dart'
    as _if69lgi4;
import 'package:chorus_client/src/protocol/greetings/greeting.dart'
    as _ix52s3dn;
import 'package:chorus_client/src/protocol/live/live_event.dart' as _ij4123it;
import 'package:chorus_client/src/protocol/media/media_kind.dart' as _i1n9e0sn;
import 'package:chorus_client/src/protocol/media/upload_ticket.dart'
    as _i4yoz54l;
import 'package:chorus_client/src/protocol/modelling/focus_nudge_info.dart'
    as _illvav7f;
import 'package:chorus_client/src/protocol/modelling/focus_word_info.dart'
    as _ih7sffdq;
import 'package:chorus_client/src/protocol/practice/practice_word.dart'
    as _ijitwxif;
import 'package:chorus_client/src/protocol/scenes/scene_info.dart' as _iolb456x;
import 'package:chorus_client/src/protocol/scenes/scene_spot_info.dart'
    as _ipq9e2w5;
import 'package:chorus_client/src/protocol/sharing/view_only_link.dart'
    as _i15qvapk;
import 'package:chorus_client/src/protocol/sitter/sitter_tap_info.dart'
    as _ixcw47ye;
import 'package:chorus_client/src/protocol/suggest/word_suggestion.dart'
    as _igbppnkp;
import 'package:chorus_client/src/protocol/summary/week_report.dart'
    as _iqxiegs0;
import 'package:chorus_client/src/protocol/trust/device_status.dart'
    as _ilm3njl8;
import 'package:chorus_client/src/protocol/voice/voice_setting.dart'
    as _iqh4kkre;
import 'package:chorus_client/src/protocol/word_suggestions/suggested_word_info.dart'
    as _iov4dup2;
import 'package:chorus_client/src/protocol/wordlog/word_log_status.dart'
    as _izr7qg8x;
import 'package:chorus_client/src/protocol/wordlog/word_use_entry.dart'
    as _iyisc6zi;
import 'package:chorus_client/src/protocol/wordsettings/second_language.dart'
    as _inmagbl8;
import 'package:chorus_client/src/protocol/wordsettings/word_translation.dart'
    as _ia8zarzx;
import 'package:http/http.dart' as _i85jenna;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _iacc;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _iaic;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'package:serverpod_database/serverpod_database.dart' as _isd;
import 'package:serverpod_offline_sync_client/serverpod_offline_sync_client.dart'
    as _ipulbpi2;
import 'protocol.dart' as _il2as5qe;
import 'sync_tables.dart' as _ii3f3u05;
import 'package:chorus_client/migrations/migration_registry.dart';

/// By extending [EmailIdpBaseEndpoint], the email identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
/// {@category Endpoint}
class EndpointEmailIdp extends _iaic.EndpointEmailIdpBase {
  EndpointEmailIdp(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'emailIdp';

  /// Logs in the user and returns a new session.
  ///
  /// Throws an [EmailAccountLoginException] in case of errors, with reason:
  /// - [EmailAccountLoginExceptionReason.invalidCredentials] if the email or
  ///   password is incorrect.
  /// - [EmailAccountLoginExceptionReason.tooManyAttempts] if there have been
  ///   too many failed login attempts.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _ida.Future<_iacc.AuthSuccess> login({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
    'emailIdp',
    'login',
    {
      'email': email,
      'password': password,
    },
  );

  /// Starts the registration for a new user account with an email-based login
  /// associated to it.
  ///
  /// Upon successful completion of this method, an email will have been
  /// sent to [email] with a verification link, which the user must open to
  /// complete the registration.
  ///
  /// Always returns a account request ID, which can be used to complete the
  /// registration. If the email is already registered, the returned ID will not
  /// be valid.
  @override
  _ida.Future<_isc.UuidValue> startRegistration({required String email}) =>
      caller.callServerEndpoint<_isc.UuidValue>(
        'emailIdp',
        'startRegistration',
        {'email': email},
      );

  /// Verifies an account request code and returns a token
  /// that can be used to complete the account creation.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if no request exists
  ///   for the given [accountRequestId] or [verificationCode] is invalid.
  @override
  _ida.Future<String> verifyRegistrationCode({
    required _isc.UuidValue accountRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyRegistrationCode',
    {
      'accountRequestId': accountRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a new account registration, creating a new auth user with a
  /// profile and attaching the given email account to it.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if the [registrationToken]
  ///   is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  ///
  /// Returns a session for the newly created user.
  @override
  _ida.Future<_iacc.AuthSuccess> finishRegistration({
    required String registrationToken,
    required String password,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
    'emailIdp',
    'finishRegistration',
    {
      'registrationToken': registrationToken,
      'password': password,
    },
  );

  /// Requests a password reset for [email].
  ///
  /// If the email address is registered, an email with reset instructions will
  /// be send out. If the email is unknown, this method will have no effect.
  ///
  /// Always returns a password reset request ID, which can be used to complete
  /// the reset. If the email is not registered, the returned ID will not be
  /// valid.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to request a password reset.
  ///
  @override
  _ida.Future<_isc.UuidValue> startPasswordReset({required String email}) =>
      caller.callServerEndpoint<_isc.UuidValue>(
        'emailIdp',
        'startPasswordReset',
        {'email': email},
      );

  /// Verifies a password reset code and returns a finishPasswordResetToken
  /// that can be used to finish the password reset.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to verify the password reset.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// If multiple steps are required to complete the password reset, this endpoint
  /// should be overridden to return credentials for the next step instead
  /// of the credentials for setting the password.
  @override
  _ida.Future<String> verifyPasswordResetCode({
    required _isc.UuidValue passwordResetRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyPasswordResetCode',
    {
      'passwordResetRequestId': passwordResetRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a password reset request by setting a new password.
  ///
  /// The [verificationCode] returned from [verifyPasswordResetCode] is used to
  /// validate the password reset request.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.policyViolation] if the new
  ///   password does not comply with the password policy.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _ida.Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) => caller.callServerEndpoint<void>(
    'emailIdp',
    'finishPasswordReset',
    {
      'finishPasswordResetToken': finishPasswordResetToken,
      'newPassword': newPassword,
    },
  );

  @override
  _ida.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'emailIdp',
    'hasAccount',
    {},
  );
}

/// By extending [RefreshJwtTokensEndpoint], the JWT token refresh endpoint
/// is made available on the server and enables automatic token refresh on the client.
/// {@category Endpoint}
class EndpointJwtRefresh extends _iacc.EndpointRefreshJwtTokens {
  EndpointJwtRefresh(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'jwtRefresh';

  /// Creates a new token pair for the given [refreshToken].
  ///
  /// If [refreshToken] is omitted, cookie-mode web clients fall back to the
  /// configured HttpOnly refresh cookie. When neither source is present this
  /// throws [RefreshTokenNotFoundException], the same public "no usable refresh
  /// credential" exception used for unknown refresh tokens.
  ///
  /// Can throw the following exceptions:
  /// -[RefreshTokenMalformedException]: refresh token is malformed and could
  ///   not be parsed. Not expected to happen for tokens issued by the server.
  /// -[RefreshTokenNotFoundException]: refresh token is unknown to the server.
  ///   Either the token was deleted or generated by a different server.
  /// -[RefreshTokenExpiredException]: refresh token has expired. Will happen
  ///   only if it has not been used within configured `refreshTokenLifetime`.
  /// -[RefreshTokenInvalidSecretException]: refresh token is incorrect, meaning
  ///   it does not refer to the current secret refresh token. This indicates
  ///   either a malfunctioning client or a malicious attempt by someone who has
  ///   obtained the refresh token. In this case the underlying refresh token
  ///   will be deleted, and access to it will expire fully when the last access
  ///   token is elapsed.
  ///
  /// This endpoint is unauthenticated, meaning the client won't include any
  /// authentication information with the call.
  @override
  _ida.Future<_iacc.AuthSuccess> refreshAccessToken({String? refreshToken}) =>
      caller.callServerEndpoint<_iacc.AuthSuccess>(
        'jwtRefresh',
        'refreshAccessToken',
        {'refreshToken': refreshToken},
        authenticated: false,
      );
}

/// Creates circles and decides who is in them.
///
/// The sync module owns the data rules of a shared space (who may read and
/// write); it deliberately performs no authorization of its own. This
/// endpoint is where the app's policy lives: only a guardian may invite, and
/// the caller's identity always comes from the authenticated session.
/// {@category Endpoint}
class EndpointCircle extends _isc.EndpointRef {
  EndpointCircle(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'circle';

  /// Creates a circle for [childName] with the caller as its guardian.
  ///
  /// The circle's boards live in a new shared sync space. The caller's client
  /// seeds the starter board after its next sync delivers that space.
  _ida.Future<_icfd3qx2.CircleInfo> createCircle(
    String childName,
    String displayName,
  ) => caller.callServerEndpoint<_icfd3qx2.CircleInfo>(
    'circle',
    'createCircle',
    {
      'childName': childName,
      'displayName': displayName,
    },
  );

  /// Every circle the caller belongs to, oldest first.
  _ida.Future<List<_icfd3qx2.CircleInfo>> myCircles() =>
      caller.callServerEndpoint<List<_icfd3qx2.CircleInfo>>(
        'circle',
        'myCircles',
        {},
      );

  /// Creates a single-use code that lets one more adult join [circleSpace]
  /// with [role]. Only a guardian may invite.
  _ida.Future<String> createInvite(
    _isc.UuidValue circleSpace,
    _ixctvk32.CircleRole role,
  ) => caller.callServerEndpoint<String>(
    'circle',
    'createInvite',
    {
      'circleSpace': circleSpace,
      'role': role,
    },
  );

  /// Joins the circle that [code] was issued for.
  ///
  /// Grants the caller read-write or read-only access to the circle's sync
  /// space according to the invited role. A caller who is already a member
  /// keeps their existing role.
  _ida.Future<_icfd3qx2.CircleInfo> acceptInvite(
    String code,
    String displayName,
  ) => caller.callServerEndpoint<_icfd3qx2.CircleInfo>(
    'circle',
    'acceptInvite',
    {
      'code': code,
      'displayName': displayName,
    },
  );
}

/// What a client checks before it starts syncing. No sign-in needed.
/// {@category Endpoint}
class EndpointStatus extends _isc.EndpointRef {
  EndpointStatus(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'status';

  _ida.Future<_i01ishb8.ServerInfo> info() =>
      caller.callServerEndpoint<_i01ishb8.ServerInfo>(
        'status',
        'info',
        {},
      );
}

/// Named copies of a board, such as "Before the school trip".
///
/// A copy keeps the board's placed words as the server holds them when it
/// is taken. Taking, reading or deleting one never touches the board: a
/// word is put back on the adult's own device, through "Needs a home".
///
/// Each method throws [CircleException] with `notAMember` for someone
/// outside the circle, and with `notAllowed` for a read-only partner who
/// takes or deletes a copy, or for a name or board the rules refuse.
/// {@category Endpoint}
class EndpointBoardCopy extends _isc.EndpointRef {
  EndpointBoardCopy(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'boardCopy';

  /// Takes a copy of the board [boardId] called [name]. Editing roles
  /// only. Refused for a board the circle does not have in use, a name
  /// `copyNameProblem` refuses, and a circle that already keeps
  /// [maxCopiesPerCircle] copies.
  _ida.Future<_if69lgi4.BoardCopyInfo> take(
    _isc.UuidValue circleSpace,
    _isc.UuidValue boardId,
    String name,
  ) => caller.callServerEndpoint<_if69lgi4.BoardCopyInfo>(
    'boardCopy',
    'take',
    {
      'circleSpace': circleSpace,
      'boardId': boardId,
      'name': name,
    },
  );

  /// The circle's copies, newest first, without their words. Members
  /// only.
  _ida.Future<List<_if69lgi4.BoardCopyInfo>> list(_isc.UuidValue circleSpace) =>
      caller.callServerEndpoint<List<_if69lgi4.BoardCopyInfo>>(
        'boardCopy',
        'list',
        {'circleSpace': circleSpace},
      );

  /// The copy [copyId] with its words, or null when the circle has no such
  /// copy. Members only.
  _ida.Future<_if69lgi4.BoardCopyInfo?> get(
    _isc.UuidValue circleSpace,
    int copyId,
  ) => caller.callServerEndpoint<_if69lgi4.BoardCopyInfo?>(
    'boardCopy',
    'get',
    {
      'circleSpace': circleSpace,
      'copyId': copyId,
    },
  );

  /// Deletes the copy [copyId]. The board is not touched. Editing roles
  /// only. Returns false when the circle has no such copy.
  _ida.Future<bool> delete(
    _isc.UuidValue circleSpace,
    int copyId,
  ) => caller.callServerEndpoint<bool>(
    'boardCopy',
    'delete',
    {
      'circleSpace': circleSpace,
      'copyId': copyId,
    },
  );
}

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _isc.EndpointRef {
  EndpointGreeting(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _ida.Future<_ix52s3dn.Greeting> hello(String name) =>
      caller.callServerEndpoint<_ix52s3dn.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

/// A live session between the members of a circle who are online together.
///
/// Everything here is ephemeral: events are relayed and never stored.
///
/// Events travel over Serverpod's server events, posted with local scope,
/// so this works on a single server instance without Redis. Members
/// connected to different instances would not see each other; running more
/// than one instance needs Redis and a different way to drop a sender's own
/// echo.
/// {@category Endpoint}
class EndpointLive extends _isc.EndpointRef {
  EndpointLive(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'live';

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
  _ida.Stream<_ij4123it.LiveEvent> join(
    _isc.UuidValue circleSpace,
    _ida.Stream<_ij4123it.LiveEvent> outgoing,
  ) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_ij4123it.LiveEvent>,
        _ij4123it.LiveEvent
      >(
        'live',
        'join',
        {'circleSpace': circleSpace},
        {'outgoing': outgoing},
      );
}

/// Family photos and recorded voices, stored privately per circle.
///
/// A file is named by the SHA-256 of its bytes, so the same picture is stored
/// once and a tile only carries the hash. Bytes go straight to private
/// storage with a ticket; nothing is handed out until the server has checked
/// them against the hash.
/// {@category Endpoint}
class EndpointMedia extends _isc.EndpointRef {
  EndpointMedia(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'media';

  /// Asks to upload a file of [bytes] bytes whose content hashes to [sha256]
  /// (lowercase hex). Editing roles only.
  ///
  /// The ticket's `uploadDescription` is null when the circle already holds
  /// verified bytes for this hash; the caller then skips the upload.
  ///
  /// Throws [CircleException] with `notAllowed` when the hash is not a
  /// lowercase SHA-256, or [bytes] is zero or over the cap for [kind]
  /// (images 400 KB, audio 600 KB).
  _ida.Future<_i4yoz54l.UploadTicket> requestUpload(
    _isc.UuidValue circleSpace,
    String sha256,
    _i1n9e0sn.MediaKind kind,
    int bytes,
  ) => caller.callServerEndpoint<_i4yoz54l.UploadTicket>(
    'media',
    'requestUpload',
    {
      'circleSpace': circleSpace,
      'sha256': sha256,
      'kind': kind,
      'bytes': bytes,
    },
  );

  /// Checks the uploaded bytes against [sha256] and marks the file verified.
  /// Editing roles only. Returns false when the upload is missing or does not
  /// match its hash.
  _ida.Future<bool> confirmUpload(
    _isc.UuidValue circleSpace,
    String sha256,
  ) => caller.callServerEndpoint<bool>(
    'media',
    'confirmUpload',
    {
      'circleSpace': circleSpace,
      'sha256': sha256,
    },
  );

  /// Short-lived download links, keyed by hash, for those of [hashes] that
  /// are verified files of this circle. Unknown hashes are left out.
  _ida.Future<Map<String, String>> downloadUrls(
    _isc.UuidValue circleSpace,
    List<String> hashes,
  ) => caller.callServerEndpoint<Map<String, String>>(
    'media',
    'downloadUrls',
    {
      'circleSpace': circleSpace,
      'hashes': hashes,
    },
  );
}

/// Who is in a circle, and a guardian's way to remove someone.
/// {@category Endpoint}
class EndpointMembers extends _isc.EndpointRef {
  EndpointMembers(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'members';

  /// Everyone in [circleSpace], guardians first, then by name. Any member.
  _ida.Future<List<_iw7jhh88.MemberInfo>> list(_isc.UuidValue circleSpace) =>
      caller.callServerEndpoint<List<_iw7jhh88.MemberInfo>>(
        'members',
        'list',
        {'circleSpace': circleSpace},
      );

  /// Removes [userId] from [circleSpace]: their sync access is revoked,
  /// their membership deleted, and a live stream of theirs closes at once.
  /// The words they added stay. Codes they made that nobody used stop
  /// working, and the code they joined with does not let them back in
  /// (see `CircleEndpoint.acceptInvite`): coming back takes a new invite.
  /// Guardians only, and never themselves.
  ///
  /// Throws [CircleException] with `notAllowed` for a caller who is not a
  /// guardian or who names themselves, or when the demo needs [userId]
  /// where they are (see [isDemoProtected]), and `notAMember` when [userId]
  /// is not in the circle.
  _ida.Future<void> remove(
    _isc.UuidValue circleSpace,
    _isc.UuidValue userId,
  ) => caller.callServerEndpoint<void>(
    'members',
    'remove',
    {
      'circleSpace': circleSpace,
      'userId': userId,
    },
  );
}

/// Focus words of the week: up to three words a guardian or therapist pins,
/// each with a one-line modelling tip, and the Thursday nudge when one has
/// not been modelled yet. Adults only see them; the child's board stays
/// calm.
/// {@category Endpoint}
class EndpointFocus extends _isc.EndpointRef {
  EndpointFocus(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'focus';

  /// This week's focus words of [circleSpace], oldest pin first. Members.
  _ida.Future<List<_ih7sffdq.FocusWordInfo>> words(
    _isc.UuidValue circleSpace,
  ) => caller.callServerEndpoint<List<_ih7sffdq.FocusWordInfo>>(
    'focus',
    'words',
    {'circleSpace': circleSpace},
  );

  /// Replaces this week's focus words of [circleSpace] with [pins] (their
  /// `weekStart` is ignored) and returns them as kept. Guardians and
  /// therapists only.
  ///
  /// Throws [CircleException] with `notAllowed` for another role, more than
  /// three words, the same word twice, a tip over 120 characters, or a
  /// word that is not on one of the circle's boards.
  _ida.Future<List<_ih7sffdq.FocusWordInfo>> setWords(
    _isc.UuidValue circleSpace,
    List<_ih7sffdq.FocusWordInfo> pins,
  ) => caller.callServerEndpoint<List<_ih7sffdq.FocusWordInfo>>(
    'focus',
    'setWords',
    {
      'circleSpace': circleSpace,
      'pins': pins,
    },
  );

  /// This week's nudge for [circleSpace]: a focus word nobody had modelled
  /// by Thursday and still has not, or null. Members.
  _ida.Future<_illvav7f.FocusNudgeInfo?> nudge(_isc.UuidValue circleSpace) =>
      caller.callServerEndpoint<_illvav7f.FocusNudgeInfo?>(
        'focus',
        'nudge',
        {'circleSpace': circleSpace},
      );
}

/// "Try a clash": a practice partner that puts a word into one cell of the
/// circle's board, so one adult with one device can watch two offline
/// claims on the same cell both survive.
///
/// The partner is a member of the circle's sync space and nothing else: it
/// has no account and no [Membership], so it never appears in the circle's
/// list of adults and can never sign in. Its id is derived from the circle,
/// so every circle has exactly one partner and every word it writes carries
/// the same author.
/// {@category Endpoint}
class EndpointPractice extends _isc.EndpointRef {
  EndpointPractice(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'practice';

  /// Has the practice partner put a word into [cellKey] of board [boardId]
  /// in [circleSpace], on the server, as another adult's device would.
  /// Editing roles only.
  ///
  /// Throws [PracticeException] with `cellTaken` when the server already
  /// holds a word there (the caller picks another empty cell), `noSuchCell`
  /// when the board or cell is not in the circle, and `tooMany` after
  /// [hourlyLimit] words in the last hour.
  _ida.Future<_ijitwxif.PracticeWord> partnerWord(
    _isc.UuidValue circleSpace,
    _isc.UuidValue boardId,
    String cellKey,
  ) => caller.callServerEndpoint<_ijitwxif.PracticeWord>(
    'practice',
    'partnerWord',
    {
      'circleSpace': circleSpace,
      'boardId': boardId,
      'cellKey': cellKey,
    },
  );
}

/// Paper backups of a board.
/// {@category Endpoint}
class EndpointPrinting extends _isc.EndpointRef {
  EndpointPrinting(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'printing';

  /// Stores [boardJson], a snapshot the caller built from its own replica,
  /// and returns an unguessable token. `GET /print/<token>` on the web server
  /// renders the snapshot as a printable page. Members only.
  ///
  /// The link works for 30 days. Throws [CircleException] with `notAllowed`
  /// when the snapshot is over 200 KB or is not a board the page can lay out
  /// (see `print_page.dart` for the format).
  _ida.Future<String> publishBoard(
    _isc.UuidValue circleSpace,
    String boardJson,
  ) => caller.callServerEndpoint<String>(
    'printing',
    'publishBoard',
    {
      'circleSpace': circleSpace,
      'boardJson': boardJson,
    },
  );

  /// The address of the printable page for [token], on the web server as
  /// the outside world reaches it. The app's own server address is the API
  /// server's, which does not serve the page, so a phone has to ask.
  ///
  /// Reads no data: the answer is the same for a token that does not exist.
  /// Throws [CircleException] with `notAllowed` for text that is not a
  /// token.
  _ida.Future<String> pageUrl(String token) =>
      caller.callServerEndpoint<String>(
        'printing',
        'pageUrl',
        {'token': token},
      );
}

/// The one-page progress report: this week's counts, kept behind a token so
/// it can be opened and printed anywhere. Counts only, never a transcript.
/// {@category Endpoint}
class EndpointProgress extends _isc.EndpointRef {
  EndpointProgress(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'progress';

  /// Works out this week's report for [circleSpace], keeps it behind a new
  /// token for 30 days, and returns the token. Guardians and therapists
  /// only, as for "This week".
  _ida.Future<String> makeReport(_isc.UuidValue circleSpace) =>
      caller.callServerEndpoint<String>(
        'progress',
        'makeReport',
        {'circleSpace': circleSpace},
      );

  /// The address of the report page for [token] on this server's web
  /// server. Throws [CircleException] (`notAllowed`) for a malformed token.
  _ida.Future<String> reportUrl(String token) =>
      caller.callServerEndpoint<String>(
        'progress',
        'reportUrl',
        {'token': token},
      );
}

/// A circle's quick phrases: the few whole sentences the child's board says
/// at once ("Stop", "Help", "I'm hurt"). Every member reads them; editing
/// roles change them. Kept on the server only, never synced: each device
/// keeps its own copy for when it is offline.
/// {@category Endpoint}
class EndpointQuickPhrase extends _isc.EndpointRef {
  EndpointQuickPhrase(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'quickPhrase';

  /// The circle's phrases in order, or the defaults when it has none of its
  /// own. Members only.
  _ida.Future<List<String>> list(_isc.UuidValue circleSpace) =>
      caller.callServerEndpoint<List<String>>(
        'quickPhrase',
        'list',
        {'circleSpace': circleSpace},
      );

  /// Replaces the circle's phrases with [phrases], in that order, and
  /// returns what was kept: trimmed, without empties or repeats, at most
  /// `maxQuickPhrases`, each at most `maxQuickPhraseLength` long (see
  /// `cleanQuickPhrases`). An empty list puts the defaults back. Editing
  /// roles only: a read-only partner is refused with `notAllowed`.
  _ida.Future<List<String>> set(
    _isc.UuidValue circleSpace,
    List<String> phrases,
  ) => caller.callServerEndpoint<List<String>>(
    'quickPhrase',
    'set',
    {
      'circleSpace': circleSpace,
      'phrases': phrases,
    },
  );
}

/// Picture scenes: a family photo with spots that speak when the child taps
/// them. Every member may list them; editing roles make and change them.
///
/// Each method throws [CircleException] with `notAMember` for someone
/// outside the circle, and with `notAllowed` for a read-only partner who
/// tries to change something, for a scene that is not one of the circle's
/// scenes in use, and for a name, photo or spot the rules refuse.
/// {@category Endpoint}
class EndpointScene extends _isc.EndpointRef {
  EndpointScene(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'scene';

  /// The circle's scenes in use, oldest first, each with its spots in the
  /// order they were drawn. Members only.
  _ida.Future<List<_iolb456x.SceneInfo>> list(_isc.UuidValue circleSpace) =>
      caller.callServerEndpoint<List<_iolb456x.SceneInfo>>(
        'scene',
        'list',
        {'circleSpace': circleSpace},
      );

  /// Makes a scene called [name] from the photo with hash [imageHash], with
  /// no spots yet. Editing roles only.
  ///
  /// The photo may still be on its way from the adult's device: like a
  /// tile's picture, it is shown wherever it has arrived.
  _ida.Future<_iolb456x.SceneInfo> create(
    _isc.UuidValue circleSpace,
    String name,
    String imageHash,
  ) => caller.callServerEndpoint<_iolb456x.SceneInfo>(
    'scene',
    'create',
    {
      'circleSpace': circleSpace,
      'name': name,
      'imageHash': imageHash,
    },
  );

  /// Renames the scene [sceneId]. Editing roles only.
  _ida.Future<_iolb456x.SceneInfo> rename(
    _isc.UuidValue circleSpace,
    int sceneId,
    String name,
  ) => caller.callServerEndpoint<_iolb456x.SceneInfo>(
    'scene',
    'rename',
    {
      'circleSpace': circleSpace,
      'sceneId': sceneId,
      'name': name,
    },
  );

  /// Archives the scene [sceneId]: it leaves every device's list. Nothing
  /// is deleted. Editing roles only. Returns false when it was already
  /// archived.
  _ida.Future<bool> archive(
    _isc.UuidValue circleSpace,
    int sceneId,
  ) => caller.callServerEndpoint<bool>(
    'scene',
    'archive',
    {
      'circleSpace': circleSpace,
      'sceneId': sceneId,
    },
  );

  /// Replaces every spot of the scene [sceneId] with [spots], in that
  /// order, all or nothing. Editing roles only.
  ///
  /// Each spot must lie on the photo with each side at least `minSpotSide`
  /// and carry a word the tile rules accept; at most [maxSpotsPerScene].
  _ida.Future<_iolb456x.SceneInfo> setSpots(
    _isc.UuidValue circleSpace,
    int sceneId,
    List<_ipq9e2w5.SceneSpotInfo> spots,
  ) => caller.callServerEndpoint<_iolb456x.SceneInfo>(
    'scene',
    'setSpots',
    {
      'circleSpace': circleSpace,
      'sceneId': sceneId,
      'spots': spots,
    },
  );
}

/// Sharing a board with someone outside the circle, such as a babysitter:
/// a page that speaks, and the same board as an .obf file.
/// {@category Endpoint}
class EndpointSharing extends _isc.EndpointRef {
  EndpointSharing(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'sharing';

  /// Stores [boardJson], a snapshot the caller built from its own replica
  /// (the paper copy's format, with `speech` where a tile says something
  /// other than its label), and returns the link to its view-only page.
  /// Editing roles only.
  ///
  /// The page opens for 7 days, unless withdrawn sooner. Throws
  /// [CircleException] with `notAllowed` when the snapshot is over 200 KB or
  /// is not a board the page can lay out.
  _ida.Future<_i15qvapk.ViewOnlyLink> publishViewOnly(
    _isc.UuidValue circleSpace,
    String boardJson,
  ) => caller.callServerEndpoint<_i15qvapk.ViewOnlyLink>(
    'sharing',
    'publishViewOnly',
    {
      'circleSpace': circleSpace,
      'boardJson': boardJson,
    },
  );

  /// Stops the page and the file behind [token] opening, now. Works for any
  /// link of the circle, paper copies included. Editing roles only.
  ///
  /// Returns false when there was nothing to withdraw: the link is unknown,
  /// belongs to another circle, or had already stopped. Throws
  /// [CircleException] with `notAllowed` for text that is not a token.
  _ida.Future<bool> withdraw(
    _isc.UuidValue circleSpace,
    String token,
  ) => caller.callServerEndpoint<bool>(
    'sharing',
    'withdraw',
    {
      'circleSpace': circleSpace,
      'token': token,
    },
  );

  /// The address of the .obf file for [token], on the web server as the
  /// outside world reaches it. Works for paper-copy tokens too.
  ///
  /// Reads no data: the answer is the same for a token that does not exist.
  /// Throws [CircleException] with `notAllowed` for text that is not a
  /// token.
  _ida.Future<String> exportUrl(String token) =>
      caller.callServerEndpoint<String>(
        'sharing',
        'exportUrl',
        {'token': token},
      );
}

/// What sitters tapped, for the circle's "What changed".
/// {@category Endpoint}
class EndpointSitter extends _isc.EndpointRef {
  EndpointSitter(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'sitter';

  /// The words sitters tapped on [circleSpace]'s view-only pages in the
  /// last week, newest first. Guardians and therapists only, as for the
  /// word log's "This week".
  _ida.Future<List<_ixcw47ye.SitterTapInfo>> recentTaps(
    _isc.UuidValue circleSpace,
  ) => caller.callServerEndpoint<List<_ixcw47ye.SitterTapInfo>>(
    'sitter',
    'recentTaps',
    {'circleSpace': circleSpace},
  );
}

/// Optional help for adults: a word suggested for a photo.
///
/// The suggestion is only returned to the adult who asked. Nothing reaches a
/// board until they approve it on their own device.
/// {@category Endpoint}
class EndpointSuggest extends _isc.EndpointRef {
  EndpointSuggest(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'suggest';

  /// Suggests a word, in the language of [locale], for the circle's verified
  /// image with hash [imageSha256]. Editing roles only.
  ///
  /// Throws [SuggestException] when the service is not set up, the circle is
  /// over its daily budget, the photo cannot be read, or the call fails.
  _ida.Future<_igbppnkp.WordSuggestion> fromPhoto(
    _isc.UuidValue circleSpace,
    String imageSha256,
    String locale,
  ) => caller.callServerEndpoint<_igbppnkp.WordSuggestion>(
    'suggest',
    'fromPhoto',
    {
      'circleSpace': circleSpace,
      'imageSha256': imageSha256,
      'locale': locale,
    },
  );

  /// Suggests 3 to 6 words across word types (things, actions, describing
  /// words), each with a part-of-speech colour key, for the circle's
  /// verified image [imageSha256]. Ideas for one photo are kept for a day.
  /// Editing roles only. Nothing is placed: an adult confirms each word.
  ///
  /// Throws [SuggestException] as [fromPhoto] does.
  _ida.Future<List<_igbppnkp.WordSuggestion>> ideasFromPhoto(
    _isc.UuidValue circleSpace,
    String imageSha256,
    String locale,
  ) => caller.callServerEndpoint<List<_igbppnkp.WordSuggestion>>(
    'suggest',
    'ideasFromPhoto',
    {
      'circleSpace': circleSpace,
      'imageSha256': imageSha256,
      'locale': locale,
    },
  );
}

/// "This week": what the word log says about one week, for the adults who
/// plan the child's words.
/// {@category Endpoint}
class EndpointSummary extends _isc.EndpointRef {
  EndpointSummary(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'summary';

  /// The week from Monday 00:00 UTC of the week [weekStart] falls in (this
  /// week when null) for [circleSpace]: most used words, words used for the
  /// first time, words added, words not used yet, and the totals. Guardians
  /// and therapists only.
  ///
  /// A week the weekly job already worked out is read as stored; any other
  /// is worked out now, so nothing depends on the job running. Throws
  /// [CircleException] with `notAllowed` for teachers and partners.
  _ida.Future<_iqxiegs0.WeekReport> week(
    _isc.UuidValue circleSpace, [
    DateTime? weekStart,
  ]) => caller.callServerEndpoint<_iqxiegs0.WeekReport>(
    'summary',
    'week',
    {
      'circleSpace': circleSpace,
      'weekStart': weekStart,
    },
  );
}

/// "Who is up to date": when each member's devices last synced a circle.
///
/// Each device reports itself after a successful sync with [heartbeat];
/// any member may read the list with [devices]. Nothing here holds a word.
/// {@category Endpoint}
class EndpointDeviceSeen extends _isc.EndpointRef {
  EndpointDeviceSeen(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'deviceSeen';

  /// Records that the caller's device [deviceId], described as
  /// [deviceLabel], finished a sync of [circleSpace] at [lastSyncAt]. Any
  /// member, read-only partners included: their devices sync too.
  _ida.Future<void> heartbeat(
    _isc.UuidValue circleSpace,
    String deviceId,
    String deviceLabel,
    DateTime lastSyncAt,
  ) => caller.callServerEndpoint<void>(
    'deviceSeen',
    'heartbeat',
    {
      'circleSpace': circleSpace,
      'deviceId': deviceId,
      'deviceLabel': deviceLabel,
      'lastSyncAt': lastSyncAt,
    },
  );

  /// Every device that has reported a sync of [circleSpace], most recently
  /// synced first. Any member.
  _ida.Future<List<_ilm3njl8.DeviceStatus>> devices(
    _isc.UuidValue circleSpace,
  ) => caller.callServerEndpoint<List<_ilm3njl8.DeviceStatus>>(
    'deviceSeen',
    'devices',
    {'circleSpace': circleSpace},
  );
}

/// The voice, speed and pitch the child speaks with, the same on every
/// device of the circle.
/// {@category Endpoint}
class EndpointVoice extends _isc.EndpointRef {
  EndpointVoice(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'voice';

  /// [circleSpace]'s voice: the defaults when nobody has chosen one. Any
  /// member may read it.
  _ida.Future<_iqh4kkre.VoiceSetting> getVoice(_isc.UuidValue circleSpace) =>
      caller.callServerEndpoint<_iqh4kkre.VoiceSetting>(
        'voice',
        'getVoice',
        {'circleSpace': circleSpace},
      );

  /// Chooses [circleSpace]'s voice. [voiceName] null is each device's own
  /// everyday voice; [rate] and [pitch] are kept within what every engine
  /// accepts. Editors only: a read-only partner gets [CircleException]
  /// with `notAllowed`.
  _ida.Future<_iqh4kkre.VoiceSetting> setVoice(
    _isc.UuidValue circleSpace,
    String? voiceName,
    double rate,
    double pitch,
  ) => caller.callServerEndpoint<_iqh4kkre.VoiceSetting>(
    'voice',
    'setVoice',
    {
      'circleSpace': circleSpace,
      'voiceName': voiceName,
      'rate': rate,
      'pitch': pitch,
    },
  );
}

/// Words suggested for the board by anyone in the circle, read-only members
/// included. A suggestion never reaches the board by itself: an editor adds
/// it through the normal add path, then chooses its spot.
/// {@category Endpoint}
class EndpointWordSuggestion extends _isc.EndpointRef {
  EndpointWordSuggestion(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'wordSuggestion';

  /// Suggests [label] (with optional [speech] and part-of-speech
  /// [colorKey]) for [circleSpace]'s board. Any member. Each text is cut to
  /// [maxSuggestedLabelLength] characters.
  ///
  /// Throws [CircleException] with `notAllowed` while the caller already
  /// has [maxOpenSuggestionsPerMember] suggestions waiting, or the circle
  /// [maxOpenSuggestionsPerCircle], so nobody can bury the others' words.
  _ida.Future<_iov4dup2.SuggestedWordInfo> suggest(
    _isc.UuidValue circleSpace,
    String label,
    String? speech,
    String? colorKey,
  ) => caller.callServerEndpoint<_iov4dup2.SuggestedWordInfo>(
    'wordSuggestion',
    'suggest',
    {
      'circleSpace': circleSpace,
      'label': label,
      'speech': speech,
      'colorKey': colorKey,
    },
  );

  /// The circle's open suggestions, oldest first. Editors only.
  _ida.Future<List<_iov4dup2.SuggestedWordInfo>> list(
    _isc.UuidValue circleSpace,
  ) => caller.callServerEndpoint<List<_iov4dup2.SuggestedWordInfo>>(
    'wordSuggestion',
    'list',
    {'circleSpace': circleSpace},
  );

  /// Answers suggestion [id]: [added] when an editor put it on the board,
  /// false when they said no. Editors only. Answering twice changes
  /// nothing.
  _ida.Future<void> resolve(
    _isc.UuidValue circleSpace,
    int id,
    bool added,
  ) => caller.callServerEndpoint<void>(
    'wordSuggestion',
    'resolve',
    {
      'circleSpace': circleSpace,
      'id': id,
      'added': added,
    },
  );
}

/// The opt-in word log: which tile the child's board spoke, and when.
///
/// Off until a guardian turns it on for the circle. It holds tile ids,
/// board ids and times only, never a label or a sentence, and a guardian can
/// delete it all at any time.
/// {@category Endpoint}
class EndpointWordLog extends _isc.EndpointRef {
  EndpointWordLog(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'wordLog';

  /// Whether [circleSpace] keeps a word log, and whether the caller may
  /// change that. Members only.
  _ida.Future<_izr7qg8x.WordLogStatus> status(_isc.UuidValue circleSpace) =>
      caller.callServerEndpoint<_izr7qg8x.WordLogStatus>(
        'wordLog',
        'status',
        {'circleSpace': circleSpace},
      );

  /// Turns the circle's word log on or off. Guardians only. Turning it off
  /// keeps what was logged; [deleteAll] removes it.
  ///
  /// Words spoken before the log was last turned on or off are not taken
  /// (see [record]), so asking for the state it is already in changes
  /// nothing, not even the time.
  _ida.Future<_izr7qg8x.WordLogStatus> setEnabled(
    _isc.UuidValue circleSpace,
    bool enabled,
  ) => caller.callServerEndpoint<_izr7qg8x.WordLogStatus>(
    'wordLog',
    'setEnabled',
    {
      'circleSpace': circleSpace,
      'enabled': enabled,
    },
  );

  /// Adds [uses] to the log and returns how many were new. Editing roles
  /// only, and only while the log is on.
  ///
  /// All or nothing: throws [WordLogException] and keeps none of the call
  /// when the log is off (`off`), there are more than 200 (`tooMany`), a
  /// time is more than five minutes ahead or more than 30 days old
  /// (`badTime`), or a tile is not one of the circle's (`unknownTile`). A
  /// word sent twice is kept once, so a batch can safely be sent again.
  /// Words of tiles marked "never log" are dropped quietly. The board is
  /// taken from the tile as the server holds it.
  ///
  /// Words spoken before the guardian last turned the log on or off, or
  /// deleted it, are dropped quietly too. A device that was offline, or
  /// never heard that its last batch arrived, still holds words; without
  /// this, sending them after a delete would put the deleted words back.
  _ida.Future<int> record(
    _isc.UuidValue circleSpace,
    List<_iyisc6zi.WordUseEntry> uses,
  ) => caller.callServerEndpoint<int>(
    'wordLog',
    'record',
    {
      'circleSpace': circleSpace,
      'uses': uses,
    },
  );

  /// Adds words an adult tapped in "Show words on the board" (model mode)
  /// as modelled, not said, and returns how many were new. The same rules
  /// and failures as [record]: editing roles only, only while the log is
  /// on, never words of tiles marked "never log". The device leaves them
  /// out in private mode.
  _ida.Future<int> recordModelled(
    _isc.UuidValue circleSpace,
    List<_iyisc6zi.WordUseEntry> uses,
  ) => caller.callServerEndpoint<int>(
    'wordLog',
    'recordModelled',
    {
      'circleSpace': circleSpace,
      'uses': uses,
    },
  );

  /// Removes the circle's whole word log for good, with the weeks worked
  /// out from it, the words sitters tapped and every progress report link.
  /// Guardians only. Returns how many words went.
  ///
  /// It also moves the log's start to now, so words a device still holds
  /// from before the delete are not taken when it sends them (see
  /// [record]).
  _ida.Future<int> deleteAll(_isc.UuidValue circleSpace) =>
      caller.callServerEndpoint<int>(
        'wordLog',
        'deleteAll',
        {'circleSpace': circleSpace},
      );
}

/// Words an adult has hidden from the child's board for now.
///
/// Server-only rows beside the frozen synced tables: hiding never moves a
/// word and never touches its tile. Any member may read the list (the
/// child's board must show what is hidden whoever is signed in on it); only
/// an editing role may change it.
/// {@category Endpoint}
class EndpointHiddenWords extends _isc.EndpointRef {
  EndpointHiddenWords(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'hiddenWords';

  /// Ids of the tiles hidden in [circleSpace]. Members only.
  _ida.Future<List<_isc.UuidValue>> list(_isc.UuidValue circleSpace) =>
      caller.callServerEndpoint<List<_isc.UuidValue>>(
        'hiddenWords',
        'list',
        {'circleSpace': circleSpace},
      );

  /// Hides ([hidden] true) or shows again the tile [tileId] of
  /// [circleSpace]. Editing roles only. Asking for the state it is already
  /// in changes nothing. The tile need not have reached the server yet: a
  /// word added offline can be hidden at once.
  _ida.Future<void> setHidden(
    _isc.UuidValue circleSpace,
    _isc.UuidValue tileId,
    bool hidden,
  ) => caller.callServerEndpoint<void>(
    'hiddenWords',
    'setHidden',
    {
      'circleSpace': circleSpace,
      'tileId': tileId,
      'hidden': hidden,
    },
  );
}

/// A circle's second (home) language and its words in it.
///
/// Any member may read them, so every board can show them; only an editing
/// role may change them.
/// {@category Endpoint}
class EndpointHomeLanguage extends _isc.EndpointRef {
  EndpointHomeLanguage(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'homeLanguage';

  /// The circle's second language, or null when it has none. Members only.
  _ida.Future<_inmagbl8.SecondLanguage?> getLanguage(
    _isc.UuidValue circleSpace,
  ) => caller.callServerEndpoint<_inmagbl8.SecondLanguage?>(
    'homeLanguage',
    'getLanguage',
    {'circleSpace': circleSpace},
  );

  /// Sets the circle's second language, or clears it with null. Editing
  /// roles only. Translations into another language are kept, so switching
  /// back brings them back.
  _ida.Future<void> setLanguage(
    _isc.UuidValue circleSpace,
    _inmagbl8.SecondLanguage? language,
  ) => caller.callServerEndpoint<void>(
    'homeLanguage',
    'setLanguage',
    {
      'circleSpace': circleSpace,
      'language': language,
    },
  );

  /// Every word of [circleSpace] in [languageCode]. Members only.
  _ida.Future<List<_ia8zarzx.WordTranslation>> listTranslations(
    _isc.UuidValue circleSpace,
    String languageCode,
  ) => caller.callServerEndpoint<List<_ia8zarzx.WordTranslation>>(
    'homeLanguage',
    'listTranslations',
    {
      'circleSpace': circleSpace,
      'languageCode': languageCode,
    },
  );

  /// Sets one word in a second language. An empty label removes it, so the
  /// word shows in the first language again. Editing roles only.
  _ida.Future<void> setTranslation(
    _isc.UuidValue circleSpace,
    _ia8zarzx.WordTranslation translation,
  ) => caller.callServerEndpoint<void>(
    'homeLanguage',
    'setTranslation',
    {
      'circleSpace': circleSpace,
      'translation': translation,
    },
  );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_idp = _iaic.Caller(client);
    offline_sync = _ipulbpi2.Caller(client);
    serverpod_auth_core = _iacc.Caller(client);
  }

  late final _iaic.Caller serverpod_auth_idp;

  late final _ipulbpi2.Caller offline_sync;

  late final _iacc.Caller serverpod_auth_core;
}

class Client extends _isc.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _isc.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_isc.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
    _i85jenna.Client? httpClientOverride,
  }) : super(
         host,
         _il2as5qe.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
         httpClientOverride: httpClientOverride,
       ) {
    emailIdp = EndpointEmailIdp(this);
    jwtRefresh = EndpointJwtRefresh(this);
    circle = EndpointCircle(this);
    status = EndpointStatus(this);
    boardCopy = EndpointBoardCopy(this);
    greeting = EndpointGreeting(this);
    live = EndpointLive(this);
    media = EndpointMedia(this);
    members = EndpointMembers(this);
    focus = EndpointFocus(this);
    practice = EndpointPractice(this);
    printing = EndpointPrinting(this);
    progress = EndpointProgress(this);
    quickPhrase = EndpointQuickPhrase(this);
    scene = EndpointScene(this);
    sharing = EndpointSharing(this);
    sitter = EndpointSitter(this);
    suggest = EndpointSuggest(this);
    summary = EndpointSummary(this);
    deviceSeen = EndpointDeviceSeen(this);
    voice = EndpointVoice(this);
    wordSuggestion = EndpointWordSuggestion(this);
    wordLog = EndpointWordLog(this);
    hiddenWords = EndpointHiddenWords(this);
    homeLanguage = EndpointHomeLanguage(this);
    modules = Modules(this);
  }

  late final EndpointEmailIdp emailIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointCircle circle;

  late final EndpointStatus status;

  late final EndpointBoardCopy boardCopy;

  late final EndpointGreeting greeting;

  late final EndpointLive live;

  late final EndpointMedia media;

  late final EndpointMembers members;

  late final EndpointFocus focus;

  late final EndpointPractice practice;

  late final EndpointPrinting printing;

  late final EndpointProgress progress;

  late final EndpointQuickPhrase quickPhrase;

  late final EndpointScene scene;

  late final EndpointSharing sharing;

  late final EndpointSitter sitter;

  late final EndpointSuggest suggest;

  late final EndpointSummary summary;

  late final EndpointDeviceSeen deviceSeen;

  late final EndpointVoice voice;

  late final EndpointWordSuggestion wordSuggestion;

  late final EndpointWordLog wordLog;

  late final EndpointHiddenWords hiddenWords;

  late final EndpointHomeLanguage homeLanguage;

  late final Modules modules;

  @override
  Map<String, _isc.EndpointRef> get endpointRefLookup => {
    'emailIdp': emailIdp,
    'jwtRefresh': jwtRefresh,
    'circle': circle,
    'status': status,
    'boardCopy': boardCopy,
    'greeting': greeting,
    'live': live,
    'media': media,
    'members': members,
    'focus': focus,
    'practice': practice,
    'printing': printing,
    'progress': progress,
    'quickPhrase': quickPhrase,
    'scene': scene,
    'sharing': sharing,
    'sitter': sitter,
    'suggest': suggest,
    'summary': summary,
    'deviceSeen': deviceSeen,
    'voice': voice,
    'wordSuggestion': wordSuggestion,
    'wordLog': wordLog,
    'hiddenWords': hiddenWords,
    'homeLanguage': homeLanguage,
  };

  @override
  Map<String, _isc.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'offline_sync': modules.offline_sync,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };

  /// Creates a new client-side database session for the given path.
  ///
  /// The [path] is the file path to the SQLite database file. Since SQLite uses
  /// WAL mode, note that `[path]-shm` and `[path]-wal` files might also exist
  /// transiently for the database while the session is open.
  ///
  /// If [runMigrations] is true, pending migrations will be applied when
  /// opening the database. Be careful when setting this to false, as it might
  /// lead to inconsistencies between the models and the database.
  ///
  /// If [isDebugMode] is true, the database integrity will be verified after
  /// the migrations are applied to provide feedback of possible issues. On a
  /// Flutter application, this should be set to [kDebugMode].
  _ida.Future<_isd.ClientDatabaseSession> createSession(
    String path, {
    bool runMigrations = true,
    bool isDebugMode = false,
  }) async {
    return await _isd.ClientDatabaseSession.open(
      path,
      _il2as5qe.Protocol(),
      clientMigrations: MigrationRegistry.migrations,
      runMigrations: runMigrations,
      isDebugMode: isDebugMode,
    );
  }

  /// Creates a new client-side database session for the given path, wrapped
  /// with the `serverpod_offline_sync` engine for the tables declared with
  /// `database: sync`. See [createSession] for the [path], [runMigrations] and
  /// [isDebugMode] parameters.
  ///
  /// The [persistentUserId] is the user all local operations belong to. When
  /// omitted, the user must be passed through the transaction.
  _ida.Future<_ipulbpi2.OfflineSyncDatabaseSession> createSyncSession(
    String path, {
    bool runMigrations = true,
    bool isDebugMode = false,
    _isc.UuidValue? persistentUserId,
  }) async {
    final session = _ipulbpi2.OfflineSyncDatabaseSession.wraps(
      await createSession(
        path,
        runMigrations: runMigrations,
        isDebugMode: isDebugMode,
      ),
      syncTables: _ii3f3u05.syncTables,
      persistentUserId: persistentUserId,
    );
    await session.db.initialize();
    return session;
  }
}
