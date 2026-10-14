/// The screen gallery on made-up data, with the app's own home screen, for
/// review in a browser with no server:
/// `flutter build web --release -t lib/main_gallery.dart`.
///
/// Nothing here reaches the network: the circle, its boards, the word log
/// and the links are the fakes of `chorus_ui`. See `chorus_ui`'s
/// `main_fake.dart` for the addresses each screen opens from.
library;

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_ui/contracts.dart' show CircleRoleX;
import 'package:chorus_ui/main_fake.dart' show ChorusGallery, GalleryFakes;
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/services.dart';

void main() => runApp(const ChorusGallery(home: galleryHome));

final UuidValue _space = UuidValue.fromString(
  '6f1d2c3a-0b4e-4c5d-8e9f-a1b2c3d4e5f6',
);
final UuidValue _me = UuidValue.fromString(
  'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
);

/// Maya's circle, with the signed-in adult in the role the gallery's
/// partner switch gives the store.
CircleInfo _circle(GalleryFakes fakes) {
  final role = fakes.store.role.canEdit
      ? CircleRole.guardian
      : CircleRole.partner;
  return CircleInfo(
    spaceUuid: _space,
    childName: GalleryFakes.childName,
    myRole: role,
    myDisplayName: 'Mum',
    members: [MemberInfo(userId: _me, displayName: 'Mum', role: role)],
  );
}

/// The app's [HomeScreen] on the gallery's fakes.
Widget galleryHome(BuildContext context, GalleryFakes fakes) {
  final circle = _circle(fakes);
  return HomeScreen(
    circles: [circle],
    selected: circle,
    onSelect: (_) {},
    store: fakes.store,
    sync: fakes.sync,
    speech: fakes.speech,
    gateway: const _GalleryGateway(),
    readiness: CircleReadiness.ready,
    onRetryReady: () {},
    onSignOut: () => Navigator.of(context).maybePop(),
    services: CircleServices(
      userId: _me.uuid,
      media: fakes.media,
      speaker: fakes.speaker,
      capture: fakes.store.role.canEdit ? fakes.capture : null,
      publishBoard: (_) async => 'https://chorus.example/print/gallery',
      wordLog: fakes.wordLog,
      summary: fakes.summary,
      sharing: fakes.store.role.canEdit ? fakes.sharing : null,
      boards: fakes.store.role.canEdit ? fakes.store : null,
    ),
  );
}

/// Circle calls answered on the device: only "Invite someone" asks, and
/// gets a made-up code.
class _GalleryGateway implements CircleGateway {
  const _GalleryGateway();

  @override
  Future<List<CircleInfo>> myCircles() async => const [];

  @override
  Future<List<CircleInfo>> rememberedCircles() async => const [];

  @override
  Future<CircleInfo> createCircle({
    required String childName,
    required String displayName,
  }) => throw UnsupportedError('The gallery makes no circles.');

  @override
  Future<CircleInfo> acceptInvite({
    required String code,
    required String displayName,
  }) => throw UnsupportedError('The gallery joins no circles.');

  @override
  Future<String> createInvite(CircleInfo circle, CircleRole role) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return 'K7QP-2MXD';
  }

  @override
  Future<void> signOut() async {}
}
