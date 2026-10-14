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
import 'package:chorus_server/src/generated/circles/circle_role.dart'
    as _iwu0lutr;
import 'package:chorus_server/src/generated/future_calls.dart' as _i1wquigt;
import 'package:chorus_server/src/generated/live/live_event.dart' as _iclh8zz1;
import 'package:chorus_server/src/generated/media/media_kind.dart' as _inazphuo;
import 'package:chorus_server/src/generated/scenes/scene_spot_info.dart'
    as _ipw1gwuw;
import 'package:chorus_server/src/generated/wordlog/word_use_entry.dart'
    as _i1jjj2rd;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _iais;
import 'package:serverpod_offline_sync_server/serverpod_offline_sync_server.dart'
    as _izehhkf5;
import '../auth/email_idp_endpoint.dart' as _iuc1hd5t;
import '../auth/jwt_refresh_endpoint.dart' as _inwq3ztq;
import '../circles/circle_endpoint.dart' as _ixefnrd7;
import '../circles/status_endpoint.dart' as _iy5k9ngi;
import '../copies/board_copy_endpoint.dart' as _igbglv03;
import '../greetings/greeting_endpoint.dart' as _il624ik7;
import '../live/live_endpoint.dart' as _i4k4ewet;
import '../media/media_endpoint.dart' as _i9ppd1x8;
import '../practice/practice_endpoint.dart' as _i56xzqly;
import '../printing/printing_endpoint.dart' as _i0tflb56;
import '../scenes/scene_endpoint.dart' as _iakn3uy1;
import '../sharing/sharing_endpoint.dart' as _ifnilofz;
import '../suggest/suggest_endpoint.dart' as _idurguj6;
import '../summary/summary_endpoint.dart' as _ipr0xx8n;
import '../trust/device_seen_endpoint.dart' as _ixbcgbh7;
import '../wordlog/word_log_endpoint.dart' as _ivqq1yo7;
export 'future_calls.dart' show ServerpodFutureCallsGetter;

