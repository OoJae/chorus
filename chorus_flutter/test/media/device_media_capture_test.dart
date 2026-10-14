import 'package:chorus_flutter/src/media/device_media_capture.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

/// The system picker. [kept] is what Android holds from a camera the app
/// was closed behind; [taken] is what the camera or library gives now.
class FakePicker extends ImagePicker {
  LostDataResponse kept = LostDataResponse.empty();

  /// Thrown instead of answering for [kept], as image_picker does in a
  /// browser and anywhere else that keeps nothing.
  Object? keptError;

  XFile? taken;

  /// Every call, oldest first.
  final List<String> calls = [];

  @override
  Future<LostDataResponse> retrieveLostData() async {
    calls.add('retrieveLostData');
    final error = keptError;
    if (error != null) throw error;
    final answer = kept;
    // The plugin hands a kept photo back once.
    kept = LostDataResponse.empty();
    return answer;
  }

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    calls.add('pickImage ${source.name}');
    return taken;
  }
}

void main() {
  late FakePicker picker;
  final keptPhoto = Uint8List.fromList(const [1, 2, 3]);
  final newPhoto = Uint8List.fromList(const [4, 5, 6]);

  setUp(() {
    picker = FakePicker()..taken = XFile.fromData(newPhoto);
  });

  LostDataResponse keep(Uint8List bytes) =>
      LostDataResponse(file: XFile.fromData(bytes), type: RetrieveType.image);

  test('a photo kept from before a restart is handed back', () async {
    picker.kept = keep(keptPhoto);
    final capture = DeviceMediaCapture(picker: picker);

    expect(await capture.pickImage(fromCamera: true), keptPhoto);
    // The camera is not opened for the same shot again.
    expect(picker.calls, ['retrieveLostData']);

    expect(await capture.pickImage(fromCamera: true), newPhoto);
    expect(picker.calls, [
      'retrieveLostData',
      'retrieveLostData',
      'pickImage camera',
    ]);
  });

  test('with nothing kept the camera opens', () async {
    final capture = DeviceMediaCapture(picker: picker);

    expect(await capture.pickImage(fromCamera: true), newPhoto);
    expect(picker.calls, ['retrieveLostData', 'pickImage camera']);
  });

  test('a kept photo that cannot be read still opens the camera', () async {
    final capture = DeviceMediaCapture(picker: picker);

    picker.keptError = PlatformException(code: 'no_access');
    expect(await capture.pickImage(fromCamera: true), newPhoto);

    picker.keptError = null;
    picker.kept = LostDataResponse(
      exception: PlatformException(code: 'camera_access_denied'),
      type: RetrieveType.image,
    );
    expect(await capture.pickImage(fromCamera: true), newPhoto);

    picker.kept = keep(Uint8List(0));
    expect(await capture.pickImage(fromCamera: true), newPhoto);

    expect(picker.calls.where((c) => c == 'pickImage camera'), hasLength(3));
  });

  test('choosing from the library does not ask for a kept photo', () async {
    picker.kept = keep(keptPhoto);
    final capture = DeviceMediaCapture(picker: picker);

    expect(await capture.pickImage(fromCamera: false), newPhoto);
    expect(picker.calls, ['pickImage gallery']);
  });

  test('in a browser the camera opens without asking', () async {
    // image_picker has no kept photos on the web and throws when asked.
    picker.keptError = UnimplementedError('getLostData');
    final capture = DeviceMediaCapture(picker: picker, web: true);

    expect(await capture.pickImage(fromCamera: true), newPhoto);
    expect(picker.calls, ['pickImage camera']);
  });

  test('on an iPhone the camera opens without asking', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    picker.keptError = UnimplementedError('getLostData');
    final capture = DeviceMediaCapture(picker: picker);

    expect(await capture.pickImage(fromCamera: true), newPhoto);
    expect(picker.calls, ['pickImage camera']);
  });
}
