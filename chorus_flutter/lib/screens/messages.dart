/// Plain-words text for failures and roles.
library;

import 'package:chorus_client/chorus_client.dart';

/// What to tell an adult when a server call failed with [error].
String failureMessage(Object error) {
  if (error is CircleException) {
    return switch (error.failure) {
      CircleFailure.notAMember =>
        'You are no longer part of this circle. Ask a parent or guardian '
            'to invite you again.',
      CircleFailure.notAllowed => 'Only a parent or guardian can do that.',
      CircleFailure.inviteInvalid =>
        'That code was not recognised. Check it and try again.',
      CircleFailure.inviteExpired =>
        'That code has run out. Ask for a new one.',
      CircleFailure.inviteUsed =>
        'That code has already been used. Ask for a new one.',
    };
  }
  return 'Chorus could not reach the server. Check the connection and '
      'try again.';
}

/// How a role is named to the adults in a circle.
String roleLabel(CircleRole role) => switch (role) {
  CircleRole.guardian => 'Parent or guardian',
  CircleRole.therapist => 'Therapist',
  CircleRole.teacher => 'Teacher',
  CircleRole.partner => 'Family or friend who can view',
};

/// What the role may do, in one line.
String roleDetail(CircleRole role) => switch (role) {
  CircleRole.guardian => 'Can change the board and invite people.',
  CircleRole.therapist => 'Can change the board.',
  CircleRole.teacher => 'Can change the board.',
  CircleRole.partner => 'Can see the board but not change it.',
};
