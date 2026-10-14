// The seen-onboarding flag: kept in a small file on this device, false
// when it was never saved or cannot be read, and remembered for the run.
import 'dart:io';

import 'package:chorus_flutter/src/local_flags.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _pathProvider = MethodChannel('plugins.flutter.io/path_provider');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('with no storage the flag is false, saving is quiet, and the run '
      'remembers what was saved', () async {
    final flags = LocalFlags();
    expect(flags.known(LocalFlag.seenOnboarding), isNull);
    expect(await flags.read(LocalFlag.seenOnboarding), isFalse);

    await flags.write(LocalFlag.seenOnboarding, true);
    expect(flags.known(LocalFlag.seenOnboarding), isTrue);
    expect(await flags.read(LocalFlag.seenOnboarding), isTrue);

    // A new start knows nothing of it.
    expect(await LocalFlags().read(LocalFlag.seenOnboarding), isFalse);
  });

  group('on a device with storage', () {
    late Directory dir;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('chorus_flags_');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_pathProvider, (call) async => dir.path);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_pathProvider, null);
      dir.deleteSync(recursive: true);
    });

    test('the flag lasts to the next start', () async {
      expect(await LocalFlags().read(LocalFlag.seenOnboarding), isFalse);

      await LocalFlags().write(LocalFlag.seenOnboarding, true);
      expect(
        File(
          '${dir.path}/${LocalFlag.seenOnboarding.fileName}',
        ).readAsStringSync(),
        'yes',
      );
      expect(await LocalFlags().read(LocalFlag.seenOnboarding), isTrue);

      await LocalFlags().write(LocalFlag.seenOnboarding, false);
      expect(await LocalFlags().read(LocalFlag.seenOnboarding), isFalse);
    });

    test('a file that says anything else is not a yes', () async {
      File(
        '${dir.path}/${LocalFlag.seenOnboarding.fileName}',
      ).writeAsStringSync('maybe');
      expect(await LocalFlags().read(LocalFlag.seenOnboarding), isFalse);
    });
  });
}