class Endpoints extends _is.EndpointDispatch {
  @override
  void initializeEndpoints(_is.Server server) {
    var endpoints = <String, _is.Endpoint>{
      'emailIdp': _iuc1hd5t.EmailIdpEndpoint()
        ..initialize(
          server,
          'emailIdp',
          null,
        ),
      'jwtRefresh': _inwq3ztq.JwtRefreshEndpoint()
        ..initialize(
          server,
          'jwtRefresh',
          null,
        ),
      'circle': _ixefnrd7.CircleEndpoint()
        ..initialize(
          server,
          'circle',
          null,
        ),
      'status': _iy5k9ngi.StatusEndpoint()
        ..initialize(
          server,
          'status',
          null,
        ),
      'boardCopy': _igbglv03.BoardCopyEndpoint()
        ..initialize(
          server,
          'boardCopy',
          null,
        ),
      'greeting': _il624ik7.GreetingEndpoint()
        ..initialize(
          server,
          'greeting',
          null,
        ),
      'live': _i4k4ewet.LiveEndpoint()
        ..initialize(
          server,
          'live',
          null,
        ),
      'media': _i9ppd1x8.MediaEndpoint()
        ..initialize(
          server,
          'media',
          null,
        ),
      'practice': _i56xzqly.PracticeEndpoint()
        ..initialize(
          server,
          'practice',
          null,
        ),
      'printing': _i0tflb56.PrintingEndpoint()
        ..initialize(
          server,
          'printing',
          null,
        ),
      'scene': _iakn3uy1.SceneEndpoint()
        ..initialize(
          server,
          'scene',
          null,
        ),
      'sharing': _ifnilofz.SharingEndpoint()
        ..initialize(
          server,
          'sharing',
          null,
        ),
      'suggest': _idurguj6.SuggestEndpoint()
        ..initialize(
          server,
          'suggest',
          null,
        ),
      'summary': _ipr0xx8n.SummaryEndpoint()
        ..initialize(
          server,
          'summary',
          null,
        ),
      'deviceSeen': _ixbcgbh7.DeviceSeenEndpoint()
        ..initialize(
          server,
          'deviceSeen',
          null,
        ),
      'wordLog': _ivqq1yo7.WordLogEndpoint()
        ..initialize(
          server,
          'wordLog',
          null,
        ),
    };
    connectors['emailIdp'] = _is.EndpointConnector(
      name: 'emailIdp',
      endpoint: endpoints['emailIdp']!,
      methodConnectors: {
        'login': _is.MethodConnector(
          name: 'login',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint).login(
                    session,
                    email: params['email'],
                    password: params['password'],
                  ),
        ),
        'startRegistration': _is.MethodConnector(
          name: 'startRegistration',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .startRegistration(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyRegistrationCode': _is.MethodConnector(
          name: 'verifyRegistrationCode',
          params: {
            'accountRequestId': _is.ParameterDescription(
              name: 'accountRequestId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _is.ParameterDescription(
              name: 'verificationCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .verifyRegistrationCode(
                    session,
                    accountRequestId: params['accountRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishRegistration': _is.MethodConnector(
          name: 'finishRegistration',
          params: {
            'registrationToken': _is.ParameterDescription(
              name: 'registrationToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .finishRegistration(
                    session,
                    registrationToken: params['registrationToken'],
                    password: params['password'],
                  ),
        ),
        'startPasswordReset': _is.MethodConnector(
          name: 'startPasswordReset',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .startPasswordReset(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyPasswordResetCode': _is.MethodConnector(
          name: 'verifyPasswordResetCode',
          params: {
            'passwordResetRequestId': _is.ParameterDescription(
              name: 'passwordResetRequestId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _is.ParameterDescription(
              name: 'verificationCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .verifyPasswordResetCode(
                    session,
                    passwordResetRequestId: params['passwordResetRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishPasswordReset': _is.MethodConnector(
          name: 'finishPasswordReset',
          params: {
            'finishPasswordResetToken': _is.ParameterDescription(
              name: 'finishPasswordResetToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'newPassword': _is.ParameterDescription(
              name: 'newPassword',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .finishPasswordReset(
                    session,
                    finishPasswordResetToken:
                        params['finishPasswordResetToken'],
                    newPassword: params['newPassword'],
                  ),
        ),
        'hasAccount': _is.MethodConnector(
          name: 'hasAccount',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .hasAccount(session),
        ),
      },
    );
    connectors['jwtRefresh'] = _is.EndpointConnector(
      name: 'jwtRefresh',
      endpoint: endpoints['jwtRefresh']!,
      methodConnectors: {
        'refreshAccessToken': _is.MethodConnector(
          name: 'refreshAccessToken',
          params: {
            'refreshToken': _is.ParameterDescription(
              name: 'refreshToken',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['jwtRefresh'] as _inwq3ztq.JwtRefreshEndpoint)
                      .refreshAccessToken(
                        session,
                        refreshToken: params['refreshToken'],
                      ),
        ),
      },
    );
    connectors['circle'] = _is.EndpointConnector(
      name: 'circle',
      endpoint: endpoints['circle']!,
      methodConnectors: {
        'createCircle': _is.MethodConnector(
          name: 'createCircle',
          params: {
            'childName': _is.ParameterDescription(
              name: 'childName',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'displayName': _is.ParameterDescription(
              name: 'displayName',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['circle'] as _ixefnrd7.CircleEndpoint)
                  .createCircle(
                    session,
                    params['childName'],
                    params['displayName'],
                  ),
        ),
        'myCircles': _is.MethodConnector(
          name: 'myCircles',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['circle'] as _ixefnrd7.CircleEndpoint)
                  .myCircles(session),
        ),
        'createInvite': _is.MethodConnector(
          name: 'createInvite',
          params: {
            'circleSpace': _is.ParameterDescription(
              name: 'circleSpace',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'role': _is.ParameterDescription(
              name: 'role',
              type: _is.getType<_iwu0lutr.CircleRole>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['circle'] as _ixefnrd7.CircleEndpoint)
                  .createInvite(
                    session,
                    params['circleSpace'],
                    params['role'],
                  ),
        ),
        'acceptInvite': _is.MethodConnector(
          name: 'acceptInvite',
          params: {
            'code': _is.ParameterDescription(
              name: 'code',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'displayName': _is.ParameterDescription(
              name: 'displayName',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['circle'] as _ixefnrd7.CircleEndpoint)
                  .acceptInvite(
                    session,
                    params['code'],
                    params['displayName'],
                  ),
        ),
      },
    );
    connectors['status'] = _is.EndpointConnector(
      name: 'status',
      endpoint: endpoints['status']!,
      methodConnectors: {
        'info': _is.MethodConnector(
          name: 'info',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['status'] as _iy5k9ngi.StatusEndpoint).info(
                session,
              ),
        ),
      },
    );
    connectors['boardCopy'] = _is.EndpointConnector(
      name: 'boardCopy',
      endpoint: endpoints['boardCopy']!,
      methodConnectors: {
        'take': _is.MethodConnector(
          name: 'take',
          params: {
            'circleSpace': _is.ParameterDescription(
              name: 'circleSpace',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'boardId': _is.ParameterDescription(
              name: 'boardId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['boardCopy'] as _igbglv03.BoardCopyEndpoint).take(
                    session,
                    params['circleSpace'],
                    params['boardId'],
                    params['name'],
                  ),
        ),
        'list': _is.MethodConnector(
          name: 'list',
          params: {
            'circleSpace': _is.ParameterDescription(
              name: 'circleSpace',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['boardCopy'] as _igbglv03.BoardCopyEndpoint).list(
                    session,
                    params['circleSpace'],
                  ),
        ),
        'get': _is.MethodConnector(
          name: 'get',
          params: {
            'circleSpace': _is.ParameterDescription(
              name: 'circleSpace',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'copyId': _is.ParameterDescription(
              name: 'copyId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['boardCopy'] as _igbglv03.BoardCopyEndpoint).get(
                    session,
                    params['circleSpace'],
                    params['copyId'],
                  ),
        ),
        'delete': _is.MethodConnector(
          name: 'delete',
          params: {
            'circleSpace': _is.ParameterDescription(
              name: 'circleSpace',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'copyId': _is.ParameterDescription(
              name: 'copyId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['boardCopy'] as _igbglv03.BoardCopyEndpoint)
                  .delete(
                    session,
                    params['circleSpace'],
                    params['copyId'],
                  ),
        ),
      },
    );
    connectors['greeting'] = _is.EndpointConnector(
      name: 'greeting',
      endpoint: endpoints['greeting']!,
      methodConnectors: {
        'hello': _is.MethodConnector(
          name: 'hello',
          params: {
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['greeting'] as _il624ik7.GreetingEndpoint).hello(
                    session,
                    params['name'],
                  ),
        ),
      },
    );
    connectors['live'] = _is.EndpointConnector(
      name: 'live',
      endpoint: endpoints['live']!,
      methodConnectors: {
        'join': _is.MethodStreamConnector(
          name: 'join',
          params: {
            'circleSpace': _is.ParameterDescription(
              name: 'circleSpace',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          streamParams: {
            'outgoing': _is.StreamParameterDescription<_iclh8zz1.LiveEvent>(
              name: 'outgoing',
              nullable: false,
            ),
          },
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['live'] as _i4k4ewet.LiveEndpoint).join(
                session,
                params['circleSpace'],
                streamParams['outgoing']!.cast<_iclh8zz1.LiveEvent>(),
              ),
        ),
      },
    );
    connectors['media'] = _is.EndpointConnector(
      name: 'media',
      endpoint: endpoints['media']!,
      methodConnectors: {
        'requestUpload': _is.MethodConnector(
          name: 'requestUpload',
          params: {
            'circleSpace': _is.ParameterDescription(
              name: 'circleSpace',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'sha256': _is.ParameterDescription(
              name: 'sha256',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'kind': _is.ParameterDescription(
              name: 'kind',
              type: _is.getType<_inazphuo.MediaKind>(),
              nullable: false,
            ),
            'bytes': _is.ParameterDescription(
              name: 'bytes',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['media'] as _i9ppd1x8.MediaEndpoint).requestUpload(
                    session,
                    params['circleSpace'],
                    params['sha256'],
                    params['kind'],
                    params['bytes'],
                  ),
        ),
        'confirmUpload': _is.MethodConnector(
          name: 'confirmUpload',
          params: {
            'circleSpace': _is.ParameterDescription(
              name: 'circleSpace',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'sha256': _is.ParameterDescription(
              name: 'sha256',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['media'] as _i9ppd1x8.MediaEndpoint).confirmUpload(
                    session,
                    params['circleSpace'],
                    params['sha256'],
                  ),
        ),
        'downloadUrls': _is.MethodConnector(
          name: 'downloadUrls',
          params: {
            'circleSpace': _is.ParameterDescription(
              name: 'circleSpace',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'hashes': _is.ParameterDescription(
              name: 'hashes',
              type: _is.getType<List<String>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['media'] as _i9ppd1x8.MediaEndpoint).downloadUrls(
                    session,
                    params['circleSpace'],
                    params['hashes'],
                  ),
        ),
      },
    );
    connectors['practice'] = _is.EndpointConnector(
      name: 'practice',
      endpoint: endpoints['practice']!,
      methodConnectors: {
        'partnerWord': _is.MethodConnector(
          name: 'partnerWord',
          params: {
            'circleSpace': _is.ParameterDescription(
              name: 'circleSpace',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'boardId': _is.ParameterDescription(
              name: 'boardId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'cellKey': _is.ParameterDescription(
              name: 'cellKey',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['practice'] as _i56xzqly.PracticeEndpoint)
                  .partnerWord(
                    session,
                    params['circleSpace'],
                    params['boardId'],
                    params['cellKey'],
                  ),
        ),
      },
    );
    connectors['printing'] = _is.EndpointConnector(
      name: 'printing',
      endpoint: endpoints['printing']!,
      methodConnectors: {
        'publishBoard': _is.MethodConnector(
          name: 'publishBoard',
          params: {
            'circleSpace': _is.ParameterDescription(
              name: 'circleSpace',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'boardJson': _is.ParameterDescription(
              name: 'boardJson',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['printing'] as _i0tflb56.PrintingEndpoint)
                  .publishBoard(
                    session,
                    params['circleSpace'],
                    params['boardJson'],
                  ),
        ),
        'pageUrl': _is.MethodConnector(
          name: 'pageUrl',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['printing'] as _i0tflb56.PrintingEndpoint).pageUrl(
                    session,
                    params['token'],
                  ),
        ),
      },
    );
    connectors['scene'] = _is.EndpointConnector(
      name: 'scene',
      endpoint: endpoints['scene']!,
      methodConnectors: {
        'list': _is.MethodConnector(
          name: 'list',
          params: {
            'circleSpace': _is.ParameterDescription(
              name: 'circleSpace',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['scene'] as _iakn3uy1.SceneEndpoint).list(
                session,
                params['circleSpace'],
              ),
        ),
        'create': _is.MethodConnector(
          name: 'create',
          params: {
            'circleSpace': _is.ParameterDescription(
              name: 'circleSpace',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'imageHash': _is.ParameterDescription(
              name: 'imageHash',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['scene'] as _iakn3uy1.SceneEndpoint).create(
                session,
                params['circleSpace'],
                params['name'],
                params['imageHash'],
              ),
        ),
        'rename': _is.MethodConnector(
          name: 'rename',
          params: {
            'circleSpace': _is.ParameterDescription(
              name: 'circleSpace',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'sceneId': _is.ParameterDescription(
              name: 'sceneId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['scene'] as _iakn3uy1.SceneEndpoint).rename(
                session,
                params['circleSpace'],
                params['sceneId'],
                params['name'],
              ),
        ),
        'archive': _is.MethodConnector(
          name: 'archive',
          params: {
            'circleSpace': _is.ParameterDescription(
              name: 'circleSpace',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'sceneId': _is.ParameterDescription(
              name: 'sceneId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['scene'] as _iakn3uy1.SceneEndpoint).archive(
                    session,
                    params['circleSpace'],
                    params['sceneId'],
                  ),
        ),
        'setSpots': _is.MethodConnector(
          name: 'setSpots',
          params: {
            'circleSpace': _is.ParameterDescription(
              name: 'circleSpace',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'sceneId': _is.ParameterDescription(
              name: 'sceneId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'spots': _is.ParameterDescription(
              name: 'spots',
              type: _is.getType<List<_ipw1gwuw.SceneSpotInfo>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['scene'] as _iakn3uy1.SceneEndpoint).setSpots(
                    session,
                    params['circleSpace'],
                    params['sceneId'],
                    params['spots'],
                  ),
        ),
      },
    );
    connectors['sharing'] = _is.EndpointConnector(
      name: 'sharing',
      endpoint: endpoints['sharing']!,
      methodConnectors: {
        'publishViewOnly': _is.MethodConnector(
          name: 'publishViewOnly',
          params: {
            'circleSpace': _is.ParameterDescription(
              name: 'circleSpace',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'boardJson': _is.ParameterDescription(
              name: 'boardJson',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sharing'] as _ifnilofz.SharingEndpoint)
                  .publishViewOnly(
                    session,
                    params['circleSpace'],
                    params['boardJson'],
                  ),
        ),
        'withdraw': _is.MethodConnector(
          name: 'withdraw',
          params: {
            'circleSpace': _is.ParameterDescription(
              name: 'circleSpace',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sharing'] as _ifnilofz.SharingEndpoint).withdraw(
                    session,
                    params['circleSpace'],
                    params['token'],
                  ),
        ),
        'exportUrl': _is.MethodConnector(
          name: 'exportUrl',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sharing'] as _ifnilofz.SharingEndpoint).exportUrl(
                    session,
                    params['token'],
                  ),
        ),
      },
    );
    connectors['suggest'] = _is.EndpointConnector(
      name: 'suggest',
      endpoint: endpoints['suggest']!,
      methodConnectors: {
        'fromPhoto': _is.MethodConnector(
          name: 'fromPhoto',
          params: {
            'circleSpace': _is.ParameterDescription(
              name: 'circleSpace',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'imageSha256': _is.ParameterDescription(
              name: 'imageSha256',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'locale': _is.ParameterDescription(
              name: 'locale',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['suggest'] as _idurguj6.SuggestEndpoint).fromPhoto(
                    session,
                    params['circleSpace'],
                    params['imageSha256'],
                    params['locale'],
                  ),
        ),
      },
    );
    connectors['summary'] = _is.EndpointConnector(
      name: 'summary',
      endpoint: endpoints['summary']!,
      methodConnectors: {
        'week': _is.MethodConnector(
          name: 'week',
          params: {
            'circleSpace': _is.ParameterDescription(
              name: 'circleSpace',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'weekStart': _is.ParameterDescription(
              name: 'weekStart',
              type: _is.getType<DateTime?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['summary'] as _ipr0xx8n.SummaryEndpoint).week(
                    session,
                    params['circleSpace'],
                    params['weekStart'],
                  ),
        ),
      },
    );
    connectors['deviceSeen'] = _is.EndpointConnector(
      name: 'deviceSeen',
      endpoint: endpoints['deviceSeen']!,
      methodConnectors: {
        'heartbeat': _is.MethodConnector(
          name: 'heartbeat',
          params: {
            'circleSpace': _is.ParameterDescription(
              name: 'circleSpace',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'deviceId': _is.ParameterDescription(
              name: 'deviceId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'deviceLabel': _is.ParameterDescription(
              name: 'deviceLabel',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'lastSyncAt': _is.ParameterDescription(
              name: 'lastSyncAt',
              type: _is.getType<DateTime>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['deviceSeen'] as _ixbcgbh7.DeviceSeenEndpoint)
                      .heartbeat(
                        session,
                        params['circleSpace'],
                        params['deviceId'],
                        params['deviceLabel'],
                        params['lastSyncAt'],
                      ),
        ),
        'devices': _is.MethodConnector(
          name: 'devices',
          params: {
            'circleSpace': _is.ParameterDescription(
              name: 'circleSpace',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['deviceSeen'] as _ixbcgbh7.DeviceSeenEndpoint)
                      .devices(
                        session,
                        params['circleSpace'],
                      ),
        ),
      },
    );
    connectors['wordLog'] = _is.EndpointConnector(
      name: 'wordLog',
      endpoint: endpoints['wordLog']!,
      methodConnectors: {
        'status': _is.MethodConnector(
          name: 'status',
          params: {
            'circleSpace': _is.ParameterDescription(
              name: 'circleSpace',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['wordLog'] as _ivqq1yo7.WordLogEndpoint).status(
                    session,
                    params['circleSpace'],
                  ),
        ),
        'setEnabled': _is.MethodConnector(
          name: 'setEnabled',
          params: {
            'circleSpace': _is.ParameterDescription(
              name: 'circleSpace',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'enabled': _is.ParameterDescription(
              name: 'enabled',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['wordLog'] as _ivqq1yo7.WordLogEndpoint)
                  .setEnabled(
                    session,
                    params['circleSpace'],
                    params['enabled'],
                  ),
        ),
        'record': _is.MethodConnector(
          name: 'record',
          params: {
            'circleSpace': _is.ParameterDescription(
              name: 'circleSpace',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'uses': _is.ParameterDescription(
              name: 'uses',
              type: _is.getType<List<_i1jjj2rd.WordUseEntry>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['wordLog'] as _ivqq1yo7.WordLogEndpoint).record(
                    session,
                    params['circleSpace'],
                    params['uses'],
                  ),
        ),
        'deleteAll': _is.MethodConnector(
          name: 'deleteAll',
          params: {
            'circleSpace': _is.ParameterDescription(
              name: 'circleSpace',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['wordLog'] as _ivqq1yo7.WordLogEndpoint).deleteAll(
                    session,
                    params['circleSpace'],
                  ),
        ),
      },
    );
    modules['serverpod_auth_idp'] = _iais.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_offline_sync'] = _izehhkf5.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth_core'] = _iacs.Endpoints()
      ..initializeEndpoints(server);
  }

  @override
  _is.FutureCallDispatch? get futureCalls {
    return _i1wquigt.FutureCalls();
  }
}
